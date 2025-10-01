# Week 4: Cloud Run & Docker - 컨테이너 기반 배포

## 🎯 학습 목표

Docker 컨테이너 기술을 이해하고 Google Cloud Run을 사용하여 AI Service와 API Service를 서버리스 환경에 배포합니다.

## 📚 핵심 개념

### 1. 컨테이너 기술 이해

### 컨테이너 vs 가상머신

```
가상머신 (VM)                    컨테이너
┌─────────────────┐            ┌─────────────────┐
│   App A         │            │   App A         │
│   Libraries     │            │   Libraries     │
│   Guest OS      │            └─────────────────┘
└─────────────────┘            ┌─────────────────┐
┌─────────────────┐            │   App B         │
│   App B         │            │   Libraries     │
│   Libraries     │            └─────────────────┘
│   Guest OS      │            ┌─────────────────┐
└─────────────────┘            │ Container Engine│
┌─────────────────┐            │    (Docker)     │
│   Hypervisor    │            └─────────────────┘
└─────────────────┘            ┌─────────────────┐
┌─────────────────┐            │    Host OS      │
│    Host OS      │            └─────────────────┘
└─────────────────┘
```

**💡 쉽게 이해하기 - 아파트 비유:**
- **가상머신 (VM)** = 독립된 집 🏠
  - 각자 전용 부엌, 화장실, 전기/수도 (Guest OS)
  - 무겁고 비효율적 (GB 단위)
  - 시작 시간: 1-2분

- **컨테이너** = 원룸 공유 아파트 🏢
  - 공용 시설 공유 (Host OS 커널 공유)
  - 가볍고 효율적 (MB 단위)
  - 시작 시간: 1-2초

### 컨테이너의 장점

- **경량성**: OS 커널 공유로 리소스 효율적
- **이식성**: 어디서든 동일하게 실행
- **빠른 시작**: 초 단위 시작 시간
- **일관성**: 개발-스테이징-프로덕션 환경 동일

**💡 "내 컴퓨터에선 되는데?" 문제 완전 해결!**

### 2. Docker 핵심 구성 요소

### Docker 아키텍처

```
┌──────────────────────────────────────┐
│          Docker Client               │
│     (docker build, run, push)        │
└──────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────┐
│          Docker Daemon               │
│         (Docker Engine)               │
└──────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────┐
│     Images    │    Containers        │
│  (템플릿)      │    (실행 인스턴스)      │
└──────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────┐
│         Docker Registry              │
│   (Docker Hub, Artifact Registry)   │
└──────────────────────────────────────┘
```

**💡 도시락 비유로 이해하기:**
  - Dockerfile: 도시락 만드는 레시피 (설계도)
  - Docker Image: 포장된 도시락 세트 (실행 준비 완료      
  상태)
  - Docker Container: 실제로 펼쳐놓고 사용 중인 도시락    
   (실행 중인 인스턴스)
  - Registry: 도시락 보관 창고 (이미지 저장소)


### Dockerfile 구조

```dockerfile
# 베이스 이미지
FROM node:18-alpine

# 작업 디렉토리
WORKDIR /app

# 의존성 파일 복사
COPY package*.json ./

# 의존성 설치
RUN npm ci --only=production

# 앱 코드 복사
COPY . .

# 포트 노출
EXPOSE 8080

# 실행 명령
CMD ["node", "server.js"]
```

**💡 각 명령어 쉽게 이해하기:**
- **FROM**: 기본 환경 선택 (이미 Node.js 설치된 이미지 사용)
- **WORKDIR**: 작업 폴더 지정
- **COPY**: 파일을 컨테이너로 복사
- **RUN**: 명령어 실행 (패키지 설치 등)
- **EXPOSE**: 통신할 포트 번호 지정
- **CMD**: 컨테이너 시작시 실행할 명령

### 3. Google Cloud Run 특징

### Cloud Run = 서버리스 컨테이너 플랫폼

```
특징:
✓ 완전 관리형 (Fully Managed)
✓ 자동 스케일링 (0 → N)
✓ 요청 기반 과금
✓ HTTPS 자동 제공
✓ 커스텀 도메인 지원
```

**💡 식당 배달 서비스로 이해하기:**
- **전통적 서버** = 직접 식당 운영 (24시간 직원 대기, 고정 비용)
- **Cloud Run** = 배달 대행 서비스 (주문시만 배달원 출발, 사용한 만큼만 과금)

**💰 실제 비용 예시:**
- 월 200만 요청까지 무료
- 일일 2,000 요청 × 30일 = 60,000 요청 → 완전 무료!

### Cloud Run vs 다른 서비스

| 서비스 | 적합한 경우 | 부적합한 경우 |
|--------|------------|---------------|
| Cloud Run | 웹 API, 마이크로서비스 | 상태 저장, 장시간 실행 |
| App Engine | 전통적 웹 앱 | 컨테이너 커스터마이징 |
| GKE | 복잡한 오케스트레이션 | 간단한 웹 서비스 |
| Cloud Functions | 이벤트 기반 처리 | 큰 패키지, 긴 실행 시간 |

### 4. Artifact Registry

### Google Artifact Registry

> ℹ️ **참고**: Google Container Registry(GCR)는 Artifact Registry로 대체되었습니다.
> - 신규 프로젝트는 Artifact Registry 사용 필수
> - Artifact Registry는 Docker 이미지뿐만 아니라 npm, Maven, Python 등 다양한 패키지 지원

