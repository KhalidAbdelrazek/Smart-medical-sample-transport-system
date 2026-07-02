from rest_framework.views import exception_handler
from .utils.response import unified_response
from rest_framework import status

def custom_exception_handler(exc, context):
    """
    Custom exception handler to return error responses in the unified format.
    """
    # Call DRF's default exception handler first to get the standard error response.
    response = exception_handler(exc, context)

    if response is not None:
        return unified_response(
            success=False,
            message="An error occurred",
            data=None,
            errors=response.data,
            status=response.status_code
        )

    return response
