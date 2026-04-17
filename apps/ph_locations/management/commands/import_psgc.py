import json
import os
from django.core.management.base import BaseCommand
from apps.ph_locations.models import Region, Province, City, Barangay

class Command(BaseCommand):
    help = 'Import Philippine Standard Geographic Code (PSGC) data from JSON files'

    def add_arguments(self, parser):
        parser.add_argument(
            '--data-dir',
            type=str,
            help='Path to directory containing PSGC JSON files',
            default='c:/Users/Johnf/OneDrive/Desktop/techcare_app/philippines-region-province-citymun-brgy-7d266cd3fe452ddd1aa46fcc8ec4f9d4b3e3fcfd/json'
        )

    def handle(self, *args, **options):
        data_dir = options['data_dir']
        
        self.stdout.write(self.style.SUCCESS(f'Importing PSGC data from: {data_dir}'))
        
        # Import order matters due to foreign keys
        self.import_regions(os.path.join(data_dir, 'refregion.json'))
        self.import_provinces(os.path.join(data_dir, 'refprovince.json'))
        self.import_cities(os.path.join(data_dir, 'refcitymun.json'))
        self.import_barangays(os.path.join(data_dir, 'refbrgy.json'))
        
        self.stdout.write(self.style.SUCCESS('PSGC data import completed successfully!'))

    def import_regions(self, file_path):
        self.stdout.write('Importing regions...')
        
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Handle RECORDS wrapper or direct array
        records = data.get('RECORDS', data) if isinstance(data, dict) else data
        
        regions = []
        for item in records:
            regions.append(Region(
                code=item['regCode'],
                name=item['regDesc']
            ))
        
        Region.objects.bulk_create(regions, ignore_conflicts=True)
        self.stdout.write(self.style.SUCCESS(f'  Imported {len(regions)} regions'))

    def import_provinces(self, file_path):
        self.stdout.write('Importing provinces...')
        
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Handle RECORDS wrapper or direct array
        records = data.get('RECORDS', data) if isinstance(data, dict) else data
        
        # Create a map of region codes to region objects
        region_map = {r.code: r for r in Region.objects.all()}
        
        provinces = []
        for item in records:
            region = region_map.get(item['regCode'])
            if region:
                provinces.append(Province(
                    code=item['provCode'],
                    name=item['provDesc'],
                    region=region
                ))
        
        Province.objects.bulk_create(provinces, ignore_conflicts=True)
        self.stdout.write(self.style.SUCCESS(f'  Imported {len(provinces)} provinces'))

    def import_cities(self, file_path):
        self.stdout.write('Importing cities and municipalities...')
        
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Handle RECORDS wrapper or direct array
        records = data.get('RECORDS', data) if isinstance(data, dict) else data
        
        # Create a map of province codes to province objects
        province_map = {p.code: p for p in Province.objects.all()}
        
        cities = []
        for item in records:
            province = province_map.get(item['provCode'])
            if province:
                # Check if it's a city (usually has 'City' in the name)
                is_city = 'city' in item['citymunDesc'].lower()
                
                cities.append(City(
                    code=item['citymunCode'],
                    name=item['citymunDesc'],
                    province=province,
                    is_city=is_city
                ))
        
        City.objects.bulk_create(cities, ignore_conflicts=True)
        self.stdout.write(self.style.SUCCESS(f'  Imported {len(cities)} cities/municipalities'))

    def import_barangays(self, file_path):
        self.stdout.write('Importing barangays...')
        
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Handle RECORDS wrapper or direct array
        records = data.get('RECORDS', data) if isinstance(data, dict) else data
        
        # Create a map of city codes to city objects
        city_map = {c.code: c for c in City.objects.all()}
        
        barangays = []
        batch_size = 1000
        count = 0
        
        for item in records:
            city = city_map.get(item['citymunCode'])
            if city:
                barangays.append(Barangay(
                    code=item['brgyCode'],
                    name=item['brgyDesc'],
                    city=city
                ))
                
                # Process in batches to avoid memory issues
                if len(barangays) >= batch_size:
                    Barangay.objects.bulk_create(barangays, ignore_conflicts=True)
                    count += len(barangays)
                    barangays = []
                    self.stdout.write(f'  ... imported {count} barangays')
        
        # Process remaining
        if barangays:
            Barangay.objects.bulk_create(barangays, ignore_conflicts=True)
            count += len(barangays)
        
        self.stdout.write(self.style.SUCCESS(f'  Imported {count} barangays'))