```
Artifact Registry 구조:
[REGION]-docker.pkg.dev/[PROJECT-ID]/[REPOSITORY]/[IMAGE]:[TAG]

예시 (신규):
asia-northeast3-docker.pkg.dev/senior-mhealth-lee/backend/ai-service:v1
└────────────┘└──────────────┘└──────────────┘└──────┘└────────┘└─┘
    리전        도메인            프로젝트 ID      저장소    이미지    태그

예시:
asia-northeast3-docker.pkg.dev/senior-mhealth-lee/backend/ai-service:v1
```

**💡 클라우드 창고로 이해하기:**
- **로컬**: docker build로 이미지 생성 (내 컴퓨터에만 존재)
- **Artifact Registry**: docker push로 창고에 보관 (팀원 누구나 사용 가능)
- **Cloud Run**: Registry에서 이미지 가져와서 실행

**🆕 Artifact Registry의 장점:**
- 리전별 저장소 (한국 리전 사용 가능 → 더 빠른 속도)
- 세밀한 권한 관리
- 취약점 스캔 강화
- npm, Maven, Python 패키지도 저장 가능


## 🚀 실습: Cloud Run 서비스 배포

### Docker Desktop 설치 가이드 👤

#### Windows 설치 방법

##### Docker Desktop 간편 설치 (2024년 최신)

> 💡 **좋은 소식!** 최신 Docker Desktop은 WSL 2를 **자동으로 설치**합니다!
> - 설치 중 WSL 2가 없으면 자동으로 활성화 및 설치
> - 복잡한 수동 설정 불필요
> - Docker Desktop이 모든 설정을 자동으로 처리

1. **Docker Desktop for Windows 다운로드**
   - https://www.docker.com/products/docker-desktop/ 접속
   - "Download for Windows" 클릭
   - 설치 파일 실행 (약 500MB)

2. **설치 과정**
   - 설치 프로그램 실행
   - "Use WSL 2 instead of Hyper-V" 옵션이 기본으로 선택됨 ✅
   - WSL 2가 없으면 자동으로 설치 제안
   - 설치 완료 후 재부팅 필요

3. **시스템 요구사항**
   - Windows 10 버전 22H2 이상 (빌드 19045 이상)
   - Windows 11 모든 버전
   - 64비트 시스템
   - 4GB 이상 RAM

4. **설치 확인**
   ```powershell
   # PowerShell에서 실행
   docker --version
   docker run hello-world

   # WSL 통합 확인 (자동 설치됨)
   wsl -l -v
   # Ubuntu와 docker-desktop이 표시되어야 함
   ```

5. **문제 해결 (필요한 경우만)**

   **수동 WSL 2 설치가 필요한 경우:**
   ```powershell
   # PowerShell 관리자 권한으로 실행

   # WSL 설치 (최신 명령어)
   wsl --install

   # 재부팅 후 확인
   wsl --status
   ```

   **Docker Desktop 시작 오류 시:**
   - Settings → General → "Use the WSL 2 based engine" 체크 확인
   - Windows 업데이트 확인
   - 가상화 기능 BIOS에서 활성화 확인

#### Mac 설치 방법
1. **Docker Desktop for Mac 다운로드**
   - https://www.docker.com/products/docker-desktop/ 접속
   - "Download for Mac" 클릭
   - Intel 칩 또는 Apple Silicon (M1/M2) 선택

2. **설치 과정**
   - 다운로드한 Docker.dmg 실행
   - Docker 아이콘을 Applications로 드래그
   - Applications에서 Docker 실행

3. **설치 확인**
   ```bash
   # Terminal에서 실행
   docker --version
   docker run hello-world
   ```

#### 공통 설정
- Docker Desktop 실행 후 우측 상단 고래 아이콘 확인 🐳
- Settings → Resources에서 메모리/CPU 할당 조정 가능
- 권장 설정: Memory 4GB, CPU 2 cores 이상

### 🤖 Vibe 코딩 프롬프트 - Docker 설치

```
Docker Desktop을 설치해주세요.

Windows 사용자:
1. Docker Desktop for Windows를 다운로드하고 설치해주세요
2. WSL 2는 자동으로 설치됩니다
3. 설치 후 재부팅해주세요
4. docker --version으로 확인해주세요

Mac 사용자:
1. Docker Desktop for Mac을 다운로드해주세요
2. Applications에 설치해주세요
3. docker --version으로 확인해주세요
```

### 사전 준비 확인 🤖

```bash
# 1. Docker 설치 확인
docker --version
# 출력 예: Docker version 24.0.7, build afdd53b

# 2. 현재 프로젝트 확인
gcloud config get-value project
# 출력: senior-mhealth-lee

# 3. 필요한 API 활성화
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# 4. 서비스 계정 키 확인
ls serviceAccountKey.json
```

### 🤖 Vibe 코딩 프롬프트 - 프로젝트 설정

```
Google Cloud에서 Cloud Run과 Docker를 위한 환경을 설정해주세요.

1. 현재 프로젝트를 본인 프로젝트 Id 로 설정해주세요
2. Cloud Run, Container Registry, Cloud Build API를 활성화해주세요
3. serviceAccountKey.json 파일이 있는지 확인해주세요
```

---

## Step 1: AI Service 컨테이너화 및 배포 (Docker 빌드)

### 1.1 Google AI Studio에서 Gemini API 키 발급 👤

> ⚠️ **중요**: AI Service가 구동되기 위해서는 Google AI Studio에서 Gemini API 키를 발급받아야 합니다.

#### Google AI Studio API 키 발급 과정

1. **Google AI Studio 접속**
   - https://aistudio.google.com/ 접속
   - Google 계정으로 로그인

2. **기존 프로젝트 선택**
   - 좌측 상단의 프로젝트 선택 드롭다운 클릭
   - 이미 생성한 GCP 프로젝트 선택 (예: `senior-mhealth-lee`)
   - 새 프로젝트가 아닌 **기존 프로젝트를 반드시 선택**해야 함

