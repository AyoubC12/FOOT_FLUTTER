from rest_framework.throttling import UserRateThrottle


class ChatRateThrottle(UserRateThrottle):
    scope = "chat"


class ChatDailyThrottle(UserRateThrottle):
    scope = "chat_day"
