import 'package:flutter_test/flutter_test.dart';

import 'package:admin_scalib/features/reservations/shared/reservation_schedule.dart';

void main() {
  const date = '2026-10-14';

  test('requires both professor and admin approval', () {
    expect(
      ReservationSchedule.isFullyApproved(
        professorApproval: 'Approved',
        adminApproval: 'Pending',
      ),
      isFalse,
    );
    expect(
      ReservationSchedule.isFullyApproved(
        professorApproval: 'Approved',
        adminApproval: 'Approved',
      ),
      isTrue,
    );
  });

  test('classifies time before start as upcoming', () {
    expect(
      ReservationSchedule.phase(
        reservationDate: date,
        startTime: '11:00:00',
        endTime: '12:00:00',
        now: DateTime(2026, 10, 14, 10, 59),
      ),
      ReservationSchedulePhase.upcoming,
    );
  });

  test('classifies exact start and active range as ongoing', () {
    expect(
      ReservationSchedule.phase(
        reservationDate: date,
        startTime: '11:00:00',
        endTime: '12:00:00',
        now: DateTime(2026, 10, 14, 11),
      ),
      ReservationSchedulePhase.ongoing,
    );
    expect(
      ReservationSchedule.phase(
        reservationDate: date,
        startTime: '11:00:00',
        endTime: '12:00:00',
        now: DateTime(2026, 10, 14, 11, 30),
      ),
      ReservationSchedulePhase.ongoing,
    );
  });

  test('classifies exact end as ended', () {
    expect(
      ReservationSchedule.phase(
        reservationDate: date,
        startTime: '11:00:00',
        endTime: '12:00:00',
        now: DateTime(2026, 10, 14, 12),
      ),
      ReservationSchedulePhase.ended,
    );
  });

  test('approval stores upcoming reservations as Approved', () {
    expect(
      ReservationSchedule.approvedStatus(
        reservationDate: date,
        startTime: '11:00:00',
        endTime: '12:00:00',
        now: DateTime(2026, 10, 14, 10),
      ),
      'Approved',
    );
    expect(
      ReservationSchedule.approvedStatus(
        reservationDate: date,
        startTime: '11:00:00',
        endTime: '12:00:00',
        now: DateTime(2026, 10, 14, 11, 30),
      ),
      'Ongoing',
    );
  });
}