3. **API 키 생성**
   - 좌측 메뉴에서 "Get API key" 클릭
   - "Create API key" 버튼 클릭
   - "Create API key in existing project" 선택
   - 본인의 GCP 프로젝트 선택 (예: `senior-mhealth-lee`)
   - API 키가 생성되면 복사하여 안전한 곳에 저장

4. **API 키 확인**
   ```
   예시 API 키 형식:
   AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

> 💡 **주의사항**: 
> - API 키는 외부에 노출되지 않도록 주의
> - 반드시 기존 GCP 프로젝트와 연결하여 생성
> - API 키는 한 번만 표시되므로 즉시 복사하여 저장

### 🤖 Vibe 코딩 프롬프트 - Google AI Studio API 키 발급

```
Google AI Studio에서 Gemini API 키를 발급받아주세요.

1. https://aistudio.google.com/ 에 접속해주세요
2. Google 계정으로 로그인해주세요
3. 기존 GCP 프로젝트를 선택해주세요 (새 프로젝트 생성 X)
4. "Get API key" → "Create API key" → "Create API key in existing project" 선택
5. 본인의 GCP 프로젝트를 선택해주세요
6. 생성된 API 키를 복사하여 안전하게 저장해주세요
```

### 1.2 AI Service 환경 설정 🤖

```bash
# backend/ai-service로 이동
cd backend/ai-service

# 필요한 API 활성화
gcloud services enable generativelanguage.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable speech.googleapis.com

# 환경 변수 파일 생성 (Google AI Studio API 키 사용)
cat > .env << EOF
# Google AI Studio API 키 (1.1에서 발급받은 키)
GOOGLE_AI_API_KEY=YOUR_GEMINI_API_KEY_HERE

# 프로젝트 설정
GOOGLE_CLOUD_PROJECT=senior-mhealth-lee
GCP_PROJECT_ID=senior-mhealth-lee

# 모델 설정 (Gemini 2.0 사용 가능)
MODEL_NAME=gemini-2.0-flash-exp
ENVIRONMENT=production
PORT=8081

# 로깅 설정
LOG_LEVEL=INFO
EOF

# .env 파일 편집하여 실제 API 키 입력
echo "⚠️  .env 파일을 편집하여 YOUR_GEMINI_API_KEY_HERE를 실제 API 키로 교체하세요"
```

> 🔑 **중요**: `YOUR_GEMINI_API_KEY_HERE` 부분을 1.1단계에서 발급받은 실제 API 키로 교체해야 합니다.

### 🤖 Vibe 코딩 프롬프트 - AI Service 설정

```
AI Service를 위한 환경을 설정해주세요.

1. backend/ai-service 폴더로 이동해주세요
2. 필요한 API들을 활성화해주세요:
   - Generative Language API: gcloud services enable generativelanguage.googleapis.com
   - Secret Manager API: gcloud services enable secretmanager.googleapis.com
   - Speech-to-Text API: gcloud services enable speech.googleapis.com
3. .env 파일을 만들고 다음 설정을 추가해주세요:
   - GOOGLE_AI_API_KEY=발급받은_실제_API_키
   - GOOGLE_CLOUD_PROJECT=senior-mhealth-lee
   - MODEL_NAME=gemini-2.0-flash-exp
   - ENVIRONMENT=production
   - PORT=8081
4. .env 파일에서 YOUR_GEMINI_API_KEY_HERE를 실제 API 키로 교체해주세요
```

### 1.3 Dockerfile 생성 🤖

```bash
cat > Dockerfile << 'EOF'
# Python 베이스 이미지
FROM python:3.9-slim

# 작업 디렉토리 설정
WORKDIR /app

# 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Python 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 앱 코드 복사
COPY . .

# 환경 변수 설정
ENV PORT=8081
ENV PYTHONUNBUFFERED=1

# 헬스체크
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8081/health || exit 1

# 서버 실행
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8081"]
EOF
```

### 🤖 Vibe 코딩 프롬프트 - Dockerfile 생성

```
AI Service를 위한 Dockerfile을 생성해주세요.

1. backend/ai-service 폴더에서 작업해주세요
2. Python 3.9-slim을 베이스 이미지로 사용해주세요
3. requirements.txt의 패키지들을 설치해주세요
4. PORT 8081에서 uvicorn으로 앱을 실행해주세요
5. 헬스체크 endpoint도 설정해주세요
```

### 1.4 Docker로 이미지 빌드 및 푸시 🤖

> ⚠️ **중요**: AI Service는 Docker를 사용하여 로컬에서 빌드하고 Registry에 푸시합니다.

#### Artifact Registry 사용 

```bash
# Artifact Registry 저장소 생성 (처음 한 번만)
gcloud artifacts repositories create backend \
  --repository-format=docker \
  --location=asia-northeast3 \
  --description="Backend services"

# Artifact Registry 인증
gcloud auth configure-docker asia-northeast3-docker.pkg.dev

# 프로젝트 ID 설정
export PROJECT_ID=$(gcloud config get-value project)

# 이미지 빌드 (Artifact Registry 태그)
docker build -t asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/ai-service:v1 .

# 이미지 푸시
docker push asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/ai-service:v1

# 푸시 확인
gcloud artifacts docker images list \
  asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend
```

### 🤖 Vibe 코딩 프롬프트 - Docker 이미지 빌드 및 푸시

```
AI Service Docker 이미지를 빌드하고 Artifact Registry에 푸시해주세요.

