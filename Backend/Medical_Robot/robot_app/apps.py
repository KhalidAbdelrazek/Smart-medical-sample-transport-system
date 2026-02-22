from django.apps import AppConfig


class RobotAppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'robot_app'

    def ready(self):
        import robot_app.signals