from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'suppliers', views.PharmacySupplierViewSet)
router.register(r'locations', views.PharmacyLocationViewSet)
router.register(r'medicines', views.PharmacyMedicineViewSet)
router.register(r'stock-batches', views.PharmacyStockBatchViewSet)
router.register(r'inventory-balances', views.PharmacyInventoryBalanceViewSet, basename='inventory-balance')
router.register(r'purchase-requests', views.PharmacyPurchaseRequestViewSet)
router.register(r'goods-receipts', views.PharmacyGoodsReceiptViewSet)
router.register(r'charge-slips', views.PharmacyChargeSlipViewSet)
router.register(r'dispense-receipts', views.PharmacyDispenseReceiptViewSet)
router.register(r'inventory-adjustments', views.PharmacyInventoryAdjustmentViewSet)
router.register(r'opd-prescriptions', views.OpdPrescriptionViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard-stats/', views.DashboardStatsView.as_view(), name='dashboard-stats'),
    path('dispense/', views.DispenseMedicineView.as_view(), name='dispense-medicine'),
    path('transfer-to-cart/', views.TransferToCartView.as_view(), name='transfer-to-cart'),
    path('dispense-from-cart/', views.DispenseFromCartView.as_view(), name='dispense-from-cart'),
    path('low-stock-alerts/', views.LowStockAlertsView.as_view(), name='low-stock-alerts'),
    path('expiry-alerts/', views.ExpiryAlertsView.as_view(), name='expiry-alerts'),
    path('confirm-delivery/', views.confirm_delivery, name='confirm-delivery'),
    path('forecasting-stats/', views.ForecastingStatsView.as_view(), name='forecasting-stats'),
    path('reports/', views.PharmacyReportView.as_view(), name='pharmacy-reports'),
    path('reports/weekly-inventory/', views.WeeklyInventoryReportView.as_view(), name='weekly-inventory-report'),
    path('reports/quarterly-dispensing/', views.QuarterlyDispensingReportView.as_view(), name='quarterly-dispensing-report'),
    path('reports/monthly-dispensing/', views.MonthlyDispensingReportView.as_view(), name='monthly-dispensing-report'),
    path('medicines/<int:medicine_id>/batches/', views.get_medicine_batches, name='medicine-batches'),
]
