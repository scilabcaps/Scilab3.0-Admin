# Audit Trail Implementation Guide

## Overview

This document outlines the implementation of an audit trail system for the SciLab Admin application. The audit trail tracks administrative actions that modify the system, answering: "Who changed the system, what did they change, and when?"

## Strategy

**Audit only administrative actions that modify the system.**

- **DO Audit**: Create, edit, delete, ban, unban, approve, reject, cancel, complete operations performed by admins
- **DON'T Audit**: Login/logout, viewing pages, searching, downloading reports, automatic stock deductions, student/professor self-actions

**Keep using `stock_history`** for inventory movements - don't duplicate those logs.

## Architecture

### Hybrid Storage Approach

To stay within Supabase free tier limits (500 MB database):

- **Recent Logs (Supabase)**: Last 30-90 days
  - Fast queries for recent activity
  - Real-time monitoring
  - Immediate access for investigations

- **Archived Logs (External Storage)**: Older than retention period
  - Long-term compliance storage
  - Cost-effective (Cloudflare R2: $0.015/GB)
  - Accessed only when needed

### Storage Calculation

- **Supabase (recent logs)**: ~4.5 MB for 90 days (100 actions/day × 500 bytes × 90 days)
- **External storage (archived)**: ~18 MB for 1 year
- **Total cost**: ~$0.001/month

## Database Schema

### Create `audit_logs` table in Supabase

```sql
CREATE TABLE audit_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  action_type TEXT NOT NULL, -- CREATE, UPDATE, DELETE, BAN, UNBAN, APPROVE, REJECT, CANCEL, COMPLETE
  entity_type TEXT NOT NULL, -- user, room, asset, chemical, reservation
  entity_id TEXT,
  old_values JSONB,
  new_values JSONB,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_action_type ON audit_logs(action_type);
```

## Implementation Steps

### Step 1: Update SupabaseConfig

Add the audit logs table constant to `lib/core/api/supabase_config.dart`:

```dart
static const String tableAuditLogs = 'audit_logs';
```

### Step 2: Create Audit Model

Create `lib/features/audit/models/audit_log_model.dart`:

```dart
class AuditLog {
  final String id;
  final String userId;
  final String actionType;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? description;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.entityType,
    this.entityId,
    this.oldValues,
    this.newValues,
    this.description,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actionType: json['action_type'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String?,
      oldValues: json['old_values'] as Map<String, dynamic>?,
      newValues: json['new_values'] as Map<String, dynamic>?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action_type': actionType,
      'entity_type': entityType,
      'entity_id': entityId,
      'old_values': oldValues,
      'new_values': newValues,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AuditLog copyWith({
    String? id,
    String? userId,
    String? actionType,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? description,
    DateTime? createdAt,
  }) {
    return AuditLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actionType: actionType ?? this.actionType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      oldValues: oldValues ?? this.oldValues,
      newValues: newValues ?? this.newValues,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

### Step 3: Create Audit Service

Create `lib/features/audit/services/audit_service.dart`:

```dart
import '../../../core/api/supabase_client.dart';
import '../../../core/api/supabase_config.dart';
import '../models/audit_log_model.dart';

class AuditService {
  static final AuditService _instance = AuditService._internal();

  factory AuditService() => _instance;

  AuditService._internal();

  /// Log an audit action to Supabase
  Future<void> logAction({
    required String actionType,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? description,
  }) async {
    try {
      final currentUser = SupabaseService.auth.currentUser;
      if (currentUser == null) return;

      await SupabaseService.database
          .from(SupabaseConfig.tableAuditLogs)
          .insert({
        'user_id': currentUser.id,
        'action_type': actionType,
        'entity_type': entityType,
        'entity_id': entityId,
        'old_values': oldValues,
        'new_values': newValues,
        'description': description,
      });
    } catch (e) {
      // Log error but don't throw - audit failures shouldn't break the app
      print('Failed to log audit action: $e');
    }
  }

