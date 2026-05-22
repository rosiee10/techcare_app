import 'package:flutter/material.dart';
import 'package:frontend/core/utils/responsive.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../../../ipd/ipd_nurse/services/ipd_inventory_service.dart';
import '../widgets/ipd_dispensing_sheet/dispensing_sheet_dialog.dart';

/// IPD Services and Dispensing Sheet Page
/// IPD Dispensing sheets created by nurses - Dispense medicines individually
class IpdDispensingSheetPage extends StatefulWidget {
  final Map<String, dynamic>? pendingActionData;
  final VoidCallback? onActionCompleted;
  const IpdDispensingSheetPage({super.key, this.pendingActionData, this.onActionCompleted});

  @override
  State<IpdDispensingSheetPage> createState() => _IpdDispensingSheetPageState();
}

class _IpdDispensingSheetPageState extends State<IpdDispensingSheetPage> {
  String _selectedStatus = 'All Status';
  String _currentTab = 'All'; // New: tracking current tab
  final TextEditingController _searchController = TextEditingController();
  final IpdInventoryService _inventoryService = IpdInventoryService();

  // Dynamic data
  bool _isLoading = true;
  bool _isOpeningDialog = false;
  List<dynamic> _dispensingSheets = [];
  List<dynamic> _filteredSheets = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterSheets();
  }

  void _filterSheets() {
    final query = _searchController.text.toLowerCase().trim();
    final statusFilter = _selectedStatus.toUpperCase();
    
    setState(() {
      _filteredSheets = _dispensingSheets.where((sheet) {
        // Tab filtering (All, Pending, Dispensed)
        if (_currentTab == 'Pending') {
          if (sheet['status'] != 'PENDING') return false;
        } else if (_currentTab == 'Dispensed') {
          if (sheet['status'] != 'DISPENSED') return false;
        }

        // Status filtering (Dropdown)
        if (_selectedStatus != 'All Status') {
          if (sheet['status'] != statusFilter) return false;
        }

        // Search filtering
        if (query.isEmpty) return true;

        final patientName = (sheet['patient_name'] ?? '').toString().toLowerCase();
        final patientId = (sheet['patient_id'] ?? '').toString().toLowerCase();
        final sheetNo = (sheet['dispensing_id'] ?? '').toString().toLowerCase();
        final ward = (sheet['ward'] ?? '').toString().toLowerCase();
        
        return patientName.contains(query) ||
               patientId.contains(query) ||
               sheetNo.contains(query) ||
               ward.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchData({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      final response = await _inventoryService.getDispensingSheets();
      final List<dynamic> sheets = response['results'] ?? [];

      setState(() {
        _dispensingSheets = sheets;
        _filteredSheets = List.from(sheets);
        if (!silent) _isLoading = false;
      });
      
      // Apply any existing filters
      _filterSheets();

      // Check for deep link data from notification
      if (widget.pendingActionData != null && widget.pendingActionData!['id'] != null) {
        final actionId = widget.pendingActionData!['id'];
        
        // Find the sheet ID in the list to make sure we have the latest detail
        final targetSheet = _dispensingSheets.firstWhere(
          (s) => s['pk'].toString() == actionId.toString() || 
                 s['dispensing_id'].toString() == actionId.toString() || 
                 s['id'].toString() == actionId.toString(),
          orElse: () => null,
        );
        
        if (targetSheet != null) {
          // IMPORTANT: Check if the sheet is still PENDING. 
          // If it was already dispensed, don't auto-open.
          if (targetSheet['status'] == 'PENDING') {
             _openDispensingDialog(targetSheet);
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  // Calculate total sheets
  int get _totalSheets => _dispensingSheets.length;

  // Calculate pending sheets
  int get _pendingSheets => _dispensingSheets.where((s) => s['status'] == 'PENDING').length;

  // Calculate completed sheets
  int get _completedSheets => _dispensingSheets.where((s) => s['status'] == 'DISPENSED').length;

  // Action Helper
  Future<void> _openDispensingDialog(dynamic sheet) async {
    if (_isOpeningDialog) return;
    setState(() => _isOpeningDialog = true);
    try {
      final response = await _inventoryService.getDispensingSheetDetail(sheet['dispensing_id'] ?? sheet['id'] ?? sheet['pk']);
      if (response['success'] == true) {
        if (mounted) {
          await DispensingSheetDialog.show(context, sheet: response['data']);
          _fetchData(silent: true); // Refresh local list
          widget.onActionCompleted?.call(); // Refresh global dashboard notifications instantly
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sheet details: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningDialog = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Responsive
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IPD Services and Dispensing Sheet',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'IPD Dispensing sheets created by nurses - Dispense medicines individually',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search and Filter Bar - Responsive
          CardContainer(
            child: (isMobile || isTablet)
              ? Column(
                  children: [
                    // Search Field
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by patient, ID, sheet...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Status Dropdown
                    SizedBox(
                      width: double.infinity,
                      child: _buildDropdown(
                        value: _selectedStatus,
                        items: const ['All Status', 'PENDING', 'APPROVED', 'DISPENSED', 'REJECTED'],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                            _filterSheets();
                          });
                        },
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Search Field
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by patient name, ID, sheet number, or ward...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status Dropdown
                    SizedBox(
                      width: 140,
                      child: _buildDropdown(
                        value: _selectedStatus,
                        items: const ['All Status', 'PENDING', 'APPROVED', 'DISPENSED', 'REJECTED'],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                            _filterSheets();
                          });
                        },
                      ),
                    ),
                  ],
                ),
          ),
          const SizedBox(height: 24),

          // Stat Cards - Mobile & Tablet: 2x2 Grid, Large Desktop: Row
          (isMobile || isTablet)
            ? Column(
                children: [
                  // First row: 2 cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Sheets',
                          value: _isLoading ? '-' : _totalSheets.toString(),
                          icon: Icons.description_outlined,
                          iconBgColor: const Color(0xFFE3F2FD),
                          iconColor: const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Pending Sheets',
                          value: _isLoading ? '-' : _pendingSheets.toString(),
                          icon: Icons.access_time_outlined,
                          iconBgColor: const Color(0xFFFFF9C4),
                          iconColor: const Color(0xFFFBC02D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Second row: 1 card
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Completed Sheets',
                          value: _isLoading ? '-' : _completedSheets.toString(),
                          icon: Icons.check_circle_outline,
                          iconBgColor: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF4CAF50),
                        ),
                      ),
                      if (isTablet) const Expanded(child: SizedBox()), // Spacer for tablet grid
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  _buildStatCard(
                    title: 'Total Sheets',
                    value: _isLoading ? '-' : _totalSheets.toString(),
                    icon: Icons.description_outlined,
                    iconBgColor: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF2196F3),
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    title: 'Pending Sheets',
                    value: _isLoading ? '-' : _pendingSheets.toString(),
                    icon: Icons.access_time_outlined,
                    iconBgColor: const Color(0xFFFFF9C4),
                    iconColor: const Color(0xFFFBC02D),
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    title: 'Completed Sheets',
                    value: _isLoading ? '-' : _completedSheets.toString(),
                    icon: Icons.check_circle_outline,
                    iconBgColor: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF4CAF50),
                  ),
                ],
              ),
          const SizedBox(height: 24),

          // Tabs Bar
          _buildTabsBar(),
          const SizedBox(height: 24),

          // Data Table - Responsive
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header (Desktop only)
                if (!isMobile)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeader('DATE & TIME', flex: 2),
                        _buildTableHeader('PATIENT DETAILS', flex: 2),
                        _buildTableHeader('CREATED BY', flex: 2),
                        _buildTableHeader('MEDICINES', flex: 1),
                        _buildTableHeader('ACTION', flex: 1),
                      ],
                    ),
                  ),
                if (!isMobile) const Divider(height: 1),
                // Table Rows - Dynamic
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_errorMessage.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                          const SizedBox(height: 16),
                          Text(_errorMessage, style: TextStyle(color: Colors.red[600])),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                else if (_filteredSheets.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, color: Colors.grey[400], size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                              ? 'No dispensing sheets found'
                              : 'No sheets found matching "${_searchController.text}"',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchController.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                _filterSheets();
                              },
                              child: const Text('Clear Search'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else if (isMobile || isTablet)
                  // Mobile & Tablet: Card-based layout
                  Column(
                    children: _filteredSheets.asMap().entries.map((entry) {
                      final sheet = entry.value;
                      final items = sheet['items'] ?? [];
                      return _buildDispensingCard(
                        sheet: sheet,
                        date: sheet['request_date'] ?? '—',
                        time: sheet['request_time'] ?? '—',
                        initials: (sheet['patient_name'] ?? '??').substring(0, 2).toUpperCase(),
                        name: sheet['patient_name'] ?? 'Unknown',
                        patientId: sheet['patient_hospital_id']?.toString() ?? '—',
                        ward: sheet['ward'] ?? 'IPD Ward',
                        createdBy: sheet['requested_by_name']?.toString() ?? 'Unknown',
                        isPharmacist: sheet['dispensed_by'] != null,
                        items: '${items.length} items',
                        pendingCount: sheet['status'] == 'PENDING' ? '${items.length} pending' : 'Processed',
                      );
                    }).toList(),
                  )
                else
                  // Desktop: Row-based layout
                  ..._filteredSheets.asMap().entries.map((entry) {
                    final sheet = entry.value;
                    final items = sheet['items'] ?? [];
                    return Column(
                      children: [
                        _buildDispensingRow(
                          sheet: sheet,
                          date: sheet['request_date'] ?? '—',
                          time: sheet['request_time'] ?? '—',
                          initials: (sheet['patient_name'] ?? '??').substring(0, 2).toUpperCase(),
                          name: sheet['patient_name'] ?? 'Unknown',
                          patientId: sheet['patient_hospital_id']?.toString() ?? '—',
                          ward: sheet['ward'] ?? 'IPD Ward',
                          createdBy: sheet['requested_by_name']?.toString() ?? 'Unknown',
                          isPharmacist: sheet['dispensed_by'] != null,
                          items: '${items.length} items',
                          pendingCount: sheet['status'] == 'PENDING' ? '${items.length} pending' : 'Processed',
                        ),
                        if (entry.key < _filteredSheets.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabItem('All', _dispensingSheets.length, Colors.grey[700]!),
            _buildTabItem('Pending', _dispensingSheets.where((s) => s['status'] == 'PENDING').length, Colors.orange[400]!),
            _buildTabItem('Dispensed', _dispensingSheets.where((s) => s['status'] == 'DISPENSED').length, Colors.blue[400]!),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int count, Color activeBadgeColor) {
    final bool isActive = _currentTab == label;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = label;
          _filterSheets();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.grey[700] : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[700],
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? Colors.grey[500]?.withOpacity(0.5) : activeBadgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : activeBadgeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDispensingRow({
    required dynamic sheet,
    required String date,
    required String time,
    required String initials,
    required String name,
    required String patientId,
    required String ward,
    required String createdBy,
    required bool isPharmacist,
    required String items,
    required String pendingCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Date & Time
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13,
                        color: time == '—' ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Patient Details
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      patientId,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ward,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Created By
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  createdBy,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          // Medicines
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  items,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  pendingCount,
                  style: TextStyle(
                    fontSize: 12,
                    color: pendingCount.toLowerCase().contains('pending') ? Colors.red[400] : Colors.green[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Action
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: () => _openDispensingDialog(sheet),
              icon: const Icon(Icons.local_hospital_outlined, size: 16),
              label: const Text('View & Dispense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile: Card-based dispensing sheet item
  Widget _buildDispensingCard({
    required dynamic sheet,
    required String date,
    required String time,
    required String initials,
    required String name,
    required String patientId,
    required String ward,
    required String createdBy,
    required bool isPharmacist,
    required String items,
    required String pendingCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name + Patient ID
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      patientId,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        ward,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    items,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    createdBy,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openDispensingDialog(sheet),
              icon: const Icon(Icons.local_hospital_outlined, size: 16),
              label: const Text('View & Dispense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
