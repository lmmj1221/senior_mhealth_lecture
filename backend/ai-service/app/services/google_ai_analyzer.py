"""
Google AI SDK 기반 텍스트 분석 서비스
Google AI의 Gemini 모델을 API 키로 직접 사용
"""

import os
import json
import logging
from typing import Dict, Any
from datetime import datetime
import google.generativeai as genai
from pydantic import BaseModel, Field

# 로깅 설정
logger = logging.getLogger(__name__)


class AnalysisRequest(BaseModel):
    """분석 요청 모델"""
    text: str = Field(..., description="분석할 텍스트")
    user_id: str = Field(default="anonymous", description="사용자 ID")
    session_id: str = Field(default="", description="세션 ID")
    enable_speaker_separation: bool = Field(default=True, description="화자 분리 활성화 여부")
    analyze_senior_only: bool = Field(default=True, description="시니어 발화만 분석")


class AnalysisResponse(BaseModel):
    """분석 응답 모델"""
    depression_score: float = Field(..., ge=0, le=100, description="우울도 점수 (0-100)")
    anxiety_score: float = Field(..., ge=0, le=100, description="불안도 점수 (0-100)")
    cognitive_score: float = Field(..., ge=0, le=100, description="인지기능 점수 (0-100)")
    emotional_state: str = Field(..., description="감정 상태")
    key_concerns: list[str] = Field(default_factory=list, description="주요 우려사항")
    recommendations: list[str] = Field(default_factory=list, description="권장사항")
    confidence: float = Field(..., ge=0, le=1, description="분석 신뢰도")
    timestamp: str = Field(default_factory=lambda: datetime.utcnow().isoformat())
    speaker_separation_applied: bool = Field(default=False, description="화자 분리 적용 여부")
    analyzed_text_type: str = Field(default="full", description="분석된 텍스트 유형: full, senior, guardian")
    original_text: str = Field(default="", description="원본 텍스트")
    senior_text: str = Field(default="", description="시니어 발화 텍스트")
    guardian_text: str = Field(default="", description="보호자 발화 텍스트")


