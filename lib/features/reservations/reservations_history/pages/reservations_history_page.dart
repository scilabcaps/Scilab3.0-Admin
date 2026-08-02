import 'package:flutter/material.dart';
import '../controllers/reservations_history_controller.dart';
import '../models/reservations_history_model.dart';
import '../widgets/receipt_modal.dart';

class ReservationsHistoryPage extends StatefulWidget {
  const ReservationsHistoryPage({super.key});

  @override
  State<ReservationsHistoryPage> createState() => _ReservationsHistoryPageState();
}

class _ReservationsHistoryPageState extends State<ReservationsHistoryPage> {
  final ReservationsHistoryController _controller =
      ReservationsHistoryController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.loadReservations();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showReceiptModal(ReservationHistory reservation) {
    showDialog(
      context: context,
      builder: (context) => ReceiptModal(
        reservation: reservation,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: const Color(0xFFE8F5E9),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatsCards(),
                const SizedBox(height: 24),
                _buildFilterSection(),
                const SizedBox(height: 20),
                Expanded(child: _buildReservationsContent()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Reservation History',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF152614),
          ),
        ),
        IconButton(
          onPressed: () {
            _controller.refresh();
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF152614),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Reservations',
            _controller.totalReservations,
            const Color(0xFF31CB00),
            Icons.receipt_long,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Completed',
            _controller.completedReservations,
            const Color(0xFF4CAF50),
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Cancelled',
            _controller.cancelledReservations,
            const Color(0xFF9E9E9E),
            Icons.cancel,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Declined',
            _controller.declinedReservations,
            const Color(0xFFF44336),
            Icons.block,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search by name, ID, room, or item...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          onChanged: (value) {
                            _controller.setSearchQuery(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildDateFilterDropdown(),
              const SizedBox(width: 16),
              _buildStatusFilterDropdown(),
              const SizedBox(width: 16),
              _buildRoleFilterButtons(),
            ],
          ),
          if (_controller.selectedDateFilter == 'specific' ||
              _controller.selectedDateFilter == 'range')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildDateFilterInputs(),
            ),
        ],
      ),
    );
  }

  Widget _buildDateFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _controller.selectedDateFilter,
          hint: const Text('Date Filter'),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Dates')),
            DropdownMenuItem(value: 'specific', child: Text('Specific Date')),
            DropdownMenuItem(value: 'range', child: Text('Date Range')),
          ],
          onChanged: (value) {
            if (value != null) {
              _controller.setSelectedDateFilter(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatusFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _controller.selectedStatusFilter.isEmpty
              ? null
              : _controller.selectedStatusFilter,
          hint: const Text('All Status'),
          items: const [
            DropdownMenuItem(value: 'Completed', child: Text('Completed')),
            DropdownMenuItem(value: 'Declined', child: Text('Declined')),
            DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
          ],
          onChanged: (value) {
            if (value != null) {
              _controller.setSelectedStatusFilter(value);
            } else {
              _controller.setSelectedStatusFilter('');
            }
          },
        ),
      ),
    );
  }

  Widget _buildRoleFilterButtons() {
    return Row(
      children: [
        const Text(
          'Role:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF152614),
          ),
        ),
        const SizedBox(width: 10),
        _buildFilterButton('All', 'all'),
        const SizedBox(width: 8),
        _buildFilterButton('Students', 'student'),
        const SizedBox(width: 8),
        _buildFilterButton('Professors', 'professor'),
      ],
    );
  }

  Widget _buildFilterButton(String label, String filterValue) {
    final isSelected = _controller.selectedFilter == filterValue;
    return InkWell(
      onTap: () {
        _controller.setSelectedFilter(filterValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF31CB00) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterInputs() {
    if (_controller.selectedDateFilter == 'specific') {
      return Row(
        children: [
          const Text('Date: ', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                _controller.setSpecificDate(picked);
              }
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _controller.specificDate != null
                  ? '${_controller.specificDate!.day}/${_controller.specificDate!.month}/${_controller.specificDate!.year}'
                  : 'Select Date',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF31CB00),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    } else if (_controller.selectedDateFilter == 'range') {
      return Row(
        children: [
          const Text('From: ', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                _controller.setDateRange(picked, _controller.endDate);
              }
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _controller.startDate != null
                  ? '${_controller.startDate!.day}/${_controller.startDate!.month}/${_controller.startDate!.year}'
                  : 'Start Date',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF31CB00),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          const Text('To: ', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                _controller.setDateRange(_controller.startDate, picked);
              }
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _controller.endDate != null
                  ? '${_controller.endDate!.day}/${_controller.endDate!.month}/${_controller.endDate!.year}'
                  : 'End Date',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF31CB00),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildReservationsContent() {
    final filteredReservations = _controller.filteredReservations;

    if (filteredReservations.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: filteredReservations.map((reservation) => _buildReservationRow(reservation)).toList(),
              ),
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('User Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 3, child: Text('Room / Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildReservationRow(ReservationHistory reservation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              reservation.userName,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildRoleBadge(reservation.role),
          ),
          Expanded(
            flex: 2,
            child: Text(
              reservation.reservationType,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              reservation.roomItemReserved,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              reservation.reservationDate,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              reservation.timeSchedule,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildStatusBadge(reservation.status),
          ),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () => _showReceiptModal(reservation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF31CB00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View Receipt', style: TextStyle(fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${_controller.currentPage} of ${_controller.totalPages} (${_controller.totalRows} total)',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _controller.currentPage > 1
                    ? () => _controller.loadReservations(page: _controller.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
              ),
              IconButton(
                onPressed: _controller.currentPage < _controller.totalPages
                    ? () => _controller.loadReservations(page: _controller.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No reservations found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search criteria',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _controller.getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _controller.getStatusTextColor(status),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _controller.getRoleColor(role),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: _controller.getRoleTextColor(role),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
