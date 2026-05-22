import 'package:flutter/material.dart';

/// Reusable Purchase Request Status Chip
/// Shows status with appropriate color and icon
/// Handles all database statuses: SUBMITTED, APPROVED, ON_DELIVERY, DELIVERED, CANCELLED/REJECTED
class PRStatusChip extends StatelessWidget {
  final String status;

  const PRStatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String displayText;
    
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'SUBMITTED':
      case 'DRAFT':
        color = Colors.orange;
        icon = Icons.access_time;
        displayText = status == 'PENDING' ? 'Pending' : (status == 'DRAFT' ? 'Draft' : 'Submitted');
        break;
      case 'APPROVED':
        color = Colors.green;
        icon = Icons.check_circle;
        displayText = 'Approved';
        break;
      case 'ON DELIVERY':
      case 'ON_DELIVERY':
        color = Colors.blue;
        icon = Icons.local_shipping;
        displayText = 'On Delivery';
        break;
      case 'DELIVERED':
      case 'COMPLETED':
        color = Colors.blue;
        icon = Icons.done_all;
        displayText = 'Delivered';
        break;
      case 'REJECTED':
      case 'CANCELLED':
        color = Colors.red;
        icon = Icons.cancel;
        displayText = status == 'REJECTED' ? 'Rejected' : 'Cancelled';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        displayText = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
