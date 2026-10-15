import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/new_reservation_models.dart';
import '../services/inventory_hold_service.dart';
import '../services/new_reservation_service.dart';

class NewReservationController extends ChangeNotifier {
  NewReservationController({NewReservationGateway? gateway})
    : _gateway = gateway ?? NewReservationService(),
      _holdService = gateway == null ? InventoryHoldService() : null,
      _cartId =
          '${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(gateway ?? Object())}';

  static const int openingMinutes = 7 * 60;
  static const int closingMinutes = 20 * 60;
  static const int slotMinutes = 30;
  static const int resourcesPerPage = 9;

  final NewReservationGateway _gateway;
  final InventoryHoldService? _holdService;
  final String _cartId;
  final Map<String, ReservationCartItem> _cart = {};
  Future<void> _holdQueue = Future<void>.value();

  List<ReservationAccount> _accounts = [];
  List<ReservationResource> _resources = [];
  List<ReservationTimeRange> _roomSchedule = [];
  ReservationResourceType _selectedType = ReservationResourceType.room;
  int _resourcePage = 1;
  DateTime _selectedDate = _nextWeekday(DateTime.now());
  int? _startMinutes;
  int? _endMinutes;
  bool _isLoading = false;
  bool _isLoadingAccounts = false;
  bool _isLoadingSchedule = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  ReservationAccount? _selectedAccount;

  List<ReservationAccount> get accounts => List.unmodifiable(_accounts);
  List<ReservationResource> get resources => List.unmodifiable(_resources);
  List<ReservationCartItem> get cart => List.unmodifiable(_cart.values);
  List<ReservationTimeRange> get roomSchedule =>
      List.unmodifiable(_roomSchedule);
  ReservationResourceType get selectedType => _selectedType;
  int get resourcePage => _resourcePage;
  DateTime get selectedDate => _selectedDate;
  int? get startMinutes => _startMinutes;
  int? get endMinutes => _endMinutes;
  bool get isLoading => _isLoading;
  bool get isLoadingAccounts => _isLoadingAccounts;
  bool get isLoadingSchedule => _isLoadingSchedule;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  ReservationAccount? get selectedAccount => _selectedAccount;

