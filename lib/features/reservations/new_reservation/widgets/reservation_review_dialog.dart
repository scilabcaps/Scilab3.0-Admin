import 'package:flutter/material.dart';

import '../controllers/new_reservation_controller.dart';
import '../models/new_reservation_models.dart';

class ReservationReviewDialog extends StatefulWidget {
  const ReservationReviewDialog({
    super.key,
    required this.controller,
    required this.dateLabel,
    required this.timeLabel,
    required this.additionalNote,
  });

  final NewReservationController controller;
  final String dateLabel;
  final String timeLabel;
  final String additionalNote;

  @override
  State<ReservationReviewDialog> createState() =>
      _ReservationReviewDialogState();
}

class _ReservationReviewDialogState extends State<ReservationReviewDialog> {
  static const Color _primary = Color(0xFF2E7D32);

  final TextEditingController _searchController = TextEditingController();
  String _roleFilter = 'all';
  int _step = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReservationAccount> get _visibleAccounts {
    final query = _searchController.text.trim().toLowerCase();
    return widget.controller.accounts.where((account) {
      final matchesRole =
          _roleFilter == 'all' || account.role.toLowerCase() == _roleFilter;
      final matchesQuery = query.isEmpty ||
          account.fullName.toLowerCase().contains(query) ||
          account.username.toLowerCase().contains(query) ||
          account.email.toLowerCase().contains(query);
      return matchesRole && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAccount = widget.controller.selectedAccount;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Row(
        children: [
          Expanded(
            child: Text(
              _step == 0 ? 'Select an account' : 'Review reservation',
            ),
          ),
          Text(
            'Step ${_step + 1} of 2',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.pop(context, false),
            tooltip: 'Close dialog',
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        // The account step needs room for searching and scrolling. The review
        // step is compact and should size to its actual summary content.
        height: _step == 0 ? 520 : 330,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _step == 0
              ? _buildAccountStep(selectedAccount)
              : _buildReviewStep(selectedAccount!),
        ),
      ),
      actions: [
        if (_step == 0)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          )
        else
          TextButton.icon(
            onPressed: () => setState(() => _step = 0),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            minimumSize: const Size(148, 48),
          ),
          onPressed: selectedAccount == null
              ? null
              : () {
                  if (_step == 0) {
                    setState(() => _step = 1);
                  } else {
                    Navigator.pop(context, true);
                  }
                },
          child: Text(_step == 0 ? 'Continue' : 'Create reservation'),
        ),
      ],
    );
  }

  Widget _buildAccountStep(ReservationAccount? selectedAccount) {
    final accounts = _visibleAccounts;
    return Column(
      key: const ValueKey('account-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose the student or professor who will own this reservation.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Search accounts',
            hintText: 'Name, username, or email',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildRoleFilter('All', 'all'),
            _buildRoleFilter('Students', 'student'),
            _buildRoleFilter('Professors', 'professor'),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: accounts.isEmpty
              ? Center(
                  child: Text(
                    'No eligible accounts match your search.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.separated(
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return _buildAccountTile(
                      account,
                      selectedAccount?.id == account.id,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRoleFilter(String label, String value) {
    final selected = _roleFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: _primary.withValues(alpha: 0.14),
      side: BorderSide(color: selected ? _primary : Colors.grey.shade300),
      labelStyle: TextStyle(
        color: selected ? _primary : Colors.grey.shade800,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => setState(() => _roleFilter = value),
    );
  }

  Widget _buildAccountTile(ReservationAccount account, bool selected) {
    final canReserve = account.canReserve;
    final subtitle = account.isStudent
        ? [
            account.email,
            if ((account.yearSection ?? '').isNotEmpty) account.yearSection!,
            if ((account.course ?? '').isNotEmpty) account.course!,
            if (!canReserve) 'No assigned professor',
          ].join(' · ')
        : account.email;

    return Material(
      color: selected
          ? _primary.withValues(alpha: 0.08)
          : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? _primary : Colors.grey.shade300,
        ),
      ),
      child: ListTile(
        enabled: canReserve,
        minVerticalPadding: 12,
        leading: CircleAvatar(
          backgroundColor: canReserve
              ? _primary.withValues(alpha: 0.12)
              : Colors.grey.shade200,
          child: Icon(
            account.isStudent ? Icons.school_outlined : Icons.person_outline,
            color: canReserve ? _primary : Colors.grey.shade500,
          ),
        ),
        title: Text(
          account.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle, color: _primary)
            : Text(
                account.roleLabel,
                style: TextStyle(
                  color: canReserve ? _primary : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
        onTap: canReserve
            ? () {
                widget.controller.selectAccount(account);
                setState(() {});
              }
            : null,
      ),
    );
  }

  Widget _buildReviewStep(ReservationAccount account) {
    return SingleChildScrollView(
      key: const ValueKey('review-step'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAccountSummary(account),
          const SizedBox(height: 20),
          _ReviewRow(label: 'Date', value: widget.dateLabel),
          _ReviewRow(label: 'Time', value: widget.timeLabel),
          if (widget.additionalNote.trim().isNotEmpty)
            _ReviewRow(
              label: 'Note',
              value: widget.additionalNote.trim(),
            ),
          const SizedBox(height: 12),
          const Text(
            'Resources',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...widget.controller.cart.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• ${item.resource.name} × ${_formatQuantity(item.quantity)}',
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                    'This admin-created reservation will bypass approval and become ongoing immediately.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSummary(ReservationAccount account) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reserved for ${account.fullName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('${account.roleLabel} · ${account.email}'),
          if (account.isStudent) ...[
            const SizedBox(height: 10),
            _ReviewRow(
              label: 'Year & section',
              value: account.yearSection?.isNotEmpty == true
                  ? account.yearSection!
                  : 'Not specified',
            ),
            _ReviewRow(
              label: 'Course',
              value: account.course?.isNotEmpty == true
                  ? account.course!
                  : 'Not specified',
            ),
            _ReviewRow(
              label: 'Professor',
              value: account.assignedProfessorName!,
            ),
          ],
        ],
      ),
    );
  }

  String _formatQuantity(num value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

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
            width: 116,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
