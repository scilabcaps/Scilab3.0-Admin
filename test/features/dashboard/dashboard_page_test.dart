import 'package:admin_scalib/features/dashboard/controllers/dashboard_controller.dart';
import 'package:admin_scalib/features/dashboard/models/dashboard_model.dart';
import 'package:admin_scalib/features/dashboard/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _LoadedDashboardController extends DashboardController {
  @override
  Future<void> loadDashboardData() async {}

  @override
  DashboardStats get stats => DashboardStats(
    totalReservations: 3,
    approvedReservations: 2,
    pendingReservations: 1,
    rejectedReservations: 0,
    totalUsers: 5,
    activeRooms: 2,
    maintenanceRooms: 0,
  );

  @override
  List<CourseReservationData> get courseData => [
    CourseReservationData(
      course: 'Chemistry',
      reservationCount: 2,
      month: 'Oct',
    ),
    CourseReservationData(course: 'Biology', reservationCount: 1, month: 'Oct'),
  ];

  @override
  List<RecentActivity> get recentActivities => [
    RecentActivity(
      id: '1',
      title: 'Reservation approved',
      description: 'Chemistry laboratory',
      timestamp: 'Just now',
      type: 'reservation',
    ),
  ];
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-public-key',
    );
  });

  testWidgets('loaded dashboard lays out inside a desktop viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = _LoadedDashboardController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DashboardPage(controller: controller)),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Reservation Status'), findsOneWidget);
    expect(find.text('Recent Activities'), findsOneWidget);
  });
}
