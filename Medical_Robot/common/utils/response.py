from rest_framework.response import Response

def unified_response(success, message, data=None, errors=None, status=200):
    """
    Standardizes all API responses to follow a consistent structure.
    """
    return Response(
        {
            "success": success,
            "message": message,
            "data": data,
            "errors": errors,
        },
        status=status
    )
