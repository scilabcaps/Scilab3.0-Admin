import 'package:flutter/material.dart';

import '../controllers/new_reservation_controller.dart';
import '../models/new_reservation_models.dart';

class NewReservationPage extends StatefulWidget {
  const NewReservationPage({super.key});

  @override
  State<NewReservationPage> createState() => _NewReservationPageState();
}

class _NewReservationPageState extends State<NewReservationPage> {
  static const Color _primary = Color(0xFF2E7D32);

  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _timeSlotsScrollController = ScrollController();
  final _controller = NewReservationController();

  @override
  void initState() {
    super.initState();
    _controller.loadResources();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _timeSlotsScrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create New Reservation',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Admin reservations are approved immediately. Choose resources, then reserve an available schedule.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (_controller.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(
                        message: _controller.errorMessage!,
                        onDismiss: _controller.clearError,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildResourcesSection(),
                    const SizedBox(height: 24),
                    _buildCartSection(),
                    const SizedBox(height: 24),
                    _buildDetailsSection(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResourcesSection() {
    return _SectionCard(
      title: 'Available Resources',
      subtitle:
          'Optionally select one laboratory room, then add any chemicals, equipment, or glassware you need.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReservationResourceType.values.map((type) {
              return ChoiceChip(
                label: Text(type.label),
                selected: _controller.selectedType == type,
                onSelected: (_) => _controller.selectType(type),
                selectedColor: _primary.withValues(alpha: 0.14),
                side: BorderSide(
                  color: _controller.selectedType == type
                      ? _primary
                      : Colors.grey.shade300,
                ),
                labelStyle: TextStyle(
                  color: _controller.selectedType == type
                      ? _primary
                      : Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (_controller.isLoading)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(color: _primary)),
            )
          else if (_controller.visibleResources.isEmpty)
            const _EmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'No resources are available in this category.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 980
                    ? 3
                    : constraints.maxWidth >= 620
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _controller.visibleResources
                      .map(
                        (resource) => SizedBox(
                          width: width,
                          child: _ResourceCard(
                            resource: resource,
                            inCart: _controller.cart.any(
                              (item) => item.resource.key == resource.key,
                            ),
                            onAdd: () => _addResource(resource),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCartSection() {
    return _SectionCard(
      title: 'Reservation Cart',
      subtitle:
          '${_controller.cart.length} selected resource${_controller.cart.length == 1 ? '' : 's'}',
      child: _controller.cart.isEmpty
          ? const _EmptyState(
              icon: Icons.shopping_cart_outlined,
              message: 'Your cart is empty. Add resources to get started.',
            )
          : Column(
              children: _controller.cart.map((item) {
                final isRoom =
                    item.resource.type == ReservationResourceType.room;
                final step =
                    item.resource.type == ReservationResourceType.chemical
                    ? 1.0
                    : 1;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _iconFor(item.resource.type),
                          color: _primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.resource.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.resource.type.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isRoom) ...[
                        IconButton(
                          tooltip: 'Decrease ${item.resource.name} quantity',
                          onPressed: () => _controller.changeQuantity(
                            item.resource.key,
                            -step,
                          ),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Semantics(
                          label:
                              '${item.resource.name} quantity ${_formatQuantity(item.quantity)}',
                          child: SizedBox(
                            width: 52,
                            child: Text(
                              _formatQuantity(item.quantity),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Increase ${item.resource.name} quantity',
                          onPressed:
                              item.quantity < item.resource.availableQuantity
                              ? () => _controller.changeQuantity(
                                  item.resource.key,
                                  step,
                                )
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                      IconButton(
                        tooltip: 'Remove ${item.resource.name}',
                        onPressed: () =>
                            _controller.removeResource(item.resource.key),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildDetailsSection() {
    return _SectionCard(
      title: 'Reservation Details',
      subtitle:
          'Operating hours are 7:00 AM to 8:00 PM in 30-minute intervals.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final calendar = _buildCalendar();
          final schedule = _buildSchedule();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: calendar),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: schedule),
                  ],
                )
              else ...[
                calendar,
                const SizedBox(height: 24),
                schedule,
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Additional note (optional)',
                  hintText:
                      'Add preparation instructions or other reservation details.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _controller.canSubmit ? _confirmReservation : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    minimumSize: const Size(210, 52),
                  ),
                  icon: _controller.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _controller.isSubmitting
                        ? 'Creating reservation…'
                        : 'Review Reservation',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select date',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: CalendarDatePicker(
            initialDate: _controller.selectedDate.isBefore(today)
                ? today
                : _controller.selectedDate,
            firstDate: today,
            lastDate: DateTime(today.year + 2, today.month, today.day),
            onDateChanged: _controller.selectDate,
          ),
        ),
      ],
    );
  }

  Widget _buildSchedule() {
    final room = _controller.selectedRoom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Select time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            if (_controller.startMinutes != null)
              TextButton.icon(
                onPressed: _controller.clearTimeSelection,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Clear'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_controller.isLoadingSchedule)
          const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator(color: _primary)),
          )
        else ...[
          if (room == null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1565C0)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No room selected. Choose a time for the equipment, chemicals, or glassware in your cart.',
                      style: TextStyle(color: Color(0xFF0D47A1)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _timeInstruction(),
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: Scrollbar(
              controller: _timeSlotsScrollController,
              thumbVisibility: true,
              child: GridView.builder(
                controller: _timeSlotsScrollController,
                padding: const EdgeInsets.only(right: 12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 150,
                  mainAxisExtent: 48,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount:
                    ((NewReservationController.closingMinutes -
                            NewReservationController.openingMinutes) ~/
                        NewReservationController.slotMinutes) +
                    1,
                itemBuilder: (context, index) {
                  final minutes =
                      NewReservationController.openingMinutes +
                      index * NewReservationController.slotMinutes;
                  return _buildTimeBoundary(minutes);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: const [
              _Legend(color: Color(0xFFE8F5E9), label: 'Available'),
              _Legend(color: Color(0xFFFFEBEE), label: 'Reserved'),
              _Legend(color: Color(0xFFE0E0E0), label: 'Past'),
              _Legend(color: Color(0xFF2E7D32), label: 'Selected'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTimeBoundary(int minutes) {
    final isClosing = minutes == NewReservationController.closingMinutes;
    final booked = !isClosing && _controller.isBookedInterval(minutes);
    final past = !isClosing && _controller.isPastInterval(minutes);
    final selected = !isClosing && _controller.isSelectedInterval(minutes);
    final isStart = _controller.startMinutes == minutes;
    final isEnd = _controller.endMinutes == minutes;
    final disabled = _controller.startMinutes == null
        ? booked || past || isClosing
        : _controller.endMinutes == null
        ? minutes <= _controller.startMinutes!
        : booked || past || isClosing;

    Color background = const Color(0xFFE8F5E9);
    Color foreground = _primary;
    if (booked) {
      background = const Color(0xFFFFEBEE);
      foreground = const Color(0xFFB71C1C);
    } else if (past || disabled) {
      background = const Color(0xFFE0E0E0);
      foreground = Colors.grey.shade700;
    }
    if (selected || isStart || isEnd) {
      background = _primary;
      foreground = Colors.white;
    }

    return Semantics(
      button: true,
      selected: selected || isStart || isEnd,
      label:
          '${minutesToDisplayTime(minutes)}, ${booked
              ? 'reserved'
              : past
              ? 'past'
              : 'available'}',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap:
              disabled &&
                  !(isClosing &&
                      _controller.startMinutes != null &&
                      _controller.endMinutes == null)
              ? null
              : () {
                  final message = _controller.selectTimeBoundary(minutes);
                  if (message != null) _showMessage(message, isError: true);
                },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minWidth: 92, minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              minutesToDisplayTime(minutes),
              style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  void _addResource(ReservationResource resource) {
    final added = _controller.addResource(resource);
    if (!added) {
      _showMessage(
        '${resource.name} has reached its available quantity.',
        isError: true,
      );
    } else if (resource.type == ReservationResourceType.room) {
      _showMessage(
        '${resource.name} selected. Any previously selected room was replaced.',
      );
    }
  }

  Future<void> _confirmReservation() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final validation = _controller.validate();
    if (validation != null) {
      _showMessage(validation, isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm reservation'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SummaryRow(
                  label: 'Date',
                  value: _formatDate(_controller.selectedDate),
                ),
                _SummaryRow(
                  label: 'Time',
                  value:
                      '${minutesToDisplayTime(_controller.startMinutes!)} – ${minutesToDisplayTime(_controller.endMinutes!)}',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Resources',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ..._controller.cart.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${item.resource.name} × ${_formatQuantity(item.quantity)}',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_outlined, color: _primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This admin-created reservation will be approved immediately.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _primary),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create Reservation'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final id = await _controller.submit(_noteController.text);
    if (!mounted) return;
    if (id != null) {
      _noteController.clear();
      _showMessage('Reservation #$id was created and approved.');
    } else if (_controller.errorMessage != null) {
      _showMessage(_controller.errorMessage!, isError: true);
    }
  }

  String _timeInstruction() {
    if (_controller.startMinutes == null) return 'Select a start time.';
    if (_controller.endMinutes == null) {
      return 'Start: ${minutesToDisplayTime(_controller.startMinutes!)}. Now select an end time.';
    }
    return '${minutesToDisplayTime(_controller.startMinutes!)} – ${minutesToDisplayTime(_controller.endMinutes!)} selected.';
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : _primary,
        ),
      );
  }

  IconData _iconFor(ReservationResourceType type) {
    switch (type) {
      case ReservationResourceType.room:
        return Icons.meeting_room_outlined;
      case ReservationResourceType.chemical:
        return Icons.science_outlined;
      case ReservationResourceType.equipment:
        return Icons.precision_manufacturing_outlined;
      case ReservationResourceType.glassware:
        return Icons.local_drink_outlined;
    }
  }

  String _formatQuantity(num value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();

  String _formatDate(DateTime value) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.resource,
    required this.inCart,
    required this.onAdd,
  });

  final ReservationResource resource;
  final bool inCart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2E7D32);
    final unavailable = !resource.isAvailable;
    final availability = resource.type == ReservationResourceType.room
        ? resource.status ?? 'Unavailable'
        : '${resource.availableQuantity} ${resource.unit ?? ''} available'
              .trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: inCart ? primary : Colors.grey.shade300,
          width: inCart ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  resource.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (inCart)
                const Icon(Icons.check_circle, size: 20, color: primary),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            resource.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          Text(
            availability,
            style: TextStyle(
              color: unavailable ? Colors.red.shade700 : primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: unavailable ? null : onAdd,
              icon: Icon(inCart ? Icons.add : Icons.add_circle_outline),
              label: Text(
                unavailable
                    ? 'Unavailable'
                    : inCart
                    ? 'Add another'
                    : 'Add to cart',
              ),
              style: OutlinedButton.styleFrom(foregroundColor: primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade500),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFB71C1C)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFF7F0000)),
              ),
            ),
            IconButton(
              tooltip: 'Dismiss error',
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
