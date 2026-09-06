import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/service/cache_service.dart';
import '../models/new_reservation_models.dart';

abstract class NewReservationGateway {
  Future<List<ReservationResource>> loadResources();

  Future<List<ReservationTimeRange>> loadRoomSchedule(
    int roomId,
    DateTime date,
  );

  Future<int> createReservation(NewReservationRequest request);
}

class NewReservationService implements NewReservationGateway {
  NewReservationService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final CacheService _cache = CacheService();

  @override
  Future<List<ReservationResource>> loadResources() async {
    final results = await Future.wait([
      _client.from('rooms').select().eq('is_deleted', false).order('room_name'),
      _client
          .from('chemicals')
          .select()
          .eq('is_deleted', false)
          .order('chemical_name'),
      _client
          .from('lab_assets')
          .select()
          .eq('is_deleted', false)
          .order('item_name'),
    ]);

    final rooms = (results[0] as List).map((row) {
      final data = row as Map<String, dynamic>;
      final status = data['status']?.toString() ?? 'Unavailable';
      return ReservationResource(
        id: data['room_id'] as int,
        name: data['room_name']?.toString() ?? 'Laboratory room',
        type: ReservationResourceType.room,
        availableQuantity: status.toLowerCase() == 'available' ? 1 : 0,
        description: 'Capacity: ${data['capacity'] ?? 'Not specified'}',
        status: status,
      );
    });

    final chemicals = (results[1] as List).map((row) {
      final data = row as Map<String, dynamic>;
      final quantity = data['stock_quantity'] as num? ?? 0;
      final unit = data['unit']?.toString() ?? 'mL';
      final formula = data['formula']?.toString().trim();
      return ReservationResource(
        id: data['chemical_id'] as int,
        name: data['chemical_name']?.toString() ?? 'Chemical',
        type: ReservationResourceType.chemical,
        availableQuantity: quantity,
        description: formula == null || formula.isEmpty
            ? '$quantity $unit available'
            : '$formula · $quantity $unit available',
        unit: unit,
      );
    });

    final assets = (results[2] as List).map((row) {
      final data = row as Map<String, dynamic>;
      final category = data['category']?.toString() ?? '';
      final type = category.toLowerCase() == 'glassware'
          ? ReservationResourceType.glassware
          : ReservationResourceType.equipment;
      return ReservationResource(
        id: data['asset_id'] as int,
        name: data['item_name']?.toString() ?? category,
        type: type,
        availableQuantity: data['available_stock'] as num? ?? 0,
        description:
            data['condition_notes']?.toString().trim().isNotEmpty == true
            ? data['condition_notes'].toString()
            : '${data['available_stock'] ?? 0} available',
      );
    });

    return [...rooms, ...chemicals, ...assets];
  }

  @override
  Future<List<ReservationTimeRange>> loadRoomSchedule(
    int roomId,
    DateTime date,
  ) async {
    final dateValue = _formatDate(date);
    final rows = await _client
        .from('reservations')
        .select('start_time, end_time')
        .eq('room_id', roomId)
        .eq('reservation_date', dateValue)
        .eq('is_deleted', false)
        .inFilter('status', ['Pending', 'Approved', 'Ongoing'])
        .neq('admin_approval', 'Cancelled')
        .neq('admin_approval', 'Declined')
        .order('start_time');

    return (rows as List).map((row) {
      final data = row as Map<String, dynamic>;
      return ReservationTimeRange(
        startMinutes: _parseTime(data['start_time'].toString()),
        endMinutes: _parseTime(data['end_time'].toString()),
      );
    }).toList();
  }