class GoogleAIAnalyzer:
    """Google AI SDK를 사용한 텍스트 기반 정신건강 분석기"""

    def __init__(self):
        """Google AI 분석기 초기화"""
        # API 키 설정
        api_key = os.getenv('GOOGLE_AI_API_KEY') or os.getenv('GEMINI_API_KEY')

        if not api_key:
            raise ValueError("GOOGLE_AI_API_KEY 환경변수가 설정되지 않았습니다")

        # Google AI SDK 초기화
        genai.configure(api_key=api_key)

        # Gemini 모델 초기화
        # Gemini 2.0 Flash Experimental 사용 (최신 모델)
        model_name = os.getenv('MODEL_NAME', 'gemini-2.0-flash-exp')

        # 사용 가능한 모델 목록 (Gemini 2.0 우선)
        valid_models = [
            'gemini-2.0-flash-exp',  # Gemini 2.0 Flash Experimental (1순위)
            'gemini-1.5-pro',        # Fallback to 1.5 Pro (2순위)
            'gemini-1.5-flash',      # Final fallback (3순위)
            'gemini-exp-1206'        # Experimental model (4순위)
        ]

        # 환경변수로 지정된 모델이 유효한지 확인
        if model_name not in valid_models:
            logger.warning(f"지정된 모델 {model_name}이 유효하지 않음. gemini-2.0-flash-exp 사용")
            model_name = 'gemini-2.0-flash-exp'

        # 모델 초기화 시도
        model_initialized = False
        for attempt_model in [model_name] + valid_models:
            if model_initialized:
                break
            try:
                self.model = genai.GenerativeModel(
                    model_name=attempt_model,
                    generation_config={
                        'temperature': 0.7,
                        'top_p': 0.95,
                        'top_k': 40,
                        'max_output_tokens': 1024,
                    }
                )
                logger.info(f"Google AI 모델 초기화 완료: {attempt_model}")
                model_initialized = True
                break
            except Exception as e:
                logger.warning(f"모델 {attempt_model} 초기화 실패: {str(e)}")
                continue

        if not model_initialized:
            raise ValueError("Google AI 모델 초기화 실패: 사용 가능한 모델이 없습니다")

        # 화자 분리 서비스 초기화
        try:
            from app.services.speaker_separator import SpeakerSeparator
            self.speaker_separator = SpeakerSeparator()
            logger.info("화자 분리 서비스 초기화 완료")
        except ImportError:
            self.speaker_separator = None
            logger.warning("화자 분리 서비스를 사용할 수 없습니다")

        logger.info(f"Google AI Gemini 분석기 초기화 완료 - 모델: {model_name}")

    def _build_prompt(self, text: str) -> str:
        """분석용 프롬프트 생성"""
        return f"""
        다음 텍스트를 분석하여 사용자의 정신건강 상태를 평가해주세요.
        화자 구분 없이 전체 내용을 종합적으로 분석합니다.

        분석할 텍스트:
        "{text}"

        다음 형식의 JSON으로 응답해주세요:
        {{
            "depression_score": 0-100 사이의 우울증 가능성 점수,
            "anxiety_score": 0-100 사이의 불안 수준 점수,
            "cognitive_score": 0-100 사이의 인지기능 점수 (100이 정상),
            "emotional_state": "현재 감정 상태 요약 (예: 안정적, 불안정, 우울, 희망적)",
            "key_concerns": ["주요 우려사항 리스트"],
            "recommendations": ["권장사항 리스트"],
            "confidence": 0-1 사이의 분석 신뢰도
        }}

        주의사항:
        - 의학적 진단이 아닌 참고 지표임을 명시
        - 점수는 객관적이고 일관되게 평가
        - 텍스트가 짧거나 애매한 경우 confidence를 낮게 설정
        - 한국어로 응답
        """

    async def analyze_mental_health(self, request: AnalysisRequest) -> AnalysisResponse:
        """텍스트 기반 정신건강 분석 수행 (비동기)"""
        try:
            logger.info(f"분석 시작 - 사용자: {request.user_id}, 텍스트 길이: {len(request.text)}")

            # 원본 텍스트 저장
            original_text = request.text
            text_to_analyze = request.text
            analyzed_text_type = "full"
            senior_text = ""
            guardian_text = ""
            speaker_separation_applied = False

            # 화자 분리 처리
            if request.enable_speaker_separation and self.speaker_separator:
                try:
                    logger.info("화자 분리 시작...")
                    separation_result = self.speaker_separator.separate_speakers(request.text)

                    if separation_result:
                        speaker_separation_applied = True
                        senior_text = separation_result.senior_text
                        guardian_text = separation_result.guardian_text

                        logger.info(f"화자 분리 완료 - 방법: {separation_result.separation_method}, "
                                  f"신뢰도: {separation_result.confidence}")

                        # 시니어 발화만 분석 옵션이 활성화되고 시니어 텍스트가 있는 경우
                        if request.analyze_senior_only and senior_text:
                            text_to_analyze = senior_text
                            analyzed_text_type = "senior"
                            logger.info("시니어 발화만 분석합니다")
                        elif not senior_text and guardian_text:
                            # 시니어 발화가 없고 보호자 발화만 있는 경우
                            logger.warning("시니어 발화가 없습니다. 전체 텍스트를 분석합니다")
                            analyzed_text_type = "full"
                except Exception as e:
                    logger.error(f"화자 분리 실패: {str(e)}")
                    # 화자 분리 실패 시 전체 텍스트 분석

            # 텍스트가 너무 짧은 경우
            if len(text_to_analyze) < 10:
                return AnalysisResponse(
                    depression_score=0,
                    anxiety_score=0,
                    cognitive_score=100,
                    emotional_state="분석 불가",
                    key_concerns=["텍스트가 너무 짧음"],
                    recommendations=["더 자세한 설명이 필요합니다"],
                    confidence=0.1,
                    speaker_separation_applied=speaker_separation_applied,
                    analyzed_text_type=analyzed_text_type,
                    original_text=original_text,
                    senior_text=senior_text,
                    guardian_text=guardian_text
                )

            # 프롬프트 생성
            prompt = self._build_prompt(text_to_analyze)

            # Google AI Gemini API 호출
            response = await self.model.generate_content_async(prompt)

            # 응답 파싱
            result = self._parse_response(response.text)

            # 화자 분리 정보 추가
            result.speaker_separation_applied = speaker_separation_applied
            result.analyzed_text_type = analyzed_text_type
            result.original_text = original_text
            result.senior_text = senior_text
            result.guardian_text = guardian_text

            logger.info(f"분석 완료 - 신뢰도: {result.confidence}, 분석 유형: {analyzed_text_type}")
            return result

        except Exception as e:
            logger.error(f"분석 중 오류 발생: {str(e)}")
            # 오류 시 기본값 반환
            return AnalysisResponse(
                depression_score=0,
                anxiety_score=0,
                cognitive_score=100,
                emotional_state="분석 실패",
                key_concerns=["분석 중 오류 발생"],
                recommendations=["시스템 관리자에게 문의하세요"],
                confidence=0
            )

    def _parse_response(self, response_text: str) -> AnalysisResponse:
        """Gemini 응답을 AnalysisResponse로 파싱"""
        try:
            # JSON 부분만 추출
            start_idx = response_text.find('{')
            end_idx = response_text.rfind('}') + 1

            if start_idx == -1 or end_idx == 0:
                raise ValueError("JSON 형식을 찾을 수 없습니다")

            json_str = response_text[start_idx:end_idx]
            data = json.loads(json_str)

            # AnalysisResponse 모델로 변환
            return AnalysisResponse(
                depression_score=float(data.get('depression_score', 0)),
                anxiety_score=float(data.get('anxiety_score', 0)),
                cognitive_score=float(data.get('cognitive_score', 100)),
                emotional_state=str(data.get('emotional_state', '알 수 없음')),
                key_concerns=list(data.get('key_concerns', [])),
                recommendations=list(data.get('recommendations', [])),
                confidence=float(data.get('confidence', 0.5))
            )

        except Exception as e:
            logger.error(f"응답 파싱 오류: {str(e)}")
            # 파싱 실패 시 기본값
            return AnalysisResponse(
                depression_score=0,
                anxiety_score=0,
                cognitive_score=100,
                emotional_state="파싱 오류",
                key_concerns=["응답 형식 오류"],
                recommendations=["재시도 필요"],
                confidence=0
            )

    def analyze_mental_health_sync(self, request: AnalysisRequest) -> AnalysisResponse:
        """동기 버전의 정신건강 분석"""
        try:
            logger.info(f"동기 분석 시작 - 사용자: {request.user_id}")

            # 텍스트가 너무 짧은 경우
            if len(request.text) < 10:
                return AnalysisResponse(
                    depression_score=0,
                    anxiety_score=0,
                    cognitive_score=100,
                    emotional_state="분석 불가",
                    key_concerns=["텍스트가 너무 짧음"],
                    recommendations=["더 자세한 설명이 필요합니다"],
                    confidence=0.1
                )

            # 프롬프트 생성
            prompt = self._build_prompt(request.text)

            # Google AI Gemini API 호출 (동기)
            response = self.model.generate_content(prompt)

            # 응답 파싱
            result = self._parse_response(response.text)

            logger.info(f"동기 분석 완료 - 신뢰도: {result.confidence}")
            return result

        except Exception as e:
            logger.error(f"동기 분석 중 오류: {str(e)}")
            return AnalysisResponse(
                depression_score=0,
                anxiety_score=0,
                cognitive_score=100,
                emotional_state="분석 실패",
                key_concerns=["분석 중 오류 발생"],
                recommendations=["시스템 관리자에게 문의하세요"],
                confidence=0
            )

    def start_chat_session(self):
        """대화형 세션 시작 (Google AI의 채팅 기능 활용)"""
        chat = self.model.start_chat()
        logger.info("Google AI 채팅 세션 시작")
        return chat

    def analyze_with_context(self, text: str, chat_session) -> AnalysisResponse:
        """이전 대화 컨텍스트를 고려한 분석"""
        try:
            prompt = self._build_prompt(text)
            response = chat_session.send_message(prompt)
            return self._parse_response(response.text)
        except Exception as e:
            logger.error(f"컨텍스트 분석 중 오류: {str(e)}")
            return AnalysisResponse(
                depression_score=0,
                anxiety_score=0,
                cognitive_score=100,
                emotional_state="분석 실패",
                key_concerns=["분석 중 오류 발생"],
                recommendations=["시스템 관리자에게 문의하세요"],
                confidence=0
            )
