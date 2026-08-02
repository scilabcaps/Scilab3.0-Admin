import 'package:flutter/material.dart';
import '../controllers/audit_controller.dart';
import '../models/audit_log_model.dart';

class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  final AuditController _controller = AuditController();

  @override
  void initState() {
    super.initState();
    _controller.loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audit Logs',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              _buildFiltersSection(theme),
              const SizedBox(height: 24),
              _buildAuditTable(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltersSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            child: _buildModernDropdown(
              label: 'Entity Type',
              value: _controller.selectedEntityType,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Entities')),
                DropdownMenuItem(value: 'user', child: Text('Users')),
                DropdownMenuItem(value: 'room', child: Text('Rooms')),
                DropdownMenuItem(value: 'asset', child: Text('Assets')),
                DropdownMenuItem(value: 'chemical', child: Text('Chemicals')),
                DropdownMenuItem(value: 'reservation', child: Text('Reservations')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _controller.setEntityTypeFilter(value);
                  _controller.loadLogs();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildModernDropdown(
              label: 'Action Type',
              value: _controller.selectedActionType,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Actions')),
                DropdownMenuItem(value: 'CREATE', child: Text('Create')),
                DropdownMenuItem(value: 'UPDATE', child: Text('Update')),
                DropdownMenuItem(value: 'DELETE', child: Text('Delete')),
                DropdownMenuItem(value: 'BAN', child: Text('Ban')),
                DropdownMenuItem(value: 'UNBAN', child: Text('Unban')),
                DropdownMenuItem(value: 'APPROVE', child: Text('Approve')),
                DropdownMenuItem(value: 'REJECT', child: Text('Reject')),
                DropdownMenuItem(value: 'CANCEL', child: Text('Cancel')),
                DropdownMenuItem(value: 'COMPLETE', child: Text('Complete')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _controller.setActionTypeFilter(value);
                  _controller.loadLogs();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildModernDropdown(
              label: 'Time Period',
              value: _controller.selectedDays,
              items: const [
                DropdownMenuItem(value: 7, child: Text('7 Days')),
                DropdownMenuItem(value: 30, child: Text('30 Days')),
                DropdownMenuItem(value: 90, child: Text('90 Days')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _controller.setDaysFilter(value);
                  _controller.loadLogs();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _controller.refresh(),
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditTable(ThemeData theme) {
    return Container(
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
          _buildTableHeader(theme),
          if (_controller.logs.isEmpty)
            _buildEmptyState()
          else
            ..._controller.logs.map((log) => _buildLogRow(log, theme)),
          _buildPagination(theme),
        ],
      ),
    );
  }

  Widget _buildTableHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Entity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 3, child: Text('User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 4, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(64),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No audit logs found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust your filters or perform some actions to see logs here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogRow(AuditLog log, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatTimestamp(log.createdAt),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(flex: 2, child: _buildModernActionChip(log.actionType, theme)),
          Expanded(
            flex: 2,
            child: Text(
              _capitalizeFirst(log.entityType),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              log.userName ?? 'Unknown',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              log.description ?? 'N/A',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(ThemeData theme) {
    if (_controller.totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
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
                    ? () => _controller.previousPage()
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
              ),
              IconButton(
                onPressed: _controller.currentPage < _controller.totalPages
                    ? () => _controller.nextPage()
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

  Widget _buildModernActionChip(String actionType, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    switch (actionType) {
      case 'CREATE':
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.add_circle_outline;
        break;
      case 'UPDATE':
        backgroundColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        icon = Icons.edit;
        break;
      case 'DELETE':
        backgroundColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        icon = Icons.delete_outline;
        break;
      case 'BAN':
        backgroundColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        icon = Icons.block;
        break;
      case 'UNBAN':
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.check_circle_outline;
        break;
      case 'APPROVE':
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.thumb_up;
        break;
      case 'REJECT':
        backgroundColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFF57C00);
        icon = Icons.thumb_down;
        break;
      case 'CANCEL':
        backgroundColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        icon = Icons.cancel;
        break;
      case 'COMPLETE':
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.check_circle;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            actionType,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
