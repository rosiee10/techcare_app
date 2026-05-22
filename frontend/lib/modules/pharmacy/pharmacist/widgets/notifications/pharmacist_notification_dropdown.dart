import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/responsive.dart';

class PharmacistNotificationDropdown extends StatefulWidget {
  final Map<String, dynamic> stats;
  final VoidCallback? onClearAll;
  final Function(int, Map<String, dynamic>?)? onNavigate;
  final Set<String> readIds;
  final Function(String) onMarkRead;
  final VoidCallback onMarkAllRead;
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const PharmacistNotificationDropdown({
    super.key,
    required this.stats,
    required this.readIds,
    required this.onMarkRead,
    required this.onMarkAllRead,
    required this.selectedDate,
    required this.onDateChanged,
    this.onClearAll,
    this.onNavigate,
  });

  @override
  State<PharmacistNotificationDropdown> createState() => _PharmacistNotificationDropdownState();
}

class _PharmacistNotificationDropdownState extends State<PharmacistNotificationDropdown> {
  bool _showAll = false;
  String _selectedTab = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final allNotifications = _getNotifications();
    
    // Filter notifications
    final filteredByDateAndReadStatus = allNotifications.where((n) {
      // 1. ALERTS: Always show alerts regardless of selected date.
      // Alerts only disappear when the medicine is no longer low stock or expired in the database.
      if (n['type'] == 'alert') return true;

      // 2. REQUESTS & APPROVED: Filter by selected date and read status
      DateTime? notifDate;
      if (n['timestamp'] != null && n['timestamp'].toString().isNotEmpty) {
        try {
          notifDate = DateTime.parse(n['timestamp'].toString());
        } catch (e) {
          // If date parsing fails, keep it visible
          return true;
        }
      }
      
      // Filter by selected date
      final selectedDateOnly = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
      
      if (notifDate != null) {
        final notifDateOnly = DateTime(notifDate.year, notifDate.month, notifDate.day);
        if (!notifDateOnly.isAtSameMomentAs(selectedDateOnly)) {
          return false;
        }
      }
      
      // Filter by read state (only for requests/approved)
      return !widget.readIds.contains(n['id']);
    }).toList();
    
    // Filter by tab
    List<Map<String, dynamic>> filteredNotifications = filteredByDateAndReadStatus;
    if (_selectedTab == 'Request') {
      filteredNotifications = filteredByDateAndReadStatus.where((n) => n['type'] == 'request').toList();
    } else if (_selectedTab == 'Approved') {
      filteredNotifications = filteredByDateAndReadStatus.where((n) => n['type'] == 'approved').toList();
    } else if (_selectedTab == 'Alerts') {
      filteredNotifications = filteredByDateAndReadStatus.where((n) => n['type'] == 'alert').toList();
    }
    
    final isWeb = Responsive.isDesktop(context);
    final previewLimit = isWeb ? 10 : 3;
    
