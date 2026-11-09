from rest_framework.throttling import UserRateThrottle


class TacticsSuggestThrottle(UserRateThrottle):
    scope = "tactics_suggest"
