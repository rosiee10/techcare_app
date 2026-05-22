import 'package:flutter/material.dart';
import 'dart:async';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  int _currentIndex = 0;
  Timer? _timer;
  final List<String> _imagePaths = [
    'assets/logos/logo.png',
    'assets/logos/pchlogo.png',
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _imagePaths.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2196F3).withOpacity(0.05),
            Colors.white,
            const Color(0xFF2196F3).withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 600 ? 20 : MediaQuery.of(context).size.width < 1024 ? 40 : 100,
        vertical: MediaQuery.of(context).size.width < 600 ? 40 : 80,
      ),
      child: MediaQuery.of(context).size.width < 768
          ? Column(
              children: [
                _buildTextContent(context),
                const SizedBox(height: 40),
                _buildImageCarousel(),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildTextContent(context)),
                const SizedBox(width: 80),
                Expanded(child: _buildImageCarousel()),
              ],
            ),
    );
  }

  Widget _buildTextContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Transform healthcare\nwith a unified digital\nplatform',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 32 : isTablet ? 42 : 56,
            fontWeight: FontWeight.w900,
            height: 1.15,
            color: const Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'A comprehensive solution connecting all hospital departments for seamless operations, improved efficiency, and enhanced patient care at Plaridel Community Hospital.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 14 : isTablet ? 15 : 17,
            color: Colors.grey[600],
            height: 1.7,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildImageCarousel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth < 600 ? screenWidth * 0.8 : screenWidth < 1024 ? 350.0 : 450.0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: imageSize,
          width: imageSize,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: Image.asset(
                _imagePaths[_currentIndex],
                key: ValueKey<int>(_currentIndex),
                height: imageSize,
                width: imageSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: imageSize,
                    width: imageSize,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _imagePaths.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentIndex == index ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentIndex == index
                    ? const Color(0xFF2196F3)
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
