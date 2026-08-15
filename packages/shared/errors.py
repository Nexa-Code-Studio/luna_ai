class BaseAppError(Exception):
    """Base domain exception for all application errors."""

    def __init__(self, message: str, code: str = "INTERNAL_ERROR"):
        super().__init__(message)
        self.message = message
        self.code = code


class NotFoundError(BaseAppError):
    def __init__(self, message: str = "Resource not found"):
        super().__init__(message, code="NOT_FOUND")


class ValidationError(BaseAppError):
    def __init__(self, message: str = "Validation failed"):
        super().__init__(message, code="VALIDATION_ERROR")


class ProviderUnavailableError(BaseAppError):
    def __init__(self, provider: str):
        super().__init__(
            f"Provider '{provider}' is currently unavailable",
            code="PROVIDER_UNAVAILABLE",
        )