1. Artifact Registry에 backend 저장소를 생성해주세요 (asia-northeast3)
2. Docker 인증을 설정해주세요
3. 이미지를 빌드해주세요 (태그: v1)
4. 빌드한 이미지를 Registry에 푸시해주세요
5. 푸시된 이미지를 확인해주세요
```

### 1.6 Cloud Run 배포 🤖

> ⚠️ **중요**: 배포 시 Google AI Studio에서 발급받은 API 키를 환경변수로 설정해야 합니다.

```bash
# 환경변수 설정 (실제 API 키로 교체 필요)
export GOOGLE_AI_API_KEY="YOUR_ACTUAL_API_KEY_HERE"
export PROJECT_ID=$(gcloud config get-value project)

# Cloud Run 배포 (Google AI Studio API 키 포함)
gcloud run deploy senior-mhealth-ai \
  --image asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/ai-service:v1 \
  --platform managed \
  --region asia-northeast3 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-instances 5 \
  --allow-unauthenticated \
  --service-account=automation-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --set-env-vars="GOOGLE_AI_API_KEY=${GOOGLE_AI_API_KEY},GOOGLE_CLOUD_PROJECT=${PROJECT_ID},MODEL_NAME=gemini-2.0-flash-exp,ENVIRONMENT=production,LOG_LEVEL=INFO"

# 배포 성공 시 URL 저장
export AI_SERVICE_URL=$(gcloud run services describe senior-mhealth-ai \
  --platform managed \
  --region asia-northeast3 \
  --format 'value(status.url)')

echo "AI Service URL: $AI_SERVICE_URL"
```

> 🔑 **API 키 보안 주의사항**:
> - `YOUR_ACTUAL_API_KEY_HERE`를 실제 발급받은 API 키로 교체
> - API 키는 터미널 히스토리에 남지 않도록 주의
> - 프로덕션 환경에서는 Secret Manager 사용 권장

### 🤖 Vibe 코딩 프롬프트 - AI Service Cloud Run 배포

```
AI Service를 Cloud Run에 배포해주세요.

1. 먼저 환경변수를 설정해주세요:
   - export GOOGLE_AI_API_KEY="발급받은_실제_API_키"
   - export PROJECT_ID=$(gcloud config get-value project)

2. Cloud Run 배포 설정:
   - 서비스 이름: senior-mhealth-ai
   - 리전: asia-northeast3
   - 메모리: 2Gi, CPU: 2
   - 타임아웃: 300초, 최대 인스턴스: 5
   - 인증 없이 접근 가능하도록 설정

3. 환경 변수 설정:
   - GOOGLE_AI_API_KEY (발급받은 API 키)
   - GOOGLE_CLOUD_PROJECT (프로젝트 ID)
   - MODEL_NAME=gemini-2.0-flash-exp
   - ENVIRONMENT=production

4. 배포된 서비스 URL을 확인해주세요
```

### 1.7 서비스 검증 🤖

```bash
# 헬스체크
curl ${AI_SERVICE_URL}/health

# 예상 응답:
# {
#   "status": "healthy",
#   "service": "ai-analysis",
#   "timestamp": "2024-09-28T..."
# }

# API 테스트
curl -X POST ${AI_SERVICE_URL}/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "text": "오늘 기분이 좋아요",
    "type": "emotion"
  }'
```

### 🤖 Vibe 코딩 프롬프트 - AI Service 검증

```
AI Service가 제대로 배포되었는지 확인해주세요.

1. 헬스체크 엔드포인트를 호출해주세요
2. /analyze 엔드포인트로 테스트 요청을 보내주세요
3. 응답이 정상적으로 오는지 확인해주세요
```

---

## Step 2: API Service 컨테이너화 및 배포 (Cloud Build)

### 2.1 API Service 환경 설정 🤖

```bash
# backend/api-service로 이동
cd ../api-service

# 환경 변수 파일 생성
cat > .env << EOF
GOOGLE_CLOUD_PROJECT=${PROJECT_ID}
AI_SERVICE_URL=${AI_SERVICE_URL}
FIREBASE_PROJECT_ID=${PROJECT_ID}
NODE_ENV=production
PORT=8080
EOF
```

### 🤖 Vibe 코딩 프롬프트 - API Service 환경 설정

```
API Service를 위한 환경을 설정해주세요.

1. backend/api-service 폴더로 이동해주세요
2. .env 파일을 생성해주세요
3. 프로젝트 ID와 AI Service URL을 환경 변수로 추가해주세요
4. Firebase 프로젝트 ID와 포트 8080을 설정해주세요
```

### 2.2 Dockerfile 생성 🤖

```bash
cat > Dockerfile << 'EOF'
# Node.js 베이스 이미지
FROM node:18-alpine

# 작업 디렉토리 설정
WORKDIR /app

# 패키지 파일 복사
COPY package*.json ./

# 프로덕션 의존성만 설치
RUN npm ci --only=production

# 앱 코드 복사
COPY . .

# 환경 변수
ENV PORT=8080
ENV NODE_ENV=production

# 헬스체크
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# 서버 실행
CMD ["node", "server.js"]
EOF
```

### 🤖 Vibe 코딩 프롬프트 - API Service Dockerfile 생성

```
API Service를 위한 Dockerfile을 생성해주세요.

