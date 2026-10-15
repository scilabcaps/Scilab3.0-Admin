import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_reservation_model.dart';
import '../services/student_reservation_service.dart';
import '../../../audit/services/audit_service.dart';

class StudentReservationController extends ChangeNotifier {
  final StudentReservationService _service = StudentReservationService();
  final AuditService _auditService = AuditService();
  List<StudentReservation> _reservations = [];
  bool _isLoading = false;
  String _selectedFilter = 'pending';
  int _currentPage = 1;
  int _totalRows = 0;
  final int _limit = 20;
  RealtimeChannel? _realtimeChannel;
  bool _realtimeReloadQueued = false;

  List<StudentReservation> get reservations => _reservations;
  String get selectedFilter => _selectedFilter;
  int get currentPage => _currentPage;
  int get totalRows => _totalRows;
  int get limit => _limit;
  int get totalPages => _totalRows > 0 ? (_totalRows / _limit).ceil() : 0;
  bool get isLoading => _isLoading;

  List<StudentReservation> get filteredReservations {
    // Filtering is now done at the database level in the service
    return _reservations;
  }

  int get filteredCount => filteredReservations.length;

  Future<void> loadReservations({int? page}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (page != null) _currentPage = page;
      _reservations = await _service.fetchStudentReservations(
        page: _currentPage,
        limit: _limit,
      );
      _totalRows = await _service.countStudentReservations();
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

  void refresh() {
    loadReservations();
  }

  Future<void> approveReservation(String reservationId) async {
    try {
      // Get reservation details for audit log before refreshing
      final reservation = _reservations.firstWhere(
        (r) => r.reservationId == reservationId,
      );

      final resultingStatus = await _service.updateAdminApproval(
        int.parse(reservationId),
        'Approved',
      );

      // Refresh the list to get updated data
      await loadReservations();

      // Log audit action
      await _auditService.logAction(
        actionType: 'APPROVE',
        entityType: 'reservation',
        entityId: reservationId,
        newValues: {'status': resultingStatus},
        description:
            'Admin approved student reservation: ${reservation.studentName} (Resources: ${reservation.resources})',
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> rejectReservation(String reservationId) async {
    try {
      // Get reservation details for audit log before refreshing
      final reservation = _reservations.firstWhere(
        (r) => r.reservationId == reservationId,
      );

      await _service.updateAdminApproval(int.parse(reservationId), 'Declined');

      // Refresh the list to get updated data
      await loadReservations();

      // Log audit action
      await _auditService.logAction(
        actionType: 'REJECT',
        entityType: 'reservation',
        entityId: reservationId,
        newValues: {'status': 'Declined'},
        description:
            'Admin rejected student reservation: ${reservation.studentName} (Resources: ${reservation.resources})',
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> startRealtime() async {
    if (_realtimeChannel != null ||
        Supabase.instance.client.auth.currentUser == null) {
      return;
    }
    _realtimeChannel =
        Supabase.instance.client
            .channel('admin-student-reservations')
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
        return const Color(0xFFD4EDDA);
      case 'ongoing':
        return const Color(0xFFD1ECF1);
      case 'declined':
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
        return const Color(0xFF155724);
      case 'ongoing':
        return const Color(0xFF0C5460);
      case 'declined':
        return const Color(0xFF721C24);
      default:
        return Colors.grey.shade700;
    }
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
