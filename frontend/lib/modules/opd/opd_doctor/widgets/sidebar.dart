import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class DoctorSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const DoctorSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<DoctorSidebar> createState() => _DoctorSidebarState();
}

class _DoctorSidebarState extends State<DoctorSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('doctor-sidebar-${_isCollapsed}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        width: _isCollapsed ? 70 : 250,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Column(
        children: [
          // Logo and Title with Toggle Button
          Container(
            padding: EdgeInsets.fromLTRB(
              _isCollapsed ? 12 : 20,
              _isCollapsed ? 16 : 20,
              _isCollapsed ? 12 : 20,
              _isCollapsed ? 12 : 20,
            ),
            child: Column(
              children: [
                // Row with Logo and Burger Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo (left side)
                    if (!_isCollapsed)
                      Expanded(
                        child: AnimatedOpacity(
                          opacity: _isCollapsed ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Column(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Image.asset(
                                  'assets/logos/logo2.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.local_hospital,
                                      color: AppColors.primaryBlue,
                                      size: 60,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Burger Button (right side)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: IconButton(
                        key: ValueKey<bool>(_isCollapsed),
                        icon: Icon(
                          _isCollapsed ? Icons.menu : Icons.menu_open,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _isCollapsed = !_isCollapsed;
                          });
                        },
                        tooltip: _isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey[300], thickness: 1),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // OVERVIEW Section
                _buildSectionHeader('OVERVIEW'),
                _buildMenuItem(0, Icons.dashboard_outlined, 'Dashboard'),
                
                const SizedBox(height: 16),
                
                // PATIENTS Section
                _buildSectionHeader('PATIENTS'),
                _buildMenuItem(1, Icons.people_outline, 'Consult Queue'),
                _buildMenuItem(2, Icons.assignment_outlined, 'Patient List'),
                
                const SizedBox(height: 16),
                
                // REFERENCE Section
                _buildSectionHeader('REFERENCE'),
                _buildMenuItem(3, Icons.science_outlined, 'Lab Availability'),
                _buildMenuItem(4, Icons.medication_outlined, 'Medicine Inventory'),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    if (_isCollapsed) {
      return const SizedBox(height: 8);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = widget.selectedIndex == index;
    
    if (_isCollapsed) {
      return Tooltip(
        message: title,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            onPressed: () => widget.onItemSelected(index),
          ),
        ),
      );
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(
          icon,
          size: 22,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          child: Text(title),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () => widget.onItemSelected(index),
      ),
    );
  }

}
