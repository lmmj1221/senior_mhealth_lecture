"""
Google Cloud Speech-to-Text API를 사용한 음성 인식 서비스
음성 파일을 텍스트로 변환하여 정신건강 분석에 활용
"""

import os
import logging
import tempfile
from typing import Optional, Dict, Any
from pathlib import Path
import io

from google.cloud import speech
from pydantic import BaseModel, Field

# 로깅 설정
logger = logging.getLogger(__name__)


class AudioRequest(BaseModel):
    """음성 분석 요청 모델"""
    user_id: str = Field(default="anonymous", description="사용자 ID")
    session_id: str = Field(default="", description="세션 ID")
    language_code: str = Field(default="ko-KR", description="언어 코드")


class TranscriptionResponse(BaseModel):
    """음성 인식 응답 모델"""
    transcript: str = Field(..., description="변환된 텍스트")
    confidence: float = Field(..., ge=0, le=1, description="인식 신뢰도")
    language_code: str = Field(..., description="인식된 언어")
    audio_duration: Optional[float] = Field(None, description="오디오 길이(초)")


class SpeechToTextService:
    """Google Cloud Speech-to-Text 서비스"""

    def __init__(self):
        """Speech-to-Text 서비스 초기화"""
        # GCP 프로젝트 설정 확인
        project_id = os.getenv('GCP_PROJECT_ID')
        if not project_id:
            raise ValueError("GCP_PROJECT_ID 환경변수가 설정되지 않았습니다")

        # Speech-to-Text 클라이언트 초기화
        self.client = speech.SpeechClient()
        
        # 지원하는 오디오 형식
        self.supported_formats = {
            '.wav': speech.RecognitionConfig.AudioEncoding.LINEAR16,
            '.mp3': speech.RecognitionConfig.AudioEncoding.MP3,
            '.m4a': speech.RecognitionConfig.AudioEncoding.MP3,  # M4A는 MP3로 처리
            '.flac': speech.RecognitionConfig.AudioEncoding.FLAC,
            '.ogg': speech.RecognitionConfig.AudioEncoding.OGG_OPUS,
        }

        logger.info("Google Cloud Speech-to-Text 서비스 초기화 완료")

    async def transcribe_audio(
        self, 
        audio_content: bytes, 
        filename: str,
        request: AudioRequest
    ) -> TranscriptionResponse:
        """음성 파일을 텍스트로 변환"""
        try:
            logger.info(f"음성 인식 시작 - 사용자: {request.user_id}, 파일: {filename}")

            # 파일 확장자 확인
            file_extension = Path(filename).suffix.lower()
            if file_extension not in self.supported_formats:
                raise ValueError(f"지원하지 않는 오디오 형식: {file_extension}")

            # 오디오 설정
            audio = speech.RecognitionAudio(content=audio_content)
            
            # 인식 설정
            config = speech.RecognitionConfig(
                encoding=self.supported_formats[file_extension],
                sample_rate_hertz=16000,  # 기본값, 실제로는 자동 감지됨
                language_code=request.language_code,
                enable_automatic_punctuation=True,  # 자동 구두점 추가
                enable_word_time_offsets=False,     # 단어별 시간 정보 비활성화
                model="latest_long",                # 긴 오디오용 모델
                use_enhanced=True,                  # 향상된 모델 사용
            )

            # Speech-to-Text API 호출
            response = self.client.recognize(config=config, audio=audio)

            # 결과 처리
            if not response.results:
                logger.warning("음성 인식 결과가 없습니다")
                return TranscriptionResponse(
                    transcript="",
                    confidence=0.0,
                    language_code=request.language_code
                )

            # 가장 신뢰도가 높은 결과 선택
            best_result = response.results[0]
            best_alternative = best_result.alternatives[0]

            transcript = best_alternative.transcript
            confidence = best_alternative.confidence

            logger.info(f"음성 인식 완료 - 신뢰도: {confidence:.2f}, 텍스트 길이: {len(transcript)}")

            return TranscriptionResponse(
                transcript=transcript,
                confidence=confidence,
                language_code=request.language_code
            )

        except Exception as e:
            logger.error(f"음성 인식 중 오류 발생: {str(e)}")
            raise Exception(f"음성 인식 실패: {str(e)}")

    async def transcribe_long_audio(
        self, 
        audio_content: bytes, 
        filename: str,
        request: AudioRequest
    ) -> TranscriptionResponse:
        """긴 오디오 파일 처리 (비동기 인식)"""
        try:
            logger.info(f"긴 오디오 인식 시작 - 파일: {filename}")

            # 파일 확장자 확인
            file_extension = Path(filename).suffix.lower()
            if file_extension not in self.supported_formats:
                raise ValueError(f"지원하지 않는 오디오 형식: {file_extension}")

            # Cloud Storage에 임시 업로드가 필요한 경우
            # 현재는 간단한 동기 처리로 구현
            return await self.transcribe_audio(audio_content, filename, request)

        except Exception as e:
            logger.error(f"긴 오디오 인식 중 오류: {str(e)}")
            raise Exception(f"긴 오디오 인식 실패: {str(e)}")

    def get_supported_formats(self) -> list[str]:
        """지원하는 오디오 형식 목록 반환"""
        return list(self.supported_formats.keys())

    def validate_audio_file(self, filename: str, file_size: int) -> Dict[str, Any]:
        """오디오 파일 유효성 검사"""
        file_extension = Path(filename).suffix.lower()
        
        validation_result = {
            "is_valid": True,
            "errors": [],
            "warnings": []
        }

        # 파일 형식 확인
        if file_extension not in self.supported_formats:
            validation_result["is_valid"] = False
            validation_result["errors"].append(f"지원하지 않는 파일 형식: {file_extension}")

        # 파일 크기 확인 (10MB 제한)
        max_size = 10 * 1024 * 1024  # 10MB
        if file_size > max_size:
            validation_result["is_valid"] = False
            validation_result["errors"].append(f"파일 크기가 너무 큽니다: {file_size / (1024*1024):.1f}MB (최대 10MB)")

        # 경고사항
        if file_size > 5 * 1024 * 1024:  # 5MB 이상
            validation_result["warnings"].append("큰 파일은 처리 시간이 오래 걸릴 수 있습니다")

        return validation_result
