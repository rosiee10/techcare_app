from django.apps import AppConfig


class SocialworkConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.socialwork'
    label = 'socialwork'
    
    def ready(self):
        """Register signals when the app is ready"""
        import apps.socialwork.signals
