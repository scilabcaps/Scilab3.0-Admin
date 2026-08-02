import 'package:flutter/material.dart';
import '../models/ongoing_reservation_model.dart';
import '../services/ongoing_reservation_service.dart';
import '../../../audit/services/audit_service.dart';

class OngoingReservationController extends ChangeNotifier {
  final OngoingReservationService _service = OngoingReservationService();
  final AuditService _auditService = AuditService();
  List<OngoingReservation> _reservations = [];
  String _selectedFilter = 'all';
  int _currentPage = 1;
  int _totalRows = 0;
  final int _limit = 20;

  List<OngoingReservation> get reservations => _reservations;
  String get selectedFilter => _selectedFilter;
  int get currentPage => _currentPage;
  int get totalRows => _totalRows;
  int get limit => _limit;
  int get totalPages => _totalRows > 0 ? (_totalRows / _limit).ceil() : 0;

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

  Future<void> loadReservations({int? page}) async {
    try {
      if (page != null) _currentPage = page;
      _reservations = await _service.fetchOngoingReservations(page: _currentPage, limit: _limit);
      _totalRows = await _service.countOngoingReservations();
      notifyListeners();
    } catch (e) {
      _reservations = [];
      _totalRows = 0;
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

      // Log audit action
      await _auditService.logAction(
        actionType: 'COMPLETE',
        entityType: 'reservation',
        entityId: reservationId,
        newValues: {'status': 'Completed'},
        description: 'Admin completed reservation: $reservationId',
      );
    } catch (e) {
      // Handle error
    }
  }

  Future<void> returnItem(String reservationId, String itemId) async {
    try {
      final reservationIndex = _reservations.indexWhere((r) => r.reservationId == reservationId);
      if (reservationIndex != -1) {
        final reservation = _reservations[reservationIndex];
        final itemIndex = reservation.items?.indexWhere((i) => i.itemId == itemId) ?? -1;
        
        if (itemIndex != -1) {
          final item = reservation.items![itemIndex];
          final unreturnedQuantity = item.quantity - item.returnedQuantity;
          
          if (unreturnedQuantity > 0 && item.assetId.isNotEmpty) {
            await _service.returnItem(
              int.parse(itemId),
              int.parse(item.assetId),
              item.quantity,
              unreturnedQuantity,
              reservationId,
            );

            // Update local state
            final updatedItems = reservation.items?.map((i) {
              if (i.itemId == itemId) {
                return i.copyWith(
                  returnedQuantity: item.quantity,
                  status: 'Returned',
                );
              }
              return i;
            }).toList();

            _reservations[reservationIndex] = reservation.copyWith(
              items: updatedItems,
              lastUpdated: DateTime.now().toString().split(' ')[0],
            );
            notifyListeners();

            // Check if all items are returned and update reservation status
            await _service.checkAndUpdateReservationStatus(int.parse(reservationId));

            // Log audit action
            await _auditService.logAction(
              actionType: 'RETURN',
              entityType: 'reservation_item',
              entityId: itemId,
              newValues: {
                'quantity_returned': item.quantity,
                'is_returned': true,
              },
              description: 'Early return of item: ${item.itemName} (Reservation ID: $reservationId)',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error returning item: $e');
    }
  }

  Future<void> returnPartialItem(String reservationId, String itemId, int quantity) async {
    try {
      final reservationIndex = _reservations.indexWhere((r) => r.reservationId == reservationId);
      if (reservationIndex != -1) {
        final reservation = _reservations[reservationIndex];
        final itemIndex = reservation.items?.indexWhere((i) => i.itemId == itemId) ?? -1;
        
        if (itemIndex != -1) {
          final item = reservation.items![itemIndex];
          final unreturnedQuantity = item.quantity - item.returnedQuantity;
          
          if (quantity <= unreturnedQuantity && item.assetId.isNotEmpty) {
            await _service.returnPartialItem(
              int.parse(itemId),
              int.parse(item.assetId),
              item.returnedQuantity,
              quantity,
              reservationId,
            );

            // Update local state
            final updatedItems = reservation.items?.map((i) {
              if (i.itemId == itemId) {
                final newReturnedQuantity = item.returnedQuantity + quantity;
                final newStatus = newReturnedQuantity >= item.quantity
                    ? 'Returned'
                    : (newReturnedQuantity > 0 ? 'Partial' : 'Pending');
                return i.copyWith(
                  returnedQuantity: newReturnedQuantity,
                  status: newStatus,
                );
              }
              return i;
            }).toList();

            _reservations[reservationIndex] = reservation.copyWith(
              items: updatedItems,
              lastUpdated: DateTime.now().toString().split(' ')[0],
            );
            notifyListeners();

            // Check if all items are returned and update reservation status
            await _service.checkAndUpdateReservationStatus(int.parse(reservationId));

            // Log audit action
            await _auditService.logAction(
              actionType: 'PARTIAL_RETURN',
              entityType: 'reservation_item',
              entityId: itemId,
              newValues: {
                'quantity_returned': item.returnedQuantity + quantity,
              },
              description: 'Partial return of $quantity ${item.itemName} (Reservation ID: $reservationId)',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error returning partial item: $e');
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
      case 'used':
        return const Color(0xFFD1ECF1);
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
      case 'used':
        return const Color(0xFF0C5460);
      default:
        return Colors.grey.shade700;
    }
  }

  void refresh() {
    loadReservations();
  }
}
