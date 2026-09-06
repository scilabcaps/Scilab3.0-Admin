import 'package:flutter_test/flutter_test.dart';
import 'package:admin_scalib/features/reservations/new_reservation/controllers/new_reservation_controller.dart';
import 'package:admin_scalib/features/reservations/new_reservation/models/new_reservation_models.dart';
import 'package:admin_scalib/features/reservations/new_reservation/services/new_reservation_service.dart';

void main() {
  late _FakeGateway gateway;
  late NewReservationController controller;

  setUp(() async {
    gateway = _FakeGateway();
    controller = NewReservationController(gateway: gateway);
    await controller.loadResources();
    await controller.selectDate(DateTime.now().add(const Duration(days: 2)));
  });

  tearDown(() => controller.dispose());

  test('selecting a second room replaces the first room', () async {
    controller.addResource(gateway.roomOne);
    controller.addResource(gateway.roomTwo);
    await Future<void>.delayed(Duration.zero);

    expect(controller.cart, hasLength(1));
    expect(controller.selectedRoom?.resource.id, gateway.roomTwo.id);
  });

  test('equipment and chemical quantities cannot exceed stock', () {
    expect(controller.addResource(gateway.equipment), isTrue);
    expect(controller.changeQuantity(gateway.equipment.key, 1), isTrue);
    expect(controller.changeQuantity(gateway.equipment.key, 1), isFalse);

    expect(controller.addResource(gateway.chemical), isTrue);
    expect(controller.changeQuantity(gateway.chemical.key, 2), isTrue);
    expect(controller.changeQuantity(gateway.chemical.key, 1), isFalse);
  });

  test('time selection rejects a range that crosses a booking', () async {
    controller.addResource(gateway.roomOne);
    await Future<void>.delayed(Duration.zero);

    expect(controller.selectTimeBoundary(8 * 60), isNull);
    expect(controller.selectTimeBoundary(10 * 60), contains('unavailable'));
    expect(controller.endMinutes, isNull);
  });

  test('submits all resource types as an immediately valid request', () async {
    controller.addResource(gateway.roomOne);
    controller.addResource(gateway.chemical);
    controller.addResource(gateway.equipment);
    controller.addResource(gateway.glassware);
    await Future<void>.delayed(Duration.zero);

    expect(controller.selectTimeBoundary(10 * 60), isNull);
    expect(controller.selectTimeBoundary(11 * 60), isNull);

    final id = await controller.submit('Admin-created reservation');

    expect(id, 42);
    expect(gateway.createdRequest, isNotNull);
    expect(gateway.createdRequest!.items, hasLength(4));
    expect(
      gateway.createdRequest!.items.map((item) => item.resource.type),
      containsAll(ReservationResourceType.values),
    );
    expect(controller.cart, isEmpty);
  });

  test('allows an equipment-only reservation without a room', () async {
    controller.addResource(gateway.equipment);
    expect(controller.selectTimeBoundary(10 * 60), isNull);
    expect(controller.selectTimeBoundary(11 * 60), isNull);

    final id = await controller.submit('Equipment only');

    expect(id, 42);
    expect(gateway.createdRequest, isNotNull);
    expect(gateway.createdRequest!.room, isNull);
    expect(
      gateway.createdRequest!.items.single.resource.type,
      ReservationResourceType.equipment,
    );
  });
}

class _FakeGateway implements NewReservationGateway {
  final roomOne = const ReservationResource(
    id: 1,
    name: 'Chemistry Laboratory',
    type: ReservationResourceType.room,
    availableQuantity: 1,
    description: 'Capacity: 30',
    status: 'Available',
  );
  final roomTwo = const ReservationResource(
    id: 2,
    name: 'Physics Laboratory',
    type: ReservationResourceType.room,
    availableQuantity: 1,
    description: 'Capacity: 30',
    status: 'Available',
  );
  final chemical = const ReservationResource(
    id: 3,
    name: 'Sodium chloride',
    type: ReservationResourceType.chemical,
    availableQuantity: 3,
    description: '3 mL available',
    unit: 'mL',
  );
  final equipment = const ReservationResource(
    id: 4,
    name: 'Microscope',
    type: ReservationResourceType.equipment,
    availableQuantity: 2,
    description: 'Available',
  );
  final glassware = const ReservationResource(
    id: 5,
    name: 'Beaker',
    type: ReservationResourceType.glassware,
    availableQuantity: 4,
    description: 'Available',
  );

  NewReservationRequest? createdRequest;

  @override
  Future<int> createReservation(NewReservationRequest request) async {
    createdRequest = request;
    return 42;
  }

  @override
  Future<List<ReservationResource>> loadResources() async {
    return [roomOne, roomTwo, chemical, equipment, glassware];
  }

  @override
  Future<List<ReservationTimeRange>> loadRoomSchedule(
    int roomId,
    DateTime date,
  ) async {
    if (roomId != roomOne.id) return [];
    return const [
      ReservationTimeRange(startMinutes: 9 * 60, endMinutes: 10 * 60),
    ];
  }
}
