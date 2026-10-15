import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/professor_reservation_model.dart';
import '../services/professor_reservation_service.dart';
import '../../../audit/services/audit_service.dart';

class ProfessorReservationController extends ChangeNotifier {
  final ProfessorReservationService _service = ProfessorReservationService();
  final AuditService _auditService = AuditService();
  List<ProfessorReservation> _reservations = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';
  int _currentPage = 1;
  int _totalRows = 0;
  final int _limit = 20;
  RealtimeChannel? _realtimeChannel;
  bool _realtimeReloadQueued = false;

  List<ProfessorReservation> get reservations => _reservations;
  String get selectedFilter => _selectedFilter;
  int get currentPage => _currentPage;
  int get totalRows => _totalRows;
  int get limit => _limit;
  int get totalPages => _totalRows > 0 ? (_totalRows / _limit).ceil() : 0;
  bool get isLoading => _isLoading;

  List<ProfessorReservation> get filteredReservations {
    // Filtering is now done at the database level in the service
    return _reservations;
  }

  int get filteredCount => filteredReservations.length;

  Future<void> loadReservations({int? page}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (page != null) _currentPage = page;
      _reservations = await _service.fetchProfessorReservations(
        page: _currentPage,
        limit: _limit,
      );
      _totalRows = await _service.countProfessorReservations();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _reservations = [];
      _totalRows = 0;
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> approveReservation(String reservationId) async {
    try {
      final index = _reservations.indexWhere(
        (r) => r.reservationId == reservationId,
      );
      final reservation = index != -1 ? _reservations[index] : null;

      final resultingStatus = await _service.approveReservation(
        int.parse(reservationId),
      );

      if (index != -1) {
        // Mark the reserved room as "Occupied"
        if (reservation?.roomId != null) {
          try {
            await _service.updateRoomStatus(
              int.parse(reservation!.roomId!),
              'Occupied',
            );

            // Log audit action for room status update
            await _auditService.logAction(
              actionType: 'UPDATE',
              entityType: 'room',
              entityId: reservation.roomId,
              oldValues: {'status': 'Available'},
              newValues: {'status': 'Occupied'},
              description:
                  'Room marked as Occupied for professor reservation: $reservationId',
            );
          } catch (e) {
            // Room update failed, continue with approval
          }
        }
      }

      // Log audit action for reservation approval
      await _auditService.logAction(
        actionType: 'APPROVE',
        entityType: 'reservation',
        entityId: reservationId,
        newValues: {'status': resultingStatus},
        description:
            'Admin approved professor reservation: ${reservation?.professorName ?? reservationId} (Resources: ${reservation?.resources ?? 'N/A'})',
      );

      // Refresh the list to get updated data
      await loadReservations();
    } catch (e) {
      print('Error approving reservation: $e');
    }
  }

  Future<void> rejectReservation(String reservationId) async {
    try {
      final index = _reservations.indexWhere(
        (r) => r.reservationId == reservationId,
      );
      final reservation = index != -1 ? _reservations[index] : null;

      await _service.rejectReservation(int.parse(reservationId));

      // Log audit action for reservation rejection
      await _auditService.logAction(
        actionType: 'REJECT',
        entityType: 'reservation',
        entityId: reservationId,
        newValues: {'status': 'Declined'},
        description:
            'Admin rejected professor reservation: ${reservation?.professorName ?? reservationId} (Resources: ${reservation?.resources ?? 'N/A'})',
      );

      // Refresh the list to get updated data
      await loadReservations();
    } catch (e) {
      print('Error rejecting reservation: $e');
    }
  }

  Future<void> startRealtime() async {
    if (_realtimeChannel != null ||
        Supabase.instance.client.auth.currentUser == null) {
      return;
    }
    _realtimeChannel =
        Supabase.instance.client
            .channel('admin-professor-reservations')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'reservations',
              callback: (_) => _queueRealtimeReload(),
            )
          ..subscribe();
  }

  void _queueRealtimeReload() {
    if (_realtimeReloadQueued) return;
    _realtimeReloadQueued = true;
    unawaited(
      Future<void>(() async {
        _realtimeReloadQueued = false;
        await loadReservations();
      }),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF3CD);
      case 'approved':
      case 'ongoing':
        return const Color(0xFFD4EDDA);
      case 'declined':
      case 'rejected':
        return const Color(0xFFF8D7DA);
      default:
        return Colors.grey.shade200;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF856404);
      case 'approved':
      case 'ongoing':
        return const Color(0xFF155724);
      case 'declined':
      case 'rejected':
        return const Color(0xFF721C24);
      default:
        return Colors.grey.shade700;
    }
  }

  void refresh() {
    loadReservations();
  }

  @override
  void dispose() {
    final channel = _realtimeChannel;
    if (channel != null) {
      unawaited(Supabase.instance.client.removeChannel(channel));
    }
    _reservations.clear();
    super.dispose();
  }
}