1. Node.js 18-alpine을 베이스 이미지로 사용해주세요
2. npm ci로 production 의존성만 설치해주세요
3. PORT 8080에서 node server.js로 앱을 실행해주세요
4. 헬스체크 endpoint도 설정해주세요
```

### 2.3 Cloud Build를 사용한 이미지 빌드 및 푸시 🤖

> ⚠️ **중요**: API Service는 Google Cloud Build를 사용하여 클라우드에서 빌드합니다.
> Docker 설치 없이도 빌드가 가능하며, 더 안전하고 빠릅니다.

#### Cloud Build 설정 파일 생성

```bash
# cloudbuild.yaml 파일 생성
cat > cloudbuild.yaml << 'EOF'
# Cloud Build 설정
steps:
  # 1단계: Docker 이미지 빌드
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'asia-northeast3-docker.pkg.dev/$PROJECT_ID/backend/api-service:$SHORT_SHA'
      - '-t'
      - 'asia-northeast3-docker.pkg.dev/$PROJECT_ID/backend/api-service:latest'
      - '.'

  # 2단계: 이미지를 Artifact Registry에 푸시
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'push'
      - 'asia-northeast3-docker.pkg.dev/$PROJECT_ID/backend/api-service:$SHORT_SHA'

  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'push'
      - 'asia-northeast3-docker.pkg.dev/$PROJECT_ID/backend/api-service:latest'

# 빌드된 이미지 목록
images:
  - 'asia-northeast3-docker.pkg.dev/$PROJECT_ID/backend/api-service:$SHORT_SHA'
  - 'asia-northeast3-docker.pkg.dev/$PROJECT_ID/backend/api-service:latest'

# 빌드 옵션
options:
  logging: CLOUD_LOGGING_ONLY
  machineType: 'N1_HIGHCPU_8'
EOF
```

#### Cloud Build 실행

```bash
# Artifact Registry 저장소 생성 (처음 한 번만)
gcloud artifacts repositories create backend \
  --repository-format=docker \
  --location=asia-northeast3 \
  --description="Backend services"

# Cloud Build 실행
gcloud builds submit \
  --config cloudbuild.yaml \
  --substitutions SHORT_SHA="v1" \
  --region asia-northeast3 .

# 빌드 상태 확인
gcloud builds list --limit 5

# 빌드된 이미지 확인
gcloud artifacts docker images list \
  asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend
```

### 🤖 Vibe 코딩 프롬프트 - Cloud Build 실행

```
Cloud Build를 사용하여 API Service 이미지를 빌드해주세요.

1. cloudbuild.yaml 파일을 생성해주세요
2. Docker 빌드와 푸시 단계를 설정해주세요
3. Artifact Registry backend 저장소를 사용해주세요
4. Cloud Build를 실행하여 이미지를 빌드해주세요
5. 빌드된 이미지를 확인해주세요
```

### 2.4 Cloud Run 배포 🤖

```bash
# Cloud Build로 빌드한 이미지 사용
gcloud run deploy senior-mhealth-api \
  --image asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/api-service:latest \
  --platform managed \
  --region asia-northeast3 \
  --memory 1Gi \
  --cpu 1 \
  --timeout 60 \
  --max-instances 10 \
  --allow-unauthenticated \
  --set-env-vars="GOOGLE_CLOUD_PROJECT=${PROJECT_ID},AI_SERVICE_URL=${AI_SERVICE_URL}"

# URL 저장
export API_SERVICE_URL=$(gcloud run services describe senior-mhealth-api \
  --platform managed \
  --region asia-northeast3 \
  --format 'value(status.url)')

echo "API Service URL: $API_SERVICE_URL"
```

### 🤖 Vibe 코딩 프롬프트 - API Service Cloud Run 배포

```
API Service를 Cloud Run에 배포해주세요.

1. 서비스 이름: senior-mhealth-api
2. Cloud Build로 빌드한 이미지를 사용해주세요
3. 리전: asia-northeast3
4. 메모리: 1Gi, CPU: 1
5. 타임아웃: 60초, 최대 인스턴스: 10
6. 인증 없이 접근 가능하도록 설정
7. 환경 변수로 프로젝트 ID와 AI Service URL을 설정해주세요
8. 배포된 서비스 URL을 확인해주세요
```

### 2.5 서비스 검증 🤖

```bash
# 헬스체크
curl ${API_SERVICE_URL}/health

# API 테스트
curl -X POST ${API_SERVICE_URL}/api/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "text": "테스트 메시지입니다",
    "userId": "test-user"
  }'
```

### 🤖 Vibe 코딩 프롬프트 - API Service 검증

```
API Service가 제대로 배포되었는지 확인해주세요.

1. 헬스체크 엔드포인트를 호출해주세요
2. /api/analyze 엔드포인트로 테스트 요청을 보내주세요
3. AI Service와의 연동이 정상적으로 작동하는지 확인해주세요
```

---

## Step 3: 서비스 통합 및 환경 설정

### 3.1 프로젝트 환경 변수 업데이트 🤖

```bash
# 프로젝트 루트로 이동
cd ../..

# .env 파일에 Cloud Run URL 추가
cat >> .env << EOF

# Cloud Run Services
CLOUD_RUN_AI_URL=${AI_SERVICE_URL}
CLOUD_RUN_API_URL=${API_SERVICE_URL}
EOF

echo "환경 변수가 업데이트되었습니다."
```

### 🤖 Vibe 코딩 프롬프트 - 프로젝트 환경 변수 업데이트

```
프로젝트의 루트 .env 파일에 배포된 Cloud Run 서비스들의 URL을 추가해주세요.

1. 프로젝트 루트 폴더로 이동해주세요.
2. .env 파일을 열어주세요.
3. 다음 내용을 파일 끝에 추가해주세요:
   - CLOUD_RUN_AI_URL=[배포된 AI 서비스의 URL]
   - CLOUD_RUN_API_URL=[배포된 API 서비스의 URL]
4. 환경 변수가 올바르게 추가되었는지 확인해주세요.
```

### 3.2 Firebase Functions 환경 설정 🤖

```bash
# Functions 디렉토리로 이동
cd backend/functions

# Firebase Functions 환경 변수 설정
firebase functions:config:set \
  services.ai_url="${AI_SERVICE_URL}" \
  services.api_url="${API_SERVICE_URL}"

