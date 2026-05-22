import 'package:flutter/material.dart';


class CurvedBackgroundContainer extends StatelessWidget {
  
  final String imagePath;
  
  final double imageHeight;
  
  final Widget child;
  
  final bool showBackButton;
  
  final VoidCallback? onBackPressed;

  final double overlapOffset;
  
  /// The border radius of the curved top corners
  final double borderRadius;
  
  /// The padding inside the white container
  final EdgeInsets padding;
  
  /// Gradient colors to use if image fails to load
  final List<Color>? fallbackGradientColors;

  /// Optional widget to overlay on the background image (e.g., logos)
  final Widget? imageOverlay;

  const CurvedBackgroundContainer({
    Key? key,
    required this.imagePath,
    required this.child,
    this.imageHeight = 280,
    this.showBackButton = true,
    this.onBackPressed,
    this.overlapOffset = 50,
    this.borderRadius = 60,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
    this.fallbackGradientColors,
    this.imageOverlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultGradientColors = [
      Colors.pink.shade300,
      Colors.purple.shade400,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Background Image with Back Button
        Stack(
          children: [
            // Background Image
            Image.asset(
              imagePath,
              height: imageHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: imageHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: fallbackGradientColors ?? defaultGradientColors,
                    ),
                  ),
                );
              },
            ),
            // Logo Overlay
            Positioned(
              bottom: 55,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // TechCare Logo
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logos/logo.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[200],
                              child: const Icon(Icons.local_hospital, color: Colors.blue),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Center Text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'TECHCARE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Plaridel Community Hospital',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Hospital Logo
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logos/pchlogo.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[200],
                              child: const Icon(Icons.account_balance, color: Colors.green),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Back Button
            if (showBackButton)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: onBackPressed ?? () => Navigator.pop(context),
                  ),
                ),
              ),
          ],
        ),
        
        // Content Section with Curved Top
        Transform.translate(
          offset: Offset(0, -overlapOffset),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
