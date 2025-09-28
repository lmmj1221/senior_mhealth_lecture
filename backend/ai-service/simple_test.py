"""
간단한 단계별 테스트 스크립트
각 단계마다 로그를 출력하여 문제점을 파악합니다.
"""

import os
import sys
import traceback

def test_step_1_environment():
    """1단계: 환경변수 확인"""
    print("=== 1단계: 환경변수 확인 ===")
    
    project_id = os.getenv('GCP_PROJECT_ID')
    location = os.getenv('GCP_LOCATION', 'asia-northeast3')
    
    print(f"GCP_PROJECT_ID: {project_id}")
    print(f"GCP_LOCATION: {location}")
    
    if not project_id:
        print("❌ GCP_PROJECT_ID가 설정되지 않았습니다")
        return False
    
    print("✅ 환경변수 확인 완료")
    return True

def test_step_2_imports():
    """2단계: 모듈 import 확인"""
    print("\n=== 2단계: 모듈 import 확인 ===")
    
    try:
        print("📦 google.cloud.speech import 시도...")
        from google.cloud import speech
        print("✅ google.cloud.speech import 성공")
        
        print("📦 vertexai import 시도...")
        import vertexai
        print("✅ vertexai import 성공")
        
        print("📦 fastapi import 시도...")
        from fastapi import FastAPI
        print("✅ fastapi import 성공")
        
        print("📦 프로젝트 모듈 import 시도...")
        sys.path.append(os.path.dirname(__file__))
        
        from app.services.speech_to_text import SpeechToTextService
        print("✅ SpeechToTextService import 성공")
        
        from app.services.vertex_ai_analyzer import VertexAIAnalyzer
        print("✅ VertexAIAnalyzer import 성공")
        
        return True
        
    except ImportError as e:
        print(f"❌ Import 오류: {str(e)}")
        traceback.print_exc()
        return False
    except Exception as e:
        print(f"❌ 예상치 못한 오류: {str(e)}")
        traceback.print_exc()
        return False

def test_step_3_stt_init():
    """3단계: STT 서비스 초기화"""
    print("\n=== 3단계: STT 서비스 초기화 ===")
    
    try:
        print("🔄 SpeechToTextService 초기화 중...")
        from app.services.speech_to_text import SpeechToTextService
        
        stt_service = SpeechToTextService()
        print("✅ STT 서비스 초기화 성공")
        
        # 지원 형식 확인
        formats = stt_service.get_supported_formats()
        print(f"📋 지원 형식: {formats}")
        
        return stt_service
        
    except Exception as e:
        print(f"❌ STT 서비스 초기화 실패: {str(e)}")
        traceback.print_exc()
        return None

def test_step_4_vertex_ai_init():
    """4단계: Vertex AI 초기화"""
    print("\n=== 4단계: Vertex AI 초기화 ===")
    
    try:
        print("🔄 VertexAIAnalyzer 초기화 중...")
        from app.services.vertex_ai_analyzer import VertexAIAnalyzer
        
        analyzer = VertexAIAnalyzer()
        print("✅ Vertex AI 분석기 초기화 성공")
        
        return analyzer
        
    except Exception as e:
        print(f"❌ Vertex AI 초기화 실패: {str(e)}")
        traceback.print_exc()
        return None

def test_step_5_simple_analysis():
    """5단계: 간단한 텍스트 분석"""
    print("\n=== 5단계: 간단한 텍스트 분석 ===")
    
    try:
        from app.services.vertex_ai_analyzer import VertexAIAnalyzer, AnalysisRequest
        
        analyzer = VertexAIAnalyzer()
        
        test_text = "안녕하세요. 테스트입니다."
        print(f"📝 테스트 텍스트: {test_text}")
        
        request = AnalysisRequest(
            text=test_text,
            user_id="test_user",
            session_id="test_session"
        )
        
        print("🔄 분석 중... (비동기 함수를 동기로 테스트)")
        
        # 동기 버전 사용
        result = analyzer.analyze_mental_health_sync(request)
        
        print("✅ 분석 완료!")
        print(f"📊 우울도: {result.depression_score}")
        print(f"📊 불안도: {result.anxiety_score}")
        print(f"📊 인지기능: {result.cognitive_score}")
        print(f"😊 감정상태: {result.emotional_state}")
        print(f"🎯 신뢰도: {result.confidence}")
        
        return True
        
    except Exception as e:
        print(f"❌ 텍스트 분석 실패: {str(e)}")
        traceback.print_exc()
        return False

def test_step_6_audio_file_check():
    """6단계: 오디오 파일 확인"""
    print("\n=== 6단계: 오디오 파일 확인 ===")
    
    try:
        from pathlib import Path
        
        # 데이터 폴더 경로
        data_dir = Path(__file__).parent.parent.parent / "data"
        print(f"📁 데이터 폴더: {data_dir}")
        
        if not data_dir.exists():
            print("❌ 데이터 폴더가 존재하지 않습니다")
            return False
        
        # 오디오 파일 찾기
        audio_files = list(data_dir.glob("*.m4a"))
        print(f"🎵 발견된 오디오 파일: {len(audio_files)}개")
        
        for file in audio_files:
            file_size = file.stat().st_size
            print(f"  - {file.name}: {file_size / (1024*1024):.1f}MB")
        
        if not audio_files:
            print("❌ 오디오 파일이 없습니다")
            return False
        
        print("✅ 오디오 파일 확인 완료")
        return audio_files[0]  # 첫 번째 파일 반환
        
    except Exception as e:
        print(f"❌ 오디오 파일 확인 실패: {str(e)}")
        traceback.print_exc()
        return None

def main():
    """메인 테스트 함수"""
    print("🚀 Senior MHealth AI Service - 단계별 테스트 시작\n")
    
    # 테스트 단계들
    steps = [
        ("환경변수 확인", test_step_1_environment),
        ("모듈 import", test_step_2_imports),
        ("STT 서비스 초기화", test_step_3_stt_init),
        ("Vertex AI 초기화", test_step_4_vertex_ai_init),
        ("간단한 텍스트 분석", test_step_5_simple_analysis),
        ("오디오 파일 확인", test_step_6_audio_file_check),
    ]
    
    results = []
    
    for i, (step_name, step_func) in enumerate(steps, 1):
        print(f"\n{'='*60}")
        print(f"🔍 {i}/{len(steps)}: {step_name}")
        print('='*60)
        
        try:
            result = step_func()
            success = result is not False and result is not None
            results.append((step_name, success, result))
            
            if success:
                print(f"✅ {step_name} 성공")
            else:
                print(f"❌ {step_name} 실패")
                print("⚠️ 이후 테스트를 중단합니다.")
                break
                
        except Exception as e:
            print(f"❌ {step_name} 중 예외 발생: {str(e)}")
            traceback.print_exc()
            results.append((step_name, False, None))
            break
    
    # 결과 요약
    print(f"\n{'='*60}")
    print("📋 테스트 결과 요약")
    print('='*60)
    
    for step_name, success, _ in results:
        status = "✅ 성공" if success else "❌ 실패"
        print(f"{step_name}: {status}")
    
    success_count = sum(1 for _, success, _ in results if success)
    total_count = len(results)
    
    print(f"\n총 {len(steps)}개 단계 중 {success_count}개 성공")
    
    if success_count == len(steps):
        print("🎉 모든 단계가 성공했습니다!")
    else:
        print("⚠️ 일부 단계가 실패했습니다.")
        print("💡 실패한 단계의 로그를 확인하여 문제를 해결하세요.")

if __name__ == "__main__":
    main()
