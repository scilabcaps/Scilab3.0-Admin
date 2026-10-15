enum ReservationResourceType { room, chemical, equipment, glassware }

class ReservationAccount {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? yearSection;
  final String? course;
  final String? assignedProfessorId;
  final String? assignedProfessorName;

  const ReservationAccount({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.yearSection,
    this.course,
    this.assignedProfessorId,
    this.assignedProfessorName,
  });

  bool get isStudent => role.toLowerCase() == 'student';
  bool get canReserve => !isStudent || assignedProfessorName != null;

  String get fullName {
    final name = '$firstName $lastName'.trim();
    if (name.isNotEmpty) return name;
    if (username.isNotEmpty) return username;
    return email;
  }

  String get roleLabel => isStudent ? 'Student' : 'Professor';
}

extension ReservationResourceTypeLabel on ReservationResourceType {
  String get label {
    switch (this) {
      case ReservationResourceType.room:
        return 'Laboratory Rooms';
      case ReservationResourceType.chemical:
        return 'Chemicals';
      case ReservationResourceType.equipment:
        return 'Equipment';
      case ReservationResourceType.glassware:
        return 'Glassware';
    }
  }
}

class ReservationResource {
  final int id;
  final String name;
  final ReservationResourceType type;
  final num availableQuantity;
  final String description;
  final String? unit;
  final String? status;

  const ReservationResource({
    required this.id,
    required this.name,
    required this.type,
    required this.availableQuantity,
    required this.description,
    this.unit,
    this.status,
  });

  ReservationResource copyWith({num? availableQuantity}) {
    return ReservationResource(
      id: id,
      name: name,
      type: type,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      description: description,
      unit: unit,
      status: status,
    );
  }

  bool get isAvailable {
    if (type == ReservationResourceType.room) {
      return status?.toLowerCase() == 'available';
    }
    return availableQuantity > 0;
  }

  String get key => '${type.name}:$id';
}

class ReservationCartItem {
  final ReservationResource resource;
  final num quantity;

  const ReservationCartItem({required this.resource, required this.quantity});

  ReservationCartItem copyWith({num? quantity}) {
    return ReservationCartItem(
      resource: resource,
      quantity: quantity ?? this.quantity,
    );
  }
}

class ReservationTimeRange {
  final int startMinutes;
  final int endMinutes;

  const ReservationTimeRange({
    required this.startMinutes,
    required this.endMinutes,
  });

  bool overlaps(int otherStart, int otherEnd) {
    return startMinutes < otherEnd && endMinutes > otherStart;
  }
}

class NewReservationRequest {
  final ReservationAccount account;
  final DateTime date;
  final int startMinutes;
  final int endMinutes;
  final String? additionalNote;
  final String? inventoryHoldCartId;
  final List<ReservationCartItem> items;

  const NewReservationRequest({
    required this.account,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    required this.items,
    this.additionalNote,
    this.inventoryHoldCartId,
  });

  ReservationCartItem? get room {
    for (final item in items) {
      if (item.resource.type == ReservationResourceType.room) return item;
    }
    return null;
  }
}

String minutesToDatabaseTime(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute:00';
}

String minutesToDisplayTime(int minutes) {
  final hour24 = minutes ~/ 60;
  final minute = (minutes % 60).toString().padLeft(2, '0');
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
  return '$hour12:$minute $period';
}
