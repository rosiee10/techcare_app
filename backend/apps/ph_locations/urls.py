from django.urls import path
from . import views

urlpatterns = [
    path('regions/', views.RegionListView.as_view(), name='region-list'),
    path('provinces/', views.ProvinceListView.as_view(), name='province-list'),
    path('cities/', views.CityListView.as_view(), name='city-list'),
    path('barangays/', views.BarangayListView.as_view(), name='barangay-list'),
    path('provinces/by-region/<str:region_code>/', views.ProvincesByRegionView.as_view(), name='provinces-by-region'),
    path('cities/by-province/<str:province_code>/', views.CitiesByProvinceView.as_view(), name='cities-by-province'),
    path('barangays/by-city/<str:city_code>/', views.BarangaysByCityView.as_view(), name='barangays-by-city'),
    path('search/', views.AddressSearchView.as_view(), name='address-search'),
]
