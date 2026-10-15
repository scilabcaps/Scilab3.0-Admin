import 'package:flutter/material.dart';

class ReservationDetailItem {
  final String name;
  final String category;
  final String detail;

  const ReservationDetailItem({
    required this.name,
    required this.category,
    required this.detail,
  });
}

List<ReservationDetailItem> reservationDetailItemsFromText(String raw) {
  return raw
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) {
        final match = RegExp(r'^(.*?)(?:\s*\(([^)]+)\))?$').firstMatch(line);
        return ReservationDetailItem(
          name: match?.group(1)?.trim() ?? line,
          category: match?.group(2)?.trim() ?? 'Resource',
          detail: 'Requested',
        );
      })
      .toList();
}

class ReservationDetailsDialog extends StatelessWidget {
  final String reservationId;
  final String date;
  final String time;
  final String status;
  final String? createdAt;
  final List<ReservationDetailItem> resources;
  final List<Widget> footerActions;

  const ReservationDetailsDialog({
    super.key,
    required this.reservationId,
    required this.date,
    required this.time,
    required this.status,
    required this.resources,
    this.createdAt,
    this.footerActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummary(),
                    const SizedBox(height: 24),
                    _buildResources(),
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF247A2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Reservation Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close reservation details',
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final fields = <MapEntry<String, String>>[
      MapEntry('Reservation ID', reservationId),
      MapEntry('Date', date),
      MapEntry('Time', time),
      MapEntry('Status', status),
      if (createdAt != null && createdAt!.trim().isNotEmpty)
        MapEntry('Created At', createdAt!),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 2 : 1;
        final width = columns == 2
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: fields
              .map(
                (field) => SizedBox(width: width, child: _buildInfoCard(field)),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildInfoCard(MapEntry<String, String> field) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7EF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.key,
            style: const TextStyle(
              color: Color(0xFF245A2A),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            field.value.isEmpty ? '—' : field.value,
            style: const TextStyle(color: Color(0xFF26352A), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResources() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resources',
          style: TextStyle(
            color: Color(0xFF245A2A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFF247A2A), height: 1),
        const SizedBox(height: 12),
        if (resources.isEmpty)
          Text(
            'No resources recorded',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 560 ? 2 : 1;
              final width = columns == 2
                  ? (constraints.maxWidth - 14) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 14,
                runSpacing: 12,
                children: resources
                    .map(
                      (item) => SizedBox(
                        width: width,
                        child: _buildResourceCard(item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildResourceCard(ReservationDetailItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7EF),
        borderRadius: BorderRadius.circular(9),
        border: const Border(
          left: BorderSide(color: Color(0xFF31CB00), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(
              color: Color(0xFF26352A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.category,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            item.detail,
            style: const TextStyle(color: Color(0xFF405348), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      alignment: Alignment.centerRight,
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAF7),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ...footerActions,
          if (footerActions.isNotEmpty) const SizedBox(width: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
