import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/new_reservation_models.dart';

class InventoryHoldService {
  InventoryHoldService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> setHold({
    required String cartId,
    required ReservationResource resource,
    required num quantity,
  }) async {
    if (resource.type == ReservationResourceType.room) return;
    await _client.rpc(
      'hold_inventory',
      params: {
        'p_cart_id': cartId,
        'p_resource_type': _resourceType(resource),
        'p_resource_id': resource.id,
        'p_quantity': quantity,
      },
    );
  }

  Future<void> releaseResource({
    required String cartId,
    required ReservationResource resource,
  }) async {
    if (resource.type == ReservationResourceType.room) return;
    await _client.rpc(
      'release_inventory_hold',
      params: {
        'p_cart_id': cartId,
        'p_resource_type': _resourceType(resource),
        'p_resource_id': resource.id,
      },
    );
  }

  Future<void> releaseAll(String cartId) async {
    await _client.rpc(
      'release_all_inventory_holds',
      params: {'p_cart_id': cartId},
    );
  }

  Future<int> finalize({
    required String cartId,
    required int reservationId,
    required int expectedItems,
  }) async {
    final result = await _client.rpc(
      'finalize_inventory_holds',
      params: {
        'p_cart_id': cartId,
        'p_reservation_id': reservationId,
        'p_expected_items': expectedItems,
      },
    );
    return (result as num?)?.toInt() ?? 0;
  }

  String _resourceType(ReservationResource resource) {
    return resource.type == ReservationResourceType.chemical
        ? 'chemical'
        : 'asset';
  }
}
