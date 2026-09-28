"""Thin wrapper around the Anthropic API. AI is entirely optional: every
public function raises AINotConfigured if no API key is set, which the
views turn into a clean 503 response rather than a crash."""

from django.conf import settings


class AINotConfigured(Exception):
    pass


class AIRequestFailed(Exception):
    pass


def _client():
    if not settings.ANTHROPIC_API_KEY:
        raise AINotConfigured('AI features are not configured on this server.')
    import anthropic
    return anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY, timeout=settings.AI_REQUEST_TIMEOUT_SECONDS)


def _complete(system_prompt, user_content, max_tokens=None):
    content = user_content[: settings.AI_MAX_INPUT_CHARS]
    client = _client()
    try:
        response = client.messages.create(
            model=settings.AI_MODEL,
            max_tokens=max_tokens or settings.AI_MAX_OUTPUT_TOKENS,
            system=system_prompt,
            messages=[{'role': 'user', 'content': content}],
        )
    except Exception as exc:  # noqa: BLE001 - surfaced as a clean API error
        raise AIRequestFailed(str(exc)) from exc

    return ''.join(block.text for block in response.content if getattr(block, 'type', None) == 'text').strip()


def generate_title(content):
    return _complete(
        'You generate a short, specific diary entry title (max 8 words). '
        'Reply with ONLY the title, no quotes, no punctuation at the end.',
        content,
        max_tokens=30,
    )


def generate_summary(content):
    return _complete(
        'You summarize a personal diary entry in 2-3 concise sentences, '
        'written in third person past tense. Reply with ONLY the summary.',
        content,
        max_tokens=200,
    )


def generate_tags(content):
    raw = _complete(
        'You suggest up to 5 short topical tags for a diary entry. '
        'Reply with ONLY a comma-separated list of lowercase single-word or short tags, nothing else.',
        content,
        max_tokens=60,
    )
    return [tag.strip().lstrip('#') for tag in raw.split(',') if tag.strip()][:5]


def improve_writing(content):
    return _complete(
        'You lightly improve the grammar, clarity and flow of a personal diary entry '
        'without changing its meaning, tone or the facts described. Reply with ONLY the improved text.',
        content,
        max_tokens=settings.AI_MAX_OUTPUT_TOKENS,
    )
