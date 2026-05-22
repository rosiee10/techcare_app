from rest_framework import generics, filters
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.db.models import Q
from .models import Region, Province, City, Barangay
from .serializers import RegionSerializer, ProvinceSerializer, CitySerializer, BarangaySerializer

class RegionListView(generics.ListAPIView):
    queryset = Region.objects.all()
    serializer_class = RegionSerializer
    permission_classes = [AllowAny]

class ProvinceListView(generics.ListAPIView):
    serializer_class = ProvinceSerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'code']
    
    def get_queryset(self):
        queryset = Province.objects.all()
        region_code = self.request.query_params.get('region', None)
        if region_code:
            queryset = queryset.filter(region__code=region_code)
        return queryset

class CityListView(generics.ListAPIView):
    serializer_class = CitySerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'code']
    
    def get_queryset(self):
        queryset = City.objects.all()
        province_code = self.request.query_params.get('province', None)
        if province_code:
            queryset = queryset.filter(province__code=province_code)
        return queryset

class BarangayListView(generics.ListAPIView):
    serializer_class = BarangaySerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'code']
    pagination_class = None  # Disable pagination to return all barangays
    
    def get_queryset(self):
        queryset = Barangay.objects.all()
        city_code = self.request.query_params.get('city', None)
        if city_code:
            queryset = queryset.filter(city__code=city_code)
        return queryset

class ProvincesByRegionView(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request, region_code):
        provinces = Province.objects.filter(region__code=region_code)
        serializer = ProvinceSerializer(provinces, many=True)
        return Response(serializer.data)

class CitiesByProvinceView(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request, province_code):
        cities = City.objects.filter(province__code=province_code)
        serializer = CitySerializer(cities, many=True)
        return Response(serializer.data)

class BarangaysByCityView(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request, city_code):
        barangays = Barangay.objects.filter(city__code=city_code)
        serializer = BarangaySerializer(barangays, many=True)
        return Response(serializer.data)

class AddressSearchView(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request):
        query = request.query_params.get('q', '')
        if not query or len(query) < 2:
            return Response({'error': 'Query must be at least 2 characters'}, status=400)
        
        # Search across all levels
        regions = Region.objects.filter(name__icontains=query)[:5]
        provinces = Province.objects.filter(name__icontains=query)[:10]
        cities = City.objects.filter(name__icontains=query)[:15]
        barangays = Barangay.objects.filter(name__icontains=query)[:20]
        
        return Response({
            'regions': RegionSerializer(regions, many=True).data,
            'provinces': ProvinceSerializer(provinces, many=True).data,
            'cities': CitySerializer(cities, many=True).data,
            'barangays': BarangaySerializer(barangays, many=True).data,
        })
