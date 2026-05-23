from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    MedistockCategoryViewSet, MedistockUnitViewSet, MedistockDepartmentViewSet,
    MedistockLocationViewSet, MedistockSupplyItemViewSet, MedistockInventoryBalanceViewSet,
    MedistockGoodsReceiptViewSet, MedistockSupplyRequestViewSet,
    MedistockSupplyRequestItemViewSet, MedistockTransactionViewSet,
    MedistockReportViewSet, MedistockPatientSearchViewSet,
    MedistockVStockSummaryViewSet, MedistockVLowStockViewSet,
    MedistockVExpiryAlertViewSet, MedistockVMonthlyConsumptionViewSet,
    MedistockVPendingRequestViewSet, MedistockVCartItemViewSet, MedistockVStockCardViewSet,
    MedistockPurchaseRequestViewSet, MedistockSupplyBatchViewSet,
)

router = DefaultRouter()
router.register(r'categories', MedistockCategoryViewSet, basename='medistock-category')
router.register(r'units', MedistockUnitViewSet, basename='medistock-unit')
router.register(r'departments', MedistockDepartmentViewSet, basename='medistock-department')
router.register(r'locations', MedistockLocationViewSet, basename='medistock-location')
router.register(r'supply-items', MedistockSupplyItemViewSet, basename='medistock-supply-item')
router.register(r'supply-batches', MedistockSupplyBatchViewSet, basename='medistock-supply-batch')
router.register(r'purchase-requests', MedistockPurchaseRequestViewSet, basename='medistock-purchase-request')
router.register(r'inventory-balance', MedistockInventoryBalanceViewSet, basename='medistock-inventory-balance')
router.register(r'goods-receipts', MedistockGoodsReceiptViewSet, basename='medistock-goods-receipt')
router.register(r'patients', MedistockPatientSearchViewSet, basename='medistock-patient-search')
router.register(r'supply-requests', MedistockSupplyRequestViewSet, basename='medistock-supply-request')
router.register(r'supply-request-items', MedistockSupplyRequestItemViewSet, basename='medistock-supply-request-item')
router.register(r'transactions', MedistockTransactionViewSet, basename='medistock-transaction')
router.register(r'reports', MedistockReportViewSet, basename='medistock-report')
router.register(r'views/stock-summary', MedistockVStockSummaryViewSet, basename='medistock-v-stock-summary')
router.register(r'views/low-stock', MedistockVLowStockViewSet, basename='medistock-v-low-stock')
router.register(r'views/expiry-alerts', MedistockVExpiryAlertViewSet, basename='medistock-v-expiry-alert')
router.register(r'views/monthly-consumption', MedistockVMonthlyConsumptionViewSet, basename='medistock-v-monthly-consumption')
router.register(r'views/pending-requests', MedistockVPendingRequestViewSet, basename='medistock-v-pending-request')
router.register(r'views/cart-items', MedistockVCartItemViewSet, basename='medistock-v-cart-item')
router.register(r'views/stock-card', MedistockVStockCardViewSet, basename='medistock-v-stock-card')

urlpatterns = [
    path('', include(router.urls)),
]
