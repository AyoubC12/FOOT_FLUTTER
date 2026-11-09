"""Firebase Cloud Messaging adapter.

Credentials stay in Django settings / env. Flutter never receives them.
Sending is a no-op until FIREBASE_CREDENTIALS_FILE is configured.
"""

from django.conf import settings

from notifications.models import DeviceToken, NotificationLog


def send_to_user(*, user, title: str, body: str) -> int:
    credentials = getattr(settings, "FIREBASE_CREDENTIALS_FILE", "")
    if not credentials:
        NotificationLog.objects.create(
            user=user,
            title=title,
            body=body,
            success=False,
            error_code="fcm_not_configured",
        )
        return 0

    tokens = DeviceToken.objects.filter(user=user, is_active=True)
    # Wire firebase_admin here when credentials are provisioned.
    NotificationLog.objects.create(
        user=user,
        title=title,
        body=body,
        success=False,
        error_code="fcm_client_not_wired",
    )
    return tokens.count()
