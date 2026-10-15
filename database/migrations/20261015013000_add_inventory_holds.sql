-- Atomic, expiring stock holds for the admin walk-in reservation cart.
CREATE TABLE IF NOT EXISTS public.inventory_holds (
  hold_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cart_id text NOT NULL,
  reservation_id integer REFERENCES public.reservations(reservation_id),
  resource_type text NOT NULL CHECK (resource_type IN ('asset', 'chemical')),
  asset_id integer REFERENCES public.lab_assets(asset_id),
  chemical_id integer REFERENCES public.chemicals(chemical_id),
  quantity numeric NOT NULL CHECK (quantity > 0),
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'finalized', 'released', 'expired')),
  expires_at timestamp with time zone NOT NULL DEFAULT (now() + interval '15 minutes'),
  created_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT inventory_holds_one_resource CHECK (
    (resource_type = 'asset' AND asset_id IS NOT NULL AND chemical_id IS NULL)
    OR (resource_type = 'chemical' AND chemical_id IS NOT NULL AND asset_id IS NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS inventory_holds_active_cart_resource
  ON public.inventory_holds (cart_id, resource_type, COALESCE(asset_id, chemical_id))
  WHERE status = 'active';

ALTER TABLE public.inventory_holds ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.release_expired_inventory_holds()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  hold_item record;
BEGIN
  FOR hold_item IN
    SELECT * FROM public.inventory_holds
    WHERE status = 'active' AND expires_at <= now()
    FOR UPDATE
  LOOP
    IF hold_item.resource_type = 'asset' THEN
      UPDATE public.lab_assets
         SET available_stock = available_stock + hold_item.quantity::integer,
             updated_at = now()
       WHERE asset_id = hold_item.asset_id;
    ELSE
      UPDATE public.chemicals
         SET stock_quantity = stock_quantity + hold_item.quantity,
             updated_at = now()
       WHERE chemical_id = hold_item.chemical_id;
    END IF;
    UPDATE public.inventory_holds
       SET status = 'expired', updated_at = now()
     WHERE hold_id = hold_item.hold_id;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.hold_inventory(
  p_cart_id text,
  p_resource_type text,
  p_resource_id integer,
  p_quantity numeric
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_hold numeric := 0;
  delta numeric;
  hold_id_value uuid;
BEGIN
  IF auth.uid() IS NULL OR p_cart_id IS NULL OR p_quantity <= 0 THEN
    RAISE EXCEPTION 'Invalid inventory hold request.' USING ERRCODE = '22023';
  END IF;
  PERFORM public.release_expired_inventory_holds();

  SELECT hold_id, quantity INTO hold_id_value, current_hold
    FROM public.inventory_holds
   WHERE cart_id = p_cart_id
     AND resource_type = p_resource_type
     AND ((p_resource_type = 'asset' AND asset_id = p_resource_id)
       OR (p_resource_type = 'chemical' AND chemical_id = p_resource_id))
     AND status = 'active'
     AND created_by = auth.uid()
   FOR UPDATE;

  delta := p_quantity - COALESCE(current_hold, 0);
  IF p_resource_type = 'asset' THEN
    IF p_quantity <> trunc(p_quantity) THEN
      RAISE EXCEPTION 'Asset quantity must be whole.' USING ERRCODE = '22023';
    END IF;
    IF delta > 0 THEN
      UPDATE public.lab_assets
         SET available_stock = available_stock - delta::integer, updated_at = now()
       WHERE asset_id = p_resource_id AND COALESCE(available_stock, 0) >= delta::integer;
      IF NOT FOUND THEN RAISE EXCEPTION 'Insufficient asset stock.' USING ERRCODE = '23514'; END IF;
    ELSIF delta < 0 THEN
      UPDATE public.lab_assets
         SET available_stock = available_stock + abs(delta)::integer, updated_at = now()
       WHERE asset_id = p_resource_id;
    END IF;
  ELSIF p_resource_type = 'chemical' THEN
    IF delta > 0 THEN
      UPDATE public.chemicals
         SET stock_quantity = stock_quantity - delta, updated_at = now()
       WHERE chemical_id = p_resource_id AND COALESCE(stock_quantity, 0) >= delta;
      IF NOT FOUND THEN RAISE EXCEPTION 'Insufficient chemical stock.' USING ERRCODE = '23514'; END IF;
    ELSIF delta < 0 THEN
      UPDATE public.chemicals
         SET stock_quantity = stock_quantity + abs(delta), updated_at = now()
       WHERE chemical_id = p_resource_id;
    END IF;
  ELSE
    RAISE EXCEPTION 'Invalid inventory resource type.' USING ERRCODE = '22023';
  END IF;

  IF hold_id_value IS NULL THEN
    INSERT INTO public.inventory_holds
      (cart_id, resource_type, asset_id, chemical_id, quantity, created_by)
    VALUES (
      p_cart_id, p_resource_type,
      CASE WHEN p_resource_type = 'asset' THEN p_resource_id END,
      CASE WHEN p_resource_type = 'chemical' THEN p_resource_id END,
      p_quantity, auth.uid()
    );
  ELSE
    UPDATE public.inventory_holds
       SET quantity = p_quantity,
           expires_at = now() + interval '15 minutes',
           updated_at = now()
     WHERE hold_id = hold_id_value;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.release_inventory_hold(
  p_cart_id text,
  p_resource_type text,
  p_resource_id integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE hold_item record;
BEGIN
  SELECT * INTO hold_item FROM public.inventory_holds
   WHERE cart_id = p_cart_id AND resource_type = p_resource_type
     AND ((p_resource_type = 'asset' AND asset_id = p_resource_id)
       OR (p_resource_type = 'chemical' AND chemical_id = p_resource_id))
     AND status = 'active'
     AND created_by = auth.uid()
   FOR UPDATE;
  IF NOT FOUND THEN RETURN; END IF;
  IF hold_item.resource_type = 'asset' THEN
    UPDATE public.lab_assets SET available_stock = available_stock + hold_item.quantity::integer, updated_at = now()
     WHERE asset_id = hold_item.asset_id;
  ELSE
    UPDATE public.chemicals SET stock_quantity = stock_quantity + hold_item.quantity, updated_at = now()
     WHERE chemical_id = hold_item.chemical_id;
  END IF;
  UPDATE public.inventory_holds SET status = 'released', updated_at = now() WHERE hold_id = hold_item.hold_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.release_all_inventory_holds(p_cart_id text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE hold_item record;
BEGIN
  FOR hold_item IN SELECT * FROM public.inventory_holds WHERE cart_id = p_cart_id AND status = 'active' AND created_by = auth.uid() FOR UPDATE LOOP
    PERFORM public.release_inventory_hold(p_cart_id, hold_item.resource_type,
      CASE WHEN hold_item.resource_type = 'asset' THEN hold_item.asset_id ELSE hold_item.chemical_id END);
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.finalize_inventory_holds(
  p_cart_id text,
  p_reservation_id integer,
  p_expected_items integer
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE hold_count integer;
BEGIN
  SELECT count(*) INTO hold_count FROM public.inventory_holds WHERE cart_id = p_cart_id AND status = 'active' AND created_by = auth.uid();
  IF hold_count <> p_expected_items THEN
    IF hold_count = 0 THEN RETURN 0; END IF;
    RAISE EXCEPTION 'Incomplete inventory holds.' USING ERRCODE = '23514';
  END IF;
  UPDATE public.inventory_holds
     SET status = 'finalized', reservation_id = p_reservation_id, updated_at = now()
   WHERE cart_id = p_cart_id AND status = 'active' AND created_by = auth.uid();
  RETURN hold_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.release_inventory_holds_for_reservation(
  p_reservation_id integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE hold_item record;
BEGIN
  FOR hold_item IN
    SELECT * FROM public.inventory_holds
     WHERE reservation_id = p_reservation_id
       AND status = 'finalized'
       AND created_by = auth.uid()
     FOR UPDATE
  LOOP
    IF hold_item.resource_type = 'asset' THEN
      UPDATE public.lab_assets
         SET available_stock = available_stock + hold_item.quantity::integer,
             updated_at = now()
       WHERE asset_id = hold_item.asset_id;
    ELSE
      UPDATE public.chemicals
         SET stock_quantity = stock_quantity + hold_item.quantity,
             updated_at = now()
       WHERE chemical_id = hold_item.chemical_id;
    END IF;
    UPDATE public.inventory_holds
       SET status = 'released', updated_at = now()
     WHERE hold_id = hold_item.hold_id;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.hold_inventory(text, text, integer, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.release_inventory_hold(text, text, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.release_all_inventory_holds(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.finalize_inventory_holds(text, integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.release_inventory_holds_for_reservation(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.release_expired_inventory_holds() TO authenticated;
