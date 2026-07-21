class DashboardStats {
  final int totalReservations;
  final int approvedReservations;
  final int pendingReservations;
  final int rejectedReservations;
  final int totalUsers;
  final int activeRooms;
  final int maintenanceRooms;
  final int totalChemicals;
  final int totalLabAssets;

  DashboardStats({
    required this.totalReservations,
    required this.approvedReservations,
    required this.pendingReservations,
    required this.rejectedReservations,
    required this.totalUsers,
    required this.activeRooms,
    required this.maintenanceRooms,
    this.totalChemicals = 0,
    this.totalLabAssets = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalReservations: json['total_reservations'] ?? 0,
      approvedReservations: json['approved_reservations'] ?? 0,
      pendingReservations: json['pending_reservations'] ?? 0,
      rejectedReservations: json['rejected_reservations'] ?? 0,
      totalUsers: json['total_users'] ?? 0,
      activeRooms: json['active_rooms'] ?? 0,
      maintenanceRooms: json['maintenance_rooms'] ?? 0,
      totalChemicals: json['total_chemicals'] ?? 0,
      totalLabAssets: json['total_lab_assets'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_reservations': totalReservations,
      'approved_reservations': approvedReservations,
      'pending_reservations': pendingReservations,
      'rejected_reservations': rejectedReservations,
      'total_users': totalUsers,
      'active_rooms': activeRooms,
      'maintenance_rooms': maintenanceRooms,
      'total_chemicals': totalChemicals,
      'total_lab_assets': totalLabAssets,
    };
  }
}

class ReservationDataPoint {
  final String day;
  final double total;
  final double approved;
  final double pending;

  ReservationDataPoint({
    required this.day,
    required this.total,
    required this.approved,
    required this.pending,
  });

  factory ReservationDataPoint.fromJson(Map<String, dynamic> json) {
    return ReservationDataPoint(
      day: json['day'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      approved: (json['approved'] ?? 0).toDouble(),
      pending: (json['pending'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'total': total,
      'approved': approved,
      'pending': pending,
    };
  }
}

class BorrowedItem {
  final String name;
  final int count;
  final String status;
  final String category;
  final String? itemId;
  final String? unit;

  BorrowedItem({
    required this.name,
    required this.count,
    required this.status,
    required this.category,
    this.itemId,
    this.unit,
  });

  factory BorrowedItem.fromJson(Map<String, dynamic> json) {
    return BorrowedItem(
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
      status: json['status'] ?? 'AVAILABLE',
      category: json['category'] ?? '',
      itemId: json['item_id']?.toString(),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
      'status': status,
      'category': category,
      'item_id': itemId,
      'unit': unit,
    };
  }
}

class RecentActivity {
  final String id;
  final String title;
  final String description;
  final String timestamp;
  final String type;
  final DateTime? createdAt;
  final String? userId;

  RecentActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.createdAt,
    this.userId,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] ?? '',
      type: json['type'] ?? 'reservation',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      userId: json['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'type': type,
      'created_at': createdAt?.toIso8601String(),
      'user_id': userId,
    };
  }
}