  /// Get recent audit logs from Supabase
  Future<List<AuditLog>> getRecentLogs({
    int days = 30,
    String? entityType,
    String? actionType,
    String? userId,
  }) async {
    try {
      var query = SupabaseService.database
          .from(SupabaseConfig.tableAuditLogs)
          .select()
          .gte('created_at', DateTime.now().subtract(Duration(days: days)).toIso8601String())
          .order('created_at', ascending: false);

      if (entityType != null) {
        query = query.eq('entity_type', entityType);
      }
      if (actionType != null) {
        query = query.eq('action_type', actionType);
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final response = await query;
      return response.map((e) => AuditLog.fromJson(e)).toList();
    } catch (e) {
      print('Failed to fetch audit logs: $e');
      return [];
    }
  }

  /// Get audit logs for a specific entity
  Future<List<AuditLog>> getLogsByEntity(String entityType, String entityId) async {
    return getRecentLogs(
      days: 365, // Longer retention for entity-specific queries
      entityType: entityType,
    ).then((logs) => logs.where((log) => log.entityId == entityId).toList());
  }

  /// Get audit logs for a specific user
  Future<List<AuditLog>> getLogsByUser(String userId) async {
    return getRecentLogs(days: 365, userId: userId);
  }
}
```

### Step 4: Add Audit Logging to Controllers

#### UserController

Add audit logging to `lib/features/user_management/controllers/user_controller.dart`:

```dart
// Add import
import '../../audit/services/audit_service.dart';

class UserController extends ChangeNotifier {
  final AuditService _auditService = AuditService();

  Future<bool> createUser({...}) async {
    // ... existing code ...
    
    // After successful user creation
    await _auditService.logAction(
      actionType: 'CREATE',
      entityType: 'user',
      entityId: authResponse.user!.id,
      newValues: {
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'role': userType,
      },
      description: 'Created $userType account: $firstName $lastName',
    );
    
    return true;
  }

  Future<bool> updateUser(User updatedUser) async {
    // Capture old values before update
    final oldUser = updatedUser.userType == 'student'
        ? _students.firstWhere((u) => u.userId == updatedUser.userId)
        : _professors.firstWhere((u) => u.userId == updatedUser.userId);
    
    // ... existing update code ...
    
    await _auditService.logAction(
      actionType: 'UPDATE',
      entityType: 'user',
      entityId: updatedUser.userId,
      oldValues: {
        'email': oldUser.email,
        'first_name': oldUser.firstName,
        'last_name': oldUser.lastName,
      },
      newValues: {
        'email': updatedUser.email,
        'first_name': updatedUser.firstName,
        'last_name': updatedUser.lastName,
      },
      description: 'Updated user: ${updatedUser.firstName} ${updatedUser.lastName}',
    );
    
    return true;
  }

  Future<void> banUser(String userId, String userType) async {
    // ... existing code ...
    
    await _auditService.logAction(
      actionType: 'BAN',
      entityType: 'user',
      entityId: userId,
      newValues: {'is_banned': true},
      description: 'Banned $userType: $userId',
    );
  }

  Future<void> unbanUser(String userId, String userType) async {
    // ... existing code ...
    
    await _auditService.logAction(
      actionType: 'UNBAN',
      entityType: 'user',
      entityId: userId,
      newValues: {'is_banned': false},
      description: 'Unbanned $userType: $userId',
    );
  }
}
```

#### RoomController

Add audit logging to `lib/features/room_and_resources/room_monitor/controllers/room_controller.dart`:

```dart
// Add import
import '../../audit/services/audit_service.dart';

class RoomController extends ChangeNotifier {
  final AuditService _auditService = AuditService();

  Future<void> updateRoomStatus(String roomId, String newStatus) async {
    // Capture old status
    final oldRoom = _rooms.firstWhere((r) => r.roomId == roomId);
    final oldStatus = oldRoom.status;
    
    // ... existing update code ...
    
    await _auditService.logAction(
      actionType: 'UPDATE',
      entityType: 'room',
      entityId: roomId,
      oldValues: {'status': oldStatus},
      newValues: {'status': newStatus},
      description: 'Changed room ${oldRoom.roomName} status: $oldStatus → $newStatus',
    );
  }
}
```

#### InventoryController

Add audit logging to `lib/features/room_and_resources/inventory/controllers/inventory_controller.dart`:

```dart
// Add import
import '../../audit/services/audit_service.dart';

class InventoryController extends ChangeNotifier {
  final AuditService _auditService = AuditService();

