class StudentReservation {
  final String reservationId;
  final String studentName;
  final String date;
  final String time;
  final String resources;
  final String yearSection;
  final String professor;
  final String status;
  final String? lastUpdated;

  StudentReservation({
    required this.reservationId,
    required this.studentName,
    required this.date,
    required this.time,
    required this.resources,
    required this.yearSection,
    required this.professor,
    required this.status,
    this.lastUpdated,
  });

  factory StudentReservation.fromJson(Map<String, dynamic> json) {
    return StudentReservation(
      reservationId: json['reservation_id']?.toString() ?? '',
      studentName: json['student_name'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      resources: json['resources'] ?? '',
      yearSection: json['year_section'] ?? '',
      professor: json['professor'] ?? '',
      status: json['status'] ?? 'Pending',
      lastUpdated: json['last_updated'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservation_id': reservationId,
      'student_name': studentName,
      'date': date,
      'time': time,
      'resources': resources,
      'year_section': yearSection,
      'professor': professor,
      'status': status,
      'last_updated': lastUpdated,
    };
  }

  StudentReservation copyWith({
    String? reservationId,
    String? studentName,
    String? date,
    String? time,
    String? resources,
    String? yearSection,
    String? professor,
    String? status,
    String? lastUpdated,
  }) {
    return StudentReservation(
      reservationId: reservationId ?? this.reservationId,
      studentName: studentName ?? this.studentName,
      date: date ?? this.date,
      time: time ?? this.time,
      resources: resources ?? this.resources,
      yearSection: yearSection ?? this.yearSection,
      professor: professor ?? this.professor,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
