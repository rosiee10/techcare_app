"""
Export all PSGC data to JSON for Flutter offline database.
Run this after importing PSGC data to generate the bundled JSON file.
"""
import json
import os
from django.core.management.base import BaseCommand
from apps.ph_locations.models import Region, Province, City, Barangay


class Command(BaseCommand):
    help = 'Export all PSGC data to JSON for Flutter offline database'

    def add_arguments(self, parser):
        parser.add_argument(
            '--output',
            type=str,
            default='frontend/assets/data/ph_address_data.json',
            help='Output file path'
        )

    def handle(self, *args, **options):
        output_path = options['output']
        
        # Ensure directory exists
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        self.stdout.write('Exporting PSGC data...')
        
        # Export regions
        regions = list(Region.objects.values('code', 'name'))
        self.stdout.write(f'  {len(regions)} regions')
        
        # Export provinces
        provinces = list(Province.objects.values('code', 'name', 'region__code'))
        # Rename region__code to region_code
        provinces = [
            {
                'code': p['code'],
                'name': p['name'],
                'region_code': p['region__code']
            }
            for p in provinces
        ]
        self.stdout.write(f'  {len(provinces)} provinces')
        
        # Export cities
        cities = list(City.objects.values('code', 'name', 'province__code'))
        # Rename province__code to province_code
        cities = [
            {
                'code': c['code'],
                'name': c['name'],
                'province_code': c['province__code']
            }
            for c in cities
        ]
        self.stdout.write(f'  {len(cities)} cities')
        
        # Export barangays (this may take a while)
        self.stdout.write('  Exporting barangays (this may take a while)...')
        barangays = []
        batch_size = 10000
        total = Barangay.objects.count()
        
        for i in range(0, total, batch_size):
            batch = Barangay.objects.values('code', 'name', 'city__code')[i:i+batch_size]
            for b in batch:
                barangays.append({
                    'code': b['code'],
                    'name': b['name'],
                    'city_code': b['city__code']
                })
            self.stdout.write(f'    Exported {min(i + batch_size, total)}/{total} barangays')
        
        self.stdout.write(f'  {len(barangays)} barangays total')
        
        # Create the output structure
        data = {
            'regions': regions,
            'provinces': provinces,
            'cities': cities,
            'barangays': barangays,
            'meta': {
                'total_regions': len(regions),
                'total_provinces': len(provinces),
                'total_cities': len(cities),
                'total_barangays': len(barangays),
            }
        }
        
        # Write to file
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        # Get file size
        file_size = os.path.getsize(output_path)
        file_size_mb = file_size / (1024 * 1024)
        
        self.stdout.write(self.style.SUCCESS(
            f'\nSuccessfully exported PSGC data to {output_path}'
        ))
        self.stdout.write(f'File size: {file_size_mb:.2f} MB')
        self.stdout.write(self.style.SUCCESS(
            'Copy this file to frontend/assets/data/ for offline support'
        ))
