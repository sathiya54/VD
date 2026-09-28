from rest_framework.views import exception_handler
from rest_framework.response import Response


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)

    if response is None:
        return response

    error_code = getattr(exc, 'default_code', 'error')
    if isinstance(response.data, dict) and 'error_code' in response.data:
        error_code = response.data['error_code']

    message = _extract_message(response.data)

    response.data = {
        'success': False,
        'message': message,
        'error_code': error_code.upper() if isinstance(error_code, str) else 'ERROR',
    }
    return response


def _extract_message(data):
    if isinstance(data, dict):
        if 'detail' in data:
            return str(data['detail'])
        for key, value in data.items():
            if key == 'error_code':
                continue
            if isinstance(value, list) and value:
                return f"{key}: {value[0]}"
            return f"{key}: {value}"
    if isinstance(data, list) and data:
        return str(data[0])
    return 'An error occurred.'