# 설정 확인
firebase functions:config:get
```

---

## Step 4: 모니터링 및 관리

### 4.1 Cloud Console에서 확인 👤

1. [Cloud Run Console](https://console.cloud.google.com/run) 접속
2. 서비스 목록 확인:
   - senior-mhealth-ai
   - senior-mhealth-api
3. 각 서비스 클릭하여 확인:
   - **메트릭**: 요청 수, 응답 시간, 에러율
   - **로그**: 실시간 로그 스트리밍
   - **리비전**: 배포 이력

### 4.2 CLI로 모니터링 🤖

```bash
# 서비스 상태 확인
gcloud run services list --platform managed --region asia-northeast3

# AI Service 로그 확인
gcloud logging read "resource.type=cloud_run_revision \
  AND resource.labels.service_name=senior-mhealth-ai" \
  --limit 20 \
  --format json | jq '.[] | {timestamp: .timestamp, message: .textPayload}'

# API Service 로그 확인
gcloud logging read "resource.type=cloud_run_revision \
  AND resource.labels.service_name=senior-mhealth-api" \
  --limit 20 \
  --format json | jq '.[] | {timestamp: .timestamp, message: .textPayload}'

# 메트릭 확인
gcloud monitoring metrics-descriptors list \
  --filter="metric.type:run.googleapis.com"
```

### 4.3 서비스 업데이트 🤖

#### AI Service 업데이트 (Docker)

```bash
# AI Service - Docker로 빌드 및 배포
cd backend/ai-service

# 환경변수 재설정 (API 키 포함)
export GOOGLE_AI_API_KEY="YOUR_ACTUAL_API_KEY_HERE"
export PROJECT_ID=$(gcloud config get-value project)

# 새 버전 빌드 및 푸시
docker build -t asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/ai-service:v2 .
docker push asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/ai-service:v2

# 새 리비전 배포 (API 키 환경변수 포함)
gcloud run deploy senior-mhealth-ai \
  --image asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/ai-service:v2 \
  --platform managed \
  --region asia-northeast3 \
  --set-env-vars="GOOGLE_AI_API_KEY=${GOOGLE_AI_API_KEY},GOOGLE_CLOUD_PROJECT=${PROJECT_ID},MODEL_NAME=gemini-2.0-flash-exp,ENVIRONMENT=production,LOG_LEVEL=INFO"
```

### 🤖 Vibe 코딩 프롬프트 - AI Service 업데이트

```
AI Service를 새 버전으로 업데이트해주세요.

1. backend/ai-service 폴더로 이동해주세요
2. 환경변수를 재설정해주세요:
   - export GOOGLE_AI_API_KEY="발급받은_실제_API_키"
   - export PROJECT_ID=$(gcloud config get-value project)
3. Docker로 새 버전(v2) 이미지를 빌드해주세요
4. 빌드한 이미지를 Registry에 푸시해주세요
5. Cloud Run에 새 리비전을 배포할 때 API 키 환경변수를 포함해주세요
```

#### API Service 업데이트 (Cloud Build)

```bash
# API Service - Cloud Build로 빌드 및 배포
cd backend/api-service

# Cloud Build 실행
gcloud builds submit \
  --config cloudbuild.yaml \
  --substitutions SHORT_SHA="v2" \
  --region asia-northeast3 .

# 새 리비전 배포
gcloud run deploy senior-mhealth-api \
  --image asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/api-service:v2 \
  --platform managed \
  --region asia-northeast3
```

### 🤖 Vibe 코딩 프롬프트 - API Service 업데이트

```
API Service를 새 버전으로 업데이트해주세요.

1. backend/api-service 폴더로 이동해주세요
2. Cloud Build로 새 버전(v2)을 빌드해주세요
3. Cloud Run에 새 이미지를 배포해주세요
4. 배포가 성공했는지 확인해주세요
```

#### 트래픽 분할 (카나리 배포)

```bash

# 트래픽 분할 (카나리 배포)
gcloud run services update-traffic senior-mhealth-ai \
  --to-revisions=LATEST=10 \
  --platform managed \
  --region asia-northeast3
```

### 🤖 Vibe 코딩 프롬프트 - 카나리 배포

```
카나리 배포를 설정해주세요.

1. 새 버전에 10%의 트래픽만 보내주세요
2. 나머지 90%는 기존 버전으로 보내주세요
3. 문제가 없다면 점진적으로 트래픽을 늘려주세요
4. 문제가 발생하면 즉시 롤백해주세요
```

---

## 🆕 빌드 방법 비교

### Docker 빌드 vs Cloud Build

| 특징 | Docker 빌드 | Cloud Build |
|------|------------|-------------|
| **사용 서비스** | AI Service | API Service |
| **빌드 위치** | 로컬 컴퓨터 | Google Cloud |
| **사전 요구사항** | Docker 설치 필수 | Docker 설치 불필요 |
| **빌드 속도** | 컴퓨터 성능에 따라 다름 | 클라우드 상에서 빠르게 빌드 |
| **사용 비용** | 무료 | 120분/일 무료 |
| **빌드 자동화** | 번거로움 | Git 푸시시 자동 빌드 가능 |
| **빌드 이력** | 로컬에만 저장 | Cloud Console에서 확인 가능 |

### 선택 기준

**Docker 빌드를 선택하는 경우:**
- 특수한 환경 설정이 필요한 경우 (AI Service)
- 빌드 프로세스를 세밀하게 제어해야 하는 경우
- 로컬 테스트가 중요한 경우

**Cloud Build를 선택하는 경우:**
- Docker 설치가 어려운 환경
- CI/CD 파이프라인 구축
- 팀 협업 프로젝트
- 빌드 자동화가 필요한 경우



## 🔍 핵심 개념 정리: AI Service vs API Service

### 서비스 구조와 역할

이 프로젝트는 **마이크로서비스 아키텍처**를 사용하여 각 서비스가 독립적으로 배포되고 운영됩니다.

#### 🏗️ 전체 시스템 아키텍처

```
┌──────────────────────────────────────────────────────┐
│           Frontend Applications                       │
│   📱 Mobile App (Flutter)  💻 Web App (Next.js)      │
└──────────────────────────────────────────────────────┘
                           ⬇️ HTTPS
