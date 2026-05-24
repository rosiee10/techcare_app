from django.db import models


class LabCategoryMaintenance(models.Model):
    lab_code = models.CharField(max_length=20, primary_key=True)
    lab_desc = models.CharField(max_length=120, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    emergency = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    display_order = models.IntegerField(default=0)

    class Meta:
        db_table = 'lab_category_maintenance'
        managed = False
        ordering = ['display_order']

    def __str__(self):
        return f"{self.lab_code} - {self.lab_desc}"


class LabDetailMaintenance(models.Model):
    lab_keyctr = models.AutoField(primary_key=True)
    lab_code = models.ForeignKey(
        LabCategoryMaintenance,
        db_column='lab_code',
        on_delete=models.CASCADE,
        related_name='details',
    )
    test_type_id = models.BigIntegerField(blank=True, null=True)
    lab_detail_desc = models.CharField(max_length=150, blank=True, null=True)
    amt_wph = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    amt_woph = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    amt_emergency = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    is_active = models.BooleanField(default=True)
    is_requestable = models.BooleanField(default=True)
    is_available = models.BooleanField(default=True)
    display_order = models.IntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'lab_detail_maintenance'
        managed = False
        ordering = ['lab_code', 'display_order']

    def __str__(self):
        return self.lab_detail_desc or ''


class DiagnosisMaintenance(models.Model):
    code = models.CharField(max_length=20, primary_key=True)
    description = models.TextField()
    hospital_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    prof_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    trail = models.CharField(max_length=120, blank=True, null=True)
    updated_trail = models.CharField(max_length=120, blank=True, null=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'diagnosis_maintenance'
        managed = False
        ordering = ['code']

    def __str__(self):
        return f"{self.code} - {self.description}"
