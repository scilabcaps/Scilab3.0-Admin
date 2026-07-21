class UnreturnedItem {
  final String detailId;
  final String reservationId;
  final String itemId;
  final String itemName;
  final String itemType;
  final String borrowerName;
  final String borrowerType; // 'student' or 'professor'
  final String borrowerId;
  final int borrowedQuantity;
  final int returnedQuantity;
  final int unreturnedQuantity;
  final String reservationDate;
  final String? dueDate;

  UnreturnedItem({
    required this.detailId,
    required this.reservationId,
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.borrowerName,
    required this.borrowerType,
    required this.borrowerId,
    required this.borrowedQuantity,
    required this.returnedQuantity,
    required this.unreturnedQuantity,
    required this.reservationDate,
    this.dueDate,
  });

  factory UnreturnedItem.fromJson(Map<String, dynamic> json) {
    return UnreturnedItem(
      detailId: json['detail_id']?.toString() ?? '',
      reservationId: json['reservation_id']?.toString() ?? '',
      itemId: json['item_id']?.toString() ?? '',
      itemName: json['item_name'] ?? '',
      itemType: json['item_type'] ?? '',
      borrowerName: json['borrower_name'] ?? '',
      borrowerType: json['borrower_type'] ?? 'student',
      borrowerId: json['borrower_id']?.toString() ?? '',
      borrowedQuantity: json['borrowed_quantity'] ?? 0,
      returnedQuantity: json['returned_quantity'] ?? 0,
      unreturnedQuantity: json['unreturned_quantity'] ?? 0,
      reservationDate: json['reservation_date'] ?? '',
      dueDate: json['due_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detail_id': detailId,
      'reservation_id': reservationId,
      'item_id': itemId,
      'item_name': itemName,
      'item_type': itemType,
      'borrower_name': borrowerName,
      'borrower_type': borrowerType,
      'borrower_id': borrowerId,
      'borrowed_quantity': borrowedQuantity,
      'returned_quantity': returnedQuantity,
      'unreturned_quantity': unreturnedQuantity,
      'reservation_date': reservationDate,
      'due_date': dueDate,
    };
  }

  UnreturnedItem copyWith({
    String? detailId,
    String? reservationId,
    String? itemId,
    String? itemName,
    String? itemType,
    String? borrowerName,
    String? borrowerType,
    String? borrowerId,
    int? borrowedQuantity,
    int? returnedQuantity,
    int? unreturnedQuantity,
    String? reservationDate,
    String? dueDate,
  }) {
    return UnreturnedItem(
      detailId: detailId ?? this.detailId,
      reservationId: reservationId ?? this.reservationId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemType: itemType ?? this.itemType,
      borrowerName: borrowerName ?? this.borrowerName,
      borrowerType: borrowerType ?? this.borrowerType,
      borrowerId: borrowerId ?? this.borrowerId,
      borrowedQuantity: borrowedQuantity ?? this.borrowedQuantity,
      returnedQuantity: returnedQuantity ?? this.returnedQuantity,
      unreturnedQuantity: unreturnedQuantity ?? this.unreturnedQuantity,
      reservationDate: reservationDate ?? this.reservationDate,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
