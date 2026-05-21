import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import 'pr_status_chip.dart';
import 'review_pr_dialog.dart';
import 'pr_details_dialog.dart';

/// Purchase Request Card Widget
/// Displays a single PR with actions based on status
class PRCard extends StatelessWidget {
  final Map<String, dynamic> purchaseRequest;
  final Function(Map<String, dynamic> updatedPR, String action)? onAction;

  const PRCard({
    super.key,
    required this.purchaseRequest,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final pr = purchaseRequest;
    final status = pr['status'] as String;
    
    return CardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pr['prNo'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                PRStatusChip(status: status),
              ],
            ),
            const SizedBox(height: 12),
            
            // Details
            _buildDetailRow(Icons.person_outline, pr['requestedBy']),
            _buildDetailRow(Icons.calendar_today, pr['date']),
            _buildDetailRow(Icons.inventory_2_outlined, '${pr['items']} item(s)'),
            const Divider(height: 24),
            
            // Total Cost
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Cost:', style: TextStyle(color: Colors.grey)),
                Text(
                  '₱${pr['totalCost'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Actions based on status
            _buildActionButton(context, pr, status),
          ],
        ),
      );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, Map<String, dynamic> pr, String status) {
    if (status == 'Pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _handleReview(context, pr),
          icon: const Icon(Icons.visibility),
          label: const Text('Review & Approve'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    }
    
    if (status == 'Approved') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => PRDetailsDialog.show(
            context: context,
            purchaseRequest: pr,
          ),
          icon: const Icon(Icons.visibility),
          label: const Text('View Details'),
        ),
      );
    }
    
    // Rejected or other status
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => PRDetailsDialog.show(
          context: context,
          purchaseRequest: pr,
        ),
        icon: const Icon(Icons.visibility),
        label: const Text('View Details'),
      ),
    );
  }

  void _handleReview(BuildContext context, Map<String, dynamic> pr) {
    ReviewPRDialog.show(
      context: context,
      purchaseRequest: pr,
      onAction: (updatedPR, action) {
        if (onAction != null) {
          onAction!(updatedPR, action);
        }
      },
    );
  }
}
