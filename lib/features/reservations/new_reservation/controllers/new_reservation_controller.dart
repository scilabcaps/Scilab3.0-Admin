import 'package:flutter/foundation.dart';

import '../models/new_reservation_models.dart';
import '../services/new_reservation_service.dart';

class NewReservationController extends ChangeNotifier {
  NewReservationController({NewReservationGateway? gateway})
    : _gateway = gateway ?? NewReservationService();

  static const int openingMinutes = 7 * 60;
  static const int closingMinutes = 20 * 60;
  static const int slotMinutes = 30;

  final NewReservationGateway _gateway;
  final Map<String, ReservationCartItem> _cart = {};

  List<ReservationResource> _resources = [];
  List<ReservationTimeRange> _roomSchedule = [];
  ReservationResourceType _selectedType = ReservationResourceType.room;
  DateTime _selectedDate = DateTime.now();
  int? _startMinutes;
  int? _endMinutes;
  bool _isLoading = false;
  bool _isLoadingSchedule = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<ReservationResource> get resources => List.unmodifiable(_resources);
  List<ReservationCartItem> get cart => List.unmodifiable(_cart.values);
  List<ReservationTimeRange> get roomSchedule =>
      List.unmodifiable(_roomSchedule);
  ReservationResourceType get selectedType => _selectedType;
  DateTime get selectedDate => _selectedDate;
  int? get startMinutes => _startMinutes;
  int? get endMinutes => _endMinutes;
  bool get isLoading => _isLoading;
  bool get isLoadingSchedule => _isLoadingSchedule;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  List<ReservationResource> get visibleResources =>
      _resources.where((resource) => resource.type == _selectedType).toList();

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

  Future<void> loadResources() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _resources = await _gateway.loadResources();
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectType(ReservationResourceType type) {
    _selectedType = type;
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

  Future<void> selectDate(DateTime value) async {
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

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final id = await _gateway.createReservation(
        NewReservationRequest(
          date: _selectedDate,
          startMinutes: _startMinutes!,
          endMinutes: _endMinutes!,
          items: cart,
          additionalNote: additionalNote.trim().isEmpty
              ? null
              : additionalNote.trim(),
        ),
      );
      _cart.clear();
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

  void _clearTime() {
    _startMinutes = null;
    _endMinutes = null;
  }

  String _friendlyError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '');
  }
}
