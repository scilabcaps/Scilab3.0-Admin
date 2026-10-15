enum ReservationSchedulePhase { upcoming, ongoing, ended }

class ReservationSchedule {
  const ReservationSchedule._();

  static bool isFullyApproved({
    required dynamic professorApproval,
    required dynamic adminApproval,
  }) {
    return professorApproval?.toString().toLowerCase() == 'approved' &&
        adminApproval?.toString().toLowerCase() == 'approved';
  }

  static ReservationSchedulePhase phase({
    required dynamic reservationDate,
    required dynamic startTime,
    required dynamic endTime,
    DateTime? now,
  }) {
    final date = reservationDate is DateTime
        ? reservationDate
        : DateTime.parse(reservationDate.toString());
    final start = _combine(date, startTime);
    var end = _combine(date, endTime);
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    final current = now ?? DateTime.now();
    if (current.isBefore(start)) return ReservationSchedulePhase.upcoming;
    if (current.isBefore(end)) return ReservationSchedulePhase.ongoing;
    return ReservationSchedulePhase.ended;
  }

  static String approvedStatus({
    required dynamic reservationDate,
    required dynamic startTime,
    required dynamic endTime,
    DateTime? now,
  }) {
    return phase(
              reservationDate: reservationDate,
              startTime: startTime,
              endTime: endTime,
              now: now,
            ) ==
            ReservationSchedulePhase.ongoing
        ? 'Ongoing'
        : 'Approved';
  }

  static DateTime _combine(DateTime date, dynamic timeValue) {
    final parts = timeValue.toString().split(':');
    if (parts.length < 2) {
      throw FormatException('Invalid reservation time: $timeValue');
    }
    final seconds = parts.length > 2 ? double.parse(parts[2]).floor() : 0;
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
      seconds,
    );
  }
}
