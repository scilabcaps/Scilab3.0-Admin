class OngoingReservation {
  final String reservationId;
  final String name;
  final String userType;
  final String programYear;
  final String? professor;
  final String date;
  final String time;
  final String status;
  final List<ReservedItem>? items;
  final String? lastUpdated;

  OngoingReservation({
    required this.reservationId,
    required this.name,
    required this.userType,
    required this.programYear,
    this.professor,
    required this.date,
    required this.time,
    required this.status,
    this.items,
    this.lastUpdated,
  });

  factory OngoingReservation.fromJson(Map<String, dynamic> json) {
    return OngoingReservation(
      reservationId: json['reservation_id']?.toString() ?? '',
      name: json['name'] ?? '',
      userType: json['user_type'] ?? 'Student',
      programYear: json['program_year'] ?? '',
      professor: json['professor'],
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? 'Ongoing',
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => ReservedItem.fromJson(item))
              .toList()
          : null,
      lastUpdated: json['last_updated'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservation_id': reservationId,
      'name': name,
      'user_type': userType,
      'program_year': programYear,
      'professor': professor,
      'date': date,
      'time': time,
      'status': status,
      'items': items?.map((item) => item.toJson()).toList(),
      'last_updated': lastUpdated,
    };
  }

  OngoingReservation copyWith({
    String? reservationId,
    String? name,
    String? userType,
    String? programYear,
    String? professor,
    String? date,
    String? time,
    String? status,
    List<ReservedItem>? items,
    String? lastUpdated,
  }) {
    return OngoingReservation(
      reservationId: reservationId ?? this.reservationId,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      programYear: programYear ?? this.programYear,
      professor: professor ?? this.professor,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      items: items ?? this.items,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ReservedItem {
  final String itemId;
  final String assetId;
  final String itemName;
  final int quantity;
  final int returnedQuantity;
  final String status;

  ReservedItem({
    required this.itemId,
    required this.assetId,
    required this.itemName,
    required this.quantity,
    required this.returnedQuantity,
    required this.status,
  });

  factory ReservedItem.fromJson(Map<String, dynamic> json) {
    return ReservedItem(
      itemId: json['item_id']?.toString() ?? '',
      assetId: json['asset_id']?.toString() ?? '',
      itemName: json['item_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      returnedQuantity: json['returned_quantity'] ?? 0,
      status: json['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'asset_id': assetId,
      'item_name': itemName,
      'quantity': quantity,
      'returned_quantity': returnedQuantity,
      'status': status,
    };
  }

  ReservedItem copyWith({
    String? itemId,
    String? assetId,
    String? itemName,
    int? quantity,
    int? returnedQuantity,
    String? status,
  }) {
    return ReservedItem(
      itemId: itemId ?? this.itemId,
      assetId: assetId ?? this.assetId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
      status: status ?? this.status,
    );
  }
}
