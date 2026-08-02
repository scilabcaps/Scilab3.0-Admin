import 'package:flutter/material.dart';
import '../models/reservations_history_model.dart';
import '../services/reservations_history_service.dart';

class ReservationsHistoryController extends ChangeNotifier {
  final ReservationsHistoryService _service = ReservationsHistoryService();
  List<ReservationHistory> _reservations = [];
  String _selectedFilter = 'all';
  String _selectedStatusFilter = '';
  String _selectedDateFilter = 'all';
  DateTime? _specificDate;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalRows = 0;
  final int _limit = 20;

  List<ReservationHistory> get reservations => _reservations;
  String get selectedFilter => _selectedFilter;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get selectedDateFilter => _selectedDateFilter;
  DateTime? get specificDate => _specificDate;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalRows => _totalRows;
  int get limit => _limit;
  int get totalPages => _totalRows > 0 ? (_totalRows / _limit).ceil() : 0;

  List<ReservationHistory> get filteredReservations {
    var filtered = _reservations;

    // Apply role filter
    switch (_selectedFilter) {
      case 'student':
        filtered = filtered
            .where((r) => r.role.toLowerCase() == 'student')
            .toList();
        break;
      case 'professor':
        filtered = filtered
            .where((r) => r.role.toLowerCase() == 'professor')
            .toList();
        break;
    }

    // Apply status filter
    if (_selectedStatusFilter.isNotEmpty) {
      filtered = filtered
          .where((r) => r.status.toLowerCase() == _selectedStatusFilter.toLowerCase())
          .toList();
    }

    // Apply date filter
    if (_selectedDateFilter == 'specific' && _specificDate != null) {
      filtered = filtered
          .where((r) => _isSameDay(r.reservationDate, _specificDate!))
          .toList();
    } else if (_selectedDateFilter == 'range' && _startDate != null && _endDate != null) {
      filtered = filtered
          .where((r) => _isDateInRange(r.reservationDate, _startDate!, _endDate!))
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) =>
        r.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        r.reservationId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        r.roomItemReserved.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  bool _isSameDay(String dateString, DateTime date) {
    try {
      final reservationDate = DateTime.parse(dateString);
      return reservationDate.year == date.year &&
          reservationDate.month == date.month &&
          reservationDate.day == date.day;
    } catch (e) {
      return false;
    }
  }

  bool _isDateInRange(String dateString, DateTime start, DateTime end) {
    try {
      final reservationDate = DateTime.parse(dateString);
      final startOnly = DateTime(start.year, start.month, start.day);
      final endOnly = DateTime(end.year, end.month, end.day);
      final reservationOnly = DateTime(reservationDate.year, reservationDate.month, reservationDate.day);
      
      return !reservationOnly.isBefore(startOnly) && !reservationOnly.isAfter(endOnly);
    } catch (e) {
      return false;
    }
  }

  int get filteredCount => filteredReservations.length;

  Future<void> loadReservations({int? page}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (page != null) _currentPage = page;
      _reservations = await _service.fetchReservations(page: _currentPage, limit: _limit);
      _totalRows = await _service.countReservations();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load reservations: $e';
      _reservations = [];
      _totalRows = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSelectedStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setSelectedDateFilter(String filter) {
    _selectedDateFilter = filter;
    notifyListeners();
  }

  void setSpecificDate(DateTime? date) {
    _specificDate = date;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedFilter = 'all';
    _selectedStatusFilter = '';
    _selectedDateFilter = 'all';
    _specificDate = null;
    _startDate = null;
    _endDate = null;
    _searchQuery = '';
    notifyListeners();
  }

  void refresh() {
    loadReservations();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFFD4EDDA);
      case 'approved':
        return const Color(0xFFD1ECF1);
      case 'rejected':
        return const Color(0xFFF8D7DA);
      case 'cancelled':
        return const Color(0xFFE2E3E5);
      case 'pending':
        return const Color(0xFFFFF3CD);
      default:
        return Colors.grey.shade200;
    }
  }

  Color getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF155724);
      case 'approved':
        return const Color(0xFF0C5460);
      case 'rejected':
        return const Color(0xFF721C24);
      case 'cancelled':
        return const Color(0xFF383D41);
      case 'pending':
        return const Color(0xFF856404);
      default:
        return Colors.grey.shade700;
    }
  }

  Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return const Color(0xFFE3F2FD);
      case 'professor':
        return const Color(0xFFF3E5F5);
      default:
        return Colors.grey.shade200;
    }
  }

  Color getRoleTextColor(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return const Color(0xFF1976D2);
      case 'professor':
        return const Color(0xFF7B1FA2);
      default:
        return Colors.grey.shade700;
    }
  }

  // Stats for header cards
  int get totalReservations => _reservations.length;
  int get completedReservations => _reservations.where((r) => r.status.toLowerCase() == 'completed').length;
  int get cancelledReservations => _reservations.where((r) => r.status.toLowerCase() == 'cancelled').length;
  int get declinedReservations => _reservations.where((r) => r.status.toLowerCase() == 'declined').length;
  int get pendingReservations => _reservations.where((r) => r.status.toLowerCase() == 'pending').length;
  int get studentReservations => _reservations.where((r) => r.role.toLowerCase() == 'student').length;
  int get professorReservations => _reservations.where((r) => r.role.toLowerCase() == 'professor').length;
}
