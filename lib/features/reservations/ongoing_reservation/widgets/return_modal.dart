import 'package:flutter/material.dart';
import '../models/ongoing_reservation_model.dart';
import '../controllers/ongoing_reservation_controller.dart';

class ReturnModal extends StatefulWidget {
  final OngoingReservation reservation;
  final OngoingReservationController controller;

  const ReturnModal({
    super.key,
    required this.reservation,
    required this.controller,
  });

  @override
  State<ReturnModal> createState() => _ReturnModalState();
}

class _ReturnModalState extends State<ReturnModal> {
  final Map<String, TextEditingController> _quantityControllers = {};
  bool _isProcessing = false;

  void _closeDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  void initState() {
    super.initState();
    if (widget.reservation.items?.isNotEmpty ?? false) {
      for (var item in widget.reservation.items!) {
        _quantityControllers[item.itemId] = TextEditingController(
          text: item.returnedQuantity.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleReturnItem(String itemId) async {
    if (_isProcessing) return;
    final dialogNavigator = Navigator.of(context, rootNavigator: true);
    final controller = _quantityControllers[itemId];
    if (controller != null) {
      final returnedQuantity = int.tryParse(controller.text) ?? 0;
      final item = widget.reservation.items?.firstWhere(
        (i) => i.itemId == itemId,
      );

      if (item != null) {
        if (returnedQuantity <= item.returnedQuantity ||
            returnedQuantity > item.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Enter a quantity between ${item.returnedQuantity + 1} and ${item.quantity}.',
              ),
            ),
          );
          return;
        }
        setState(() => _isProcessing = true);
        final reservationId = widget.reservation.reservationId;
        final reservationController = widget.controller;

        if (returnedQuantity >= item.quantity) {
          final returnOperation = reservationController.returnItem(
            reservationId,
            itemId,
          );
          dialogNavigator.pop();
          await returnOperation;
          await reservationController.loadReservations();
        } else {
          final returnQuantity = returnedQuantity - item.returnedQuantity;
          final returnOperation = reservationController.returnPartialItem(
            reservationId,
            itemId,
            returnQuantity,
          );
          dialogNavigator.pop();
          await returnOperation;
          await reservationController.loadReservations();
        }
      }
    }
  }

  void _handleReturnAll() async {
    if (_isProcessing) return;
    final dialogNavigator = Navigator.of(context, rootNavigator: true);
    setState(() => _isProcessing = true);
    if (widget.reservation.items?.isNotEmpty ?? false) {
      final items = List<ReservedItem>.from(widget.reservation.items!);
      final reservationId = widget.reservation.reservationId;
      final reservationController = widget.controller;
      dialogNavigator.pop();

      for (var item in items) {
        if (item.status.toLowerCase() != 'used' &&
            item.returnedQuantity < item.quantity &&
            item.assetId.isNotEmpty) {
          await reservationController.returnItem(
            reservationId,
            item.itemId,
          );
        }
      }
      await reservationController.loadReservations();
    } else if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReservationInfo(),
                      const SizedBox(height: 20),
                      if (widget.reservation.items?.isNotEmpty ?? false)
                        _buildItemsList()
                      else
                        const Text('No items in this reservation'),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF31CB00),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Reservation details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _closeDialog,
            tooltip: 'Close dialog',
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Name:', widget.reservation.name),
          const SizedBox(height: 8),
          _buildInfoRow('User Type:', widget.reservation.userType),
          const SizedBox(height: 8),
          _buildInfoRow('Program & Year:', widget.reservation.programYear),
          if (widget.reservation.professor != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Professor:', widget.reservation.professor!),
          ],
          const SizedBox(height: 8),
          _buildInfoRow('Date:', widget.reservation.date),
          const SizedBox(height: 8),
          _buildInfoRow('Time:', widget.reservation.time),
          const SizedBox(height: 8),
          _buildInfoRow('Status:', widget.reservation.status),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reserved Items',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.reservation.items!.map((item) => _buildItemCard(item)),
      ],
    );
  }

  Widget _buildItemCard(ReservedItem item) {
    final controller = _quantityControllers[item.itemId];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.itemName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              _buildItemStatusBadge(item.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Quantity: ${item.quantity} | Returned: ${item.returnedQuantity}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          if (item.status.toLowerCase() != 'used')
            Row(
              children: [
                const Text('Return total'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    enabled: !_isProcessing,
                    onChanged: (_) => setState(() {}),
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => _handleReturnItem(item.itemId),
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isProcessing ? null : () => _handleReturnItem(item.itemId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF31CB00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text('Confirm return'),
                ),
              ],
            )
          else
            const Text(
              'Chemical consumed — no return required',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.controller.getItemStatusColor(status),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: widget.controller.getItemStatusTextColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final hasReturnableItems = widget.reservation.items?.any((item) => 
      item.status.toLowerCase() != 'used' && 
      item.returnedQuantity < item.quantity &&
      item.assetId.isNotEmpty
    ) ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (hasReturnableItems)
            ElevatedButton(
              onPressed: _isProcessing ? null : _handleReturnAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF31CB00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Return all'),
            ),
          const Spacer(),
          TextButton(
            onPressed: _closeDialog,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
