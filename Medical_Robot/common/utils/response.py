from rest_framework.response import Response

def format_error_message(e):
    """
    Extracts a clean, user-friendly error message from an exception.
    Handles DRF ValidationError details (dict or list) and other exceptions.
    """
    if hasattr(e, 'detail'):
        detail = e.detail
        if isinstance(detail, dict):
            # If it's a dict, get the first error message
            if detail:
                first_key = next(iter(detail))
                first_error = detail[first_key]
                if isinstance(first_error, list) and len(first_error) > 0:
                    return str(first_error[0])
                return str(first_error)
            return "Validation error"
        elif isinstance(detail, list) and len(detail) > 0:
            return str(detail[0])
        return str(detail)
    
    # Handle standard exceptions
    if hasattr(e, 'args') and len(e.args) > 0:
        return str(e.args[0])
        
    return str(e)

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
