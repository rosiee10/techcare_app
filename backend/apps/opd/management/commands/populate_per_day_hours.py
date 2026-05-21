"""
Management command to populate per-day hours from days_open using default hours.
"""
from django.core.management.base import BaseCommand
from apps.opd.models import OpdServiceSchedule


class Command(BaseCommand):
    help = 'Populate per-day hours columns using default hours (07:00-17:00)'

    def handle(self, *args, **options):
        from datetime import time
        count = 0
        default_open = time(7, 0)
        default_close = time(17, 0)

        for service in OpdServiceSchedule.objects.all():
            if not service.days_open:
                continue

            days_open_list = [d.strip() for d in service.days_open.split(',')]

            for day in days_open_list:
                if day == 'Mon':
                    service.mon_open = default_open
                    service.mon_close = default_close
                elif day == 'Tue':
                    service.tue_open = default_open
                    service.tue_close = default_close
                elif day == 'Wed':
                    service.wed_open = default_open
                    service.wed_close = default_close
                elif day == 'Thu':
                    service.thu_open = default_open
                    service.thu_close = default_close
                elif day == 'Fri':
                    service.fri_open = default_open
                    service.fri_close = default_close
                elif day == 'Sat':
                    service.sat_open = default_open
                    service.sat_close = default_close

            service.save()
            count += 1
            self.stdout.write(
                f'Migrated {service.service}: days={days_open_list}, hours={default_open}-{default_close}'
            )

        self.stdout.write(self.style.SUCCESS(f'Successfully migrated {count} services'))
