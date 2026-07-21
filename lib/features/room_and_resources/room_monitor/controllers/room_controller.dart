import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../../../../core/api/supabase_client.dart';
import '../../../../core/api/supabase_config.dart';
import '../../../../core/service/cache_service.dart';

class RoomController extends ChangeNotifier {
  List<Room> _rooms = [];
  final CacheService _cache = CacheService();

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
    } catch (e) {
      debugPrint('Error updating room status: $e');
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
}
