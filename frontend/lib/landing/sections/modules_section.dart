import 'package:flutter/material.dart';
import '../widgets/module_card.dart';
import '../../core/utils/responsive.dart';

class ModulesSection extends StatelessWidget {
  const ModulesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : isTablet ? 40 : 80,
      ),
      child: Column(
        children: [
          Text(
            'OUR MODULES',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            'Comprehensive Healthcare Modules\nFor Modern Hospital Management',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 24 : isTablet ? 30 : 36,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            'Our unified platform combines essential hospital management systems into one seamless solution, designed to streamline every aspect of healthcare operations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),
          SizedBox(height: isMobile ? 32 : 48),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount;
              double childAspectRatio;
              
              if (screenWidth < 600) {
                crossAxisCount = 1;
                childAspectRatio = 1.6;
              } else if (screenWidth < 900) {
                crossAxisCount = 2;
                childAspectRatio = 1.4;
              } else if (screenWidth < 1200) {
                crossAxisCount = 3;
                childAspectRatio = 1.3;
              } else {
                crossAxisCount = 4;
                childAspectRatio = 1.2;
              }
              
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: isMobile ? 8 : 12,
                crossAxisSpacing: isMobile ? 8 : 12,
                childAspectRatio: childAspectRatio,
                children: const [
              ModuleCard(
                icon: Icons.person_outline,
                title: 'OpiDigims',
                subtitle: 'Outpatient Management',
                description: 'Digital outpatient management system for scheduling and queuing.',
                iconColor: Colors.blue,
              ),
              ModuleCard(
                icon: Icons.hotel,
                title: 'InPatient',
                subtitle: 'Hospital Admission',
                description: 'Management system for inpatient admissions and bed allocation.',
                iconColor: Colors.red,
              ),
              ModuleCard(
                icon: Icons.medication,
                title: 'PharmaTrack',
                subtitle: 'Pharmacy Inventory',
                description: 'Real-time pharmaceutical inventory tracking and management.',
                iconColor: Colors.red,
              ),
              ModuleCard(
                icon: Icons.inventory_2,
                title: 'MediStock',
                subtitle: 'Central Supply Office Inventory',
                description: 'Centralized management system for hospital supplies.',
                iconColor: Colors.blue,
              ),
              ModuleCard(
                icon: Icons.science,
                title: 'Labora-X',
                subtitle: 'Laboratory & Radiology',
                description: 'Request and result management for lab and radiology diagnostics.',
                iconColor: Colors.purple,
              ),
              ModuleCard(
                icon: Icons.favorite,
                title: 'Social Work',
                subtitle: 'Patient Assistance',
                description: 'Patient financial assistance and case evaluation system.',
                iconColor: Colors.pink,
              ),
              ModuleCard(
                icon: Icons.attach_money,
                title: 'Hospital Billing',
                subtitle: 'Billing System',
                description: 'Patient billing and financial management for hospital services.',
                iconColor: Colors.orange,
              ),
              ModuleCard(
                icon: Icons.restaurant,
                title: 'AutoKMS',
                subtitle: 'Kitchen Management',
                description: 'Automated kitchen management for patient meal services.',
                iconColor: Colors.blue,
              ),
            ],
          );
            },
          ),
        ],
      ),
    );
  }
}
