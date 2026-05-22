import 'package:flutter/material.dart';
import '../widgets/image_carousel.dart';
import '../../core/utils/responsive.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : isTablet ? 40 : 80,
      ),
      child: isMobile
          ? Column(
              children: [
                _buildTextContent(context, isMobile, isTablet),
                const SizedBox(height: 32),
                _buildImageCarousel(isMobile),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildImageCarousel(isMobile)),
                SizedBox(width: isTablet ? 40 : 60),
                Expanded(child: _buildTextContent(context, isMobile, isTablet)),
              ],
            ),
    );
  }

  Widget _buildImageCarousel(bool isMobile) {
    return ImageCarousel(
      imagePaths: const [
        'assets/images/about/pch2.jpg',
        'assets/images/about/pch3.jpg',
        'assets/images/about/pch4.jpg',
        'assets/images/about/pch5.jpg',
        'assets/images/about/pch6.jpg',
        'assets/images/about/pch7.jpg',
        'assets/images/about/opd.jpg',
      ],
      height: isMobile ? 250 : 350,
      autoPlay: true,
      autoPlayInterval: const Duration(seconds: 4),
      showIndicators: true,
    );
  }

  Widget _buildTextContent(BuildContext context, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'ABOUT US',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: Colors.blue[700],
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Text(
          'A dedicated team with the core\nmission to help',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 24 : isTablet ? 30 : 36,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            height: 1.3,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 24),
        Text(
          'Plaridel Community Hospital is committed to delivering excellence in healthcare through innovative digital solutions that enhance patient care and streamline hospital operations.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: Colors.grey[700],
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Our integrated platform connects all departments, enabling seamless communication, efficient workflows, and improved patient outcomes across the entire healthcare journey.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: Colors.grey[700],
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
