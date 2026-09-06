import 'package:flutter/material.dart';
import '../../../core/api/supabase_client.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../core/models/navigation_item.dart';
import 'dashboard_page.dart';
import '../../audit/pages/audit_page.dart';
import '../../user_management/pages/manage_students_page.dart';
import '../../user_management/pages/manage_professors_page.dart';
import '../../user_management/pages/accounts_approvals_page.dart';
import '../../room_and_resources/room_monitor/pages/room_monitor_page.dart';
import '../../room_and_resources/inventory/pages/inventory_page.dart';
import '../../room_and_resources/unreturned_item/pages/unreturned_item_page.dart';
import '../../reservations/ongoing_reservation/pages/ongoing_reservation_page.dart';
import '../../reservations/professor_reservation/pages/professor_reservation_page.dart';
import '../../reservations/student_reservation/pages/student_reservation_page.dart';
import '../../reservations/reservations_history/pages/reservations_history_page.dart';
import '../../reservations/new_reservation/pages/new_reservation_page.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../notifications/models/notification_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NotificationController _notificationController = NotificationController();
  NavigationItemType _selectedItem = NavigationItemType.dashboard;
  String _selectedSubItem = '';
  String? _initialReservationId;
  final Set<NavigationItemType> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    _notificationController.initialize();
  }

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

  void _handleNavigation(String destination) {
    setState(() {
      _selectedSubItem = destination;

      // Set the appropriate parent item based on destination
      if ([
        'Accounts Approvals',
        'Manage Students',
        'Manage Professors',
      ].contains(destination)) {
        _selectedItem = NavigationItemType.userManagement;
        _expandedItems.add(NavigationItemType.userManagement);
      } else if ([
        'Room Monitor',
        'Inventory',
        'Unreturned Items',
      ].contains(destination)) {
        _selectedItem = NavigationItemType.roomResources;
        _expandedItems.add(NavigationItemType.roomResources);
      } else if ([
        'New Reservation',
        'Ongoing Reservations',
        'Professor Reservations',
        'Student Reservations',
        'Reservation History',
      ].contains(destination)) {
        _selectedItem = NavigationItemType.reservations;
        _expandedItems.add(NavigationItemType.reservations);
      } else if (destination == 'Audit') {
        _selectedItem = NavigationItemType.audit;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildAppBar(authController),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFF2E7D32)),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/Scilab_Logo.png',
                  height: 32,
                  width: 32,
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SciLabReserve',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Lab Management',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: navigationItems.map((item) {
                return _buildNavigationItem(item);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item) {
    final isSelected = _selectedItem == item.type;
    final hasSubItems = item.subItems != null && item.subItems!.isNotEmpty;
    final isSubItemExpanded = hasSubItems && _expandedItems.contains(item.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _selectedItem = item.type;
              _selectedSubItem = '';
              if (hasSubItems) {
                if (_expandedItems.contains(item.type)) {
                  _expandedItems.remove(item.type);
                } else {
                  _expandedItems.add(item.type);
                }
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2E7D32).withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 20),
                Icon(
                  item.icon,
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (hasSubItems)
                  Icon(
                    isSubItemExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : Colors.grey[600],
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (hasSubItems && isSubItemExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              children: item.subItems!.map((subItem) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSubItem = subItem.title;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedSubItem == subItem.title
                          ? const Color(0xFF2E7D32).withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          subItem.icon,
                          color: _selectedSubItem == subItem.title
                              ? const Color(0xFF2E7D32)
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            subItem.title,
                            style: TextStyle(
                              color: _selectedSubItem == subItem.title
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey[700],
                              fontWeight: _selectedSubItem == subItem.title
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildAppBar(AuthController authController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/images/DLSP_Logo.png', height: 40),
              const SizedBox(width: 16),
              Text(
                _getPageTitle(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          Row(
            children: [
              AnimatedBuilder(
                animation: _notificationController,
                builder: (context, _) => _buildNotificationBell(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authController.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBell() {
    final count = _notificationController.unreadCount;
    return Semantics(
      button: true,
      label: 'Notifications, $count unread',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: _showNotificationPanel,
          ),
          if (count > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showNotificationPanel() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AnimatedBuilder(
        animation: _notificationController,
        builder: (context, _) => _NotificationDialog(
          controller: _notificationController,
          onNotificationTap: _openNotification,
        ),
      ),
    );
  }

  Future<void> _openNotification(AppNotification notification) async {
    final type = notification.type.toLowerCase();
    final reservationId = notification.relatedId;
    if (reservationId == null || !type.contains('reservation')) return;

    final reservation = await SupabaseService.database
        .from('reservations')
        .select('user_id')
        .eq('reservation_id', int.tryParse(reservationId) ?? -1)
        .maybeSingle();
    final userId = reservation?['user_id']?.toString();
    final user = userId == null
        ? null
        : await SupabaseService.database
            .from('user_info')
            .select('role')
            .eq('id', userId)
            .maybeSingle();
    final isProfessor = user?['role']?.toString().toLowerCase() == 'professor';

    Navigator.of(context).pop();
    _initialReservationId = reservationId;
    _handleNavigation(isProfessor ? 'Professor Reservations' : 'Student Reservations');
  }

  String _getPageTitle() {
    if (_selectedSubItem.isNotEmpty) {
      return _selectedSubItem;
    }
    switch (_selectedItem) {
      case NavigationItemType.dashboard:
        return 'Dashboard';
      case NavigationItemType.audit:
        return 'Audit';
      case NavigationItemType.reservations:
        return 'Reservations';
      case NavigationItemType.roomResources:
        return 'Room & Resources';
      case NavigationItemType.userManagement:
        return 'User Management';
    }
  }

  Widget _buildContent() {
    // Handle sub-items first
    if (_selectedSubItem.isNotEmpty) {
      switch (_selectedSubItem) {
        case 'New Reservation':
          return const NewReservationPage();
        case 'Accounts Approvals':
          return const AccountsApprovalsPage();
        case 'Manage Students':
          return const ManageStudentsPage();
        case 'Manage Professors':
          return const ManageProfessorsPage();
        case 'Room Monitor':
          return const RoomMonitorPage();
        case 'Inventory':
          return const InventoryPage();
        case 'Unreturned Items':
          return const UnreturnedItemPage();
        case 'Reservation History':
        return ReservationsHistoryPage(initialReservationId: _initialReservationId);
        case 'Professor Reservations':
          return ProfessorReservationPage(
            key: ValueKey('professor-$_initialReservationId'),
            initialReservationId: _initialReservationId,
            onInitialReservationHandled: _clearInitialReservation,
          );
        case 'Student Reservations':
          return StudentReservationPage(
            key: ValueKey('student-$_initialReservationId'),
            initialReservationId: _initialReservationId,
            onInitialReservationHandled: _clearInitialReservation,
          );
        case 'Ongoing Reservations':
          return const OngoingReservationPage();
      }
    }

    // Handle main navigation items
    switch (_selectedItem) {
      case NavigationItemType.dashboard:
        return DashboardPage(onNavigate: _handleNavigation);
      case NavigationItemType.audit:
        return const AuditPage();
      case NavigationItemType.reservations:
        // Default to first sub-item
        return const OngoingReservationPage();
      case NavigationItemType.roomResources:
        // Default to first sub-item
        return const RoomMonitorPage();
      case NavigationItemType.userManagement:
        // Default to first sub-item
        return const AccountsApprovalsPage();
    }
  }

  void _clearInitialReservation() {
    if (_initialReservationId == null || !mounted) return;
    setState(() => _initialReservationId = null);
  }
}

class _NotificationDialog extends StatelessWidget {
  const _NotificationDialog({required this.controller, required this.onNotificationTap});
  final NotificationController controller;
  final ValueChanged<AppNotification> onNotificationTap;

  String _relative(DateTime date) {
    final difference = DateTime.now().difference(date.toLocal());
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(child: Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                if (controller.unreadCount > 0)
                  TextButton(onPressed: controller.markAllAsRead, child: const Text('Mark all as read')),
              ]),
              if (controller.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (controller.errorMessage != null)
                Expanded(child: Center(child: Text('Unable to load notifications.')))
              else if (controller.notifications.isEmpty)
                const Expanded(child: Center(child: Text('No notifications')))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: controller.notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = controller.notifications[index];
                      return ListTile(
                        onTap: () async {
                          await controller.markAsRead(item);
                          onNotificationTap(item);
                        },
                        tileColor: item.isRead ? null : const Color(0xFFE8F5E9),
                        leading: Icon(item.isRead ? Icons.notifications_none : Icons.notifications, color: const Color(0xFF2E7D32)),
                        title: Text(item.title, style: TextStyle(fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold)),
                        subtitle: Text('${item.message}\n${_relative(item.createdAt)}'),
                        isThreeLine: true,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
