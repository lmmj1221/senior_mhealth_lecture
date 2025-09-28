# Senior MHealth AI Service - API 완전 가이드

## 📚 목차
1. [기본 개념](#기본-개념)
2. [프로젝트 구조](#프로젝트-구조)
3. [핵심 기술 스택](#핵심-기술-스택)
4. [엔드포인트 상세 분석](#엔드포인트-상세-분석)
5. [코드 구조와 연결 관계](#코드-구조와-연결-관계)
6. [실제 사용 예제](#실제-사용-예제)

---

## 🎯 기본 개념

### API란?
**API (Application Programming Interface)**는 서로 다른 소프트웨어가 소통하는 방법을 정의한 규칙입니다.

**🏪 카페 주문 시스템으로 이해하기:**
```
👤 고객        📋 메뉴판        👨‍🍳 바리스타        ☕ 커피머신
  │              │                │                │
  │── "아메리카노" ──►│── 주문서 ──►│── 커피 제조 ──►│
  │              │                │                │
  │◄── 커피 전달 ────│◄── 완성품 ───│◄── 커피 완성 ───│
```

**💻 웹 API로 바꿔보면:**
```
🌐 웹 브라우저   📡 API 엔드포인트   🖥️ 서버        🤖 AI 서비스
     │              │                │                │
     │── HTTP 요청 ──►│── 데이터 처리 ──►│── AI 분석 ──►│
     │              │                │                │
     │◄── JSON 응답 ──│◄── 결과 반환 ────│◄── 분석 완료 ──│
```

**핵심**: API는 **"주문서"** 역할! 정확한 형식으로 요청하면 원하는 결과를 받을 수 있습니다.

### REST API
**REST**는 웹에서 정보를 주고받는 규칙입니다.

**🏪 카페 메뉴판으로 이해하기:**
```
📋 HTTP 메서드 = 주문 방식
┌─────────────────────────────────────────┐
│ GET    /menu     → 📖 "메뉴 보여주세요"    │
│ POST   /order    → ✏️  "주문할게요"       │  
│ PUT    /order/1  → 🔄 "주문 변경해주세요"  │
│ DELETE /order/1  → ❌ "주문 취소해주세요"  │
└─────────────────────────────────────────┘
```

**🎤 우리 AI 서비스로 바꿔보면:**
```
📡 엔드포인트 = 서비스 메뉴
┌─────────────────────────────────────────────┐
│ GET    /health        → 🏥 "서버 상태 확인"   │
│ POST   /analyze       → 📝 "텍스트 분석해줘"  │
│ POST   /transcribe    → 🎤 "음성을 글로 바꿔줘" │
│ POST   /analyze-audio → 🧠 "음성 분석해줘"   │
└─────────────────────────────────────────────┘
```

---

## 🏗️ 프로젝트 구조

```
backend/ai-service/
├── app/
│   ├── main.py                     # 🌐 API 엔드포인트 (컨트롤러)
│   └── services/
│       ├── speech_to_text.py       # 🎤 음성 인식 서비스
│       └── vertex_ai_analyzer.py   # 🧠 AI 분석 서비스
├── requirements.txt                # 📦 필요한 패키지 목록
├── Dockerfile                      # 🐳 Docker 설정
└── README.md                       # 📖 프로젝트 설명
```

### 계층 구조
**🏢 회사 조직도로 이해하기:**

```
🏢 Senior MHealth AI Service 회사 조직도
┌─────────────────────────────────────────────────────────┐
│                    🎯 API Layer                         │
│                   (접수처 - main.py)                    │
│  "고객 요청을 받고, 적절한 부서로 연결하고, 결과를 전달"     │
│                                                         │
│  👨‍💼 직원: FastAPI                                      │
│  📋 업무: HTTP 요청 받기 → 검증 → 부서 연결 → 응답 생성    │
└─────────────────────────────────────────────────────────┘
                            ⬇️
┌─────────────────────────────────────────────────────────┐
│                 🔧 Service Layer                        │
│              (실무 부서 - services/*.py)                 │
│           "실제 일을 처리하는 전문가들"                    │
│                                                         │
│  🎤 STT팀: speech_to_text.py                           │
│  🧠 AI팀: vertex_ai_analyzer.py                        │
│  📋 업무: 음성 인식, AI 분석, 데이터 처리                 │
└─────────────────────────────────────────────────────────┘
                            ⬇️
┌─────────────────────────────────────────────────────────┐
│                🌐 External APIs                         │
│              (외부 협력업체 - Google Cloud)              │
│            "실제 기술을 제공하는 전문 업체"                │
│                                                         │
│  ☁️ Google Speech-to-Text                              │
│  🤖 Google Vertex AI (Gemini)                         │
│  📋 업무: 음성 인식 기술, AI 모델 제공                    │
└─────────────────────────────────────────────────────────┘
```

**🔄 업무 흐름:**
```
👤 고객 요청 → 🎯 접수처 → 🔧 실무팀 → 🌐 외부업체 → 📊 결과 → 👤 고객
```

---

## ⚡ 핵심 기술 스택

### 1. **FastAPI** 🚀
**🏪 카페 점장님 역할**

```
👨‍💼 FastAPI = 똑똑한 카페 점장님
┌─────────────────────────────────────────────┐
│  📋 메뉴판 자동 생성 (API 문서)              │
│  ✅ 주문 검증 (데이터 검증)                  │
│  🚀 빠른 서비스 (고성능)                    │
│  📞 주문 접수 (HTTP 요청 처리)               │
│  📦 결과 포장 (JSON 응답)                   │
└─────────────────────────────────────────────┘
```

```python
from fastapi import FastAPI
app = FastAPI()

@app.get("/")                    # 📋 메뉴에 "기본 인사" 추가
async def hello():               # 🤖 비동기로 빠르게 처리
    return {"message": "안녕하세요!"}  # 📦 JSON으로 포장해서 전달
```

**💡 왜 FastAPI를 선택했나요?**
- **자동 문서 생성**: 코드만 작성하면 API 설명서가 자동으로 만들어짐
- **타입 검증**: 잘못된 데이터가 들어오면 자동으로 차단
- **빠른 성능**: 동시에 여러 요청을 처리할 수 있음

### 2. **Uvicorn** ⚡
**🚚 배달 트럭 역할**

```
🚚 Uvicorn = 초고속 배달 트럭
┌─────────────────────────────────────────────┐
│  🌐 인터넷 도로에서 대기                     │
│  📦 FastAPI 요리를 고객에게 배달             │
│  🚀 동시에 여러 주문 처리 (비동기)           │
│  🔄 24시간 무중단 서비스                    │
└─────────────────────────────────────────────┘
```

```bash
# 🚚 배달 트럭 출발!
uvicorn app.main:app --host 0.0.0.0 --port 8080
#        ↑        ↑     ↑              ↑
#     FastAPI앱  트럭   모든 주소      8080번 도로
```

**🔄 역할 분담:**
```
👨‍🍳 FastAPI  = 요리사 (API 로직 작성)
🚚 Uvicorn   = 배달원 (웹 서버 실행)
🏠 고객      = 브라우저/앱 (요청 보내기)
```

### 3. **Pydantic** 📋
**🛡️ 보안 검색대 역할**

```
🛡️ Pydantic = 공항 보안 검색대
┌─────────────────────────────────────────────┐
│  ✅ 신분증 확인 (타입 검증)                  │
│  📏 수하물 검사 (데이터 형식 확인)           │
│  🚫 위험물 차단 (잘못된 데이터 거부)         │
│  📝 탑승권 발급 (검증된 데이터 모델 생성)     │
└─────────────────────────────────────────────┘
```

```python
from pydantic import BaseModel, Field

class AudioRequest(BaseModel):           # 🎫 탑승권 양식
    user_id: str = Field(default="anonymous")      # ✅ 필수: 사용자 ID
    language_code: str = Field(default="ko-KR")    # ✅ 선택: 언어 (기본값: 한국어)

# 🔍 검증 과정
request_data = {"user_id": "홍길동", "language_code": "ko-KR"}  # ✅ 통과
bad_data = {"user_id": 123, "language_code": "invalid"}        # ❌ 차단
```

**🚨 보안 검색 결과:**
```
✅ 올바른 데이터 → 🎫 검증된 모델 객체 생성
❌ 잘못된 데이터 → 🚫 자동으로 오류 메시지 반환
```

### 4. **Google Cloud Services** ☁️
**🏭 전문 기술 공장 역할**

```
🏭 Google Cloud = 최첨단 기술 공장
┌─────────────────────────────────────────────────────────┐
│  🎤 Speech-to-Text 공장                                 │
│  "음성을 받아서 → 🔄 마법 처리 → 📝 텍스트로 변환"        │
│                                                         │
│  🧠 Vertex AI (Gemini) 공장                            │  
│  "텍스트를 받아서 → 🤖 AI 분석 → 📊 정신건강 결과"        │
└─────────────────────────────────────────────────────────┘
```

```python
from google.cloud import speech          # 🎤 음성 인식 공장 연결
import vertexai                         # 🧠 AI 분석 공장 연결

# 🏭 공장 가동 과정
audio_file = "어머니와의_통화.m4a"       # 🎤 원료 투입
↓
text = "오늘 기분이 안 좋아요..."        # 📝 1차 가공품
↓  
analysis = {                            # 📊 최종 제품
    "depression_score": 65,
    "recommendations": ["상담 권장"]
}
```

**🔑 공장 출입증 (인증):**
```
GCP_PROJECT_ID = "senior-mhealth-lecture"  # 🏭 공장 출입 허가증
GOOGLE_APPLICATION_CREDENTIALS = "key.json" # 🔐 보안 키카드
```

---

## 🔗 엔드포인트 상세 분석

### 1. 헬스체크 엔드포인트

#### **`GET /` - 기본 헬스체크**
```python
@app.get("/", response_model=HealthResponse)
async def health_check():
    return HealthResponse(
        status="healthy",
        service="senior-mhealth-ai-simple", 
        version="2.0.0"
    )
```

**용도**: 서버가 살아있는지 확인
**응답 예시**:
```json
{
  "status": "healthy",
  "service": "senior-mhealth-ai-simple",
  "version": "2.0.0"
}
```

#### **`GET /health` - 상세 헬스체크**
```python
@app.get("/health")
async def detailed_health():
    health_status = {
        "status": "healthy",
        "components": {
            "vertex_ai_analyzer": "ready" if analyzer else "not_initialized",
            "gcp_project": "configured" if os.getenv("GCP_PROJECT_ID") else "missing"
        },
        "environment": {
            "project_id": os.getenv("GCP_PROJECT_ID", "not_set"),
            "region": os.getenv("GCP_REGION", "not_set")
        }
    }
    return health_status
```

**용도**: 각 컴포넌트의 상태 확인
**응답 예시**:
```json
{
  "status": "healthy",
  "components": {
    "vertex_ai_analyzer": "ready",
    "gcp_project": "configured"
  },
  "environment": {
    "project_id": "senior-mhealth-lecture",
    "region": "asia-northeast3"
  }
}
```

### 2. 텍스트 분석 엔드포인트

#### **`POST /analyze` - 텍스트 기반 정신건강 분석**
```python
@app.post("/analyze", response_model=AnalysisResponse)
async def analyze_text(request: AnalysisRequest):
    # 1. 입력 검증
    if not request.text or len(request.text.strip()) == 0:
        raise HTTPException(status_code=400, detail="텍스트가 비어있습니다")
    
    # 2. AI 분석 수행
    result = await analyzer.analyze_mental_health(request)
    
    # 3. 결과 반환
    return result
```

**요청 예시**:
```json
{
  "text": "요즘 기분이 우울하고 힘들어요. 잠도 잘 안 와요.",
  "user_id": "user123",
  "session_id": "session456"
}
```

**응답 예시**:
```json
{
  "depression_score": 75.5,
  "anxiety_score": 60.0,
  "cognitive_score": 85.0,
  "emotional_state": "우울",
  "key_concerns": ["우울감", "수면 장애"],
  "recommendations": ["전문가 상담 권장", "규칙적인 운동"],
  "confidence": 0.85,
  "timestamp": "2024-01-20T12:00:00Z"
}
```

### 3. 음성 처리 엔드포인트

#### **`POST /transcribe` - 음성 → 텍스트 변환**
```python
@app.post("/transcribe", response_model=TranscriptionResponse)
async def transcribe_audio(
    file: UploadFile = File(...),
    user_id: str = Form(default="anonymous"),
    language_code: str = Form(default="ko-KR")
):
    # 1. 파일 검증
    audio_content = await file.read()
    validation = stt_service.validate_audio_file(file.filename, len(audio_content))
    
    # 2. 음성 인식 수행
    audio_request = AudioRequest(user_id=user_id, language_code=language_code)
    result = await stt_service.transcribe_audio(audio_content, file.filename, audio_request)
    
    return result
```

**요청**: `multipart/form-data` 형태의 음성 파일
**응답 예시**:
```json
{
  "transcript": "안녕하세요. 오늘 기분이 좋지 않아요.",
  "confidence": 0.92,
  "language_code": "ko-KR",
  "audio_duration": 3.5
}
```

#### **`POST /analyze-audio` - 통합 분석 (핵심 기능!)**

**🎭 2막 연극으로 이해하기:**

```
🎭 "음성 분석 연극" - 2막 구성
┌─────────────────────────────────────────────────────────────┐
│                        🎬 1막: 음성 인식                     │
│  🎤 "어머니와의 통화.m4a"                                    │
│           ↓                                                 │
│  🏭 Google STT 공장에서 처리                                │
│           ↓                                                 │
│  📝 "오늘 기분이 우울하고 잠이 안 와요"                       │
└─────────────────────────────────────────────────────────────┘
                            ⬇️ 막간 전환
┌─────────────────────────────────────────────────────────────┐
│                        🎬 2막: AI 분석                      │
│  📝 "오늘 기분이 우울하고 잠이 안 와요"                       │
│           ↓                                                 │
│  🤖 Vertex AI Gemini가 분석                                │
│           ↓                                                 │
│  📊 {                                                       │
│      "depression_score": 75,                               │
│      "anxiety_score": 60,                                  │
│      "recommendations": ["전문가 상담 권장"]                 │
│     }                                                       │
└─────────────────────────────────────────────────────────────┘
```

```python
@app.post("/analyze-audio", response_model=AnalysisResponse)
async def analyze_audio(file: UploadFile = File(...), ...):
    # 🎬 1막: 음성 → 텍스트 변환
    transcription = await stt_service.transcribe_audio(...)
    
    # 🎬 2막: 텍스트 → 정신건강 분석  
    analysis_request = AnalysisRequest(text=transcription.transcript, ...)
    result = await analyzer.analyze_mental_health(analysis_request)
    
    return result  # 🎉 대단원의 막
```

**🔄 전체 여정:**
```
👤 사용자 → 🎤 음성파일 → 🏭 STT → 📝 텍스트 → 🤖 AI → 📊 결과 → 👤 사용자
   업로드     (.m4a)      Google   한국어    Gemini   분석결과    확인
```

### 4. 유틸리티 엔드포인트

#### **`GET /audio-formats` - 지원 형식 확인**
```python
@app.get("/audio-formats")
async def get_supported_audio_formats():
    return {
        "formats": [".wav", ".mp3", ".m4a", ".flac", ".ogg"],
        "max_file_size": "10MB",
        "recommended_format": ".wav (최고 품질)"
    }
```

---

## 🔄 코드 구조와 연결 관계

### 1. Import 관계 (의존성)
**🧩 레고 블록 조립하기:**

```
🧩 main.py = 레고 조립 설명서
┌─────────────────────────────────────────────────────────────┐
│  "이 블록들을 가져와서 멋진 로봇을 만들어보자!"                 │
│                                                             │
│  📦 speech_to_text.py에서 가져올 블록들:                     │
│  ├── 🎤 SpeechToTextService    (음성 인식 엔진)             │
│  ├── 📝 AudioRequest           (음성 요청서 양식)            │
│  └── 📋 TranscriptionResponse  (음성 인식 결과지)           │
│                                                             │
│  📦 vertex_ai_analyzer.py에서 가져올 블록들:                │
│  ├── 🧠 VertexAIAnalyzer      (AI 분석 엔진)               │
│  ├── 📄 AnalysisRequest       (분석 요청서 양식)            │
│  └── 📊 AnalysisResponse      (분석 결과지)                │
└─────────────────────────────────────────────────────────────┘
```

```python
# main.py = 🏗️ 건축 현장 감독
from app.services.speech_to_text import (
    SpeechToTextService,      # 🎤 음성 인식 전문가
    AudioRequest,             # 📝 음성 작업 지시서
    TranscriptionResponse     # 📋 음성 작업 완료 보고서
)
from app.services.vertex_ai_analyzer import (
    VertexAIAnalyzer,        # 🧠 AI 분석 전문가
    AnalysisRequest,         # 📄 분석 작업 지시서  
    AnalysisResponse         # 📊 분석 작업 완료 보고서
)
```

### 2. 전역 인스턴스 관리
**🏭 공장 기계 관리:**

```
🏭 AI 서비스 공장 - 기계 관리실
┌─────────────────────────────────────────────────────────────┐
│                    🎛️ 중앙 제어실                            │
│                                                             │
│  📊 전역 변수 (공장 기계 현황판)                             │
│  ├── 🤖 analyzer = None      (AI 분석 기계 - 대기중)        │
│  └── 🎤 stt_service = None   (음성 인식 기계 - 대기중)       │
│                                                             │
│  🔄 공장 가동 절차 (lifespan 함수)                          │
│  ├── 1️⃣ 전원 켜기: analyzer = VertexAIAnalyzer()          │
│  ├── 2️⃣ 기계 점검: stt_service = SpeechToTextService()    │
│  ├── 3️⃣ 생산 시작: yield (24시간 가동)                     │
│  └── 4️⃣ 전원 끄기: 공장 종료 시                            │
└─────────────────────────────────────────────────────────────┘
```

```python
# 🏭 공장 기계 현황판
analyzer = None      # 🤖 AI 분석 기계 (아직 꺼져있음)
stt_service = None   # 🎤 음성 인식 기계 (아직 꺼져있음)

# 🔄 공장 가동/중단 관리자
@asynccontextmanager
async def lifespan(app: FastAPI):
    global analyzer, stt_service
    
    # 🔌 기계들 전원 켜기 (1회만!)
    analyzer = VertexAIAnalyzer()        # 🤖 AI 기계 가동
    stt_service = SpeechToTextService()  # 🎤 음성 기계 가동
    
    yield  # 🏭 공장 24시간 가동 중...
    
    # 🔌 공장 종료 시 전원 끄기
```

**💡 왜 전역으로 관리하나요?**
- **효율성**: 기계를 한 번만 켜고 계속 사용 (재사용)
- **성능**: 매번 새로 만들면 느려짐
- **비용**: Google Cloud 연결을 계속 유지

### 3. 데이터 흐름
**🎪 서커스 공연으로 이해하기:**

```
🎪 "데이터 변환 서커스" - 4단계 묘기
┌─────────────────────────────────────────────────────────────┐
│  🎭 1단계: HTTP 요청 → Pydantic 모델                        │
│  👤 관객이 던진 공 (음성파일) → 🤹‍♂️ 곡예사가 받기 (FastAPI)  │
│                                                             │
│  file: UploadFile = File(...)  # 🤹‍♂️ "공을 받았다!"        │
└─────────────────────────────────────────────────────────────┘
                            ⬇️
┌─────────────────────────────────────────────────────────────┐
│  🎭 2단계: HTTP 데이터 → 서비스 모델                        │
│  🤹‍♂️ 곡예사가 공을 예쁘게 포장 → 📦 선물 상자로 변환        │
│                                                             │
│  audio_request = AudioRequest(                              │
│      user_id="홍길동",        # 🏷️ 받는 사람 이름표         │
│      language_code="ko-KR"    # 🌍 배송 국가 표시           │
│  )                                                          │
└─────────────────────────────────────────────────────────────┘
                            ⬇️
┌─────────────────────────────────────────────────────────────┐
│  🎭 3단계: 서비스 호출                                      │
│  📦 선물을 전문가에게 전달 → 🔬 마법사가 분석               │
│                                                             │
│  result = await stt_service.transcribe_audio(...)          │
│  # 🔬 "음성을 텍스트로 바꾸는 마법을 부리겠다!"              │
└─────────────────────────────────────────────────────────────┘
                            ⬇️
┌─────────────────────────────────────────────────────────────┐
│  🎭 4단계: 서비스 결과 → HTTP 응답                          │
│  🔬 마법사의 결과 → 📋 보고서로 정리 → 👤 관객에게 전달     │
│                                                             │
│  return result  # 🎁 "짜잔! 결과를 JSON으로 포장해서 드려요!" │
└─────────────────────────────────────────────────────────────┘
```

**🔄 실제 데이터 변환 과정:**
```
📱 클라이언트        🎯 FastAPI         🔧 Service         ☁️ Google
     │                  │                │                  │
🎤 .m4a 파일 ──────► 📦 UploadFile ──► 🎵 bytes ────► 📝 "안녕하세요"
     │                  │                │                  │
👤 "홍길동" ────────► 📝 Form 데이터 ──► 🏷️ AudioRequest    │
     │                  │                │                  │
     │                  │                │ ◄────────────── 📊 결과
     │                  │                │                  │
     │ ◄──────────── 📋 JSON 응답 ◄─── 📊 AnalysisResponse  │
```

### 4. 오류 처리 계층
```python
# 서비스 계층 (speech_to_text.py)
def validate_audio_file(self, filename: str, file_size: int):
    if file_size > 10 * 1024 * 1024:  # 10MB 제한
        return {"is_valid": False, "errors": ["파일이 너무 큽니다"]}

# API 계층 (main.py)
validation = stt_service.validate_audio_file(file.filename, len(audio_content))
if not validation["is_valid"]:
    raise HTTPException(
        status_code=400, 
        detail=f"검증 실패: {validation['errors']}"
    )
```

---

## 🚀 실제 사용 예제

### 1. 서버 실행
```bash
# 환경변수 설정
export GCP_PROJECT_ID=senior-mhealth-lecture
export GCP_LOCATION=asia-northeast3

# 의존성 설치
pip install -r requirements.txt

# 서버 실행
python -m app.main
# 또는
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

### 2. API 테스트

#### 헬스체크
```bash
curl http://localhost:8080/
curl http://localhost:8080/health
```

#### 텍스트 분석
```bash
curl -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "text": "요즘 기분이 우울하고 힘들어요",
    "user_id": "test_user"
  }'
```

#### 음성 파일 분석 (핵심 기능)
```bash
curl -X POST http://localhost:8080/analyze-audio \
  -F "file=@통화녹음어머니_250505_122325.m4a" \
  -F "user_id=test_user" \
  -F "language_code=ko-KR"
```

### 3. 브라우저에서 API 문서 확인
```
http://localhost:8080/docs     # Swagger UI
http://localhost:8080/redoc    # ReDoc
```

---

## 🎯 핵심 개념 정리

### API 로직의 역할
```
클라이언트 요청 ──► API 로직 ──► 비즈니스 로직 ──► 응답
    (HTTP)         (FastAPI)     (Service Layer)    (JSON)
```

1. **HTTP 요청 받기**: 파일, JSON 데이터 등
2. **데이터 검증**: Pydantic으로 자동 검증
3. **서비스 호출**: 실제 작업을 서비스 계층에 위임
4. **응답 생성**: 결과를 JSON으로 변환하여 반환
5. **오류 처리**: 예외를 적절한 HTTP 상태 코드로 변환

### FastAPI의 역할
- **HTTP 서버**: 웹 요청을 받고 응답하는 서버
- **라우팅**: URL 경로를 함수에 매핑
- **자동 검증**: 입력 데이터 타입 및 형식 검증
- **문서 생성**: API 명세서 자동 생성
- **비동기 처리**: 동시에 여러 요청 처리 가능

### 서비스 계층의 역할
- **비즈니스 로직**: 실제 작업 수행 (음성 인식, AI 분석)
- **외부 API 호출**: Google Cloud 서비스 연동
- **데이터 처리**: 파일 검증, 형식 변환 등
- **오류 처리**: 비즈니스 규칙에 따른 예외 처리

---

## 📝 용어 사전

| 용어 | 설명 | 예시 |
|------|------|------|
| **API** | 소프트웨어 간 소통 규칙 | REST API, GraphQL |
| **엔드포인트** | API의 특정 URL 경로 | `/analyze`, `/transcribe` |
| **FastAPI** | Python 웹 API 프레임워크 | `@app.post("/analyze")` |
| **Uvicorn** | ASGI 웹 서버 | `uvicorn app.main:app` |
| **Pydantic** | 데이터 검증 라이브러리 | `class AudioRequest(BaseModel)` |
| **HTTP 메서드** | 요청 유형 | GET, POST, PUT, DELETE |
| **JSON** | 데이터 교환 형식 | `{"key": "value"}` |
| **비동기 (async)** | 동시 처리 방식 | `async def`, `await` |
| **의존성 주입** | 객체 간 의존 관계 관리 | 서비스 인스턴스 주입 |
| **계층 구조** | 코드 조직화 방식 | Controller → Service → Infrastructure |

---

## 🎉 마무리

이 프로젝트는 **음성 기반 정신건강 분석 서비스**로, 다음과 같은 흐름으로 동작합니다:

1. **사용자**: 음성 파일 업로드 (`.m4a` 등)
2. **STT 서비스**: 음성을 한국어 텍스트로 변환
3. **AI 분석**: Gemini 모델로 정신건강 상태 분석
4. **결과 반환**: 우울도, 불안도, 권장사항 등 제공

**핵심 엔드포인트**: `POST /analyze-audio` - 음성 파일 하나로 모든 분석 완료!

이러한 구조를 통해 **확장성**, **유지보수성**, **테스트 용이성**을 확보했으며, FastAPI의 강력한 기능들을 활용하여 개발 생산성을 크게 향상시켰습니다. 🚀
