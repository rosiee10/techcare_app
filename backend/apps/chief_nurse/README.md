# Chief Nurse Module

This module is organized into separate sub-modules for collaborative development.

## Folder Structure

```
backend/apps/chief_nurse/
├── __init__.py
├── models.py              # Shared models (if any)
├── views.py               # Main chief nurse views (Ward, Bed, Nurse management)
├── urls.py                # Main URL router (imports from sub-modules)
├── tests.py               # Tests
├── README.md              # This file
├── pharmacy/              # YOUR CODE (Pharmacy Section) - TRANSFERRED
│   ├── __init__.py
│   ├── views.py           # Your pharmacy API views (fully functional)
│   └── urls.py            # Your pharmacy routes
└── kitchen/               # CLASSMATE'S CODE (Kitchen Section)
    ├── __init__.py
    ├── views.py           # Classmate adds kitchen API views here
    └── urls.py            # Classmate adds kitchen routes here
```

## ✅ Your Pharmacy Code (TRANSFERRED)

**Status:** All your pharmacy code has been moved to `pharmacy/` folder!

- **Location:** `backend/apps/chief_nurse/pharmacy/`
- **Views file:** `pharmacy/views.py` - Contains all your functional pharmacy code
- **URLs file:** `pharmacy/urls.py` - All routes configured

### Your Pharmacy Endpoints:
- `GET /api/chief-nurse/pharmacy/dashboard/` - Dashboard stats
- `GET /api/chief-nurse/pharmacy/purchase-requests/` - List all purchase requests
- `GET /api/chief-nurse/pharmacy/purchase-requests/stats/` - Get PR statistics
- `POST /api/chief-nurse/pharmacy/purchase-requests/<id>/approve/` - Approve/reject PR

### Old endpoints still work (backward compatible):
- `GET /api/chief-nurse/pharmacy/purchase-requests/` (original route)
- `POST /api/chief-nurse/pharmacy/purchase-requests/<id>/approve/` (original route)

## Classmate's Code (Kitchen)

- **Location:** `backend/apps/chief_nurse/kitchen/`
- **Views file:** `kitchen/views.py` - Classmate adds kitchen API views here
- **URLs file:** `kitchen/urls.py` - Classmate adds kitchen routes here
- **API prefix:** `/api/chief-nurse/kitchen/`

Example endpoints for classmate:
- `GET /api/chief-nurse/kitchen/dashboard/`
- `GET /api/chief-nurse/kitchen/orders/`

## Collaboration Rules

- **You:** Only edit files in `pharmacy/` folder - your code is now isolated there
- **Classmate:** Only edit files in `kitchen/` folder
- **Main folder (`chief_nurse/`):** Leave it alone - contains core nursing features only
- **No conflicts:** You and your classmate can work simultaneously without overwriting each other's code!

## What Was Transferred

All your pharmacy purchase request functionality:
1. `get_pharmacy_purchase_requests` - Fetch all PRs with items
2. `approve_pharmacy_purchase_request` - Approve/reject PRs
3. `get_pharmacy_pr_stats` - Dashboard statistics
4. `PharmacyDashboardView` - Dashboard API view

## Next Steps for You

1. Add any **NEW** pharmacy features to `pharmacy/views.py`
2. Add any **NEW** routes to `pharmacy/urls.py`
3. Test that your existing endpoints still work
4. Your code is now safe from classmate's changes!
