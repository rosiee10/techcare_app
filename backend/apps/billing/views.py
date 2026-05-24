from django.db.models import Q
from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import DiagnosisMaintenance, LabDetailMaintenance, LabCategoryMaintenance
from .serializers import DiagnosisMaintenanceSerializer, LabDetailSerializer, LabCategorySerializer


class DiagnosisMaintenanceViewSet(viewsets.ModelViewSet):
    serializer_class = DiagnosisMaintenanceSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        queryset = DiagnosisMaintenance.objects.all().order_by('code')
        search = self.request.query_params.get('search', None)
        if search:
            queryset = queryset.filter(
                Q(code__icontains=search) | Q(description__icontains=search)
            )
        return queryset

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class LabCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = LabCategorySerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None
    queryset = LabCategoryMaintenance.objects.filter(is_active=True).order_by('display_order')


class LabDetailViewSet(viewsets.ModelViewSet):
    serializer_class = LabDetailSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        queryset = LabDetailMaintenance.objects.select_related('lab_code').filter(is_active=True)
        lab_code = self.request.query_params.get('lab_code', None)
        search = self.request.query_params.get('search', None)
        if lab_code:
            queryset = queryset.filter(lab_code=lab_code)
        if search:
            queryset = queryset.filter(
                Q(lab_detail_desc__icontains=search) |
                Q(lab_code__lab_desc__icontains=search)
            )
        return queryset.order_by('lab_code', 'display_order')

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.is_active = False
        instance.save(update_fields=['is_active'])
        return Response(status=status.HTTP_204_NO_CONTENT)