  Future<void> updateStock(String itemId, String category, int newQuantity) async {
    // Capture old values
    final index = _inventoryItems.indexWhere((i) => i.itemId == itemId && i.category.toLowerCase() == category.toLowerCase());
    final oldItem = _inventoryItems[index];
    final oldQuantity = oldItem.quantity;
    
    // ... existing update code ...
    
    await _auditService.logAction(
      actionType: 'UPDATE',
      entityType: category.toLowerCase() == 'chemical' ? 'chemical' : 'asset',
      entityId: itemId,
      oldValues: {'quantity': oldQuantity},
      newValues: {'quantity': newQuantity},
      description: 'Manual stock adjustment for ${oldItem.itemName}: $oldQuantity → $newQuantity',
    );
  }
}
```

#### StudentReservationController

Add audit logging to `lib/features/reservations/student_reservation/controllers/student_reservation_controller.dart`:

```dart
// Add import
import '../../audit/services/audit_service.dart';

class StudentReservationController extends ChangeNotifier {
  final AuditService _auditService = AuditService();

  Future<void> approveReservation(String reservationId) async {
    // ... existing code ...
    
    await _auditService.logAction(
      actionType: 'APPROVE',
      entityType: 'reservation',
      entityId: reservationId,
      newValues: {'status': 'Approved'},
      description: 'Admin approved student reservation: $reservationId',
    );
  }

  Future<void> rejectReservation(String reservationId) async {
    // ... existing code ...
    
    await _auditService.logAction(
      actionType: 'REJECT',
      entityType: 'reservation',
      entityId: reservationId,
      newValues: {'status': 'Declined'},
      description: 'Admin rejected student reservation: $reservationId',
    );
  }
}
```

#### OngoingReservationController

Add audit logging to `lib/features/reservations/ongoing_reservation/controllers/ongoing_reservation_controller.dart`:

```dart
// Add import
import '../../audit/services/audit_service.dart';

class OngoingReservationController extends ChangeNotifier {
  final AuditService _auditService = AuditService();

  Future<void> completeReservation(String reservationId) async {
    // ... existing code ...
    
    await _auditService.logAction(
      actionType: 'COMPLETE',
      entityType: 'reservation',
      entityId: reservationId,
      newValues: {'status': 'Completed'},
      description: 'Admin completed reservation: $reservationId',
    );
  }
}
```

### Step 5: Create Audit Controller

Create `lib/features/audit/controllers/audit_controller.dart`:

```dart
import 'package:flutter/material.dart';
import '../models/audit_log_model.dart';
import '../services/audit_service.dart';

class AuditController extends ChangeNotifier {
  final AuditService _service = AuditService();
  
  List<AuditLog> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filters
  String _selectedEntityType = 'all';
  String _selectedActionType = 'all';
  int _selectedDays = 30;

  List<AuditLog> get logs => _filteredLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedEntityType => _selectedEntityType;
  String get selectedActionType => _selectedActionType;
  int get selectedDays => _selectedDays;

  List<AuditLog> get _filteredLogs {
    var filtered = _logs;
    
    if (_selectedEntityType != 'all') {
      filtered = filtered.where((log) => log.entityType == _selectedEntityType).toList();
    }
    if (_selectedActionType != 'all') {
      filtered = filtered.where((log) => log.actionType == _selectedActionType).toList();
    }
    
    return filtered;
  }

