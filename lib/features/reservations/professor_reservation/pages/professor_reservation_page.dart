import 'package:flutter/material.dart';
import '../controllers/professor_reservation_controller.dart';
import '../models/professor_reservation_model.dart';
import '../widgets/approval_modal.dart';

class ProfessorReservationPage extends StatefulWidget {
  const ProfessorReservationPage({super.key});

  @override
  State<ProfessorReservationPage> createState() => _ProfessorReservationPageState();
}

class _ProfessorReservationPageState extends State<ProfessorReservationPage> {
  final ProfessorReservationController _controller =
      ProfessorReservationController();
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

  void _showApprovalModal(ProfessorReservation reservation) {
    showDialog(
      context: context,
      builder: (context) => ApprovalModal(
        reservation: reservation,
        controller: _controller,
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
                _buildReservationsContent(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Pending Approval for Professor Reservations',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatsCards() {
    final pending = _controller.reservations.where((r) => r.professorApproval.toLowerCase() == 'pending').length;
    final approved = _controller.reservations.where((r) => r.professorApproval.toLowerCase() == 'approved').length;
    final declined = _controller.reservations.where((r) => r.professorApproval.toLowerCase() == 'declined').length;
    final total = _controller.reservations.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Pending', pending, const Color(0xFFFF9800), Icons.pending),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Approved', approved, const Color(0xFF4CAF50), Icons.check_circle),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Declined', declined, const Color(0xFFF44336), Icons.cancel),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Total', total, const Color(0xFF2196F3), Icons.list),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
      child: Row(
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
                        hintText: 'Search reservations...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Filter:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF152614),
            ),
          ),
          const SizedBox(width: 15),
          _buildFilterButton('All', 'all'),
          const SizedBox(width: 10),
          _buildFilterButton('Pending', 'pending'),
          const SizedBox(width: 10),
          _buildFilterButton('Approved', 'approved'),
          const SizedBox(width: 10),
          _buildFilterButton('Declined', 'declined'),
          const SizedBox(width: 16),
          Text(
            'Showing: ${_filteredReservations.length} reservations',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
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

  List<ProfessorReservation> get _filteredReservations {
    var reservations = _controller.filteredReservations;
    
    if (_searchController.text.isNotEmpty) {
      reservations = reservations.where((r) => 
        r.professorName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        r.resources.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        r.additionalNote.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }
    
    return reservations;
  }

  Widget _buildReservationsContent() {
    final filteredReservations = _filteredReservations;

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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Colors.grey.shade100,
          ),
          headingRowHeight: 48,
          dataRowHeight: 56,
          columnSpacing: 20,
          columns: const [
            DataColumn(
              label: Text(
                'Professor Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Resources',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Additional Note',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: filteredReservations.map((reservation) {
            return DataRow(
              color: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return Colors.grey.shade50;
                }
                return Colors.white;
              }),
              cells: [
                DataCell(
                  Text(
                    reservation.professorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    reservation.date,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                DataCell(
                  Text(
                    reservation.time,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      reservation.resources,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      reservation.additionalNote,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
                DataCell(_buildStatusBadge(reservation.professorApproval)),
                DataCell(
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () {
                        _showApprovalModal(reservation);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF31CB00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
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
            Icons.person_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No professor reservations',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _controller.getStatusColor(status),
        borderRadius: BorderRadius.circular(16),
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
}
