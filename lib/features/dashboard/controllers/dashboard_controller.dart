import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

class DashboardController extends ChangeNotifier {
  final DashboardService _service = DashboardService();
  
  DashboardStats? _stats;
  List<ReservationDataPoint> _reservationData = [];
  List<BorrowedItem> _borrowedItems = [];
  List<RecentActivity> _recentActivities = [];
  bool _isLoading = false;

  DashboardStats? get stats => _stats;
  List<ReservationDataPoint> get reservationData => _reservationData;
  List<BorrowedItem> get borrowedItems => _borrowedItems;
  List<RecentActivity> get recentActivities => _recentActivities;
  bool get isLoading => _isLoading;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getDashboardStats(),
        _service.getReservationTrends(),
        _service.getBorrowedItems(),
        _service.getRecentActivities(),
      ]);
      
      _stats = results[0] as DashboardStats;
      _reservationData = results[1] as List<ReservationDataPoint>;
      _borrowedItems = results[2] as List<BorrowedItem>;
      _recentActivities = results[3] as List<RecentActivity>;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      
      // Fallback to mock data if service fails
      _stats = _getMockStats();
      _reservationData = _getMockReservationData();
      _borrowedItems = _getMockBorrowedItems();
      _recentActivities = _getMockRecentActivities();
      notifyListeners();
    }
  }

  DashboardStats _getMockStats() {
    return DashboardStats(
      totalReservations: 150,
      approvedReservations: 120,
      pendingReservations: 30,
      rejectedReservations: 10,
      totalUsers: 45,
      activeRooms: 8,
      maintenanceRooms: 2,
      totalChemicals: 25,
      totalLabAssets: 40,
    );
  }

  List<ReservationDataPoint> _getMockReservationData() {
    return [
      ReservationDataPoint(day: 'Mon', total: 0.8, approved: 0.6, pending: 0.2),
      ReservationDataPoint(day: 'Tue', total: 0.6, approved: 0.5, pending: 0.1),
      ReservationDataPoint(day: 'Wed', total: 0.7, approved: 0.6, pending: 0.1),
      ReservationDataPoint(day: 'Thu', total: 0.5, approved: 0.4, pending: 0.1),
      ReservationDataPoint(day: 'Fri', total: 0.9, approved: 0.7, pending: 0.2),
      ReservationDataPoint(day: 'Sat', total: 0.6, approved: 0.5, pending: 0.1),
      ReservationDataPoint(day: 'Sun', total: 0.8, approved: 0.6, pending: 0.2),
    ];
  }

  List<BorrowedItem> _getMockBorrowedItems() {
    return [
      BorrowedItem(name: 'Microscope', count: 45, status: 'AVAILABLE', category: 'Equipment'),
      BorrowedItem(name: 'Beaker Set', count: 38, status: 'AVAILABLE', category: 'Equipment'),
      BorrowedItem(name: 'Test Tubes', count: 32, status: 'GOOD STOCK', category: 'Equipment'),
      BorrowedItem(name: 'Pipettes', count: 28, status: 'AVAILABLE', category: 'Equipment'),
      BorrowedItem(name: 'Flask 500ml', count: 42, status: 'AVAILABLE', category: 'Glassware'),
      BorrowedItem(name: 'Petri Dish', count: 35, status: 'AVAILABLE', category: 'Glassware'),
      BorrowedItem(name: 'Graduated Cylinder', count: 30, status: 'GOOD STOCK', category: 'Glassware'),
      BorrowedItem(name: 'Condenser', count: 25, status: 'AVAILABLE', category: 'Glassware'),
      BorrowedItem(name: 'HCl Solution', count: 50, status: 'AVAILABLE', category: 'Chemicals'),
      BorrowedItem(name: 'NaOH Solution', count: 45, status: 'AVAILABLE', category: 'Chemicals'),
      BorrowedItem(name: 'Sulfuric Acid', count: 40, status: 'GOOD STOCK', category: 'Chemicals'),
      BorrowedItem(name: 'Ethanol', count: 35, status: 'AVAILABLE', category: 'Chemicals'),
    ];
  }

  List<RecentActivity> _getMockRecentActivities() {
    return [
      RecentActivity(
        id: '1',
        title: 'New Reservation',
        description: 'John Doe reserved Computer Lab 1',
        timestamp: '2 minutes ago',
        type: 'reservation',
      ),
      RecentActivity(
        id: '2',
        title: 'Item Returned',
        description: 'Microscope returned by Jane Smith',
        timestamp: '15 minutes ago',
        type: 'inventory',
      ),
      RecentActivity(
        id: '3',
        title: 'Room Status Updated',
        description: 'Science Lab 1 marked as Available',
        timestamp: '1 hour ago',
        type: 'room',
      ),
      RecentActivity(
        id: '4',
        title: 'New User Added',
        description: 'Student account created for Mike Johnson',
        timestamp: '2 hours ago',
        type: 'user',
      ),
      RecentActivity(
        id: '5',
        title: 'Reservation Approved',
        description: 'Prof. Williams reservation approved',
        timestamp: '3 hours ago',
        type: 'reservation',
      ),
    ];
  }

  List<BorrowedItem> getItemsByCategory(String category) {
    return _borrowedItems.where((item) => item.category == category).toList();
  }

  void refreshData() {
    loadDashboardData();
  }
}
