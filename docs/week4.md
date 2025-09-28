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
│    (Docker Hub, GCR, ECR)           │
└──────────────────────────────────────┘
```

**💡 도시락 비유로 이해하기:**
- **Dockerfile** = 레시피 📝
- **Docker Image** = 완성된 도시락 세트 🍱
- **Docker Container** = 먹고 있는 도시락 🥢
- **Docker Hub/GCR** = 도시락 판매점 🏪

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

### 4. Container Registry → Artifact Registry

### Google Artifact Registry (GCR의 진화 버전)

> ⚠️ **중요 변경사항**: Google Container Registry(GCR)는 2024년부터 Artifact Registry로 대체됩니다.
> - GCR은 여전히 작동하지만, 신규 프로젝트는 Artifact Registry 사용 권장
> - Artifact Registry는 Docker 이미지뿐만 아니라 다양한 패키지 지원

```
Artifact Registry 구조:
[REGION]-docker.pkg.dev/[PROJECT-ID]/[REPOSITORY]/[IMAGE]:[TAG]

예시 (신규):
asia-northeast3-docker.pkg.dev/senior-mhealth-lee/backend/ai-service:v1
└────────────┘└──────────────┘└──────────────┘└──────┘└────────┘└─┘
    리전        도메인            프로젝트 ID      저장소    이미지    태그

기존 GCR (여전히 작동):
gcr.io/senior-mhealth-lee/ai-service:v1
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

### 이미지 태깅 전략

```
# 환경별 태깅
:latest     # 최신 버전 (개발)
:staging    # 스테이징 환경
:prod       # 프로덕션 환경

# 버전 태깅
:v1.0.0     # 시맨틱 버저닝
:v1.0.1
:v2.0.0

# 커밋 해시 태깅
:abc123     # Git 커밋 해시
```

**💡 베스트 프랙티스:**
- ✅ 명확한 버전 사용: `v1.2.3`
- ✅ 환경 구분: `prod-v1.2.3`
- ❌ latest만 사용 (프로덕션에 위험)
- ❌ 의미없는 이름: `final`, `test`

---

## 🚀 실습: Cloud Run 서비스 배포

### 사전 준비 확인 🤖

```bash
# 1. 현재 프로젝트 확인
gcloud config get-value project
# 출력: senior-mhealth-lee

# 2. 필요한 API 활성화
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# 3. 서비스 계정 키 확인
ls serviceAccountKey.json

# 4. Docker 설치 확인 (선택사항)
docker --version
```

---

## Step 1: AI Service 컨테이너화 및 배포

### 1.1 Vertex AI 설정 👤

