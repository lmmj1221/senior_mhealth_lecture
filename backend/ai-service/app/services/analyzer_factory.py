"""
Analyzer Factory - 환경에 따라 적절한 Analyzer 선택
로컬: Google AI SDK (API Key 사용)
GCP: Vertex AI (서비스 계정 사용)
"""

import os
import logging

logger = logging.getLogger(__name__)


def get_analyzer():
    """환경에 따라 적절한 Analyzer 인스턴스 반환"""

    # 명시적으로 USE_VERTEX_AI가 설정된 경우만 Vertex AI 사용
    if os.getenv('USE_VERTEX_AI', '').lower() == 'true':
        logger.info("USE_VERTEX_AI=true 감지 - Vertex AI Analyzer 강제 사용")
        from app.services.vertex_ai_analyzer import VertexAIAnalyzer
        return VertexAIAnalyzer()

    # Google AI API Key가 있으면 Google AI SDK 사용 (안정성 우선)
    elif os.getenv('GOOGLE_AI_API_KEY'):
        logger.info("Google AI API Key 감지 - Google AI Analyzer 사용")
        from app.services.google_ai_analyzer import GoogleAIAnalyzer
        return GoogleAIAnalyzer()

    # GCP 환경이지만 API Key가 없는 경우에만 Vertex AI 사용
    elif os.getenv('GCP_PROJECT_ID') or os.getenv('GOOGLE_CLOUD_PROJECT'):
        logger.info("GCP 프로젝트 감지 (API Key 없음) - Vertex AI Analyzer 사용")
        try:
            from app.services.vertex_ai_analyzer import VertexAIAnalyzer
            return VertexAIAnalyzer()
        except Exception as e:
            logger.error(f"Vertex AI 초기화 실패: {str(e)}")
            raise ValueError(f"Vertex AI 사용 불가: {str(e)}")

    else:
        raise ValueError("AI 서비스 설정이 없습니다. GOOGLE_AI_API_KEY 또는 GCP_PROJECT_ID가 필요합니다.")