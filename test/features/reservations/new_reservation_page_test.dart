import 'package:admin_scalib/features/reservations/new_reservation/controllers/new_reservation_controller.dart';
import 'package:admin_scalib/features/reservations/new_reservation/models/new_reservation_models.dart';
import 'package:admin_scalib/features/reservations/new_reservation/pages/new_reservation_page.dart';
import 'package:admin_scalib/features/reservations/new_reservation/services/new_reservation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows nine resource cards per page with working navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = NewReservationController(gateway: _PaginationGateway());
    addTearDown(controller.dispose);
    await controller.loadResources();
    controller.selectType(ReservationResourceType.equipment);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NewReservationPage(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(find.text('Equipment 1'), findsOneWidget);
    expect(find.text('Equipment 9'), findsOneWidget);
    expect(find.text('Equipment 10'), findsNothing);

    final next = find.byKey(const Key('resource-page-next'));
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pump();

    expect(find.text('Page 2 of 2'), findsOneWidget);
    expect(find.text('Equipment 1'), findsNothing);
    expect(find.text('Equipment 10'), findsOneWidget);
    expect(find.text('Equipment 11'), findsOneWidget);
  });
}

class _PaginationGateway implements NewReservationGateway {
  @override
  Future<List<ReservationResource>> loadResources() async {
    return List.generate(
      11,
      (index) => ReservationResource(
        id: index + 1,
        name: 'Equipment ${index + 1}',
        type: ReservationResourceType.equipment,
        availableQuantity: 5,
        description: 'Available',
      ),
    );
  }

  @override
  Future<List<ReservationAccount>> loadReservationAccounts() async => const [];

  @override
  Future<List<ReservationTimeRange>> loadRoomSchedule(
    int roomId,
    DateTime date,
  ) async => const [];

  @override
  Future<int> createReservation(NewReservationRequest request) async => 1;
}
