import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/provider/auth_provider.dart';
import '../../../../core/reusable_widgets/stat_card.dart';
import '../../../../core/reusable_widgets/card_container.dart';
import '../../../../core/reusable_widgets/section_header.dart';
import '../widgets/sidebar.dart';
import '../../../shared/appbar/appbar_header.dart';

class IcdCoderDashboard extends StatefulWidget {
  const IcdCoderDashboard({super.key});

  @override
  State<IcdCoderDashboard> createState() => _IcdCoderDashboardState();
}

class _IcdCoderDashboardState extends State<IcdCoderDashboard> {
  int _selectedIndex = 0; // Start with Dashboard selected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Left: Sidebar
          IcdCoderSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          
          // Right: Header + Content
          Expanded(
            child: Column(
              children: [
                // Shared Header Component
                AppBarHeader(
                  currentPage: _getPageTitle(),
                  onHomePressed: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                ),
                
                // Main Content Area
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildConsultQueue();
      case 2:
        return _buildPatientList();
      case 3:
        return _buildLabAvailability();
      case 4:
        return _buildMedicineInventory();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF00ACC1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Dr.!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ICD Coder Dashboard',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.dashboard_outlined,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Stat Cards - Using Reusable StatCard Widget
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'My Queue Today',
                  value: '0',
                  subtitle: 'Assigned',
                  icon: Icons.grid_view,
                  bgColor: const Color(0xFFE3F2FD),
                  iconColor: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: StatCard(
                  title: 'Seen Today',
                  value: '0',
                  subtitle: 'Done',
                  icon: Icons.check_circle_outline,
                  bgColor: const Color(0xFFE8F5E9),
                  iconColor: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: StatCard(
                  title: 'Pending Results',
                  value: '0',
                  subtitle: 'Lab / X-Ray',
                  icon: Icons.science_outlined,
                  bgColor: const Color(0xFFF3E5F5),
                  iconColor: const Color(0xFF9C27B0),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: StatCard(
                  title: 'Draft Orders',
                  value: '1',
                  subtitle: 'Unsaved',
                  icon: Icons.drafts_outlined,
                  bgColor: const Color(0xFFE3F2FD),
                  iconColor: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Main Content Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Consultation Queue Table
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConsultationQueueTable(),
                    const SizedBox(height: 24),
                    _buildResultsInbox(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right: Calendar
              Expanded(
                flex: 1,
                child: _buildCalendarWidget(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultQueue() {
    return const Center(child: Text('Consult Queue - Coming Soon'));
  }

  Widget _buildPatientList() {
    return const Center(child: Text('Patient List - Coming Soon'));
  }

  Widget _buildLabAvailability() {
    return const Center(child: Text('Lab Availability - Coming Soon'));
  }

  Widget _buildMedicineInventory() {
    return const Center(child: Text('Medicine Inventory - Coming Soon'));
  }

  // Removed _buildDoctorStatCard - Now using reusable StatCard widget

  Widget _buildConsultationQueueTable() {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'My Consultation Queue'),
          const SizedBox(height: 20),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                children: [
                  _buildTableHeader('QUEUE'),
                  _buildTableHeader('PATIENT'),
                  _buildTableHeader('AGE'),
                  _buildTableHeader('CHIEF COMPLAINT'),
                  _buildTableHeader('STATUS'),
                ],
              ),
              _buildQueueRow('Q-002', 'Maria Reyes', '7 F', 'Lagnat 2 araw', 'In Consultation', const Color(0xFFFF9800)),
              _buildQueueRow('Q-004', 'Ana Gomez', '28 F', 'Regular check-up', 'For Consultation', const Color(0xFFFBC02D)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
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

  TableRow _buildQueueRow(String queue, String patient, String age, String complaint, String status, Color statusColor) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            queue,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF5722),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            patient,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            age,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            complaint,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsInbox() {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Results Inbox'),
          const SizedBox(height: 16),
          _buildResultItem('CBC + Urinalysis', 'Cruz, J. - 24F', const Color(0xFF2196F3)),
          const SizedBox(height: 12),
          _buildResultItem('Chest X-ray', 'Cruz, M. - 56F', const Color(0xFF2196F3)),
          const SizedBox(height: 12),
          _buildResultItem('Urinalysis', 'Reyes, A. - 32M', const Color(0xFFFF9800)),
        ],
      ),
    );
  }

  Widget _buildResultItem(String test, String patient, Color actionColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.description_outlined, size: 20, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                test,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                patient,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: actionColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            actionColor == const Color(0xFF2196F3) ? 'Review' : 'Verify',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarWidget() {
    return CardContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () {},
              ),
              const Text(
                'March 2026',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((day) => SizedBox(
            width: 32,
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 12),
        ...List.generate(5, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final dayNum = weekIndex * 7 + dayIndex - 5;
                if (dayNum < 1 || dayNum > 31) {
                  return const SizedBox(width: 32, height: 32);
                }
                final isToday = dayNum == 9;
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xFF2196F3) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 12,
                        color: isToday ? Colors.white : Colors.black87,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Consult Queue';
      case 2:
        return 'Patient List';
      case 3:
        return 'Lab Availability';
      case 4:
        return 'Medicine Inventory';
      default:
        return 'Dashboard';
    }
  }
}
