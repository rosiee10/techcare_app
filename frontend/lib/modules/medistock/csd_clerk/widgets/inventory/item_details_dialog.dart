import 'package:flutter/material.dart';

/// Item Details Dialog
class ItemDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> item;

  const ItemDetailsDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, {required Map<String, dynamic> item}) {
    return showDialog(
      context: context,
      builder: (context) => ItemDetailsDialog(item: item),
    );
  }

  (Color, Color) _getStatusColors(String status) {
    switch (status) {
      case 'Low Stock':
        return (const Color(0xFFFFF8E1), const Color(0xFFFF8F00));
      case 'Near Expiry':
        return (const Color(0xFFFFEBEE), const Color(0xFFD32F2F));
      case 'Expired':
        return (const Color(0xFFEFEBE9), const Color(0xFF5D4037));
      default:
        return (const Color(0xFFE8F5E9), const Color(0xFF388E3C));
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColors = _getStatusColors(item['status']);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 500 ? 500.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Item Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Item Name
            _buildDetailRow('Item Name', item['itemName']),
            const Divider(height: 24),

            // Category
            _buildDetailRow('Category', item['category']),
            const Divider(height: 24),

            // Quantity
            _buildDetailRow('Quantity', '${item['quantity']} ${item['unit']}'),
            const Divider(height: 24),

            // Expiry Date
            _buildDetailRow('Expiry Date', item['expiryDate']),
            const Divider(height: 24),

            // Status
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColors.$1,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['status'],
                      style: TextStyle(
                        color: statusColors.$2,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
