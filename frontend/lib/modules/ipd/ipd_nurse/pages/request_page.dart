import 'package:flutter/material.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../widgets/request/dispensing_sheet_form.dart';
import '../widgets/request/cart_form.dart';
import '../widgets/request/stock_card_form.dart';

/// Request Page for IPD Nurse
/// Pharmacy: Dispensing Sheet (when open) or Cart Form (when closed)
/// Central Supply: Stock Card Request
class IpdNurseRequestPage extends StatefulWidget {
  const IpdNurseRequestPage({super.key});

  @override
  State<IpdNurseRequestPage> createState() => _IpdNurseRequestPageState();
}

class _IpdNurseRequestPageState extends State<IpdNurseRequestPage>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _pharmacyTabController;

  // Form data for Dispensing Sheet
  final List<Map<String, dynamic>> _dispensingItems = [];
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _roomNoController = TextEditingController();
  final TextEditingController _drugNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();


  // Form data for Stock Card Request
  final List<Map<String, dynamic>> _stockItems = [];
  final TextEditingController _stockPatientController = TextEditingController();
  final TextEditingController _stockRoomController = TextEditingController();
  final TextEditingController _stockItemController = TextEditingController();
  final TextEditingController _stockQtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _pharmacyTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _pharmacyTabController.dispose();
    _patientNameController.dispose();
    _roomNoController.dispose();
    _drugNameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _quantityController.dispose();
    _stockPatientController.dispose();
    _stockRoomController.dispose();
    _stockItemController.dispose();
    _stockQtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and tabs inline
          isSmallScreen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create dispensing, cart, or stock requests',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Compact Pill-style Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        controller: _mainTabController,
                        isScrollable: true,
                        indicator: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF64748B),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabAlignment: TabAlignment.start,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                        tabs: const [
                          Tab(
                            height: 36,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_pharmacy_outlined, size: 16),
                                SizedBox(width: 6),
                                Text('Pharmacy'),
                              ],
                            ),
                          ),
                          Tab(
                            height: 36,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 16),
                                SizedBox(width: 6),
                                Text('Central Supply'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create dispensing, cart, or stock requests',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    // Right: Compact Pill-style Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        controller: _mainTabController,
                        isScrollable: true,
                        indicator: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF64748B),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabAlignment: TabAlignment.start,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                        tabs: const [
                          Tab(
                            height: 36,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_pharmacy_outlined, size: 16),
                                SizedBox(width: 6),
                                Text('Pharmacy'),
                              ],
                            ),
                          ),
                          Tab(
                            height: 36,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 16),
                                SizedBox(width: 6),
                                Text('Central Supply'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 32),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPharmacyTab(isSmallScreen),
                _buildCentralSupplyTab(isSmallScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pharmacy Tab with Dispensing Sheet and Cart Form sub-tabs
  Widget _buildPharmacyTab(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-tabs with status badge on the right
        Row(
          children: [
            // Tabs
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _pharmacyTabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabAlignment: TabAlignment.start,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  tabs: const [
                    Tab(
                      height: 32,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.medical_services_outlined, size: 14),
                          SizedBox(width: 6),
                          Text('Dispensing Sheet'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 32,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 14),
                          SizedBox(width: 6),
                          Text('Cart Form'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Status Badge - changes based on selected tab
            _buildPharmacyStatusBadge(),
          ],
        ),
        const SizedBox(height: 24),

        // Sub-tab Content
        Expanded(
          child: TabBarView(
            controller: _pharmacyTabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              DispensingSheetForm(
                isSmallScreen: isSmallScreen,
              ),
              CartForm(
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Status badge that changes based on selected pharmacy tab
  Widget _buildPharmacyStatusBadge() {
    return AnimatedBuilder(
      animation: _pharmacyTabController,
      builder: (context, child) {
        final isDispensingSheet = _pharmacyTabController.index == 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDispensingSheet ? const Color(0xFFDBEAFE) : const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDispensingSheet ? Icons.storefront_outlined : Icons.shopping_cart_outlined,
                size: 16,
                color: isDispensingSheet ? const Color(0xFF2563EB) : const Color(0xFF059669),
              ),
              const SizedBox(width: 6),
              Text(
                isDispensingSheet ? 'Pharmacy is OPEN' : 'Pharmacy is CLOSED - Cart Mode',
                style: TextStyle(
                  color: isDispensingSheet ? const Color(0xFF2563EB) : const Color(0xFF059669),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Central Supply Tab
  Widget _buildCentralSupplyTab(bool isSmallScreen) {
    return StockCardForm(isSmallScreen: isSmallScreen);
  }

  Widget _buildFormCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CardContainer(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestRow(String formType, String patient, String room, String status, String date) {
    final (bgColor, textColor) = _getStatusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              formType,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(patient, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          ),
          Expanded(
            flex: 1,
            child: Text(room, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockRequestRow(String item, String patient, String room, String status, String date) {
    final (bgColor, textColor) = _getStatusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(patient, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          ),
          Expanded(
            flex: 1,
            child: Text(room, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _getStatusColors(String status) {
    switch (status) {
      case 'Pending':
        return (const Color(0xFFFFF8E1), const Color(0xFFFF8F00));
      case 'Approved':
        return (const Color(0xFFE3F2FD), const Color(0xFF1976D2));
      case 'Dispensed':
      case 'Completed':
        return (const Color(0xFFE8F5E9), const Color(0xFF388E3C));
      default:
        return (const Color(0xFFEEEEEE), const Color(0xFF757575));
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildTableHeader(String title, {int flex = 1, Color? textColor, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.grey[600],
        ),
      ),
    );
  }
}
