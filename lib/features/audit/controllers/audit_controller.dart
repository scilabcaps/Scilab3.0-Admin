import 'package:flutter/material.dart';
import '../models/audit_log_model.dart';
import '../services/audit_service.dart';

class AuditController extends ChangeNotifier {
  final AuditService _service = AuditService();
  
  List<AuditLog> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filters
  String _selectedEntityType = 'all';
  String _selectedActionType = 'all';
  int _selectedDays = 30;

  // Pagination
  int _currentPage = 1;
  static const int _rowsPerPage = 10;

  List<AuditLog> get logs => _paginatedLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedEntityType => _selectedEntityType;
  String get selectedActionType => _selectedActionType;
  int get selectedDays => _selectedDays;
  int get currentPage => _currentPage;
  int get totalPages => (_filteredLogs.length / _rowsPerPage).ceil();
  int get totalRows => _filteredLogs.length;

  List<AuditLog> get _filteredLogs {
    var filtered = _logs;
    
    if (_selectedEntityType != 'all') {
      filtered = filtered.where((log) => log.entityType == _selectedEntityType).toList();
    }
    if (_selectedActionType != 'all') {
      filtered = filtered.where((log) => log.actionType == _selectedActionType).toList();
    }
    
    return filtered;
  }

  List<AuditLog> get _paginatedLogs {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    
    if (startIndex >= _filteredLogs.length) {
      _currentPage = 1;
      return _filteredLogs.take(_rowsPerPage).toList();
    }
    
    return _filteredLogs.sublist(startIndex, endIndex > _filteredLogs.length ? _filteredLogs.length : endIndex);
  }

  Future<void> loadLogs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logs = await _service.getRecentLogs(
        days: _selectedDays,
        entityType: _selectedEntityType == 'all' ? null : _selectedEntityType,
        actionType: _selectedActionType == 'all' ? null : _selectedActionType,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load audit logs: $e';
      _logs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setEntityTypeFilter(String type) {
    _selectedEntityType = type;
    notifyListeners();
  }

  void setActionTypeFilter(String type) {
    _selectedActionType = type;
    notifyListeners();
  }

  void setDaysFilter(int days) {
    _selectedDays = days;
    notifyListeners();
  }

  void clearFilters() {
    _selectedEntityType = 'all';
    _selectedActionType = 'all';
    _selectedDays = 30;
    notifyListeners();
  }

  void refresh() {
    loadLogs();
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void nextPage() {
    if (_currentPage < totalPages) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }
}
