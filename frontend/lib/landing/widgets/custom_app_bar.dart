import 'package:flutter/material.dart';
import '../../core/utils/colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/reusable_widgets/buttons.dart';
import '../../core/reusable_widgets/page_title.dart';
import '../modals/login_modal.dart';
import '../pages/mobile_login_page.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onHomePressed;
  final VoidCallback? onModulesPressed;
  final VoidCallback? onAboutPressed;
  final VoidCallback? onContactPressed;
  final String activeSection;
  final ValueChanged<bool>? onMenuToggle;

  const CustomAppBar({
    super.key,
    this.onLoginPressed,
    this.onHomePressed,
    this.onModulesPressed,
    this.onAboutPressed,
    this.onContactPressed,
    this.activeSection = 'Home',
    this.onMenuToggle,
  });

  @override
  State<CustomAppBar> createState() => CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(72);
}

class CustomAppBarState extends State<CustomAppBar> with SingleTickerProviderStateMixin {
  bool _isMenuExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool get isMenuExpanded => _isMenuExpanded;

  void _toggleMenu() {
    setState(() {
      _isMenuExpanded = !_isMenuExpanded;
      if (_isMenuExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      widget.onMenuToggle?.call(_isMenuExpanded);
    });
  }

  void _showLoginModal(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      // Show full-page login on mobile
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MobileLoginPage(),
        ),
      );
    } else {
      // Show modal on tablet/desktop
      showDialog(
        context: context,
        builder: (context) => const LoginModal(),
      );
    }
  }

  Widget buildMobileMenu() {
    return SizeTransition(
      sizeFactor: _animation,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, thickness: 1),
            _buildMobileMenuItem(
              icon: Icons.home_outlined,
              label: 'Home',
              isActive: widget.activeSection == 'Home',
              onTap: () {
                _toggleMenu();
                widget.onHomePressed?.call();
              },
            ),
            _buildMobileMenuItem(
              icon: Icons.apps_outlined,
              label: 'Modules',
              isActive: widget.activeSection == 'Modules',
              onTap: () {
                _toggleMenu();
                widget.onModulesPressed?.call();
              },
            ),
            _buildMobileMenuItem(
              icon: Icons.info_outline,
              label: 'About',
              isActive: widget.activeSection == 'About',
              onTap: () {
                _toggleMenu();
                widget.onAboutPressed?.call();
              },
            ),
            _buildMobileMenuItem(
              icon: Icons.contact_mail_outlined,
              label: 'Contact',
              isActive: widget.activeSection == 'Contact',
              onTap: () {
                _toggleMenu();
                widget.onContactPressed?.call();
              },
            ),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GradientButton(
                text: 'Login',
                onPressed: () {
                  _toggleMenu();
                  _showLoginModal(context);
                },
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);
    
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: isDesktop ? 90 : 70,
      titleSpacing: isDesktop ? 40 : 16,
      title: Row(
        children: [
          Image.asset(
            'assets/logos/logo.png',
            height: isMobile ? 40 : (isDesktop ? 65 : 50),
            width: isMobile ? 40 : (isDesktop ? 65 : 50),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.local_hospital, color: AppColors.primaryBlue, size: 60);
            },
          ),
          SizedBox(width: isMobile ? 8 : 10),
          PageTitle(
            title: 'TECHCARE',
            titleFontSize: isMobile ? 16 : 20,
            addShadow: false,
            textAlign: TextAlign.start,
          ),
          const Spacer(),
          // Mobile: Show hamburger menu
          if (isMobile) ...[
            IconButton(
              icon: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _animation,
                color: const Color(0xFF2196F3),
                size: 28,
              ),
              onPressed: _toggleMenu,
              tooltip: 'Menu',
            ),
            const SizedBox(width: 8),
          ],
          // Tablet & Desktop: Show navigation buttons
          if (!isMobile) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavButton(
                  label: 'Home',
                  onPressed: widget.onHomePressed ?? () {},
                  isActive: widget.activeSection == 'Home',
                ),
                SizedBox(width: isDesktop ? 32 : 16),
                _NavButton(
                  label: 'Modules',
                  onPressed: widget.onModulesPressed ?? () {},
                  isActive: widget.activeSection == 'Modules',
                ),
                SizedBox(width: isDesktop ? 32 : 16),
                _NavButton(
                  label: 'About',
                  onPressed: widget.onAboutPressed ?? () {},
                  isActive: widget.activeSection == 'About',
                ),
                SizedBox(width: isDesktop ? 32 : 16),
                _NavButton(
                  label: 'Contact',
                  onPressed: widget.onContactPressed ?? () {},
                  isActive: widget.activeSection == 'Contact',
                ),
              ],
            ),
            const Spacer(),
            GradientButton(
              text: 'Login',
              onPressed: () => _showLoginModal(context),
            ),
            SizedBox(width: isDesktop ? 40 : 16),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileMenuItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2196F3).withOpacity(0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? const Color(0xFF2196F3) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? const Color(0xFF2196F3) : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  const _NavButton({
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF2196F3) : Colors.black87,
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            width: label.length * 8.0,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF2196F3) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