    // Apply "View All" limit
    final notifications = _showAll ? filteredNotifications : filteredNotifications.take(previewLimit).toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: isWeb ? 420 : 340,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: theme.titleStyle.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You have ${filteredByDateAndReadStatus.length} unread alerts',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: widget.selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2101),
                        builder: (context, child) {
                          final isMobile = Responsive.isMobile(context);
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: theme.buttonPrimary,
                                onPrimary: Colors.white,
                                onSurface: theme.textPrimary,
                              ),
                              dialogTheme: DialogThemeData(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            child: isMobile 
                              ? Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 60, right: 20),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 340,
                                        maxHeight: 560,
                                      ),
                                      child: child!,
                                    ),
                                  ),
                                )
                              : child!,
                          );
                        },
                      );
                      if (picked != null) {
                        widget.onDateChanged(picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.buttonPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: theme.buttonPrimary),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM dd, yyyy').format(widget.selectedDate),
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.buttonPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tabs Implementation
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildTab('All', filteredByDateAndReadStatus.length),
                  _buildTab('Request', filteredByDateAndReadStatus.where((n) => n['type'] == 'request').length),
                  _buildTab('Approved', filteredByDateAndReadStatus.where((n) => n['type'] == 'approved').length),
                  _buildTab('Alerts', filteredByDateAndReadStatus.where((n) => n['type'] == 'alert').length),
                ],
              ),
            ),
            
            const Divider(height: 1),

            // Notifications List
            Flexible(
              child: notifications.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: theme.textSecondary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No $_selectedTab notifications',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return _NotificationItem(
                          title: notif['title'] as String,
                          subtitle: notif['subtitle'] as String,
                          icon: notif['icon'] as IconData,
                          color: notif['color'] as Color,
                          time: notif['time'] as String,
                          onTap: () {
                            // User request: Don't mark as read automatically on click.
                            // The notification should only disappear after the action is performed.
                            // Performing the action will change the DB status, and the next fetch will remove it.
                            
                            Navigator.pop(context);
                            if (notif['index'] != null) {
                              widget.onNavigate?.call(notif['index'] as int, notif['data'] as Map<String, dynamic>?);
                            }
                          },
                        );
                      },
                    ),
            ),

            // Footer
            if (filteredNotifications.length > previewLimit && !_showAll) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Increased bottom padding
                child: Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _showAll = true;
                      });
                    },
                    child: Text(
                      'View All Notifications',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16), // Ensure some space if button is hidden
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    final isSelected = _selectedTab == label;
    final theme = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = label;
            _showAll = false; // Reset view all when switching tabs
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? theme.buttonPrimary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : theme.textSecondary,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : theme.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getNotifications() {
    final stats = widget.stats;
    final List<Map<String, dynamic>> items = [];

    // 1. Pending Dispensing Sheets (Individual)
    final List<dynamic> pendingSheets = stats['pending_dispensing_sheets'] ?? [];
    for (var sheet in pendingSheets) {
      items.add({
        'id': 'sheet_${sheet['document_no']}_${sheet['timestamp']}',
        'type': 'request',
        'title': 'New Dispensing Request',
        'subtitle': '${sheet['patient_name']} (${sheet['document_no']}) in ${sheet['ward']}',
        'icon': Icons.description_outlined,
        'color': Colors.blue,
        'time': sheet['time'] ?? 'Just now',
        'index': 3, // IPD Dispensing Sheet index
        'timestamp': sheet['timestamp'] ?? '',
        'data': sheet, // Pass full sheet data for deep linking
      });
    }

    // 2. Approved Purchase Requests (Individual)
    final List<dynamic> approvedPRs = stats['approved_prs'] ?? [];
    for (var pr in approvedPRs) {
      items.add({
        'id': 'pr_${pr['pr_no']}_${pr['timestamp']}',
        'type': 'approved',
        'title': 'Purchase Request Approved',
        'subtitle': 'PR #${pr['pr_no']} has been approved by the Chief Nurse.',
        'icon': Icons.check_circle_outline,
        'color': Colors.green,
        'time': pr['time'] ?? 'Just now',
        'index': 6, // Purchase Request index
        'timestamp': pr['timestamp'] ?? '',
        'data': pr, // Pass full PR data for deep linking
      });
    }

    // Sort combined notifications (Dispensing + PRs) by timestamp descending
    items.sort((a, b) {
      String timeA = a['timestamp'] ?? '';
      String timeB = b['timestamp'] ?? '';
      return timeB.compareTo(timeA);
    });

    // 3. Low Stock Alerts (Individual) - Always below time-based notifications
    final List<dynamic> lowStockAlerts = stats['low_stock_alerts'] ?? [];
    for (var alert in lowStockAlerts) {
      items.add({
        'id': 'low_stock_${alert['name']}',
        'type': 'alert',
        'title': 'Low Stock: ${alert['name']}',
        'subtitle': 'Current stock: ${alert['qty']} (Reorder Level: ${alert['reorder_level']})',
        'icon': Icons.warning_amber_rounded,
        'color': Colors.red,
        'time': 'Alert',
        'index': 1, // Inventory index
      });
    }

    // 4. Expiry Alerts (Individual)
    final List<dynamic> expiryAlerts = stats['expiry_alerts'] ?? [];
    for (var alert in expiryAlerts) {
      items.add({
        'id': 'expiry_${alert['medicine_name']}_${alert['batch_no']}',
        'type': 'alert',
        'title': 'Expiring Soon: ${alert['medicine_name']}',
        'subtitle': 'Batch ${alert['batch_no']} expires on ${alert['expiry_date']} (Qty: ${alert['qty']})',
        'icon': Icons.access_time_rounded,
        'color': Colors.purple,
        'time': 'Near Expiry',
        'index': 1, // Inventory index
      });
    }

    return items;
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String time;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF334155),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