1. [Vertex AI Console](https://console.cloud.google.com/vertex-ai) 접속
2. API 활성화 확인
3. 프로젝트 선택: senior-mhealth-lee
4. 서비스 계정 권한 확인

### 1.2 AI Service 환경 설정 🤖

```bash
# backend/ai-service로 이동
cd backend/ai-service

# Vertex AI API 활성화
gcloud services enable aiplatform.googleapis.com

# 환경 변수 파일 생성
cat > .env << EOF
GOOGLE_CLOUD_PROJECT=senior-mhealth-lee
VERTEX_AI_LOCATION=asia-northeast3
MODEL_NAME=gemini-pro
ENVIRONMENT=production
PORT=8081
EOF
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

### 1.4 로컬 테스트 (선택사항) 🤖

```bash
# Docker 이미지 빌드
docker build -t ai-service-local .

# 컨테이너 실행
docker run -p 8081:8081 --env-file .env ai-service-local

# 다른 터미널에서 테스트
curl http://localhost:8081/health
```

### 1.5 Registry에 이미지 푸시 🤖

#### 옵션 A: Artifact Registry 사용 (권장) 🆕

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

#### 옵션 B: Container Registry 사용 (레거시)

```bash
# Container Registry 인증
gcloud auth configure-docker

# 이미지 빌드 (GCR 태그)
docker build -t gcr.io/${PROJECT_ID}/senior-mhealth-ai:v1 .

# 이미지 푸시
docker push gcr.io/${PROJECT_ID}/senior-mhealth-ai:v1

# 푸시 확인
gcloud container images list --repository=gcr.io/${PROJECT_ID}
```

### 1.6 Cloud Run 배포 🤖

```bash
# 옵션 A: Artifact Registry 이미지 사용 (권장)
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
  --set-env-vars="GOOGLE_CLOUD_PROJECT=${PROJECT_ID},VERTEX_AI_LOCATION=asia-northeast3,MODEL_NAME=gemini-pro,ENVIRONMENT=production"

# 옵션 B: GCR 이미지 사용 (레거시)
# --image gcr.io/${PROJECT_ID}/senior-mhealth-ai:v1

# 배포 성공 시 URL 저장
export AI_SERVICE_URL=$(gcloud run services describe senior-mhealth-ai \
  --platform managed \
  --region asia-northeast3 \
  --format 'value(status.url)')

echo "AI Service URL: $AI_SERVICE_URL"
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

---

## Step 2: API Service 컨테이너화 및 배포

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

### 2.3 GCR에 이미지 푸시 🤖

```bash
# 옵션 A: Artifact Registry (권장)
docker build -t asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/api-service:v1 .
docker push asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/api-service:v1

# 옵션 B: GCR (레거시)
# docker build -t gcr.io/${PROJECT_ID}/senior-mhealth-api:v1 .
# docker push gcr.io/${PROJECT_ID}/senior-mhealth-api:v1
```

### 2.4 Cloud Run 배포 🤖

```bash
# 옵션 A: Artifact Registry 이미지 사용 (권장)
gcloud run deploy senior-mhealth-api \
  --image asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/api-service:v1 \
  --platform managed \
  --region asia-northeast3 \
  --memory 1Gi \
  --cpu 1 \
  --timeout 60 \
  --max-instances 10 \
  --allow-unauthenticated \
  --set-env-vars="GOOGLE_CLOUD_PROJECT=${PROJECT_ID},AI_SERVICE_URL=${AI_SERVICE_URL}"

# 옵션 B: GCR 이미지 사용 (레거시)
# --image gcr.io/${PROJECT_ID}/senior-mhealth-api:v1

# URL 저장
export API_SERVICE_URL=$(gcloud run services describe senior-mhealth-api \
  --platform managed \
  --region asia-northeast3 \
  --format 'value(status.url)')

echo "API Service URL: $API_SERVICE_URL"
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

```bash
# 코드 수정 후 새 버전 배포
# 옵션 A: Artifact Registry (권장)
docker build -t asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/ai-service:v2 .
docker push asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/ai-service:v2

# 옵션 B: GCR (레거시)
# docker build -t gcr.io/${PROJECT_ID}/senior-mhealth-ai:v2 .
# docker push gcr.io/${PROJECT_ID}/senior-mhealth-ai:v2

# 새 리비전 배포
gcloud run deploy senior-mhealth-ai \
  --image asia-northeast3-docker.pkg.dev/${PROJECT_ID}/backend/ai-service:v2 \
  --platform managed \
  --region asia-northeast3

# 트래픽 분할 (카나리 배포)
gcloud run services update-traffic senior-mhealth-ai \
  --to-revisions=LATEST=10 \
  --platform managed \
  --region asia-northeast3
```

---

## 🔧 트러블슈팅

### Docker 관련 문제

#### 빌드 실패
```bash
# 문제: "Cannot connect to Docker daemon"
# 해결: Docker Desktop 실행 확인
docker ps

# 문제: "no space left on device"
# 해결: Docker 이미지 정리
docker system prune -a
```

#### 푸시 실패
```bash
# 문제: "denied: Token exchange failed"
# 해결: 재인증
gcloud auth login
gcloud auth configure-docker

# 문제: "denied: Project not found"
# 해결: 프로젝트 확인
gcloud config set project senior-mhealth-lee
```

### Cloud Run 관련 문제

#### 배포 실패
```bash
# 문제: "Quota exceeded"
# 해결: 할당량 확인
gcloud compute project-info describe --project=${PROJECT_ID}

# 문제: "Container failed to start"
# 해결: 로그 확인
gcloud logging read "resource.type=cloud_run_revision" --limit 50
```

#### 성능 문제
```bash
# 콜드 스타트 개선
gcloud run services update senior-mhealth-api \
  --min-instances=1 \
  --platform managed \
  --region asia-northeast3

# 메모리 부족 해결
gcloud run services update senior-mhealth-ai \
  --memory=4Gi \
  --platform managed \
  --region asia-northeast3
```

---

## 💰 비용 최적화

### Cloud Run 무료 티어
- 월 200만 요청 무료
- 월 360,000 GB-초 메모리 무료
- 월 180,000 vCPU-초 무료

### 비용 절감 전략

```bash
# 1. 최소 인스턴스 0으로 설정 (기본값)
gcloud run services update senior-mhealth-api \
  --min-instances=0 \
  --platform managed \
  --region asia-northeast3

# 2. 동시 요청 수 최적화
gcloud run services update senior-mhealth-api \
  --concurrency=100 \
  --platform managed \
  --region asia-northeast3

# 3. CPU 할당 최적화 (요청 처리 중에만)
gcloud run services update senior-mhealth-api \
  --cpu-throttling \
  --platform managed \
  --region asia-northeast3
```

### 비용 모니터링 👤

1. [Billing Console](https://console.cloud.google.com/billing) 접속
2. Budget & alerts 설정
3. Cost breakdown by service 확인

---

## ✅ 완료 체크리스트

- [ ] Docker 기본 개념 이해
- [ ] Vertex AI 설정 및 권한 확인
- [ ] AI Service Docker 이미지 빌드
- [ ] AI Service Cloud Run 배포
- [ ] API Service Docker 이미지 빌드
- [ ] API Service Cloud Run 배포
- [ ] 서비스 간 통신 테스트
- [ ] 환경 변수 파일 업데이트
- [ ] 모니터링 설정 확인
- [ ] 비용 최적화 적용

---

## 🎯 학습 성과

이번 주차를 완료하면:
- ✅ Docker 컨테이너 기술 이해
- ✅ Dockerfile 작성 능력
- ✅ Cloud Run 서버리스 배포
- ✅ Container Registry 활용
- ✅ 마이크로서비스 아키텍처 구현
- ✅ 클라우드 네이티브 배포 전략

---

## 📚 다음 주차 예고

**Week 5: Cloud Functions & Firestore**
- Cloud Functions 개발
- Firestore 데이터베이스 설계
- 실시간 데이터 동기화
- Cloud Run과 Functions 통합

---

## 🔗 참고 자료

- [Docker 공식 문서](https://docs.docker.com/)
- [Cloud Run 공식 문서](https://cloud.google.com/run/docs)
- [Container Registry 가이드](https://cloud.google.com/container-registry/docs)
- [Vertex AI 문서](https://cloud.google.com/vertex-ai/docs)