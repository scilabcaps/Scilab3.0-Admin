import 'package:flutter/material.dart';
import '../models/dashboard_model.dart' show DashboardStats, CourseReservationData, BorrowedItem, RecentActivity;
import '../services/dashboard_service.dart';

class DashboardController extends ChangeNotifier {
  final DashboardService _service = DashboardService();
  
  DashboardStats? _stats;
  List<CourseReservationData> _courseData = [];
  List<BorrowedItem> _borrowedItems = [];
  List<RecentActivity> _recentActivities = [];
  bool _isLoading = false;

  DashboardStats? get stats => _stats;
  List<CourseReservationData> get courseData => _courseData;
  List<BorrowedItem> get borrowedItems => _borrowedItems;
  List<RecentActivity> get recentActivities => _recentActivities;
  bool get isLoading => _isLoading;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getDashboardStats(),
        _service.getTopCourses(),
        _service.getBorrowedItems(),
        _service.getRecentActivities(),
      ]);
      
      _stats = results[0] as DashboardStats;
      _courseData = results[1] as List<CourseReservationData>;
      _borrowedItems = results[2] as List<BorrowedItem>;
      _recentActivities = results[3] as List<RecentActivity>;
      
      print('Dashboard data loaded successfully');
      print('Course data count: ${_courseData.length}');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading dashboard data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  List<BorrowedItem> getItemsByCategory(String category) {
    return _borrowedItems.where((item) => item.category == category).toList();
  }

  void refreshData() {
    loadDashboardData();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
  }
}