  static DateTime _nextWeekday(DateTime value) {
    var date = DateTime(value.year, value.month, value.day);
    while (date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  List<ReservationResource> get visibleResources =>
      _resources.where((resource) => resource.type == _selectedType).toList();

  int get resourcePageCount {
    final count = visibleResources.length;
    return count == 0 ? 0 : (count + resourcesPerPage - 1) ~/ resourcesPerPage;
  }

  List<ReservationResource> get paginatedResources {
    final resources = visibleResources;
    if (resources.isEmpty) return const [];
    final start = (_resourcePage - 1) * resourcesPerPage;
    final end = (start + resourcesPerPage).clamp(0, resources.length);
    return resources.sublist(start, end);
  }

  ReservationCartItem? get selectedRoom {
    for (final item in _cart.values) {
      if (item.resource.type == ReservationResourceType.room) return item;
    }
    return null;
  }

  bool get hasValidTime =>
      _startMinutes != null &&
      _endMinutes != null &&
      _endMinutes! > _startMinutes!;

  bool get canSubmit => _cart.isNotEmpty && hasValidTime && !_isSubmitting;

  bool get _holdsEnabled => _holdService != null;

  Future<void> loadReservationAccounts() async {
    _isLoadingAccounts = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _accounts = await _gateway.loadReservationAccounts();
    } catch (error) {
      _accounts = [];
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoadingAccounts = false;
      notifyListeners();
    }
  }

  void selectAccount(ReservationAccount account) {
    if (!account.canReserve) return;
    _selectedAccount = account;
    notifyListeners();
  }

  Future<void> loadResources() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _resources = await _gateway.loadResources();
      _clampResourcePage();
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectType(ReservationResourceType type) {
    _selectedType = type;
    _resourcePage = 1;
    notifyListeners();
  }

  void previousResourcePage() {
    if (_resourcePage <= 1) return;
    _resourcePage--;
    notifyListeners();
  }

  void nextResourcePage() {
    if (_resourcePage >= resourcePageCount) return;
    _resourcePage++;
    notifyListeners();
  }

  bool addResource(ReservationResource resource) {
    if (!resource.isAvailable) return false;

    if (resource.type == ReservationResourceType.room) {
      final roomKeys = _cart.entries
          .where(
            (entry) =>
                entry.value.resource.type == ReservationResourceType.room,
          )
          .map((entry) => entry.key)
          .toList();
      for (final key in roomKeys) {
        _cart.remove(key);
      }
      _cart[resource.key] = ReservationCartItem(
        resource: resource,
        quantity: 1,
      );
      _clearTime();
      _loadSchedule();
    } else {
      final current = _cart[resource.key];
      final increment = resource.type == ReservationResourceType.chemical
          ? 1.0
          : 1;
      final nextQuantity = (current?.quantity ?? 0) + increment;
      if (nextQuantity > resource.availableQuantity) return false;
      _cart[resource.key] = ReservationCartItem(
        resource: resource,
        quantity: nextQuantity,
      );
    }
    notifyListeners();
    return true;
  }

  Future<bool> addResourceAndHold(ReservationResource resource) {
    if (!_holdsEnabled || resource.type == ReservationResourceType.room) {
      return Future.value(addResource(resource));
    }
    return _queueHold(() async {
      final currentResource = _resourceByKey(resource.key) ?? resource;
      if (!currentResource.isAvailable) return false;
      final current = _cart[currentResource.key];
      final increment = currentResource.type == ReservationResourceType.chemical
          ? 1.0
          : 1;
      final nextQuantity = (current?.quantity ?? 0) + increment;
      if (nextQuantity > currentResource.availableQuantity) return false;
      await _holdService!.setHold(
        cartId: _cartId,
        resource: currentResource,
        quantity: nextQuantity,
      );
      _cart[currentResource.key] = ReservationCartItem(
        resource: currentResource,
        quantity: nextQuantity,
      );
      _adjustRemaining(currentResource.key, -increment);
      notifyListeners();
      return true;
    });
  }

  void removeResource(String key) {
    final removed = _cart.remove(key);
    if (removed?.resource.type == ReservationResourceType.room) {
      _roomSchedule = [];
      _clearTime();
    }
    notifyListeners();
  }

  bool changeQuantity(String key, num delta) {
    final item = _cart[key];
    if (item == null || item.resource.type == ReservationResourceType.room) {
      return false;
    }
    final next = item.quantity + delta;
    if (next <= 0) {
      removeResource(key);
      return true;
    }
    if (next > item.resource.availableQuantity) return false;
    _cart[key] = item.copyWith(quantity: next);
    notifyListeners();
    return true;
  }

  Future<bool> changeQuantityAndHold(String key, num delta) {
    if (!_holdsEnabled) return Future.value(changeQuantity(key, delta));
    return _queueHold(() async {
      final item = _cart[key];
      if (item == null || item.resource.type == ReservationResourceType.room) {
        return false;
      }
      final next = item.quantity + delta;
      if (next <= 0) {
        await _holdService!.releaseResource(
          cartId: _cartId,
          resource: item.resource,
        );
        _cart.remove(key);
        _adjustRemaining(key, item.quantity);
        notifyListeners();
        return true;
      }
      if (delta > 0) {
        final available = _resourceByKey(key)?.availableQuantity ?? 0;
        if (delta > available) return false;
      }
      await _holdService!.setHold(
        cartId: _cartId,
        resource: item.resource,
        quantity: next,
      );
      _cart[key] = item.copyWith(quantity: next);
      _adjustRemaining(key, -delta);
      notifyListeners();
      return true;
    });
  }

  Future<void> removeResourceAndRelease(String key) {
    if (!_holdsEnabled) {
      removeResource(key);
      return Future<void>.value();
    }
    return _queueHold(() async {
      final item = _cart[key];
      if (item == null) return;
      if (item.resource.type != ReservationResourceType.room) {
        await _holdService!.releaseResource(
          cartId: _cartId,
          resource: item.resource,
        );
        _adjustRemaining(key, item.quantity);
      }
      removeResource(key);
    });
  }

  Future<void> selectDate(DateTime value) async {
    if (value.weekday == DateTime.saturday ||
        value.weekday == DateTime.sunday) {
      return;
    }
    _selectedDate = DateTime(value.year, value.month, value.day);
    _clearTime();
    notifyListeners();
    await _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final room = selectedRoom;
    if (room == null) return;
    _isLoadingSchedule = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _roomSchedule = await _gateway.loadRoomSchedule(
        room.resource.id,
        _selectedDate,
      );
    } catch (error) {
      _roomSchedule = [];
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoadingSchedule = false;
      notifyListeners();
    }
  }

