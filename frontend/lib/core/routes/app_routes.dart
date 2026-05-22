import 'package:flutter/material.dart';
import '../../landing/pages/landing_page.dart';
import '../../landing/pages/change_password_page.dart';
import '../../landing/pages/mobile_login_page.dart';
import '../../landing/pages/mobile_home_page.dart';
import '../../modules/admin/pages/admin_dashboard.dart';
import '../../modules/opd/opd_doctor/pages/opd_doctor_dashboard.dart';
import '../../modules/opd/opd_nurse/pages/opd_nurse_dashboard.dart';
import '../../modules/opd/opd_clerk/pages/opd_clerk_dashboard.dart';
import '../../modules/opd/opd_clerk/pages/register_patient_page.dart';
import '../../modules/pharmacy/pharmacist/pages/pharmacist_dashboard.dart';
import '../../modules/billing/cashier/pages/cashier_dashboard.dart';
import '../../modules/billing/icd_coder/pages/icd_coder_dashboard.dart';
import '../../modules/billing/billing_staff/pages/billing_staff_dashboard.dart';
import '../../modules/lab/lab_staff/pages/lab_staff_dashboard.dart';
import '../../modules/lab/xray_staff/pages/xray_staff_dashboard.dart';
import '../../modules/ipd/ipd_doctor/pages/ipd_doctor_dashboard.dart';
import '../../modules/ipd/ipd_nurse/pages/ipd_nurse_dashboard.dart';
import '../../modules/ipd/attendant/pages/attendant_dashboard.dart';
import '../../modules/chief_nurse/pages/chief_nurse_dashboard.dart';
import '../../modules/kitchen/kitchen_staff/pages/kitchen_staff_dashboard.dart';
import '../../modules/medistock/csd_clerk/pages/csd_clerk_dashboard.dart';
import '../../modules/medistock/csd_staff/pages/csd_staff_dashboard.dart';
import '../../modules/socialwork/social_work/pages/social_worker_dashboard.dart';
import '../../modules/socialwork/mayors_office/pages/mayors_office_dashboard.dart';
import '../../modules/socialwork/congressman/pages/congressman_dashboard.dart';
import '../../modules/patient/pages/patient_dashboard.dart';

