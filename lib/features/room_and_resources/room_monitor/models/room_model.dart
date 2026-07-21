class Room {
  final String roomId;
  final String roomName;
  final int capacity;
  final String status;
  final String? reservationDate;
  final String? startTime;
  final String? endTime;
  final bool isDeleted;

  Room({
    required this.roomId,
    required this.roomName,
    required this.capacity,
    required this.status,
    this.reservationDate,
    this.startTime,
    this.endTime,
    this.isDeleted = false,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: json['room_id']?.toString() ?? '',
      roomName: json['room_name'] ?? '',
      capacity: json['capacity'] ?? 0,
      status: json['status'] ?? 'Available',
      reservationDate: json['reservation_date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'room_name': roomName,
      'capacity': capacity,
      'status': status,
      'reservation_date': reservationDate,
      'start_time': startTime,
      'end_time': endTime,
      'is_deleted': isDeleted,
    };
  }

  String get timeRange {
    if (startTime != null && endTime != null) {
      return '$startTime - $endTime';
    }
    return '-';
  }

  Room copyWith({
    String? roomId,
    String? roomName,
    int? capacity,
    String? status,
    String? reservationDate,
    String? startTime,
    String? endTime,
    bool? isDeleted,
  }) {
    return Room(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      reservationDate: reservationDate ?? this.reservationDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
