"""
로컬 테스트 스크립트
STT + 텍스트 분석 기능을 테스트합니다.
"""

import os
import asyncio
import sys
from pathlib import Path

# 프로젝트 루트를 Python 경로에 추가
sys.path.append(str(Path(__file__).parent))

from app.services.speech_to_text import SpeechToTextService, AudioRequest
from app.services.vertex_ai_analyzer import VertexAIAnalyzer, AnalysisRequest


async def test_stt_service():
    """STT 서비스 테스트"""
    print("=== STT 서비스 테스트 ===")
    
    # 환경변수 확인
    project_id = os.getenv('GCP_PROJECT_ID')
    if not project_id:
        print("❌ GCP_PROJECT_ID 환경변수가 설정되지 않았습니다")
        print("다음 명령으로 설정하세요:")
        print("export GCP_PROJECT_ID=your-project-id")
        return False
    
    try:
        # STT 서비스 초기화
        stt_service = SpeechToTextService()
        print("✅ STT 서비스 초기화 성공")
        
        # 지원 형식 확인
        formats = stt_service.get_supported_formats()
        print(f"📋 지원 형식: {formats}")
        
        return True
        
    except Exception as e:
        print(f"❌ STT 서비스 초기화 실패: {str(e)}")
        return False


async def test_vertex_ai():
    """Vertex AI 분석기 테스트"""
    print("\n=== Vertex AI 분석기 테스트 ===")
    
    try:
        # Vertex AI 분석기 초기화
        analyzer = VertexAIAnalyzer()
        print("✅ Vertex AI 분석기 초기화 성공")
        
        # 간단한 텍스트 분석 테스트
        test_text = "요즘 기분이 우울하고 힘들어요. 잠도 잘 안 오고 식욕도 없어요."
        request = AnalysisRequest(
            text=test_text,
            user_id="test_user",
            session_id="test_session"
        )
        
        print(f"📝 테스트 텍스트: {test_text}")
        print("🔄 분석 중...")
        
        result = await analyzer.analyze_mental_health(request)
        
        print("✅ 분석 완료!")
        print(f"📊 우울도: {result.depression_score}")
        print(f"📊 불안도: {result.anxiety_score}")
        print(f"📊 인지기능: {result.cognitive_score}")
        print(f"😊 감정상태: {result.emotional_state}")
        print(f"🎯 신뢰도: {result.confidence}")
        
        return True
        
    except Exception as e:
        print(f"❌ Vertex AI 분석기 테스트 실패: {str(e)}")
        return False


async def test_audio_file():
    """실제 음성 파일 테스트"""
    print("\n=== 음성 파일 테스트 ===")
    
    # 테스트 파일 경로
    data_dir = Path(__file__).parent.parent.parent / "data"
    audio_files = list(data_dir.glob("*.m4a"))
    
    if not audio_files:
        print("❌ 테스트할 음성 파일이 없습니다")
        return False
    
    test_file = audio_files[0]
    print(f"📁 테스트 파일: {test_file.name}")
    
    try:
        # STT 서비스 초기화
        stt_service = SpeechToTextService()
        
        # 파일 읽기
        with open(test_file, 'rb') as f:
            audio_content = f.read()
        
        print(f"📏 파일 크기: {len(audio_content) / (1024*1024):.1f}MB")
        
        # 파일 유효성 검사
        validation = stt_service.validate_audio_file(test_file.name, len(audio_content))
        if not validation["is_valid"]:
            print(f"❌ 파일 유효성 검사 실패: {validation['errors']}")
            return False
        
        print("✅ 파일 유효성 검사 통과")
        
        # 음성 인식 수행
        audio_request = AudioRequest(
            user_id="test_user",
            session_id="test_session",
            language_code="ko-KR"
        )
        
        print("🔄 음성 인식 중...")
        result = await stt_service.transcribe_audio(audio_content, test_file.name, audio_request)
        
        print("✅ 음성 인식 완료!")
        print(f"📝 인식된 텍스트: {result.transcript}")
        print(f"🎯 신뢰도: {result.confidence}")
        
        return result.transcript
        
    except Exception as e:
        print(f"❌ 음성 파일 테스트 실패: {str(e)}")
        return False


async def test_integrated_analysis():
    """통합 분석 테스트 (STT + 텍스트 분석)"""
    print("\n=== 통합 분석 테스트 ===")
    
    # 음성 파일 테스트
    transcript = await test_audio_file()
    if not transcript:
        return False
    
    try:
        # 텍스트 분석
        analyzer = VertexAIAnalyzer()
        
        analysis_request = AnalysisRequest(
            text=transcript,
            user_id="test_user",
            session_id="test_session"
        )
        
        print("🔄 정신건강 분석 중...")
        result = await analyzer.analyze_mental_health(analysis_request)
        
        print("✅ 통합 분석 완료!")
        print(f"📊 우울도: {result.depression_score}")
        print(f"📊 불안도: {result.anxiety_score}")
        print(f"📊 인지기능: {result.cognitive_score}")
        print(f"😊 감정상태: {result.emotional_state}")
        print(f"⚠️ 주요 우려사항: {result.key_concerns}")
        print(f"💡 권장사항: {result.recommendations}")
        print(f"🎯 신뢰도: {result.confidence}")
        
        return True
        
    except Exception as e:
        print(f"❌ 통합 분석 실패: {str(e)}")
        return False


async def main():
    """메인 테스트 함수"""
    print("🚀 Senior MHealth AI Service 로컬 테스트 시작\n")
    
    # 환경 확인
    print("=== 환경 확인 ===")
    print(f"GCP_PROJECT_ID: {os.getenv('GCP_PROJECT_ID', 'NOT SET')}")
    print(f"GCP_LOCATION: {os.getenv('GCP_LOCATION', 'NOT SET (기본값: asia-northeast3)')}")
    
    # 인증 확인
    auth_file = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
    if auth_file:
        print(f"GOOGLE_APPLICATION_CREDENTIALS: {auth_file}")
    else:
        print("GOOGLE_APPLICATION_CREDENTIALS: NOT SET")
        print("⚠️ GCP 인증이 필요할 수 있습니다. 다음 중 하나를 실행하세요:")
        print("   1. gcloud auth application-default login")
        print("   2. export GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json")
    
    print()
    
    # 테스트 실행
    tests = [
        ("STT 서비스", test_stt_service),
        ("Vertex AI 분석기", test_vertex_ai),
        ("통합 분석", test_integrated_analysis),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = await test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} 테스트 중 예외 발생: {str(e)}")
            results.append((test_name, False))
    
    # 결과 요약
    print("\n" + "="*50)
    print("📋 테스트 결과 요약")
    print("="*50)
    
    for test_name, result in results:
        status = "✅ 성공" if result else "❌ 실패"
        print(f"{test_name}: {status}")
    
    success_count = sum(1 for _, result in results if result)
    total_count = len(results)
    
    print(f"\n총 {total_count}개 테스트 중 {success_count}개 성공")
    
    if success_count == total_count:
        print("🎉 모든 테스트가 성공했습니다!")
    else:
        print("⚠️ 일부 테스트가 실패했습니다. 설정을 확인해주세요.")


if __name__ == "__main__":
    asyncio.run(main())
