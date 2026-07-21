import 'package:flutter/material.dart';
import '../models/student_reservation_model.dart';
import '../services/student_reservation_service.dart';

class StudentReservationController extends ChangeNotifier {
  final StudentReservationService _service = StudentReservationService();
  List<StudentReservation> _reservations = [];
  String _selectedFilter = 'pending';

  List<StudentReservation> get reservations => _reservations;
  String get selectedFilter => _selectedFilter;

  List<StudentReservation> get filteredReservations {
    switch (_selectedFilter) {
      case 'pending':
        return _reservations
            .where((r) => r.status.toLowerCase() == 'pending')
            .toList();
      case 'approved':
        return _reservations
            .where((r) => r.status.toLowerCase() == 'approved')
            .toList();
      case 'rejected':
        return _reservations
            .where((r) => r.status.toLowerCase() == 'declined')
            .toList();
      default:
        return _reservations;
    }
  }

  int get filteredCount => filteredReservations.length;

  Future<void> loadReservations() async {
    try {
      _reservations = await _service.fetchStudentReservations();
      notifyListeners();
    } catch (e) {
      _reservations = [];
      notifyListeners();
    }
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> approveReservation(String reservationId) async {
    try {
      await _service.updateAdminApproval(int.parse(reservationId), 'Approved');
      final index = _reservations.indexWhere((r) => r.reservationId == reservationId);
      if (index != -1) {
        _reservations[index] = _reservations[index].copyWith(
          status: 'Approved',
          lastUpdated: DateTime.now().toString().split(' ')[0],
        );
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> rejectReservation(String reservationId) async {
    try {
      await _service.updateAdminApproval(int.parse(reservationId), 'Declined');
      final index = _reservations.indexWhere((r) => r.reservationId == reservationId);
      if (index != -1) {
        _reservations[index] = _reservations[index].copyWith(
          status: 'Declined',
          lastUpdated: DateTime.now().toString().split(' ')[0],
        );
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF3CD);
      case 'approved':
        return const Color(0xFFD4EDDA);
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
      case 'declined':
        return const Color(0xFF721C24);
      default:
        return Colors.grey.shade700;
    }
  }
}
