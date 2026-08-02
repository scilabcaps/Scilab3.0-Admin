import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../../../../core/api/supabase_client.dart';
import '../../../../core/api/supabase_config.dart';
import '../../../../core/service/cache_service.dart';
import '../../../audit/services/audit_service.dart';

class RoomController extends ChangeNotifier {
  List<Room> _rooms = [];
  final CacheService _cache = CacheService();
  final AuditService _auditService = AuditService();

  List<Room> get rooms => _rooms;

  Future<void> loadRooms() async {
    final cacheKey = 'rooms_list';
    
    // Try to get from cache first
    final cachedRooms = _cache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cachedRooms != null) {
      _rooms = cachedRooms.map((data) => Room.fromJson(data)).toList();
      notifyListeners();
      return;
    }

    try {
      final response = await SupabaseService.database
          .from(SupabaseConfig.tableRooms)
          .select()
          .eq('is_deleted', false)
          .order('room_name');

      final List<Room> rooms = [];
      for (final roomData in response) {
        rooms.add(Room.fromJson(roomData));
      }

      _rooms = rooms;
      notifyListeners();

      // Cache the result with 10 minute TTL (room status changes infrequently)
      await _cache.set(cacheKey, rooms.map((room) => room.toJson()).toList(), ttlMinutes: 10);
    } catch (e) {
      debugPrint('Error loading rooms: $e');
      _rooms = _getMockRooms();
      notifyListeners();
    }
  }

  List<Room> _getMockRooms() {
    return [
      Room(
        roomId: '1',
        roomName: 'Computer Lab 1',
        capacity: 30,
        reservationDate: '2026-06-28',
        startTime: '08:00',
        endTime: '10:00',
        status: 'Occupied',
      ),
      Room(
        roomId: '2',
        roomName: 'Computer Lab 2',
        capacity: 25,
        reservationDate: null,
        startTime: null,
        endTime: null,
        status: 'Available',
      ),
      Room(
        roomId: '3',
        roomName: 'Science Lab 1',
        capacity: 20,
        reservationDate: null,
        startTime: null,
        endTime: null,
        status: 'Maintenance',
      ),
    ];
  }

  Future<void> updateRoomStatus(String roomId, String newStatus) async {
    try {
      // Capture old status
      final oldRoom = _rooms.firstWhere((r) => r.roomId == roomId);
      final oldStatus = oldRoom.status;

      await SupabaseService.database
          .from(SupabaseConfig.tableRooms)
          .update({'status': newStatus})
          .eq('room_id', int.parse(roomId));

      _rooms = _rooms.map((room) {
        if (room.roomId == roomId) {
          return room.copyWith(status: newStatus);
        }
        return room;
      }).toList();
      notifyListeners();

      // Clear cache after room status update to ensure consistency
      await _cache.remove('rooms_list');

      // Log audit action
      await _auditService.logAction(
        actionType: 'UPDATE',
        entityType: 'room',
        entityId: roomId,
        oldValues: {'status': oldStatus},
        newValues: {'status': newStatus},
        description: 'Changed room ${oldRoom.roomName} status: $oldStatus → $newStatus',
      );
    } catch (e) {
      debugPrint('Error updating room status: $e');
    }
  }

  Future<void> addRoom({
    required String roomName,
    required int capacity,
    String status = 'Available',
  }) async {
    try {
      final response = await SupabaseService.database
          .from(SupabaseConfig.tableRooms)
          .insert({
            'room_name': roomName,
            'capacity': capacity,
            'status': status,
            'is_deleted': false,
          })
          .select()
          .single();

      final newRoom = Room.fromJson(response);
      _rooms.add(newRoom);
      notifyListeners();

      // Log audit action for room creation
      await _auditService.logAction(
        actionType: 'CREATE',
        entityType: 'room',
        entityId: newRoom.roomId,
        newValues: {
          'room_name': roomName,
          'capacity': capacity,
          'status': status,
        },
        description: 'Created new room: $roomName',
      );

      // Clear cache after adding a room to ensure consistency
      await _cache.remove('rooms_list');
    } catch (e) {
      debugPrint('Error adding room: $e');
      rethrow;
    }
  }

  Future<void> editRoom({
    required String roomId,
    String? roomName,
    int? capacity,
    String? status,
  }) async {
    try {
      // Capture old values
      final oldRoom = _rooms.firstWhere((r) => r.roomId == roomId);
      final oldValues = <String, dynamic>{
        'room_name': oldRoom.roomName,
        'capacity': oldRoom.capacity,
        'status': oldRoom.status,
      };

      final updateData = <String, dynamic>{};
      if (roomName != null) updateData['room_name'] = roomName;
      if (capacity != null) updateData['capacity'] = capacity;
      if (status != null) updateData['status'] = status;

      await SupabaseService.database
          .from(SupabaseConfig.tableRooms)
          .update(updateData)
          .eq('room_id', int.parse(roomId));

      _rooms = _rooms.map((room) {
        if (room.roomId == roomId) {
          return room.copyWith(
            roomName: roomName,
            capacity: capacity,
            status: status,
          );
        }
        return room;
      }).toList();
      notifyListeners();

      // Build new values for audit log
      final newValues = <String, dynamic>{
        'room_name': roomName ?? oldRoom.roomName,
        'capacity': capacity ?? oldRoom.capacity,
        'status': status ?? oldRoom.status,
      };

      // Log audit action for room edit
      await _auditService.logAction(
        actionType: 'UPDATE',
        entityType: 'room',
        entityId: roomId,
        oldValues: oldValues,
        newValues: newValues,
        description: 'Edited room: ${oldRoom.roomName}',
      );

      // Clear cache after editing a room to ensure consistency
      await _cache.remove('rooms_list');
    } catch (e) {
      debugPrint('Error editing room: $e');
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      // Capture room info before deletion
      final roomToDelete = _rooms.firstWhere((r) => r.roomId == roomId);

      // Soft delete by setting is_deleted flag
      await SupabaseService.database
          .from(SupabaseConfig.tableRooms)
          .update({'is_deleted': true})
          .eq('room_id', int.parse(roomId));

      _rooms = _rooms.where((room) => room.roomId != roomId).toList();
      notifyListeners();

      // Log audit action for room deletion
      await _auditService.logAction(
        actionType: 'DELETE',
        entityType: 'room',
        entityId: roomId,
        oldValues: {
          'room_name': roomToDelete.roomName,
          'capacity': roomToDelete.capacity,
          'status': roomToDelete.status,
        },
        description: 'Deleted room: ${roomToDelete.roomName}',
      );

      // Clear cache after deleting a room to ensure consistency
      await _cache.remove('rooms_list');
    } catch (e) {
      debugPrint('Error deleting room: $e');
      rethrow;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFFD4EDDA);
      case 'occupied':
      case 'over time':
        return const Color(0xFFF8D7DA);
      case 'maintenance':
        return const Color(0xFFFFF3CD);
      default:
        return Colors.grey.shade200;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFF155724);
      case 'occupied':
      case 'over time':
        return const Color(0xFF721C24);
      case 'maintenance':
        return const Color(0xFF856404);
      default:
        return Colors.grey.shade700;
    }
  }

  void refresh() {
    loadRooms();
  }
}
