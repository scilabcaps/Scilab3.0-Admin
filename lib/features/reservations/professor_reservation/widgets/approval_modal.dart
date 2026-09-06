import 'package:flutter/material.dart';
import '../models/professor_reservation_model.dart';
import '../controllers/professor_reservation_controller.dart';

class ApprovalModal extends StatefulWidget {
  final ProfessorReservation reservation;
  final ProfessorReservationController controller;
  final VoidCallback onClose;

  const ApprovalModal({
    super.key,
    required this.reservation,
    required this.controller,
    required this.onClose,
  });

  @override
  State<ApprovalModal> createState() => _ApprovalModalState();
}

class _ApprovalModalState extends State<ApprovalModal> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
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
      padding: const EdgeInsets.all(20),
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
            'Professor Reservation Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
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
          _buildInfoRow('Professor Name:', widget.reservation.professorName),
          const SizedBox(height: 8),
          _buildInfoRow('Date:', widget.reservation.date),
          const SizedBox(height: 8),
          _buildInfoRow('Time:', widget.reservation.time),
          const SizedBox(height: 8),
          _buildInfoRow('Resources:', widget.reservation.resources),
          const SizedBox(height: 8),
          _buildInfoRow('Additional Note:', widget.reservation.additionalNote),
          const SizedBox(height: 8),
          _buildInfoRow('Professor Approval:', widget.reservation.professorApproval),
          const SizedBox(height: 8),
          _buildInfoRow('Admin Approval:', widget.reservation.adminApproval),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
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

  Widget _buildFooter() {
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: widget.onClose,
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              await widget.controller.rejectReservation(widget.reservation.reservationId);
              widget.onClose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Reject'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              await widget.controller.approveReservation(widget.reservation.reservationId);
              widget.onClose();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF31CB00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
}
