import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../../../core/api/supabase_client.dart';
import '../../../core/api/supabase_config.dart';
import '../../../core/service/cache_service.dart';
import '../../audit/services/audit_service.dart';

class UserController extends ChangeNotifier {
  List<User> _students = [];
  List<User> _professors = [];
  List<User> _pendingApprovals = [];
  String? _errorMessage;
  final CacheService _cache = CacheService();
  final AuditService _auditService = AuditService();

  List<User> get students => _students;
  List<User> get professors => _professors;
  List<User> get pendingApprovals => _pendingApprovals;
  String? get errorMessage => _errorMessage;

  Future<void> loadStudents() async {
    final cacheKey = 'students_list';
    
    // Try to get from cache first
    final cachedStudents = _cache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cachedStudents != null) {
      _students = cachedStudents.map((data) => User(
        userId: data['userId'],
        displayName: data['displayName'],
        firstName: data['firstName'],
        lastName: data['lastName'],
        phone: data['phone'],
        email: data['email'],
        userType: data['userType'],
        createdAt: DateTime.parse(data['createdAt']),
        isBanned: data['isBanned'],
      )).toList();
      notifyListeners();
      return;
    }

    try {
      final response = await SupabaseService.database
          .from(SupabaseConfig.tableUserInfo)
          .select()
          .eq('role', 'student');

      print('Raw response: $response');

      _students = (response as List).map((data) {
        return User(
          userId: data['id'],
          displayName: data['username'] ?? '',
          firstName: data['first_name'] ?? '',
          lastName: data['last_name'] ?? '',
          phone: data['phone'],
          email: data['email'] ?? '',
          userType: 'student',
          createdAt: DateTime.parse(data['created_at']),
          isBanned: data['is_banned'] ?? false,
        );
      }).toList();

      print('Loaded ${_students.length} students');
      notifyListeners();

      // Cache the result with 60 minute TTL (user data changes infrequently)
      await _cache.set(cacheKey, _students.map((user) => {
        'userId': user.userId,
        'displayName': user.displayName,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'phone': user.phone,
        'email': user.email,
        'userType': user.userType,
        'createdAt': user.createdAt?.toIso8601String(),
        'isBanned': user.isBanned,
      }).toList(), ttlMinutes: 60);
    } catch (e) {
      print('Error loading students: $e');
      _students = [];
      notifyListeners();
    }
  }

  Future<void> loadProfessors() async {
    final cacheKey = 'professors_list';
    
    // Try to get from cache first
    final cachedProfessors = _cache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cachedProfessors != null) {
      _professors = cachedProfessors.map((data) => User(
        userId: data['userId'],
        displayName: data['displayName'],
        firstName: data['firstName'],
        lastName: data['lastName'],
        phone: data['phone'],
        email: data['email'],
        userType: data['userType'],
        createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
        isBanned: data['isBanned'],
      )).toList();
      notifyListeners();
      return;
    }

    try {
      final response = await SupabaseService.database
          .from(SupabaseConfig.tableUserInfo)
          .select()
          .eq('role', 'professor');

      _professors = (response as List).map((data) {
        return User(
          userId: data['id'],
          displayName: data['username'] ?? '',
          firstName: data['first_name'] ?? '',
          lastName: data['last_name'] ?? '',
          phone: data['phone'],
          email: data['email'] ?? '',
          userType: 'professor',
          createdAt: DateTime.parse(data['created_at']),
          isBanned: data['is_banned'] ?? false,
        );
      }).toList();

      notifyListeners();

      // Cache the result with 60 minute TTL (user data changes infrequently)
      await _cache.set(cacheKey, _professors.map((user) => {
        'userId': user.userId,
        'displayName': user.displayName,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'phone': user.phone,
        'email': user.email,
        'userType': user.userType,
        'createdAt': user.createdAt?.toIso8601String(),
        'isBanned': user.isBanned,
      }).toList(), ttlMinutes: 60);
    } catch (e) {
      print('Error loading professors: $e');
      _professors = [];
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String userType,
    String? phone,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Create auth user in Supabase
      final authResponse = await SupabaseService.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (authResponse.user == null) {
        _errorMessage = 'Failed to create auth user';
        notifyListeners();
        return false;
      }

      // Step 2: Insert user info into user_info table
      final userData = <String, dynamic>{
        'id': authResponse.user!.id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'role': userType,
      };
      
      // Auto-approve professor accounts
      if (userType == 'professor') {
        userData['isApproved'] = 1;
      }
      
      await SupabaseService.database
          .from(SupabaseConfig.tableUserInfo)
          .insert(userData);

      // Step 3: Add to local list
      final newUser = User(
        userId: authResponse.user!.id,
        displayName: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        userType: userType,
        createdAt: DateTime.now(),
      );

      if (userType == 'student') {
        _students.add(newUser);
      } else {
        _professors.add(newUser);
      }

      notifyListeners();

      // Clear cache after user creation to ensure consistency
      if (userType == 'student') {
        await _cache.remove('students_list');
      } else {
        await _cache.remove('professors_list');
      }

      // Log audit action
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
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('Error creating user: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> banUser(String userId, String userType) async {
    try {
      // Update user_info table
      await SupabaseService.database
          .from(SupabaseConfig.tableUserInfo)
          .update({'is_banned': true})
          .eq('id', userId);

      if (userType == 'student') {
        final index = _students.indexWhere((user) => user.userId == userId);
        if (index != -1) {
          _students[index] = _students[index].copyWith(isBanned: true);
        }
      } else {
        final index = _professors.indexWhere((user) => user.userId == userId);
        if (index != -1) {
          _professors[index] = _professors[index].copyWith(isBanned: true);
        }
      }

      notifyListeners();

      // Clear cache after user ban to ensure consistency
      if (userType == 'student') {
        await _cache.remove('students_list');
      } else {
        await _cache.remove('professors_list');
      }

      // Log audit action
      await _auditService.logAction(
        actionType: 'BAN',
        entityType: 'user',
        entityId: userId,
        newValues: {'is_banned': true},
        description: 'Banned $userType: $userId',
      );
    } catch (e) {
      print('Error banning user: $e');
    }
  }

  Future<void> unbanUser(String userId, String userType) async {
    try {
      // Update user_info table
      await SupabaseService.database
          .from(SupabaseConfig.tableUserInfo)
          .update({'is_banned': false})
          .eq('id', userId);

      if (userType == 'student') {
        final index = _students.indexWhere((user) => user.userId == userId);
        if (index != -1) {
          _students[index] = _students[index].copyWith(isBanned: false);
        }
      } else {
        final index = _professors.indexWhere((user) => user.userId == userId);
        if (index != -1) {
          _professors[index] = _professors[index].copyWith(isBanned: false);
        }
      }

      notifyListeners();

      // Clear cache after user unban to ensure consistency
      if (userType == 'student') {
        await _cache.remove('students_list');
      } else {
        await _cache.remove('professors_list');
      }

      // Log audit action
      await _auditService.logAction(
        actionType: 'UNBAN',
        entityType: 'user',
        entityId: userId,
        newValues: {'is_banned': false},
        description: 'Unbanned $userType: $userId',
      );
    } catch (e) {
      print('Error unbanning user: $e');
    }
  }

  void clearLocalData() {
    _students.clear();
    _professors.clear();
    _pendingApprovals.clear();
    notifyListeners();
  }

  Future<void> loadPendingApprovals() async {
    final cacheKey = 'pending_approvals_list';
    
    // Try to get from cache first
    final cachedApprovals = _cache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cachedApprovals != null) {
      _pendingApprovals = cachedApprovals.map((data) => User(
        userId: data['userId'],
        displayName: data['displayName'],
        firstName: data['firstName'],
        lastName: data['lastName'],
        phone: data['phone'],
        email: data['email'],
        userType: data['userType'],
        createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
        isBanned: data['isBanned'],
      )).toList();
      notifyListeners();
      return;
    }

    try {
      // Load users with isApproved = 0 or where approval status is pending
      final response = await SupabaseService.database
          .from(SupabaseConfig.tableUserInfo)
          .select()
          .eq('isApproved', 0);

      _pendingApprovals = (response as List).map((data) {
        return User(
          userId: data['id'],
          displayName: data['username'] ?? '',
          firstName: data['first_name'] ?? '',
          lastName: data['last_name'] ?? '',
          phone: data['phone'],
          email: data['email'] ?? '',
          userType: data['role'] ?? 'student',
          createdAt: DateTime.parse(data['created_at']),
          isBanned: data['is_banned'] ?? false,
        );
      }).toList();

      notifyListeners();

      // Cache the result with 30 minute TTL (approvals change more frequently)
      await _cache.set(cacheKey, _pendingApprovals.map((user) => {
        'userId': user.userId,
        'displayName': user.displayName,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'phone': user.phone,
        'email': user.email,
        'userType': user.userType,
        'createdAt': user.createdAt?.toIso8601String(),
        'isBanned': user.isBanned,
      }).toList(), ttlMinutes: 30);
    } catch (e) {
      print('Error loading pending approvals: $e');
      _pendingApprovals = [];
      notifyListeners();
    }
  }

  Future<bool> approveAccount(String userId) async {
    try {
      // Update user_info table to mark as approved
      await SupabaseService.database
          .from(SupabaseConfig.tableUserInfo)
          .update({'isApproved': 1})
          .eq('id', userId);

      // Remove from pending approvals
      _pendingApprovals.removeWhere((user) => user.userId == userId);
      notifyListeners();

      // Clear cache after approval to ensure consistency
      await _cache.remove('pending_approvals_list');

      // Log audit action
      await _auditService.logAction(
        actionType: 'APPROVE',
        entityType: 'user',
        entityId: userId,
        newValues: {'isApproved': 1},
        description: 'Approved account: $userId',
      );

      return true;
    } catch (e) {
      print('Error approving account: $e');
      return false;
    }
  }

  Future<bool> approveAsProfessor(String userId) async {
    try {
      // Update user_info table to mark as approved and set role to professor
      await SupabaseService.database
          .from(SupabaseConfig.tableUserInfo)
          .update({
            'isApproved': 1,
            'role': 'professor',
          })
          .eq('id', userId);

      // Remove from pending approvals
      _pendingApprovals.removeWhere((user) => user.userId == userId);
      notifyListeners();

      // Clear cache after approval to ensure consistency
      await _cache.remove('pending_approvals_list');

      // Log audit action
      await _auditService.logAction(
        actionType: 'APPROVE',
        entityType: 'user',
        entityId: userId,
        newValues: {'isApproved': 1, 'role': 'professor'},
        description: 'Approved account as professor: $userId',
      );

      return true;
    } catch (e) {
      print('Error approving account as professor: $e');
      return false;
    }
  }

  Future<bool> rejectAccount(String userId, String? reason) async {
    try {
      // Update user_info table to mark as rejected
      await SupabaseService.database
          .from(SupabaseConfig.tableUserInfo)
          .update({
            'isApproved': 2,
            'rejection_reason': reason,
          })
          .eq('id', userId);

      // Remove from pending approvals
      _pendingApprovals.removeWhere((user) => user.userId == userId);
      notifyListeners();

      // Clear cache after rejection to ensure consistency
      await _cache.remove('pending_approvals_list');

      // Log audit action
      await _auditService.logAction(
        actionType: 'REJECT',
        entityType: 'user',
        entityId: userId,
        newValues: {
          'is_approved': false,
          'is_rejected': true,
          'rejection_reason': reason,
        },
        description: 'Rejected account: $userId',
      );

      return true;
    } catch (e) {
      print('Error rejecting account: $e');
      return false;
    }
  }

  Future<bool> updateUser(User updatedUser) async {
    _errorMessage = null;
    notifyListeners();

    try {
      // Capture old values before update
      final oldUser = updatedUser.userType == 'student'
          ? _students.firstWhere((u) => u.userId == updatedUser.userId)
          : _professors.firstWhere((u) => u.userId == updatedUser.userId);

      // Update user_info table
      await SupabaseService.database
          .from(SupabaseConfig.tableUserInfo)
          .update({
        'email': updatedUser.email,
        'first_name': updatedUser.firstName,
        'last_name': updatedUser.lastName,
        'phone': updatedUser.phone,
      })
          .eq('id', updatedUser.userId);

      // Update local list
      if (updatedUser.userType == 'student') {
        final index = _students.indexWhere((u) => u.userId == updatedUser.userId);
        if (index != -1) {
          _students[index] = updatedUser;
        }
      } else {
        final index = _professors.indexWhere((u) => u.userId == updatedUser.userId);
        if (index != -1) {
          _professors[index] = updatedUser;
        }
      }

      notifyListeners();

      // Clear cache after user update to ensure consistency
      if (updatedUser.userType == 'student') {
        await _cache.remove('students_list');
      } else {
        await _cache.remove('professors_list');
      }

      // Log audit action
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
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('Error updating user: $e');
      notifyListeners();
      return false;
    }
  }


  String? validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'First name is required';
    }
    return null;
  }

  String? validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Last name is required';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    // Stricter regex to match Supabase email validation requirements
    // Requires at least 3 characters before @ and valid domain
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]{3,}@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email (min 3 characters before @)';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validatePasswordMatch(String? password, String? confirmPassword) {
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}
