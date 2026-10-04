import 'package:flutter_test/flutter_test.dart';

import 'package:admin_scalib/features/reservations/new_reservation/models/new_reservation_models.dart';

void main() {
  test('occupied rooms remain selectable because schedule validates the time', () {
    const room = ReservationResource(
      id: 1,
      name: 'Chemistry Laboratory',
      type: ReservationResourceType.room,
      availableQuantity: 1,
      description: 'Capacity: 30',
      status: 'Available',
    );

    expect(room.isAvailable, isTrue);
  });

  test('maintenance rooms remain unavailable', () {
    const room = ReservationResource(
      id: 2,
      name: 'Physics Laboratory',
      type: ReservationResourceType.room,
      availableQuantity: 0,
      description: 'Capacity: 30',
      status: 'Maintenance',
    );

    expect(room.isAvailable, isFalse);
  });
}
