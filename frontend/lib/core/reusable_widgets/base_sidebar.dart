import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SidebarMenuItem {
  final int index;
  final IconData icon;
  final String title;

  const SidebarMenuItem({
    required this.index,
    required this.icon,
    required this.title,
  });
}

class SidebarSection {
  final String title;
  final List<SidebarMenuItem> items;

  const SidebarSection({
    required this.title,
    required this.items,
  });
}

class BaseSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<SidebarSection> sections;
  final String? logoAssetPath;

  const BaseSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.sections,
    this.logoAssetPath = 'assets/logos/logo.png',
  });

  @override
  State<BaseSidebar> createState() => _BaseSidebarState();
}

class _BaseSidebarState extends State<BaseSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Container(
      key: ValueKey('sidebar-${_isCollapsed}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        width: _isCollapsed ? 70 : 250,
        decoration: BoxDecoration(
          color: theme.sidebarBackground,
          border: Border(
            right: BorderSide(color: theme.cardBorder, width: 1),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(theme),
            Divider(height: 1, color: theme.cardBorder, thickness: 1),
            _buildMenuItems(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _isCollapsed ? 12 : 20,
        _isCollapsed ? 16 : 20,
        _isCollapsed ? 12 : 20,
        _isCollapsed ? 12 : 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isCollapsed)
            Expanded(
              child: AnimatedOpacity(
                opacity: _isCollapsed ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: Image.asset(
                      widget.logoAssetPath!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.local_hospital,
                          color: theme.buttonPrimary,
                          size: 50,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
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
                color: theme.buttonPrimary,
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
    );
  }

  Widget _buildMenuItems(AppThemeData theme) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (var i = 0; i < widget.sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _buildSectionHeader(widget.sections[i].title, theme),
            ...widget.sections[i].items.map((item) => _buildMenuItem(
                  item.index,
                  item.icon,
                  item.title,
                  theme,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppThemeData theme) {
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
          color: theme.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title, AppThemeData theme) {
    final isSelected = widget.selectedIndex == index;

    if (_isCollapsed) {
      return Tooltip(
        message: title,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : theme.sidebarText,
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
        gradient: isSelected
          ? const LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(
          icon,
          size: 22,
          color: isSelected ? Colors.white : theme.sidebarText,
        ),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : theme.textPrimary,
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
