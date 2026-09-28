from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import AIRequest
from .services import AINotConfigured, AIRequestFailed, generate_summary, generate_tags, generate_title, improve_writing


class BaseAIView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_scope = 'ai'
    request_type = None
    ai_setting_flag = None  # e.g. 'ai_allow_summary'

    def post(self, request):
        content = (request.data.get('content') or '').strip()
        if not content:
            return Response(
                {'detail': 'content is required.', 'error_code': 'CONTENT_REQUIRED'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        profile = request.user.profile
        if not profile.ai_enabled or (self.ai_setting_flag and not getattr(profile, self.ai_setting_flag)):
            return Response(
                {'detail': 'AI assistant is disabled for this account.', 'error_code': 'AI_DISABLED'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            result = self.call_ai(content)
        except AINotConfigured:
            return Response(
                {'detail': 'AI assistant is not available.', 'error_code': 'AI_NOT_CONFIGURED'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        except AIRequestFailed:
            AIRequest.objects.create(
                owner=request.user, request_type=self.request_type,
                input_length=len(content), output_length=0, status='error',
            )
            return Response(
                {'detail': 'The AI request failed. Please try again.', 'error_code': 'AI_REQUEST_FAILED'},
                status=status.HTTP_502_BAD_GATEWAY,
            )

        AIRequest.objects.create(
            owner=request.user, request_type=self.request_type,
            input_length=len(content), output_length=len(str(result)), status='success',
        )
        return Response(self.format_result(result))

    def call_ai(self, content):
        raise NotImplementedError

    def format_result(self, result):
        raise NotImplementedError


class TitleView(BaseAIView):
    request_type = 'title'

    def call_ai(self, content):
        return generate_title(content)

    def format_result(self, result):
        return {'title': result}


class SummaryView(BaseAIView):
    request_type = 'summary'
    ai_setting_flag = 'ai_allow_summary'

    def call_ai(self, content):
        return generate_summary(content)

    def format_result(self, result):
        return {'summary': result}


class TagsView(BaseAIView):
    request_type = 'tags'

    def call_ai(self, content):
        return generate_tags(content)

    def format_result(self, result):
        return {'tags': result}


class ImproveView(BaseAIView):
    request_type = 'improve'
    ai_setting_flag = 'ai_allow_improve'

    def call_ai(self, content):
        return improve_writing(content)

    def format_result(self, result):
        return {'improved_content': result}
