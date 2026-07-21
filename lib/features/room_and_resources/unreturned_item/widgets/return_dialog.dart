import 'package:flutter/material.dart';
import '../models/unreturned_item_model.dart';

class ReturnDialog extends StatefulWidget {
  final UnreturnedItem item;
  final Function(int) onReturn;

  const ReturnDialog({
    super.key,
    required this.item,
    required this.onReturn,
  });

  @override
  State<ReturnDialog> createState() => _ReturnDialogState();
}

class _ReturnDialogState extends State<ReturnDialog> {
  int _returnQuantity = 0;

  @override
  void initState() {
    super.initState();
    _returnQuantity = widget.item.unreturnedQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Return Item'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemDetails(),
            const SizedBox(height: 20),
            _buildQuantitySelector(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _returnQuantity > 0
              ? () {
                  widget.onReturn(_returnQuantity);
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF31CB00),
            foregroundColor: Colors.white,
          ),
          child: const Text('Return'),
        ),
      ],
    );
  }

  Widget _buildItemDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item: ${widget.item.itemName}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Borrower: ${widget.item.borrowerName}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type: ${widget.item.itemType}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Borrowed: ${widget.item.borrowedQuantity}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Returned: ${widget.item.returnedQuantity}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8D7DA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Unreturned: ${widget.item.unreturnedQuantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF721C24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reservation Date: ${widget.item.reservationDate}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          if (widget.item.dueDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Due Date: ${widget.item.dueDate}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity to Return:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              onPressed: _returnQuantity > 1
                  ? () {
                      setState(() {
                        _returnQuantity--;
                      });
                    }
                  : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_returnQuantity',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _returnQuantity < widget.item.unreturnedQuantity
                  ? () {
                      setState(() {
                        _returnQuantity++;
                      });
                    }
                  : null,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _returnQuantity = widget.item.unreturnedQuantity;
                });
              },
              child: const Text('Return All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Max: ${widget.item.unreturnedQuantity}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