  Future<void> loadLogs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logs = await _service.getRecentLogs(
        days: _selectedDays,
        entityType: _selectedEntityType == 'all' ? null : _selectedEntityType,
        actionType: _selectedActionType == 'all' ? null : _selectedActionType,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load audit logs: $e';
      _logs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setEntityTypeFilter(String type) {
    _selectedEntityType = type;
    notifyListeners();
  }

  void setActionTypeFilter(String type) {
    _selectedActionType = type;
    notifyListeners();
  }

  void setDaysFilter(int days) {
    _selectedDays = days;
    notifyListeners();
  }

  void clearFilters() {
    _selectedEntityType = 'all';
    _selectedActionType = 'all';
    _selectedDays = 30;
    notifyListeners();
  }

  void refresh() {
    loadLogs();
  }
}
```

### Step 6: Update Audit Page UI

Update `lib/features/audit/pages/audit_page.dart`:

```dart
import 'package:flutter/material.dart';
import '../controllers/audit_controller.dart';
import '../models/audit_log_model.dart';

class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  final AuditController _controller = AuditController();

  @override
  void initState() {
    super.initState();
    _controller.loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Audit Logs',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _buildEntityTypeFilter(),
                  const SizedBox(width: 12),
                  _buildActionTypeFilter(),
                  const SizedBox(width: 12),
                  _buildDaysFilter(),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _controller.refresh(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAuditTable(),
        ],
      ),
    );
  }

  Widget _buildEntityTypeFilter() {
    return DropdownButton<String>(
      value: _controller.selectedEntityType,
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Entities')),
        DropdownMenuItem(value: 'user', child: Text('Users')),
        DropdownMenuItem(value: 'room', child: Text('Rooms')),
        DropdownMenuItem(value: 'asset', child: Text('Assets')),
        DropdownMenuItem(value: 'chemical', child: Text('Chemicals')),
        DropdownMenuItem(value: 'reservation', child: Text('Reservations')),
      ],
      onChanged: (value) {
        if (value != null) {
          _controller.setEntityTypeFilter(value);
          _controller.loadLogs();
        }
      },
    );
  }

  Widget _buildActionTypeFilter() {
    return DropdownButton<String>(
      value: _controller.selectedActionType,
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Actions')),
        DropdownMenuItem(value: 'CREATE', child: Text('Create')),
        DropdownMenuItem(value: 'UPDATE', child: Text('Update')),
        DropdownMenuItem(value: 'DELETE', child: Text('Delete')),
        DropdownMenuItem(value: 'BAN', child: Text('Ban')),
        DropdownMenuItem(value: 'UNBAN', child: Text('Unban')),
        DropdownMenuItem(value: 'APPROVE', child: Text('Approve')),
        DropdownMenuItem(value: 'REJECT', child: Text('Reject')),
        DropdownMenuItem(value: 'CANCEL', child: Text('Cancel')),
        DropdownMenuItem(value: 'COMPLETE', child: Text('Complete')),
      ],
      onChanged: (value) {
        if (value != null) {
          _controller.setActionTypeFilter(value);
          _controller.loadLogs();
        }
      },
    );
  }

  Widget _buildDaysFilter() {
    return DropdownButton<int>(
      value: _controller.selectedDays,
      items: const [
        DropdownMenuItem(value: 7, child: Text('7 Days')),
        DropdownMenuItem(value: 30, child: Text('30 Days')),
        DropdownMenuItem(value: 90, child: Text('90 Days')),
      ],
      onChanged: (value) {
        if (value != null) {
          _controller.setDaysFilter(value);
          _controller.loadLogs();
        }
      },
    );
  }

  Widget _buildAuditTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          _buildTableHeader(),
          ..._controller.logs.map((log) => _buildLogRow(log)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Entity', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 4, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildLogRow(AuditLog log) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(_formatTimestamp(log.createdAt))),
          Expanded(flex: 2, child: _buildActionChip(log.actionType)),
          Expanded(flex: 2, child: Text(log.entityType)),
          Expanded(flex: 4, child: Text(log.description ?? 'N/A')),
        ],
      ),
    );
  }

  Widget _buildActionChip(String actionType) {
    Color color;
    switch (actionType) {
      case 'CREATE':
        color = Colors.green;
        break;
      case 'UPDATE':
        color = Colors.blue;
        break;
      case 'DELETE':
        color = Colors.red;
        break;
      case 'BAN':
        color = Colors.red;
        break;
      case 'UNBAN':
        color = Colors.green;
        break;
      case 'APPROVE':
        color = Colors.green;
        break;
      case 'REJECT':
        color = Colors.orange;
        break;
      case 'CANCEL':
        color = Colors.red;
        break;
      case 'COMPLETE':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(actionType),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
```

### Step 7: Log Rotation Service (Optional - For Future Implementation)

Create `lib/features/audit/services/audit_rotation_service.dart` for archiving old logs:

```dart
import '../../../core/api/supabase_client.dart';
import '../../../core/api/supabase_config.dart';

class AuditRotationService {
  /// Archive logs older than retention period to external storage
  Future<void> archiveOldLogs({int retentionDays = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    
    // Fetch logs to archive
    final oldLogs = await SupabaseService.database
        .from(SupabaseConfig.tableAuditLogs)
        .select()
        .lt('created_at', cutoffDate.toIso8601String());
    
    if (oldLogs.isEmpty) return;
    
    // TODO: Upload to external storage (Cloudflare R2, Supabase Storage, etc.)
    // await _uploadToExternalStorage(oldLogs, cutoffDate);
    
    // Delete from Supabase
    await SupabaseService.database
        .from(SupabaseConfig.tableAuditLogs)
        .delete()
        .lt('created_at', cutoffDate.toIso8601String());
  }
}
```

## Audit Points Summary

### ✅ Operations to Audit

| Module | Operation | Controller | Method |
|--------|-----------|------------|--------|
| User Management | Create user | UserController | createUser() |
| User Management | Edit user | UserController | updateUser() |
| User Management | Ban user | UserController | banUser() |
| User Management | Unban user | UserController | unbanUser() |
| Room Management | Change room status | RoomController | updateRoomStatus() |
| Lab Assets | Manual stock adjustment | InventoryController | updateStock() |
| Chemicals | Manual stock adjustment | InventoryController | updateStock() |
| Reservations | Admin approve | StudentReservationController | approveReservation() |
| Reservations | Admin reject | StudentReservationController | rejectReservation() |
| Reservations | Complete reservation | OngoingReservationController | completeReservation() |

### ❌ Operations NOT to Audit

| Module | Reason |
|--------|--------|
| AuthController | Login/logout excluded from strategy |
| ProfessorReservationController | Professor actions, not admin |
| ReservationsHistoryController | Read-only operations |
| UnreturnedItemController | Already logged in stock_history |
| DashboardController | Read-only operations |
| OngoingReservationController.updateItemStatus() | Stock changes in stock_history |

## Future Enhancements

1. **Room CRUD Operations**: Add audit logging for add/edit/delete room operations (not currently in RoomController)
2. **Asset CRUD Operations**: Add audit logging for add/edit/delete asset operations (not currently in InventoryController)
3. **Reservation Cancel/Ongoing**: Add audit logging for cancel and mark ongoing operations
4. **Announcements Module**: Add audit logging when announcements feature is implemented
5. **System Settings**: Add audit logging for settings changes (semester, schedule, limits, etc.)
6. **External Storage Archival**: Implement Cloudflare R2 or Supabase Storage for log archival
7. **Scheduled Rotation**: Set up cron job or Supabase Edge Function for automatic log rotation
8. **Export Functionality**: Add CSV/PDF export for audit reports
9. **User Details**: Fetch and display user names in audit log table
10. **Advanced Filtering**: Add date range picker and search functionality

## Testing Checklist

- [ ] Verify audit logs are created for each audited operation
- [ ] Verify old_values and new_values are correctly captured
- [ ] Verify audit page displays logs correctly
- [ ] Verify filters work (entity type, action type, days)
- [ ] Verify audit failures don't break the application
- [ ] Verify database size stays within limits
- [ ] Test log rotation service when implemented
- [ ] Verify user information is correctly associated with logs

## Notes

- Audit service catches errors silently to prevent breaking the application
- Consider adding a retry mechanism for failed audit logs
- The `stock_history` table remains the primary audit trail for inventory movements
- This implementation stays within Supabase free tier limits with the hybrid storage approach
