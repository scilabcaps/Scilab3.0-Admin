import 'package:flutter/material.dart';
import '../models/ongoing_reservation_model.dart';
import '../services/ongoing_reservation_service.dart';

class OngoingReservationController extends ChangeNotifier {
  final OngoingReservationService _service = OngoingReservationService();
  List<OngoingReservation> _reservations = [];
  String _selectedFilter = 'all';

  List<OngoingReservation> get reservations => _reservations;
  String get selectedFilter => _selectedFilter;

  List<OngoingReservation> get filteredReservations {
    switch (_selectedFilter) {
      case 'student':
        return _reservations
            .where((r) => r.userType.toLowerCase() == 'student')
            .toList();
      case 'professor':
        return _reservations
            .where((r) => r.userType.toLowerCase() == 'professor')
            .toList();
      default:
        return _reservations;
    }
  }

  int get filteredCount => filteredReservations.length;

  Future<void> loadReservations() async {
    try {
      _reservations = await _service.fetchOngoingReservations();
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

  Future<void> updateItemStatus(
    String reservationId,
    String itemId,
    int returnedQuantity,
  ) async {
    try {
      await _service.updateItemReturn(int.parse(itemId), returnedQuantity);
      
      final reservationIndex =
          _reservations.indexWhere((r) => r.reservationId == reservationId);
      if (reservationIndex != -1) {
        final reservation = _reservations[reservationIndex];
        final updatedItems = reservation.items?.map((item) {
          if (item.itemId == itemId) {
            final newStatus = returnedQuantity >= item.quantity
                ? 'Returned'
                : (returnedQuantity > 0 ? 'Partial' : 'Pending');
            return item.copyWith(
              returnedQuantity: returnedQuantity,
              status: newStatus,
            );
          }
          return item;
        }).toList();

        _reservations[reservationIndex] = reservation.copyWith(
          items: updatedItems,
          lastUpdated: DateTime.now().toString().split(' ')[0],
        );
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> completeReservation(String reservationId) async {
    try {
      await _service.completeReservation(int.parse(reservationId));
      final index = _reservations.indexWhere((r) => r.reservationId == reservationId);
      if (index != -1) {
        _reservations.removeAt(index);
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return const Color(0xFFD1ECF1);
      case 'completed':
        return const Color(0xFFD4EDDA);
      case 'cancelled':
        return const Color(0xFFF8D7DA);
      case 'returned':
        return const Color(0xFFD4EDDA);
      case 'partial':
        return const Color(0xFFFFF3CD);
      case 'pending':
        return const Color(0xFFF8D7DA);
      default:
        return Colors.grey.shade200;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return const Color(0xFF0C5460);
      case 'completed':
        return const Color(0xFF155724);
      case 'cancelled':
        return const Color(0xFF721C24);
      case 'returned':
        return const Color(0xFF155724);
      case 'partial':
        return const Color(0xFF856404);
      case 'pending':
        return const Color(0xFF721C24);
      default:
        return Colors.grey.shade700;
    }
  }

  Color getItemStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'returned':
        return const Color(0xFFD4EDDA);
      case 'partial':
        return const Color(0xFFFFF3CD);
      case 'pending':
        return const Color(0xFFF8D7DA);
      default:
        return Colors.grey.shade200;
    }
  }

  Color getItemStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'returned':
        return const Color(0xFF155724);
      case 'partial':
        return const Color(0xFF856404);
      case 'pending':
        return const Color(0xFF721C24);
      default:
        return Colors.grey.shade700;
    }
  }
}
