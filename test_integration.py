"""
AI 서비스 통합 테스트 - 화자 분리 기능 포함
"""

import asyncio
import aiohttp
import os
from pathlib import Path

# API 엔드포인트
API_BASE = "http://localhost:8081"


async def test_analyze_endpoint():
    """텍스트 분석 엔드포인트 테스트 (화자 분리 포함)"""

    print("=" * 60)
    print("🧪 /analyze 엔드포인트 테스트")
    print("=" * 60)

    # 테스트 케이스들
    test_cases = [
        {
            "name": "아들-엄마 대화 (화자 분리 활성화)",
            "data": {
                "text": "엄마, 오늘은 좀 어떠세요? 괜찮아. 아들아, 너는 잘 지내니?",
                "enable_speaker_separation": True,
                "analyze_senior_only": True
            }
        },
        {
            "name": "전체 텍스트 분석 (화자 분리 비활성화)",
            "data": {
                "text": "엄마, 오늘은 좀 어떠세요? 괜찮아. 아들아, 너는 잘 지내니?",
                "enable_speaker_separation": False,
                "analyze_senior_only": False
            }
        },
        {
            "name": "시니어만 발화 (화자 분리 활성화)",
            "data": {
                "text": "괜찮아. 오늘은 날씨가 좋구나. 밥은 먹었어.",
                "enable_speaker_separation": True,
                "analyze_senior_only": True
            }
        }
    ]

    async with aiohttp.ClientSession() as session:
        for case in test_cases:
            print(f"\n📝 테스트: {case['name']}")
            print(f"   입력: {case['data']['text'][:50]}...")

            try:
                async with session.post(
                    f"{API_BASE}/analyze",
                    json=case['data']
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        print(f"   ✅ 성공")
                        print(f"      화자 분리: {result.get('speaker_separation_applied', False)}")
                        print(f"      분석 유형: {result.get('analyzed_text_type', 'unknown')}")
                        print(f"      우울도: {result.get('depression_score', 0):.1f}")
                        print(f"      불안도: {result.get('anxiety_score', 0):.1f}")
                        print(f"      감정: {result.get('emotional_state', '')}")

                        if result.get('speaker_separation_applied'):
                            if result.get('senior_text'):
                                print(f"      시니어 발화: {result.get('senior_text')[:30]}...")
                            if result.get('guardian_text'):
                                print(f"      보호자 발화: {result.get('guardian_text')[:30]}...")
                    else:
                        error = await response.text()
                        print(f"   ❌ 실패 ({response.status}): {error}")
            except Exception as e:
                print(f"   ❌ 오류: {str(e)}")


async def test_analyze_audio_endpoint():
    """음성 분석 엔드포인트 테스트 (화자 분리 포함)"""

    print("\n" + "=" * 60)
    print("🧪 /analyze-audio 엔드포인트 테스트")
    print("=" * 60)

    audio_file = "test/test.mp3"

    if not os.path.exists(audio_file):
        print(f"❌ 테스트 파일이 없습니다: {audio_file}")
        return

    async with aiohttp.ClientSession() as session:
        # 파일 업로드 준비
        with open(audio_file, 'rb') as f:
            data = aiohttp.FormData()
            data.add_field('file',
                          f,
                          filename='test.mp3',
                          content_type='audio/mpeg')
            data.add_field('user_id', 'test_user')
            data.add_field('session_id', 'test_session')
            data.add_field('language_code', 'ko-KR')
            data.add_field('enable_speaker_separation', 'true')
            data.add_field('analyze_senior_only', 'true')

            print(f"📁 테스트 파일: {audio_file}")

            try:
                async with session.post(
                    f"{API_BASE}/analyze-audio",
                    data=data
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        print("✅ 음성 분석 성공")
                        print(f"   화자 분리: {result.get('speaker_separation_applied', False)}")
                        print(f"   분석 유형: {result.get('analyzed_text_type', 'unknown')}")
                        print(f"   원본 텍스트: {result.get('original_text', '')[:50]}...")

                        if result.get('senior_text'):
                            print(f"   시니어 발화: {result.get('senior_text')}")
                        if result.get('guardian_text'):
                            print(f"   보호자 발화: {result.get('guardian_text')}")

                        print(f"   우울도: {result.get('depression_score', 0):.1f}")
                        print(f"   불안도: {result.get('anxiety_score', 0):.1f}")
                        print(f"   인지기능: {result.get('cognitive_score', 0):.1f}")
                        print(f"   감정 상태: {result.get('emotional_state', '')}")
                    else:
                        error = await response.text()
                        print(f"❌ 실패 ({response.status}): {error}")
            except Exception as e:
                print(f"❌ 오류: {str(e)}")


async def test_health_check():
    """헬스체크 테스트"""

    print("\n" + "=" * 60)
    print("🧪 헬스체크 테스트")
    print("=" * 60)

    async with aiohttp.ClientSession() as session:
        try:
            async with session.get(f"{API_BASE}/health") as response:
                if response.status == 200:
                    result = await response.json()
                    print("✅ 서비스 상태: 정상")
                    print(f"   버전: {result.get('version', 'unknown')}")
                    print(f"   AI 분석기: {result.get('components', {}).get('ai_analyzer', 'unknown')}")
                else:
                    print(f"❌ 서비스 상태: 비정상 ({response.status})")
        except Exception as e:
            print(f"❌ 서버 연결 실패: {str(e)}")


async def main():
    """통합 테스트 실행"""

    print("\n🚀 AI 서비스 통합 테스트 시작")
    print("=" * 60)

    # 헬스체크
    await test_health_check()

    # 텍스트 분석 테스트
    await test_analyze_endpoint()

    # 음성 분석 테스트
    await test_analyze_audio_endpoint()

    print("\n" + "=" * 60)
    print("✅ 통합 테스트 완료!")


if __name__ == "__main__":
    asyncio.run(main())