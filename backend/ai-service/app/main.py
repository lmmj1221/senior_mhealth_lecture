"""
Senior MHealth AI Service - Simplified Version
Gemini API 기반 텍스트 분석 서비스
"""

import os
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, status, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from dotenv import load_dotenv

from app.services.vertex_ai_analyzer import (
    VertexAIAnalyzer,
    AnalysisRequest,
    AnalysisResponse
)
from app.services.speech_to_text import (
    SpeechToTextService,
    AudioRequest,
    TranscriptionResponse
)

# 환경변수 로드
load_dotenv()

# 로깅 설정
logging.basicConfig(
    level=getattr(logging, os.getenv("LOG_LEVEL", "INFO")),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 전역 서비스 인스턴스
analyzer = None
stt_service = None


class HealthResponse(BaseModel):
    """헬스체크 응답 모델"""
    status: str
    service: str
    version: str


@asynccontextmanager
async def lifespan(app: FastAPI):
    """애플리케이션 생명주기 관리"""
    global analyzer, stt_service

    # 시작 시
    logger.info("AI 서비스 시작 중...")
    try:
        analyzer = VertexAIAnalyzer()
        logger.info("Vertex AI Gemini 분석기 초기화 완료")
        
        stt_service = SpeechToTextService()
        logger.info("Speech-to-Text 서비스 초기화 완료")
    except Exception as e:
        logger.error(f"서비스 초기화 실패: {str(e)}")
        raise

    yield

    # 종료 시
    logger.info("AI 서비스 종료 중...")


# FastAPI 앱 생성
app = FastAPI(
    title="Senior MHealth AI Service - Vertex AI",
    description="GCP Vertex AI Gemini 기반 정신건강 텍스트 분석 서비스",
    version="2.0.0",
    lifespan=lifespan
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 프로덕션에서는 구체적인 도메인 지정
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", response_model=HealthResponse)
async def health_check():
    """헬스체크 엔드포인트"""
    return HealthResponse(
        status="healthy",
        service="senior-mhealth-ai-simple",
        version="2.0.0"
    )


@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_text(request: AnalysisRequest):
    """
    텍스트 기반 정신건강 분석

    화자 분리 없이 전체 텍스트를 분석하여
    우울도, 불안도, 인지기능 등의 정신건강 지표를 반환합니다.
    """
    global analyzer

    if not analyzer:
        logger.error("분석기가 초기화되지 않음")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="분석 서비스가 준비되지 않았습니다"
        )

    try:
        logger.info(f"분석 요청 수신 - 사용자: {request.user_id}")

        # 텍스트 검증
        if not request.text or len(request.text.strip()) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="분석할 텍스트가 비어있습니다"
            )

        # 분석 수행
        result = await analyzer.analyze_mental_health(request)

        logger.info(f"분석 완료 - 신뢰도: {result.confidence}")
        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"분석 처리 중 오류: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"분석 처리 중 오류가 발생했습니다: {str(e)}"
        )


@app.get("/health")
async def detailed_health():
    """상세 헬스체크"""
    global analyzer

    health_status = {
        "status": "healthy",
        "service": "senior-mhealth-ai-simple",
        "version": "2.0.0",
        "components": {
            "vertex_ai_analyzer": "ready" if analyzer else "not_initialized",
            "gcp_project": "configured" if os.getenv("GCP_PROJECT_ID") else "missing"
        },
        "environment": {
            "project_id": os.getenv("GCP_PROJECT_ID", "not_set"),
            "region": os.getenv("GCP_REGION", "not_set"),
            "port": os.getenv("PORT", "8080")
        }
    }

    # 전체 상태 결정
    if not analyzer or not os.getenv("GCP_PROJECT_ID"):
        health_status["status"] = "unhealthy"

    return JSONResponse(
        status_code=200 if health_status["status"] == "healthy" else 503,
        content=health_status
    )