┌──────────────────────────────────────────────────────┐
│        API Service (backend/api-service)             │
│              🎯 Port: 8080                           │
│         "중앙 비즈니스 로직 서버"                      │
│                                                      │
│  역할:                                               │
│  • 클라이언트 요청의 진입점                           │
│  • 사용자 인증 및 권한 관리                          │
│  • 데이터 검증 및 변환                               │
│  • Firestore 데이터베이스 CRUD                       │
│  • AI Service와의 통신 중계                          │
│  • 비즈니스 규칙 적용                                │
└──────────────────────────────────────────────────────┘
                           ⬇️ HTTP (내부 통신)
┌──────────────────────────────────────────────────────┐
│         AI Service (backend/ai-service)              │
│              🤖 Port: 8081                           │
│           "AI 분석 전문 서비스"                       │
│                                                      │
│  역할:                                               │
│  • 음성 → 텍스트 변환 (Speech-to-Text)               │
│  • 감정 분석 및 정신건강 평가                         │
│  • Vertex AI (Gemini) 직접 연동                      │
│  • AI 모델 추론 및 분석                              │
└──────────────────────────────────────────────────────┘
```

### 📊 상세 비교표

| 구분 | AI Service | API Service |
|------|-----------|-------------|
| **위치** | `backend/ai-service/` | `backend/api-service/` |
| **포트** | 8081 | 8080 |
| **언어** | Python | Node.js 또는 Python |
| **프레임워크** | FastAPI | Express 또는 FastAPI |
| **주요 기능** | AI 분석 전문 | 비즈니스 로직 처리 |
| **클라이언트 접근** | 간접 (API Service 경유) | 직접 (Frontend와 통신) |
| **데이터베이스** | 접근 안함 | Firestore 직접 조작 |
| **인증** | 없음 (내부 서비스) | Firebase Auth 통합 |
| **확장성** | 독립적 스케일링 | 독립적 스케일링 |

### 🔄 실제 요청 흐름 예시

**시니어 음성 분석 요청 처리 과정:**

```
1. 📱 모바일 앱: 음성 녹음
   ↓
2. 🌐 POST /api/voice_analysis (API Service)
   - 사용자 인증 확인
   - 요청 데이터 검증
   ↓
3. 🔄 POST /analyze-audio (AI Service 호출)
   - 음성을 텍스트로 변환
   - Vertex AI로 감정 분석
   - 정신건강 점수 계산
   ↓
4. 💾 Firestore 저장 (API Service)
   - 분석 결과 저장
   - 사용자 히스토리 업데이트
   ↓
5. 📱 응답 반환 (모바일 앱)
   - 분석 결과 표시
   - 건강 권고사항 제공
```

### 💡 왜 이렇게 분리했나요?

#### 1. **관심사의 분리 (Separation of Concerns)**
- AI Service: AI/ML 로직에만 집중
- API Service: 비즈니스 로직과 데이터 관리에 집중

#### 2. **독립적 확장성**
- AI 요청이 많을 때: AI Service만 스케일 업
- 일반 API 요청이 많을 때: API Service만 스케일 업
- 비용 최적화 가능

#### 3. **기술 스택 유연성**
- AI Service: Python (ML 라이브러리 생태계 활용)
- API Service: Node.js (빠른 I/O 처리)
- 각 서비스에 최적의 언어 사용

#### 4. **장애 격리**
- AI Service 장애 시: 기본 기능은 정상 작동
- API Service 장애 시: AI 서비스는 독립적 운영 가능
- 전체 시스템 안정성 향상

#### 5. **개발 팀 분리**
- AI 팀: AI Service 개발
- 백엔드 팀: API Service 개발
- 병렬 개발 가능

### 🚀 Cloud Run 배포 전략

두 서비스는 독립적으로 Cloud Run에 배포되어:
- **자동 스케일링**: 각자의 부하에 따라 0~N개 인스턴스
- **서로 다른 리소스 할당**:
  - AI Service: 메모리 2Gi, CPU 2 (무거운 AI 처리)
  - API Service: 메모리 1Gi, CPU 1 (가벼운 비즈니스 로직)
- **독립적 업데이트**: 한 서비스 업데이트 시 다른 서비스 영향 없음

### 📝 자주 하는 실수

1. **❌ 잘못된 접근**: Frontend에서 AI Service 직접 호출
   **✅ 올바른 접근**: Frontend → API Service → AI Service

2. **❌ 잘못된 포트**: API Service를 8081로 설정
   **✅ 올바른 포트**: API Service(8080), AI Service(8081)

3. **❌ 잘못된 인증**: AI Service에 Firebase Auth 추가
   **✅ 올바른 인증**: API Service에만 인증, AI Service는 내부 통신만

이러한 마이크로서비스 구조를 이해하면 확장 가능하고 유지보수가 쉬운 클라우드 네이티브 애플리케이션을 구축할 수 있습니다!

---

## 🎯 추가 기능: 화자 분리(Speaker Diarization)

이 프로젝트는 Google Cloud Speech API의 화자 분리 기능을 통합하여 시니어와 보호자의 대화를 자동으로 구분하고, 시니어의 발화만을 선택적으로 분석할 수 있습니다.

### 핵심 기능
- **Google Cloud Speech API 네이티브 화자 분리**: 2-3명의 화자 자동 구분
- **시니어/보호자 구분 알고리즘**: 한국어 특성 기반 화자 식별
- **선택적 분석**: 시니어 발화만 추출하여 정확한 정신건강 분석
- **Gemini 2.0 모델 통합**: 최신 AI 모델로 분석 품질 향상

### 상세 구현 문서
화자 분리 기능의 전체 구현 내용은 별도 문서를 참조하세요:
- 📄 [Week 4 추가: 화자 분리(Speaker Diarization) 기능 구현](week4-speaker-diarization.md)

### 배포된 서비스
- **URL**: https://ai-service-speaker-716250412647.asia-northeast3.run.app
- **기능**: 화자 분리 + 시니어 텍스트 추출 + Gemini 2.0 분석
- **보안**: Secret Manager를 통한 API 키 관리 (줄바꿈 없이 저장)

---

## 🔑 Google AI Studio API 키 관리 가이드

### API 키 보안 모범 사례

#### 1. 로컬 개발 환경
```bash
# .env 파일 사용 (Git에 커밋하지 않음)
echo "GOOGLE_AI_API_KEY=your-api-key" >> .env
echo ".env" >> .gitignore
```

#### 2. Cloud Run 배포 환경
```bash
# 환경변수로 직접 설정
export GOOGLE_AI_API_KEY="your-api-key"
gcloud run deploy ... --set-env-vars="GOOGLE_AI_API_KEY=${GOOGLE_AI_API_KEY}"
```

#### 3. 프로덕션 환경 (권장) - Secret Manager 사용

> ⚠️ **중요**: Secret Manager에 API 키 저장 시 줄바꿈(new line) 금지!

```bash
# 1단계: API 키 길이 확인 (Gemini API 키는 보통 39자)
echo -n "YOUR_API_KEY_HERE" | wc -c
# 예상 출력: 39 (AIzaSy로 시작하는 39자리)

