class FootballProviderError(Exception):
    def __init__(self, message: str, *, status_code: int = 502, errors: dict | None = None):
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.errors = errors or {}


class FootballConfigError(FootballProviderError):
    def __init__(self) -> None:
        super().__init__(
            "Football data provider is not configured.",
            status_code=503,
        )


class FootballRateLimitError(FootballProviderError):
    def __init__(self, retry_after: int | None = None) -> None:
        super().__init__(
            "Football data provider rate limit reached. Try again shortly.",
            status_code=429,
        )
        self.retry_after = retry_after
