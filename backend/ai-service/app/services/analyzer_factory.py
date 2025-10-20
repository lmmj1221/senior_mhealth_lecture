"""
Analyzer Factory - Google AI Studio API 통일 사용
모든 환경에서 Google AI Studio API 사용 (API Key 기반)
"""

import os
import logging

logger = logging.getLogger(__name__)


def get_analyzer():
    """Google AI Studio API Analyzer 인스턴스 반환"""

    # Google AI API Key 확인
    api_key = os.getenv('GOOGLE_AI_API_KEY') or os.getenv('GEMINI_API_KEY')

    if not api_key:
        raise ValueError("Google AI API Key가 필요합니다. GOOGLE_AI_API_KEY 또는 GEMINI_API_KEY 환경변수를 설정하세요.")

    logger.info("Google AI Studio API Analyzer 사용")
    from app.services.google_ai_analyzer import GoogleAIAnalyzer
    return GoogleAIAnalyzer()