  bool isPastInterval(int minutes) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_selectedDate.isBefore(today)) return true;
    if (!_selectedDate.isAtSameMomentAs(today)) return false;
    return minutes < now.hour * 60 + now.minute;
  }

  bool isBookedInterval(int minutes) {
    return _roomSchedule.any(
      (range) =>
          minutes < range.endMinutes &&
          minutes + slotMinutes > range.startMinutes,
    );
  }

  bool isSelectedInterval(int minutes) {
    if (_startMinutes == null) return false;
    final end = _endMinutes ?? (_startMinutes! + slotMinutes);
    return minutes >= _startMinutes! && minutes < end;
  }

  String? selectTimeBoundary(int minutes) {
    if (minutes < openingMinutes || minutes > closingMinutes) {
      return 'Select a time within operating hours.';
    }

    if (_startMinutes == null || _endMinutes != null) {
      if (minutes == closingMinutes) {
        return 'The reservation must start before 8:00 PM.';
      }
      if (isPastInterval(minutes)) {
        return 'Reservations cannot start in the past.';
      }
      if (isBookedInterval(minutes)) return 'That time is already reserved.';
      _startMinutes = minutes;
      _endMinutes = null;
      notifyListeners();
      return null;
    }

    if (minutes <= _startMinutes!) {
      return 'The end time must be after the start time.';
    }
    for (int slot = _startMinutes!; slot < minutes; slot += slotMinutes) {
      if (isPastInterval(slot) || isBookedInterval(slot)) {
        return 'The selected range contains an unavailable time.';
      }
    }
    _endMinutes = minutes;
    notifyListeners();
    return null;
  }

  void clearTimeSelection() {
    _clearTime();
    notifyListeners();
  }

  String? validate() {
    if (_selectedDate.weekday == DateTime.saturday ||
        _selectedDate.weekday == DateTime.sunday) {
      return 'Reservations are only available Monday through Friday.';
    }
    if (_cart.isEmpty) {
      return 'Add at least one room, chemical, equipment item, or glassware item.';
    }
    if (!hasValidTime) return 'Select a valid start and end time.';
    return null;
  }

  Future<int?> submit(String additionalNote) async {
    final validation = validate();
    if (validation != null) {
      _errorMessage = validation;
      notifyListeners();
      return null;
    }
    final account = _selectedAccount;
    if (account == null) {
      _errorMessage = 'Select an account for this reservation.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _holdQueue;
      final id = await _gateway.createReservation(
        NewReservationRequest(
          account: account,
          date: _selectedDate,
          startMinutes: _startMinutes!,
          endMinutes: _endMinutes!,
          items: cart,
          additionalNote: additionalNote.trim().isEmpty
              ? null
              : additionalNote.trim(),
          inventoryHoldCartId: _holdsEnabled ? _cartId : null,
        ),
      );
      _cart.clear();
      _selectedAccount = null;
      _roomSchedule = [];
      _clearTime();
      await loadResources();
      return id;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_holdsEnabled) {
      unawaited(_holdQueue.then((_) => _holdService!.releaseAll(_cartId)));
    }
    super.dispose();
  }

  Future<T> _queueHold<T>(Future<T> Function() operation) {
    final next = _holdQueue.then((_) => operation());
    _holdQueue = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        _errorMessage = _friendlyError(error);
        notifyListeners();
      },
    );
    return next;
  }

  ReservationResource? _resourceByKey(String key) {
    for (final resource in _resources) {
      if (resource.key == key) return resource;
    }
    return null;
  }

  void _adjustRemaining(String key, num delta) {
    final resourceIndex = _resources.indexWhere((item) => item.key == key);
    if (resourceIndex < 0) return;
    final resource = _resources[resourceIndex];
    final remaining = resource.availableQuantity + delta;
    final updatedResource = resource.copyWith(
      availableQuantity: remaining < 0 ? 0 : remaining,
    );
    _resources[resourceIndex] = updatedResource;
    final cartItem = _cart[key];
    if (cartItem != null) {
      _cart[key] = ReservationCartItem(
        resource: updatedResource,
        quantity: cartItem.quantity,
      );
    }
  }

  void _clearTime() {
    _startMinutes = null;
    _endMinutes = null;
  }

  void _clampResourcePage() {
    final pages = resourcePageCount;
    if (pages == 0) {
      _resourcePage = 1;
    } else if (_resourcePage > pages) {
      _resourcePage = pages;
    }
  }

  String _friendlyError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '');
  }
}
