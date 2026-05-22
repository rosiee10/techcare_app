# Chief Nurse Module - Frontend

This module is organized into separate sub-modules for collaborative development.

## Folder Structure

```
frontend/lib/modules/chief_nurse/
├── pages/
│   ├── chief_nurse_dashboard.dart      # Main dashboard page
│   ├── pharmacy_purchase_request_page.dart  # YOUR PHARMACY PAGE
│   └── ... (other pages)
├── services/
│   ├── chief_nurse_service.dart       # Core nursing services (Ward, Bed, Nurse)
│   └── chief_nurse_pharmacy_service.dart  # YOUR PHARMACY SERVICES - ADD NEW FEATURES HERE!
├── widgets/
│   ├── pharmacy_purchase_request/     # YOUR PHARMACY WIDGETS
│   └── ... (other widgets)
└── README.md                          # This file
```

## ✅ Your Pharmacy Code (ISOLATED)

**Status:** All your pharmacy code is now isolated!

### Your Files:
- **Service:** `services/chief_nurse_pharmacy_service.dart` - All pharmacy API calls
- **Page:** `pages/pharmacy_purchase_request_page.dart` - Already updated to use new service
- **Widgets:** `widgets/pharmacy_purchase_request/` - Your pharmacy UI components

### Your API Endpoints (All Working):
- `GET /api/chief-nurse/pharmacy/purchase-requests/`
- `GET /api/chief-nurse/pharmacy/purchase-requests/stats/`
- `POST /api/chief-nurse/pharmacy/purchase-requests/<id>/approve/`
- `GET /api/chief-nurse/pharmacy/dashboard/`

## Collaboration Rules

- **You:** Only edit files in your pharmacy-related files:
  - `services/chief_nurse_pharmacy_service.dart`
  - `pages/pharmacy_purchase_request_page.dart`
  - `widgets/pharmacy_purchase_request/`
  
- **Classmate:** Will have their own kitchen-related files

- **Core nursing files (`chief_nurse_service.dart`):** Leave it alone - contains ward/bed/nurse features only

## How to Add New Pharmacy Features

1. **Add API method** to `chief_nurse_pharmacy_service.dart`:
```dart
Future<Map<String, dynamic>> yourNewFeature() async {
  // Call your backend endpoint
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/chief-nurse/pharmacy/your-endpoint/'),
    ...
  );
}
```

2. **Use in your page** (already set up):
```dart
final _pharmacyService = ChiefNursePharmacyService();
final result = await _pharmacyService.yourNewFeature();
```

3. **Backend:** Add new views to `backend/apps/chief_nurse/pharmacy/views.py`

## Backend-Frontend Connection

```
Frontend (chief_nurse_pharmacy_service.dart)
    ↓ API Call
Backend Main URLs (chief_nurse/urls.py) - includes pharmacy/
    ↓ include()
Backend Pharmacy URLs (chief_nurse/pharmacy/urls.py)
    ↓ calls
Backend Pharmacy Views (chief_nurse/pharmacy/views.py)
```

All connections are verified and working! You can safely add new pharmacy features without affecting your classmate's work.
