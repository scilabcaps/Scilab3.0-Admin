import 'package:flutter/material.dart';

enum NavigationItemType {
  dashboard,
  audit,
  reservations,
  roomResources,
  userManagement,
}

class NavigationItem {
  final String title;
  final NavigationItemType type;
  final IconData icon;
  final List<NavigationItem>? subItems;

  NavigationItem({
    required this.title,
    required this.type,
    required this.icon,
    this.subItems,
  });
}

final navigationItems = [
  NavigationItem(
    title: 'Dashboard',
    type: NavigationItemType.dashboard,
    icon: Icons.dashboard,
  ),
  NavigationItem(
    title: 'Audit Logs',
    type: NavigationItemType.audit,
    icon: Icons.history,
  ),
  NavigationItem(
    title: 'Reservations',
    type: NavigationItemType.reservations,
    icon: Icons.calendar_month,
    subItems: [
      NavigationItem(
        title: 'Reservation History',
        type: NavigationItemType.reservations,
        icon: Icons.history,
      ),
      NavigationItem(
        title: 'Professor Reservations',
        type: NavigationItemType.reservations,
        icon: Icons.person,
      ),
      NavigationItem(
        title: 'Student Reservations',
        type: NavigationItemType.reservations,
        icon: Icons.school,
      ),
      NavigationItem(
        title: 'Ongoing Reservations',
        type: NavigationItemType.reservations,
        icon: Icons.pending_actions,
      ),
    ],
  ),
  NavigationItem(
    title: 'Room & Resources',
    type: NavigationItemType.roomResources,
    icon: Icons.meeting_room,
    subItems: [
      NavigationItem(
        title: 'Room Monitor',
        type: NavigationItemType.roomResources,
        icon: Icons.monitor,
      ),
      NavigationItem(
        title: 'Inventory',
        type: NavigationItemType.roomResources,
        icon: Icons.inventory_2,
      ),
      NavigationItem(
        title: 'Unreturned Items',
        type: NavigationItemType.roomResources,
        icon: Icons.assignment_return,
      ),
    ],
  ),
  NavigationItem(
    title: 'User Management',
    type: NavigationItemType.userManagement,
    icon: Icons.people,
    subItems: [
      NavigationItem(
        title: 'Accounts Approvals',
        type: NavigationItemType.userManagement,
        icon: Icons.approval,
      ),
      NavigationItem(
        title: 'Manage Professors',
        type: NavigationItemType.userManagement,
        icon: Icons.person_outline,
      ),
      NavigationItem(
        title: 'Manage Students',
        type: NavigationItemType.userManagement,
        icon: Icons.school,
      ),
    ],
  ),
];
