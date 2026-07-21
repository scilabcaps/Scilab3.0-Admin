class ProfessorReservation {
  final String reservationId;
  final String? roomId;
  final String professorName;
  final String date;
  final String time;
  final String resources;
  final String additionalNote;
  final String professorApproval;
  final String? lastUpdated;

  ProfessorReservation({
    required this.reservationId,
    this.roomId,
    required this.professorName,
    required this.date,
    required this.time,
    required this.resources,
    required this.additionalNote,
    required this.professorApproval,
    this.lastUpdated,
  });

  factory ProfessorReservation.fromJson(Map<String, dynamic> json) {
    return ProfessorReservation(
      reservationId: json['reservation_id']?.toString() ?? '',
      roomId: json['room_id']?.toString(),
      professorName: json['professor_name'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      resources: json['resources'] ?? '',
      additionalNote: json['additional_note'] ?? '',
      professorApproval: json['professor_approval'] ?? 'Pending',
      lastUpdated: json['last_updated'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservation_id': reservationId,
      'room_id': roomId,
      'professor_name': professorName,
      'date': date,
      'time': time,
      'resources': resources,
      'additional_note': additionalNote,
      'professor_approval': professorApproval,
      'last_updated': lastUpdated,
    };
  }

  ProfessorReservation copyWith({
    String? reservationId,
    String? roomId,
    String? professorName,
    String? date,
    String? time,
    String? resources,
    String? additionalNote,
    String? professorApproval,
    String? lastUpdated,
  }) {
    return ProfessorReservation(
      reservationId: reservationId ?? this.reservationId,
      roomId: roomId ?? this.roomId,
      professorName: professorName ?? this.professorName,
      date: date ?? this.date,
      time: time ?? this.time,
      resources: resources ?? this.resources,
      additionalNote: additionalNote ?? this.additionalNote,
      professorApproval: professorApproval ?? this.professorApproval,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