# 2단계: API 키에 줄바꿈이 없는지 확인
echo -n "YOUR_API_KEY_HERE" | od -c
# 줄바꿈(\n)이나 캐리지 리턴(\r)이 없어야 함

# 3단계: Secret Manager에 저장 (줄바꿈 없이)
echo -n "YOUR_API_KEY_HERE" | gcloud secrets create gemini-api-key --data-file=-

# 4단계: 저장된 값 확인
gcloud secrets versions access latest --secret="gemini-api-key" | wc -c
# 원본 API 키와 동일한 길이여야 함 (39자)

# 5단계: Cloud Run에서 Secret Manager 연결
gcloud run deploy senior-mhealth-ai \
  --image asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/ai-service:v1 \
  --platform managed \
  --region asia-northeast3 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-instances 5 \
  --allow-unauthenticated \
  --service-account=automation-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --set-secrets="GOOGLE_AI_API_KEY=gemini-api-key:latest"
```

**🔍 Secret Manager 검증 체크리스트:**
- ✅ API 키 길이: 39자 (AIzaSy로 시작)
- ✅ 줄바꿈 없음: `echo -n` 사용 필수
- ✅ 저장 후 길이 재확인
- ✅ 특수문자나 공백 없음

### API 키 문제 해결

#### 자주 발생하는 오류

1. **"API key not found" 오류**
   - Google AI Studio에서 API 키가 올바르게 생성되었는지 확인
   - 환경변수 이름이 `GOOGLE_AI_API_KEY`인지 확인

2. **"Project not found" 오류**
   - API 키가 올바른 GCP 프로젝트와 연결되었는지 확인
   - Google AI Studio에서 기존 프로젝트를 선택했는지 확인

3. **"Quota exceeded" 오류**
   - Google AI Studio에서 사용량 한도 확인
   - 필요시 결제 계정 연결

4. **Secret Manager 관련 오류**
   - **"Secret Manager API not enabled"**: `gcloud services enable secretmanager.googleapis.com`
   - **"Invalid API key format"**: API 키 길이가 39자가 아니거나 줄바꿈 포함
   - **"Permission denied"**: 서비스 계정에 Secret Manager 권한 부족
   
   ```bash
   # Secret Manager 권한 추가
   gcloud projects add-iam-policy-binding ${PROJECT_ID} \
     --member="serviceAccount:automation-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
     --role="roles/secretmanager.secretAccessor"
   ```

5. **API 키 길이 불일치 오류**
   ```bash
   # 문제: API 키에 줄바꿈이 포함된 경우
   echo "AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   " | wc -c
   # 출력: 40 (줄바꿈 포함으로 1자 초과)
   
   # 해결: echo -n 사용
   echo -n "AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" | wc -c
   # 출력: 39 (정확한 길이)
   ```

#### API 키 테스트 방법

```bash
# 로컬에서 API 키 테스트
curl -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GOOGLE_AI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [{
        "text": "Hello, how are you?"
      }]
    }]
  }'
```

### 환경별 설정 요약

| 환경 | API 키 설정 방법 | 보안 수준 | 주의사항 |
|------|-----------------|-----------|----------|
| **로컬 개발** | `.env` 파일 | 중간 | `.gitignore`에 추가 필수 |
| **Cloud Run** | 환경변수 | 중간 | 터미널 히스토리 주의 |
| **프로덕션** | Secret Manager | 높음 | **줄바꿈 금지**, 길이 확인 필수 |

> 💡 **팁**: 
> - 개발 단계: 환경변수 방식 사용
> - 프로덕션: **반드시 Secret Manager 사용**
> - Secret Manager 사용 시: `echo -n` 명령어로 줄바꿈 방지
> - API 키 길이: **정확히 39자** (AIzaSy로 시작)

---

