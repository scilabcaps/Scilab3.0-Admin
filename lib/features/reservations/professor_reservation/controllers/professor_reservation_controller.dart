import 'package:flutter/material.dart';
import '../models/professor_reservation_model.dart';
import '../services/professor_reservation_service.dart';

class ProfessorReservationController extends ChangeNotifier {
  final ProfessorReservationService _service = ProfessorReservationService();
  List<ProfessorReservation> _reservations = [];
  String _selectedFilter = 'pending';

  List<ProfessorReservation> get reservations => _reservations;
  String get selectedFilter => _selectedFilter;

  List<ProfessorReservation> get filteredReservations {
    switch (_selectedFilter) {
      case 'pending':
        return _reservations
            .where((r) => r.professorApproval.toLowerCase() == 'pending')
            .toList();
      case 'approved':
        return _reservations
            .where((r) => r.professorApproval.toLowerCase() == 'approved')
            .toList();
      case 'declined':
        return _reservations
            .where((r) => r.professorApproval.toLowerCase() == 'declined')
            .toList();
      default:
        return _reservations;
    }
  }

  int get filteredCount => filteredReservations.length;

  Future<void> loadReservations() async {
    try {
      _reservations = await _service.fetchProfessorReservations();
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
      await _service.updateProfessorApproval(int.parse(reservationId), 'Approved');

      final index = _reservations.indexWhere((r) => r.reservationId == reservationId);
      if (index != -1) {
        final reservation = _reservations[index];
        // Mark the reserved room as "Occupied"
        if (reservation.roomId != null) {
          try {
            await _service.updateRoomStatus(int.parse(reservation.roomId!), 'Occupied');
          } catch (e) {
            // Room update failed, continue with approval
          }
        }
        _reservations[index] = reservation.copyWith(
          professorApproval: 'Approved',
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
      await _service.updateProfessorApproval(int.parse(reservationId), 'Declined');
      final index = _reservations.indexWhere((r) => r.reservationId == reservationId);
      if (index != -1) {
        _reservations[index] = _reservations[index].copyWith(
          professorApproval: 'Declined',
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

  @override
  void dispose() {
    _reservations.clear();
    super.dispose();
  }
}
