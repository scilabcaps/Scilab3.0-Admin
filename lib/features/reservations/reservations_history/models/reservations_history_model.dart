class ReservationHistory {
  final String reservationId;
  final String userName;
  final String role;
  final String reservationType;
  final String roomItemReserved;
  final String reservationDate;
  final String timeSchedule;
  final String status;
  final String dateCreated;
  final List<ReservedItem>? items;

  ReservationHistory({
    required this.reservationId,
    required this.userName,
    required this.role,
    required this.reservationType,
    required this.roomItemReserved,
    required this.reservationDate,
    required this.timeSchedule,
    required this.status,
    required this.dateCreated,
    this.items,
  });

  factory ReservationHistory.fromJson(Map<String, dynamic> json) {
    return ReservationHistory(
      reservationId: json['reservation_id']?.toString() ?? '',
      userName: json['user_name'] ?? '',
      role: json['role'] ?? 'Student',
      reservationType: json['reservation_type'] ?? 'Room',
      roomItemReserved: json['room_item_reserved'] ?? '',
      reservationDate: json['reservation_date'] ?? '',
      timeSchedule: json['time_schedule'] ?? '',
      status: json['status'] ?? 'Pending',
      dateCreated: json['date_created'] ?? '',
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => ReservedItem.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservation_id': reservationId,
      'user_name': userName,
      'role': role,
      'reservation_type': reservationType,
      'room_item_reserved': roomItemReserved,
      'reservation_date': reservationDate,
      'time_schedule': timeSchedule,
      'status': status,
      'date_created': dateCreated,
      'items': items?.map((item) => item.toJson()).toList(),
    };
  }

  ReservationHistory copyWith({
    String? reservationId,
    String? userName,
    String? role,
    String? reservationType,
    String? roomItemReserved,
    String? reservationDate,
    String? timeSchedule,
    String? status,
    String? dateCreated,
    List<ReservedItem>? items,
  }) {
    return ReservationHistory(
      reservationId: reservationId ?? this.reservationId,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      reservationType: reservationType ?? this.reservationType,
      roomItemReserved: roomItemReserved ?? this.roomItemReserved,
      reservationDate: reservationDate ?? this.reservationDate,
      timeSchedule: timeSchedule ?? this.timeSchedule,
      status: status ?? this.status,
      dateCreated: dateCreated ?? this.dateCreated,
      items: items ?? this.items,
    );
  }
}

class ReservedItem {
  final String itemId;
  final String itemName;
  final int quantity;
  final int returnedQuantity;
  final String status;

  ReservedItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.returnedQuantity,
    required this.status,
  });

  factory ReservedItem.fromJson(Map<String, dynamic> json) {
    return ReservedItem(
      itemId: json['item_id']?.toString() ?? '',
      itemName: json['item_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      returnedQuantity: json['returned_quantity'] ?? 0,
      status: json['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
      'returned_quantity': returnedQuantity,
      'status': status,
    };
  }

  ReservedItem copyWith({
    String? itemId,
    String? itemName,
    int? quantity,
    int? returnedQuantity,
    String? status,
  }) {
    return ReservedItem(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
      status: status ?? this.status,
    );
  }
}