class AppRoutes {
  static const String mobileHome = '/mobile-home';
  static const String landing = '/';
  static const String login = '/login';
  static const String changePassword = '/change-password';
  static const String adminDashboard = '/admin/dashboard';
  static const String opdDoctorDashboard = '/opd/doctor/dashboard';
  static const String opdNurseDashboard = '/opd/nurse/dashboard';
  static const String opdClerkDashboard = '/opd/clerk/dashboard';
  static const String registerPatient = '/opd-clerk/register';
  static const String pharmacistDashboard = '/pharmacist/dashboard';
  static const String cashierDashboard = '/cashier/dashboard';
  static const String icdCoderDashboard = '/icd-coder/dashboard';
  static const String billingStaffDashboard = '/billing-staff/dashboard';
  static const String labStaffDashboard = '/lab-staff/dashboard';
  static const String xrayStaffDashboard = '/xray-staff/dashboard';
  static const String ipdDoctorDashboard = '/ipd/doctor/dashboard';
  static const String ipdNurseDashboard = '/ipd/nurse/dashboard';
  static const String ipdAttendantDashboard = '/ipd/attendant/dashboard';
  static const String chiefNurseDashboard = '/chief-nurse/dashboard';
  static const String kitchenStaffDashboard = '/kitchen-staff/dashboard';
  static const String csdClerkDashboard = '/csd-clerk/dashboard';
  static const String csdStaffDashboard = '/csd-staff/dashboard';
  static const String socialWorkerDashboard = '/social-worker/dashboard';
  static const String mayorsOfficeDashboard = '/mayors-office/dashboard';
  static const String congressmanDashboard = '/congressman/dashboard';
  static const String patientDashboard = '/patient/dashboard';
  
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      mobileHome: (context) => const MobileHomePage(),
      landing: (context) => const LandingPage(),
      login: (context) => const MobileLoginPage(),
      changePassword: (context) => const ChangePasswordPage(),
      adminDashboard: (context) => const AdminDashboard(),
      opdDoctorDashboard: (context) => const OpdDoctorDashboard(),
      opdNurseDashboard: (context) => const OpdNurseDashboard(),
      opdClerkDashboard: (context) => const OpdClerkDashboard(),
      registerPatient: (context) => const RegisterPatientPage(),
      pharmacistDashboard: (context) => const PharmacistDashboard(),
      cashierDashboard: (context) => const CashierDashboard(),
      icdCoderDashboard: (context) => const IcdCoderDashboard(),
      billingStaffDashboard: (context) => const BillingStaffDashboard(),
      labStaffDashboard: (context) => const LabStaffDashboard(),
      xrayStaffDashboard: (context) => const XrayStaffDashboard(),
      ipdDoctorDashboard: (context) => const IpdDoctorDashboard(),
      ipdNurseDashboard: (context) => const IpdNurseDashboard(),
      ipdAttendantDashboard: (context) => const IpdAttendantDashboard(),
      chiefNurseDashboard: (context) => const ChiefNurseDashboard(),
      kitchenStaffDashboard: (context) => const KitchenStaffDashboard(),
      csdClerkDashboard: (context) => const CsdClerkDashboard(),
      csdStaffDashboard: (context) => const CsdStaffDashboard(),
      socialWorkerDashboard: (context) => const SocialWorkerDashboard(),
      mayorsOfficeDashboard: (context) => const MayorsOfficeDashboard(),
      congressmanDashboard: (context) => const CongressmanDashboard(),
      patientDashboard: (context) => const PatientDashboard(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case mobileHome:
        return MaterialPageRoute(builder: (context) => const MobileHomePage());
      case landing:
        return MaterialPageRoute(builder: (context) => const LandingPage());
      case login:
        return MaterialPageRoute(builder: (context) => const MobileLoginPage());
      case changePassword:
        return MaterialPageRoute(builder: (context) => const ChangePasswordPage());
      case adminDashboard:
        return MaterialPageRoute(builder: (context) => const AdminDashboard());
      case opdDoctorDashboard:
        return MaterialPageRoute(builder: (context) => const OpdDoctorDashboard());
      case opdNurseDashboard:
        return MaterialPageRoute(builder: (context) => const OpdNurseDashboard());
      case opdClerkDashboard:
        final initialIndex = settings.arguments as int?;
        return MaterialPageRoute(
          builder: (context) => OpdClerkDashboard(initialIndex: initialIndex),
        );
      case registerPatient:
        return MaterialPageRoute(builder: (context) => const RegisterPatientPage());
      case pharmacistDashboard:
        return MaterialPageRoute(builder: (context) => const PharmacistDashboard());
      case cashierDashboard:
        return MaterialPageRoute(builder: (context) => const CashierDashboard());
      case icdCoderDashboard:
        return MaterialPageRoute(builder: (context) => const IcdCoderDashboard());
      case billingStaffDashboard:
        return MaterialPageRoute(builder: (context) => const BillingStaffDashboard());
      case labStaffDashboard:
        return MaterialPageRoute(builder: (context) => const LabStaffDashboard());
      case xrayStaffDashboard:
        return MaterialPageRoute(builder: (context) => const XrayStaffDashboard());
      case ipdDoctorDashboard:
        return MaterialPageRoute(builder: (context) => const IpdDoctorDashboard());
      case ipdNurseDashboard:
        return MaterialPageRoute(builder: (context) => const IpdNurseDashboard());
      case ipdAttendantDashboard:
        return MaterialPageRoute(builder: (context) => const IpdAttendantDashboard());
      case chiefNurseDashboard:
        return MaterialPageRoute(builder: (context) => const ChiefNurseDashboard());
      case kitchenStaffDashboard:
        return MaterialPageRoute(builder: (context) => const KitchenStaffDashboard());
      case csdClerkDashboard:
        return MaterialPageRoute(builder: (context) => const CsdClerkDashboard());
      case csdStaffDashboard:
        return MaterialPageRoute(builder: (context) => const CsdStaffDashboard());
      case socialWorkerDashboard:
        return MaterialPageRoute(builder: (context) => const SocialWorkerDashboard());
      case mayorsOfficeDashboard:
        return MaterialPageRoute(builder: (context) => const MayorsOfficeDashboard());
      case congressmanDashboard:
        return MaterialPageRoute(builder: (context) => const CongressmanDashboard());
      case patientDashboard:
        return MaterialPageRoute(builder: (context) => const PatientDashboard());
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
    }
  }
  
  /// Get dashboard route based on user role, deployment, and sub_role
  static String getDashboardRouteForRole(String? role, {String? deployment, String? subRole}) {
    final roleUpper = role?.toUpperCase();
    final deploymentUpper = deployment?.toUpperCase();
    final subRoleUpper = subRole?.toUpperCase();
    
    switch (roleUpper) {
      case 'ADMIN':
        return adminDashboard;
        
      case 'DOCTOR':
        // Check deployment for doctors
        if (deploymentUpper == 'OPD') {
          return opdDoctorDashboard;
        } else if (deploymentUpper == 'IPD') {
          return ipdDoctorDashboard;
        } else if (deploymentUpper == 'BOTH') {
          return opdDoctorDashboard; // Default to OPD for combined
        } else {
          // No deployment specified, default to OPD
          return opdDoctorDashboard;
        }
        
      case 'NURSE':
        // Check deployment and sub_role for nurses
        if (deploymentUpper == 'IPD' || deploymentUpper == 'BOTH') {
          // IPD nurses: check sub_role
          if (subRoleUpper == 'RN') {
            return ipdNurseDashboard; // RN dashboard
          } else if (subRoleUpper == 'ATTENDANT') {
            return ipdAttendantDashboard; // Attendant dashboard
          } else {
            // No sub_role specified for IPD, default to RN
            return ipdNurseDashboard;
          }
        } else if (deploymentUpper == 'OPD') {
          return opdNurseDashboard; // OPD nurse (no sub_role needed)
        } else {
          return opdNurseDashboard; // Default to OPD
        }
        
      case 'PHARMACIST':
        return pharmacistDashboard;
        
      case 'CASHIER':
        return cashierDashboard;
        
      case 'ICD_CODER':
      case 'ICD CODER':
        return icdCoderDashboard;
        
      case 'CLERK':
        // Check deployment for clerks
        if (deploymentUpper == 'OPD') {
          return opdClerkDashboard;
        } else if (deploymentUpper == 'CSD') {
          return csdClerkDashboard;
        } else {
          // No deployment specified, return to landing
          return landing;
        }
        
      case 'STAFF':
        // Route based on deployment for staff
        if (deploymentUpper == 'BILLING') {
          return billingStaffDashboard;
        } else if (deploymentUpper == 'KITCHEN') {
          return kitchenStaffDashboard;
        } else if (deploymentUpper == 'LAB') {
          return labStaffDashboard;
        } else if (deploymentUpper == 'XRAY') {
          return xrayStaffDashboard;
        } else if (deploymentUpper == 'CSD') {
          return csdStaffDashboard;
        } else {
          // Default for unspecified deployment
          return landing;
        }
        
      case 'SOCIAL_WORKER':
      case 'SOCIAL WORKER':
        return socialWorkerDashboard;
        
      case 'MAYORS_OFFICE':
      case 'MAYORS OFFICE':
      case "MAYOR'S OFFICE":
        return mayorsOfficeDashboard;
        
      case 'CONGRESSMAN':
        return congressmanDashboard;
        
      case 'PATIENT':
        return patientDashboard;
        
      case 'CHIEF_NURSE':
      case 'CHIEF NURSE':
        return chiefNurseDashboard;
        
      default:
        return landing;
    }
  }
}