@app.post("/transcribe", response_model=TranscriptionResponse)
async def transcribe_audio(
    file: UploadFile = File(...),
    user_id: str = Form(default="anonymous"),
    session_id: str = Form(default=""),
    language_code: str = Form(default="ko-KR")
):
    """
    음성 파일을 텍스트로 변환
    
    지원 형식: .wav, .mp3, .m4a, .flac, .ogg
    최대 파일 크기: 10MB
    """
    global stt_service
    
    if not stt_service:
        logger.error("STT 서비스가 초기화되지 않음")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="음성 인식 서비스가 준비되지 않았습니다"
        )
    
    try:
        logger.info(f"음성 파일 업로드 - 사용자: {user_id}, 파일: {file.filename}")
        
        # 파일 유효성 검사
        if not file.filename:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="파일명이 없습니다"
            )
        
        # 파일 내용 읽기
        audio_content = await file.read()
        
        # 파일 크기 검사
        validation = stt_service.validate_audio_file(file.filename, len(audio_content))
        if not validation["is_valid"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"파일 유효성 검사 실패: {', '.join(validation['errors'])}"
            )
        
        # 음성 인식 요청 생성
        audio_request = AudioRequest(
            user_id=user_id,
            session_id=session_id,
            language_code=language_code
        )
        
        # 음성 인식 수행
        result = await stt_service.transcribe_audio(audio_content, file.filename, audio_request)
        
        logger.info(f"음성 인식 완료 - 신뢰도: {result.confidence}")
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"음성 인식 처리 중 오류: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"음성 인식 처리 중 오류가 발생했습니다: {str(e)}"
        )


@app.post("/analyze-audio", response_model=AnalysisResponse)
async def analyze_audio(
    file: UploadFile = File(...),
    user_id: str = Form(default="anonymous"),
    session_id: str = Form(default=""),
    language_code: str = Form(default="ko-KR")
):
    """
    음성 파일을 텍스트로 변환한 후 정신건강 분석 수행
    
    STT + 텍스트 분석을 한 번에 처리하는 통합 엔드포인트
    """
    global stt_service, analyzer
    
    if not stt_service or not analyzer:
        logger.error("서비스가 초기화되지 않음")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="분석 서비스가 준비되지 않았습니다"
        )
    
    try:
        logger.info(f"음성 분석 요청 - 사용자: {user_id}, 파일: {file.filename}")
        
        # 1단계: 음성을 텍스트로 변환
        if not file.filename:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="파일명이 없습니다"
            )
        
        audio_content = await file.read()
        
        # 파일 유효성 검사
        validation = stt_service.validate_audio_file(file.filename, len(audio_content))
        if not validation["is_valid"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"파일 유효성 검사 실패: {', '.join(validation['errors'])}"
            )
        
        # 음성 인식
        audio_request = AudioRequest(
            user_id=user_id,
            session_id=session_id,
            language_code=language_code
        )
        
        transcription = await stt_service.transcribe_audio(audio_content, file.filename, audio_request)
        
        if not transcription.transcript or len(transcription.transcript.strip()) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="음성에서 텍스트를 인식할 수 없습니다"
            )
        
        logger.info(f"음성 인식 완료 - 텍스트: {transcription.transcript[:50]}...")
        
        # 2단계: 텍스트 분석
        analysis_request = AnalysisRequest(
            text=transcription.transcript,
            user_id=user_id,
            session_id=session_id
        )
        
        result = await analyzer.analyze_mental_health(analysis_request)
        
        logger.info(f"통합 분석 완료 - 신뢰도: {result.confidence}")
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"음성 분석 처리 중 오류: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"음성 분석 처리 중 오류가 발생했습니다: {str(e)}"
        )


@app.get("/audio-formats")
async def get_supported_audio_formats():
    """지원하는 오디오 형식 목록 반환"""
    global stt_service
    
    if not stt_service:
        return {"formats": [".wav", ".mp3", ".m4a", ".flac", ".ogg"]}
    
    return {
        "formats": stt_service.get_supported_formats(),
        "max_file_size": "10MB",
        "recommended_format": ".wav (최고 품질)"
    }


@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    """일반 예외 처리기"""
    logger.error(f"처리되지 않은 예외: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={
            "detail": "내부 서버 오류가 발생했습니다",
            "error": str(exc) if os.getenv("LOG_LEVEL") == "DEBUG" else None
        }
    )


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", 8080))

    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=port,
        reload=os.getenv("ENV", "production") != "production",
        log_level=os.getenv("LOG_LEVEL", "info").lower()
    )