  @override
  Future<int> createReservation(NewReservationRequest request) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Your session has expired. Please sign in again.');
    }

    await _validateAvailability(request);

    String adminName = user.email ?? 'Administrator';
    try {
      final profiles = await _client
          .from('user_info')
          .select('first_name, last_name, username')
          .eq('id', user.id)
          .limit(1);
      if (profiles.isNotEmpty) {
        final profile = profiles.first;
        final fullName =
            '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'
                .trim();
        adminName = fullName.isNotEmpty
            ? fullName
            : profile['username']?.toString() ?? adminName;
      }
    } catch (_) {
      // The authenticated email is a safe display fallback when profile data
      // is unavailable under the current database policy.
    }

    int? reservationId;
    final updatedAssets = <int, num>{};
    final updatedChemicals = <int, num>{};
    try {
      final inserted = await _client
          .from('reservations')
          .insert({
            'user_id': user.id,
            'room_id': request.room?.resource.id,
            'reservation_date': _formatDate(request.date),
            'start_time': minutesToDatabaseTime(request.startMinutes),
            'end_time': minutesToDatabaseTime(request.endMinutes),
            'professor': adminName,
            'professor_approval': 'Approved',
            'admin_approval': 'Approved',
            'status': 'Ongoing',
            'additional_note': request.additionalNote,
          })
          .select('reservation_id')
          .single();
      reservationId = inserted['reservation_id'] as int;

      for (final item in request.items) {
        final resource = item.resource;
        if (resource.type == ReservationResourceType.room) continue;

        if (resource.type == ReservationResourceType.chemical) {
          final row = await _client
              .from('chemicals')
              .select('stock_quantity, unit')
              .eq('chemical_id', resource.id)
              .single();
          final original = row['stock_quantity'] as num? ?? 0;
          if (original < item.quantity) {
            throw StateError('${resource.name} no longer has enough stock.');
          }
          await _client.from('chemical_usage').insert({
            'reservation_id': reservationId,
            'chemical_id': resource.id,
            'quantity_used': item.quantity,
            'unit': row['unit']?.toString() ?? resource.unit ?? 'mL',
            'purpose': request.additionalNote?.isNotEmpty == true
                ? request.additionalNote
                : 'Laboratory use',
          });
          await _client
              .from('chemicals')
              .update({'stock_quantity': original - item.quantity})
              .eq('chemical_id', resource.id);
          updatedChemicals[resource.id] = original;
        } else {
          final row = await _client
              .from('lab_assets')
              .select('available_stock')
              .eq('asset_id', resource.id)
              .single();
          final original = row['available_stock'] as num? ?? 0;
          if (original < item.quantity) {
            throw StateError('${resource.name} no longer has enough stock.');
          }
          await _client.from('reservation_items').insert({
            'reservation_id': reservationId,
            'asset_id': resource.id,
            'quantity_borrowed': item.quantity.toInt(),
            'quantity_returned': 0,
            'is_returned': false,
          });
          await _client
              .from('lab_assets')
              .update({'available_stock': original - item.quantity})
              .eq('asset_id', resource.id);
          updatedAssets[resource.id] = original;
        }
      }

      await _clearCaches();
      return reservationId;
    } catch (error) {
      await _rollback(
        reservationId: reservationId,
        assets: updatedAssets,
        chemicals: updatedChemicals,
      );
      rethrow;
    }
  }

  Future<void> _validateAvailability(NewReservationRequest request) async {
    final room = request.room;
    if (room != null) {
      final schedule = await loadRoomSchedule(room.resource.id, request.date);
      if (schedule.any(
        (range) => range.overlaps(request.startMinutes, request.endMinutes),
      )) {
        throw StateError(
          'The selected room was just reserved for this time. Choose another time or room.',
        );
      }
    }

    for (final item in request.items) {
      if (item.resource.type == ReservationResourceType.room) continue;
      final table = item.resource.type == ReservationResourceType.chemical
          ? 'chemicals'
          : 'lab_assets';
      final idColumn = item.resource.type == ReservationResourceType.chemical
          ? 'chemical_id'
          : 'asset_id';
      final stockColumn = item.resource.type == ReservationResourceType.chemical
          ? 'stock_quantity'
          : 'available_stock';
      final row = await _client
          .from(table)
          .select(stockColumn)
          .eq(idColumn, item.resource.id)
          .single();
      final current = row[stockColumn] as num? ?? 0;
      if (current < item.quantity) {
        throw StateError('${item.resource.name} only has $current available.');
      }
    }
  }

  Future<void> _rollback({
    required int? reservationId,
    required Map<int, num> assets,
    required Map<int, num> chemicals,
  }) async {
    for (final entry in assets.entries) {
      try {
        await _client
            .from('lab_assets')
            .update({'available_stock': entry.value})
            .eq('asset_id', entry.key);
      } catch (_) {}
    }
    for (final entry in chemicals.entries) {
      try {
        await _client
            .from('chemicals')
            .update({'stock_quantity': entry.value})
            .eq('chemical_id', entry.key);
      } catch (_) {}
    }
    if (reservationId != null) {
      try {
        await _client
            .from('reservation_items')
            .delete()
            .eq('reservation_id', reservationId);
        await _client
            .from('chemical_usage')
            .delete()
            .eq('reservation_id', reservationId);
        await _client
            .from('reservations')
            .delete()
            .eq('reservation_id', reservationId);
      } catch (_) {}
    }
  }

  Future<void> _clearCaches() async {
    for (final key in [
      'dashboard_stats',
      'dashboard_recent_activities',
      'dashboard_borrowed_items',
    ]) {
      await _cache.remove(key);
    }
  }

  int _parseTime(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
