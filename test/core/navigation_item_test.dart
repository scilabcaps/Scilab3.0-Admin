import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:admin_scalib/core/models/navigation_item.dart';

void main() {
  test('Reservations includes New Reservation as its first submenu item', () {
    final reservations = navigationItems.firstWhere(
      (item) => item.title == 'Reservations',
    );

    expect(reservations.subItems, isNotNull);
    expect(reservations.subItems!.first.title, 'New Reservation');
    expect(reservations.subItems!.first.type, NavigationItemType.reservations);
    expect(reservations.subItems!.first.icon, Icons.add_box);
  });

  test('Room & Resources includes Announcements', () {
    final roomResources = navigationItems.firstWhere(
      (item) => item.title == 'Room & Resources',
    );

    expect(
      roomResources.subItems!.any((item) => item.title == 'Announcements'),
      isTrue,
    );
  });
}
