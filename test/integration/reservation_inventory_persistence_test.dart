import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:admin_scalib/features/reservations/new_reservation/models/new_reservation_models.dart';
import 'package:admin_scalib/features/reservations/new_reservation/services/new_reservation_service.dart';

const _email = String.fromEnvironment('LIVE_TEST_EMAIL');
const _password = String.fromEnvironment('LIVE_TEST_PASSWORD');

void main() {
  test(
    'authenticated reservation persists chemical, equipment, and glassware deductions',
    () async {
      final env = await _readEnv();
      final client = SupabaseClient(
        env['SUPABASE_URL']!,
        env['SUPABASE_ANON_KEY']!,
      );
      await client.auth.signInWithPassword(email: _email, password: _password);

      final service = NewReservationService(client: client);
      final accounts = await service.loadReservationAccounts();
      final account = accounts.singleWhere(
        (value) => value.id == client.auth.currentUser!.id,
      );
      expect(account.canReserve, isTrue);
      final resources = await service.loadResources();
      final selected = <ReservationResource>[
        resources.firstWhere(
          (value) =>
              value.type == ReservationResourceType.chemical &&
              value.availableQuantity >= 2,
        ),
        resources.firstWhere(
          (value) =>
              value.type == ReservationResourceType.equipment &&
              value.availableQuantity >= 2,
        ),
        resources.firstWhere(
          (value) =>
              value.type == ReservationResourceType.glassware &&
              value.availableQuantity >= 2,
        ),
      ];
      final original = {
        for (final resource in selected)
          resource.key: resource.availableQuantity,
      };
      final request = NewReservationRequest(
        account: account,
        date: _nextWeekday(),
        startMinutes: 7 * 60,
        endMinutes: 7 * 60 + 30,
        items: [
          for (final resource in selected)
            ReservationCartItem(resource: resource, quantity: 2),
        ],
        additionalNote: 'Automated inventory persistence verification',
      );

      int? reservationId;
      try {
        reservationId = await service.createReservation(request);

        final reservation = await client
            .from('reservations')
            .select('inventory_deducted')
            .eq('reservation_id', reservationId)
            .single();
        expect(reservation['inventory_deducted'], isTrue);

        final afterFirstDeduction = await _readStocks(client, selected);
        for (final resource in selected) {
          expect(
            afterFirstDeduction[resource.key],
            closeTo(original[resource.key]! - 2, 0.001),
          );
        }

        await client.rpc(
          'deduct_reservation_inventory',
          params: {'p_reservation_id': reservationId},
        );
        final afterRetry = await _readStocks(client, selected);
        expect(afterRetry, afterFirstDeduction);
      } finally {
        if (reservationId != null) {
          for (final resource in selected) {
            if (resource.type == ReservationResourceType.chemical) {
              await client
                  .from('chemicals')
                  .update({'stock_quantity': original[resource.key]})
                  .eq('chemical_id', resource.id);
            } else {
              await client
                  .from('lab_assets')
                  .update({'available_stock': original[resource.key]!.toInt()})
                  .eq('asset_id', resource.id);
            }
          }
          await client
              .from('reservation_items')
              .delete()
              .eq('reservation_id', reservationId);
          await client
              .from('chemical_usage')
              .delete()
              .eq('reservation_id', reservationId);
          await client
              .from('reservations')
              .delete()
              .eq('reservation_id', reservationId);
        }
        await client.auth.signOut();
      }
    },
    skip: _email.isEmpty || _password.isEmpty
        ? 'Pass LIVE_TEST_EMAIL and LIVE_TEST_PASSWORD with --dart-define.'
        : false,
  );
}

Future<Map<String, String>> _readEnv() async {
  final lines = await File('.env').readAsLines();
  final values = <String, String>{};
  for (final line in lines) {
    final separator = line.indexOf('=');
    if (separator <= 0) continue;
    values[line.substring(0, separator)] = line.substring(separator + 1);
  }
  return values;
}

DateTime _nextWeekday() {
  var date = DateTime.now().add(const Duration(days: 1));
  while (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
    date = date.add(const Duration(days: 1));
  }
  return DateTime(date.year, date.month, date.day);
}

Future<Map<String, num>> _readStocks(
  SupabaseClient client,
  List<ReservationResource> resources,
) async {
  final values = <String, num>{};
  for (final resource in resources) {
    if (resource.type == ReservationResourceType.chemical) {
      final row = await client
          .from('chemicals')
          .select('stock_quantity')
          .eq('chemical_id', resource.id)
          .single();
      values[resource.key] = row['stock_quantity'] as num;
    } else {
      final row = await client
          .from('lab_assets')
          .select('available_stock')
          .eq('asset_id', resource.id)
          .single();
      values[resource.key] = row['available_stock'] as num;
    }
  }
  return values;
}
