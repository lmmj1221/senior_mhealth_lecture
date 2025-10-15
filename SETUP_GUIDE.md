# 🚀 Senior MHealth - 프로젝트 환경 설정 가이드

이 가이드는 Senior MHealth 프로젝트의 **완전한 환경 설정**을 안내합니다.
Week 5까지의 모든 설정 요소를 포함하며, GCP, Firebase, Cloud Run, Functions 등의 설정을 다룹니다.

## 📋 사전 준비 사항

### 필요한 계정 및 도구
- [ ] Google Cloud Platform 계정 (GCP)
- [ ] Firebase 프로젝트
- [ ] GitHub 계정
- [ ] Vercel 계정 (https://vercel.com/signup)
- [ ] OpenAI API 계정 (https://platform.openai.com)
- [ ] Node.js 18+ 설치
- [ ] Python 3.9+ 설치
- [ ] Git 설치
- [ ] Docker 설치 (선택사항)

## 📚 목차

1. [GCP 프로젝트 설정](#1️⃣-gcp-프로젝트-설정)
2. [Firebase 프로젝트 설정](#2️⃣-firebase-프로젝트-설정)
3. [환경 변수 파일 구성](#3️⃣-환경-변수-파일-구성)
4. [Service Account 키 생성](#4️⃣-service-account-키-생성)
5. [Cloud Run 배포](#5️⃣-cloud-run-배포)
6. [Cloud Functions 배포](#6️⃣-cloud-functions-배포)
7. [Firestore 설정](#7️⃣-firestore-설정)
8. [API 키 발급](#8️⃣-api-키-발급)
9. [Vercel 배포](#9️⃣-vercel-배포)
10. [검증 및 테스트](#🔍-검증-및-테스트)

---

## 1️⃣ GCP 프로젝트 설정

### 1.1 GCP 프로젝트 생성 또는 확인

**기존 프로젝트가 있는 경우:**
```bash
# 현재 프로젝트 확인
gcloud config get-value project

# 프로젝트 정보 확인
gcloud projects describe credible-runner-474101-f6

# 프로젝트 설정
gcloud config set project credible-runner-474101-f6
```

**새 프로젝트 생성:**
```bash
# 프로젝트 생성
gcloud projects create [PROJECT_ID] --name="Senior MHealth"

# 프로젝트 설정
gcloud config set project [PROJECT_ID]

# 프로젝트 번호 확인
gcloud projects describe [PROJECT_ID] --format="value(projectNumber)"
```

### 1.2 필수 API 활성화

```bash
# 모든 필수 API 한번에 활성화
gcloud services enable \
  cloudfunctions.googleapis.com \
  firestore.googleapis.com \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  storage-api.googleapis.com \
  storage-component.googleapis.com \
  firebase.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  artifactregistry.googleapis.com

# 활성화 확인
gcloud services list --enabled
```

### 1.3 결제 계정 연결

```bash
# 결제 계정 목록 확인
gcloud billing accounts list

# 프로젝트에 결제 계정 연결
gcloud billing projects link [PROJECT_ID] \
  --billing-account=[BILLING_ACCOUNT_ID]
```

---

## 2️⃣ Firebase 프로젝트 설정

### 2.1 Firebase 프로젝트 생성 또는 연결

**방법 1: 기존 GCP 프로젝트를 Firebase로 업그레이드**

1. [Firebase Console](https://console.firebase.google.com) 접속
2. "프로젝트 추가" 클릭
3. 기존 GCP 프로젝트 선택 (`credible-runner-474101-f6`)
4. Firebase 프로젝트로 업그레이드 확인

**방법 2: 새 Firebase 프로젝트 생성**

1. [Firebase Console](https://console.firebase.google.com) 접속
2. "프로젝트 만들기" 클릭
3. 프로젝트 이름 입력
4. Google Analytics 설정 (선택사항)
5. 프로젝트 생성 완료

### 2.2 Firebase CLI 설정

```bash
# Firebase CLI 설치
npm install -g firebase-tools

# Firebase 로그인
firebase login

# 프로젝트 목록 확인
firebase projects:list

# 프로젝트 선택
firebase use credible-runner-474101-f6
```

### 2.3 Firebase 서비스 활성화

Firebase Console(`https://console.firebase.google.com/project/credible-runner-474101-f6`)에서:

#### ✅ Authentication (인증)
1. Authentication 메뉴 클릭
2. "시작하기" 클릭
3. 로그인 방법:
   - **이메일/비밀번호**: 활성화
   - **Google**: 활성화 (선택사항)

#### ✅ Firestore Database
1. Firestore Database 메뉴 클릭
2. "데이터베이스 만들기" 클릭
3. 위치 선택: **asia-northeast3 (서울)**
4. 보안 규칙: **테스트 모드로 시작** (나중에 프로덕션 규칙 적용)
5. 생성 완료

#### ✅ Cloud Storage
1. Storage 메뉴 클릭
2. "시작하기" 클릭
3. 위치 선택: **asia-northeast3 (서울)**
4. 보안 규칙: **테스트 모드로 시작**

#### ✅ Cloud Functions
1. Functions 메뉴 클릭
2. Blaze(종량제) 요금제로 업그레이드 필요
3. "업그레이드" 클릭

### 2.4 Firebase 웹 앱 추가

1. **프로젝트 설정** (⚙️ 아이콘) 클릭
2. **일반** 탭 > **내 앱** 섹션
3. **웹 앱 추가** (</> 아이콘) 클릭
4. 앱 이름 입력: `Senior MHealth Web`
5. Firebase 호스팅 설정: **체크 해제**
6. **앱 등록** 클릭
7. **Firebase 구성 정보 복사** (매우 중요!)

```javascript
// 이 정보를 .env 파일에 사용합니다
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "credible-runner-474101-f6.firebaseapp.com",
  projectId: "credible-runner-474101-f6",
  storageBucket: "credible-runner-474101-f6.firebasestorage.app",
  messagingSenderId: "117743917401",
  appId: "1:117743917401:web:...",
  measurementId: "G-..."
};
```

### 2.5 Firebase Cloud Messaging (FCM) 웹 푸시 인증서

1. 프로젝트 설정 > **Cloud Messaging** 탭
2. **웹 푸시 인증서** 섹션
3. **키 쌍 생성** 클릭
4. 생성된 **키(VAPID)** 복사
5. 이 키를 `.env` 파일의 `FIREBASE_VAPID_KEY`에 저장

---

## 3️⃣ 환경 변수 파일 구성

프로젝트에는 여러 환경 변수 파일이 필요합니다. 각 파일의 목적과 설정 방법을 설명합니다.

### 3.1 프로젝트 루트 `.env` 파일

**위치**: `/Users/callii/Documents/senior_mhealth_lecture/.env`

```bash
# 루트 .env 파일 생성
cd /Users/callii/Documents/senior_mhealth_lecture

cat > .env << 'EOF'
# === GCP Project Configuration ===
GCP_PROJECT_ID=credible-runner-474101-f6
GCP_PROJECT_NUMBER=117743917401
GCP_REGION=asia-northeast3

# === Firebase Configuration ===
FIREBASE_API_KEY=<Firebase Console에서 복사>
FIREBASE_AUTH_DOMAIN=credible-runner-474101-f6.firebaseapp.com
FIREBASE_PROJECT_ID=credible-runner-474101-f6
FIREBASE_STORAGE_BUCKET=credible-runner-474101-f6.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=117743917401
FIREBASE_APP_ID=<Firebase Console에서 복사>
FIREBASE_MEASUREMENT_ID=<Firebase Console에서 복사>
FIREBASE_VAPID_KEY=<Firebase Cloud Messaging에서 생성>

# === Service URLs (배포 후 업데이트) ===
CLOUD_RUN_AI_URL=https://senior-mhealth-ai-<hash>-an.a.run.app
CLOUD_RUN_API_URL=https://senior-mhealth-api-<hash>-an.a.run.app
WEB_APP_URL=https://your-app.vercel.app

# === Storage ===
STORAGE_BUCKET=credible-runner-474101-f6.firebasestorage.app

# === API Keys ===
OPENAI_API_KEY=<OpenAI API Key>
GEMINI_API_KEY=<Google Gemini API Key>
ANTHROPIC_API_KEY=<Anthropic API Key (선택)>

# === Authentication ===
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=<openssl rand -base64 32로 생성>
JWT_SECRET=<openssl rand -base64 32로 생성>

# === Environment ===
NODE_ENV=development
ENVIRONMENT=development
DEBUG_MODE=true
EOF
```

### 3.2 Backend 공통 `.env` 파일

**위치**: `backend/.env`

```bash
cd backend

cat > .env << 'EOF'
# === GCP Configuration ===
GCP_PROJECT_ID=credible-runner-474101-f6
GCP_PROJECT_NUMBER=117743917401
GCP_REGION=asia-northeast3

# === Firebase Configuration ===
FIREBASE_PROJECT_ID=credible-runner-474101-f6
FIREBASE_STORAGE_BUCKET=credible-runner-474101-f6.firebasestorage.app

# === Service Account ===
GOOGLE_APPLICATION_CREDENTIALS=./service-account-key.json

# === Environment ===
NODE_ENV=development
ENVIRONMENT=development
LOG_LEVEL=info
LOG_FORMAT=json
EOF
```

### 3.3 Cloud Functions `.env` 파일

**위치**: `backend/functions/.env`

```bash
cd backend/functions

cat > .env << 'EOF'
# === Firebase 프로젝트 설정 ===
FIREBASE_PROJECT_ID=credible-runner-474101-f6
FIREBASE_PROJECT_LOCATION=asia-northeast3
FIREBASE_STORAGE_BUCKET=credible-runner-474101-f6.firebasestorage.app

# === 개발 환경 ===
NODE_ENV=development
PORT=5001

# === CORS 설정 ===
ALLOWED_ORIGINS=http://localhost:3000

# === AI 서비스 연동 ===
CLOUD_RUN_AI_URL=<Cloud Run 배포 후 업데이트>
CLOUD_RUN_API_URL=<Cloud Run 배포 후 업데이트>

# === 보안 설정 ===
JWT_SECRET=<openssl rand -base64 32로 생성>
JWT_EXPIRES_IN=7d

# === 로깅 ===
LOG_LEVEL=info
ENABLE_MONITORING=true

# === 타임존 ===
TIMEZONE=Asia/Seoul
EOF
```

### 3.4 AI Service `.env` 파일

**위치**: `backend/ai-service/.env`

```bash
cd backend/ai-service

cat > .env << 'EOF'
# === GCP 설정 ===
GCP_PROJECT_ID=credible-runner-474101-f6
GCP_PROJECT_NUMBER=117743917401
GCP_LOCATION=asia-northeast3

# === Firebase 설정 ===
FIREBASE_PROJECT_ID=credible-runner-474101-f6
FIREBASE_STORAGE_BUCKET=credible-runner-474101-f6.firebasestorage.app

# === 서버 설정 ===
PORT=8080
ENV=development
HOST=0.0.0.0
LOG_LEVEL=INFO

# === 인증 설정 ===
GOOGLE_APPLICATION_CREDENTIALS=../service-account-key.json

# === AI 모델 설정 ===
OPENAI_API_KEY=<OpenAI API Key>
GEMINI_API_KEY=<Gemini API Key>
ANTHROPIC_API_KEY=<Anthropic API Key (선택)>

# === 모델 캐시 설정 ===
MODEL_CACHE_SIZE=100
MODEL_CACHE_TTL=3600

# === Firestore 설정 ===
FIRESTORE_DATABASE_ID=(default)

# === Storage 설정 ===
STORAGE_BUCKET=credible-runner-474101-f6.firebasestorage.app

# === 음성 분석 설정 ===
VOICE_ANALYSIS_ENABLED=true
MAX_AUDIO_FILE_SIZE=50MB
SUPPORTED_AUDIO_FORMATS=m4a,mp3,wav,webm
EOF
```

### 3.5 API Service `.env` 파일

**위치**: `backend/api-service/.env`

```bash
cd backend/api-service

cat > .env << 'EOF'
# === Server Configuration ===
PORT=8080
HOST=0.0.0.0
ENVIRONMENT=development

# === Google Cloud Configuration ===
GOOGLE_CLOUD_PROJECT=credible-runner-474101-f6
GCP_PROJECT_NUMBER=117743917401
GCP_REGION=asia-northeast3
GOOGLE_APPLICATION_CREDENTIALS=../service-account-key.json

# === Firebase Configuration ===
FIREBASE_PROJECT_ID=credible-runner-474101-f6

# === Firestore Configuration ===
FIRESTORE_DATABASE_ID=(default)

# === Cloud Storage Configuration ===
STORAGE_BUCKET_NAME=credible-runner-474101-f6.firebasestorage.app

# === Security ===
JWT_SECRET_KEY=<openssl rand -base64 32로 생성>
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# === AI Service ===
AI_SERVICE_URL=<Cloud Run 배포 후 업데이트>

# === API Keys ===
OPENAI_API_KEY=<OpenAI API Key>
GEMINI_API_KEY=<Gemini API Key>

# === Logging ===
LOG_LEVEL=INFO
LOG_FORMAT=json

# === CORS Configuration ===
ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com

# === Rate Limiting ===
RATE_LIMIT_PER_MINUTE=60
EOF
```

### 3.6 환경 변수 업데이트 스크립트

복잡한 환경 변수를 쉽게 생성하기 위한 스크립트:

```bash
# JWT Secret 생성
openssl rand -base64 32

# 또는 모든 Secret을 한번에 생성
cat << 'EOF' > generate_secrets.sh
#!/bin/bash

echo "=== Generating Secrets ==="
echo ""
echo "NEXTAUTH_SECRET=$(openssl rand -base64 32)"
echo "JWT_SECRET=$(openssl rand -base64 32)"
echo "JWT_SECRET_KEY=$(openssl rand -base64 32)"
echo ""
echo "이 값들을 각 .env 파일에 복사하세요!"
EOF

chmod +x generate_secrets.sh
./generate_secrets.sh
```

---

## 4️⃣ Service Account 키 생성

Firebase Admin SDK와 GCP 서비스 인증을 위한 Service Account 키를 생성합니다.

### 4.1 Firebase Console에서 키 생성

1. [Firebase Console - Service Accounts](https://console.firebase.google.com/project/credible-runner-474101-f6/settings/serviceaccounts/adminsdk) 접속
2. 프로젝트 설정-서비스계정
3. **새 비공개 키 생성** 버튼 클릭
4. **키 생성** 확인
5. JSON 파일 자동 다운로드 (`credible-runner-474101-f6-xxxxxx.json`)

### 4.2 키 파일 설치

```bash
# 다운로드한 키 파일을 프로젝트로 복사
cp ~/Downloads/credible-runner-474101-f6-*.json \
   backend/service-account-key.json

# 보안을 위한 권한 설정
chmod 600 backend/service-account-key.json

# 키 파일 검증
cat backend/service-account-key.json | python -m json.tool > /dev/null && \
  echo "✅ 유효한 JSON 파일" || echo "❌ 잘못된 JSON 파일"
```

### 4.3 환경 변수 설정

```bash
# 로컬 개발 환경
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/backend/service-account-key.json"

# 또는 .bashrc / .zshrc에 추가
echo 'export GOOGLE_APPLICATION_CREDENTIALS="/Users/callii/Documents/senior_mhealth_lecture/backend/service-account-key.json"' >> ~/.zshrc
```

---

## 5️⃣ Cloud Run 배포

### 5.1 AI Service 배포

```bash
cd backend/ai-service

# Docker 이미지 빌드 및 배포
gcloud run deploy senior-mhealth-ai \
  --source . \
  --region=asia-northeast3 \
  --platform=managed \
  --allow-unauthenticated \
  --set-env-vars="GCP_PROJECT_ID=credible-runner-474101-f6,GCP_LOCATION=asia-northeast3" \
  --memory=1Gi \
  --timeout=300

# 배포된 URL 확인
gcloud run services describe senior-mhealth-ai \
  --region=asia-northeast3 \
  --format='value(status.url)'
```

### 5.2 API Service 배포

```bash
cd backend/api-service

# Docker 이미지 빌드 및 배포
gcloud run deploy senior-mhealth-api \
  --source . \
  --region=asia-northeast3 \
  --platform=managed \
  --allow-unauthenticated \
  --set-env-vars="GOOGLE_CLOUD_PROJECT=credible-runner-474101-f6,GCP_REGION=asia-northeast3" \
  --memory=1Gi \
  --timeout=300

# 배포된 URL 확인
gcloud run services describe senior-mhealth-api \
  --region=asia-northeast3 \
  --format='value(status.url)'
```

### 5.3 배포된 URL을 환경 변수에 업데이트

```bash
# 배포된 URL 저장
AI_URL=$(gcloud run services describe senior-mhealth-ai --region=asia-northeast3 --format='value(status.url)')
API_URL=$(gcloud run services describe senior-mhealth-api --region=asia-northeast3 --format='value(status.url)')

echo "CLOUD_RUN_AI_URL=$AI_URL"
echo "CLOUD_RUN_API_URL=$API_URL"

# 이 값들을 각 .env 파일에 업데이트하세요
```

---

## 6️⃣ Cloud Functions 배포

### 6.1 Functions 환경 변수 설정

```bash
cd backend/functions

# Cloud Run URL을 Firebase Functions Config에 설정
firebase functions:config:set \
  services.ai_url="<AI Service URL>" \
  services.api_url="<API Service URL>"

# 설정 확인
firebase functions:config:get
```

### 6.2 의존성 설치 및 배포

```bash
# 의존성 설치
npm install

# Functions 배포
firebase deploy --only functions

# 특정 함수만 배포
firebase deploy --only functions:processVoiceFile
```

### 6.3 배포 확인

```bash
# 배포된 함수 목록
firebase functions:list

# 함수 로그 확인
firebase functions:log
```

---

## 7️⃣ Firestore 설정

### 7.1 보안 규칙 배포

```bash
# 보안 규칙 배포
firebase deploy --only firestore:rules

# 인덱스 배포
firebase deploy --only firestore:indexes

# Storage 규칙 배포
firebase deploy --only storage
```

---

## 8️⃣ API 키 발급

### 8.1 OpenAI API 키 (필수)

1. [OpenAI Platform](https://platform.openai.com/api-keys) 접속
2. **Create new secret key** 클릭
3. 키 이름 입력: `senior-mhealth`
4. 생성된 키 복사하여 `.env` 파일들에 추가

### 8.2 Google Gemini API 키 (선택)

1. [Google AI Studio](https://makersuite.google.com/app/apikey) 접속
2. **Create API Key** 클릭
3. 생성된 키 복사하여 `.env` 파일들에 추가

---

## 9️⃣ Vercel 배포 설정 (Web)

### 9.1 Vercel CLI 설치

```bash
npm install -g vercel
```

### 9.2 Vercel 로그인

```bash
vercel login
```

### 9.3 Web 앱 환경 변수 설정

**위치**: `frontend/web/.env.local`

```bash
cd frontend/web

cat > .env.local << 'EOF'
# Firebase Configuration
NEXT_PUBLIC_FIREBASE_API_KEY=<Firebase Console에서 복사>
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=credible-runner-474101-f6.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=credible-runner-474101-f6
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=credible-runner-474101-f6.firebasestorage.app
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=117743917401
NEXT_PUBLIC_FIREBASE_APP_ID=<Firebase Console에서 복사>
NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=<Firebase Console에서 복사>
NEXT_PUBLIC_FIREBASE_VAPID_KEY=<Firebase Cloud Messaging에서 생성>

# API URLs
NEXT_PUBLIC_API_URL=https://asia-northeast3-credible-runner-474101-f6.cloudfunctions.net/api
NEXT_PUBLIC_CLOUD_RUN_API_URL=<Cloud Run API URL>
NEXT_PUBLIC_CLOUD_RUN_AI_URL=<Cloud Run AI URL>

# App URL (배포 후 업데이트)
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOF
```

### 9.4 Web 앱 배포

```bash
# Vercel 프로젝트 연결
vercel

# 프로덕션 배포
vercel --prod
```

### 9.5 Vercel 환경 변수 설정

**Vercel Dashboard에서:**

1. https://vercel.com/dashboard 접속
2. 프로젝트 선택
3. Settings > Environment Variables
4. `.env.local`의 모든 변수 추가
5. 재배포: `vercel --prod`

### 9.6 배포된 URL 업데이트

배포 후 받은 Vercel URL을 환경 변수에 업데이트:

```bash
# .env.local 파일 수정
NEXT_PUBLIC_APP_URL=https://your-project.vercel.app
```

---

## 🔍 검증 및 테스트

### 10.1 로컬 개발 환경 테스트

```bash
# Terminal 1: Cloud Functions
cd backend/functions
npm run serve

# Terminal 2: AI Service
cd backend/ai-service
python main.py

# Terminal 3: API Service
cd backend/api-service
python main.py

# Terminal 4: Web Frontend
cd frontend/web
npm run dev
```

### 10.2 환경 변수 확인

```bash
# 모든 .env 파일 존재 확인
ls -la .env
ls -la backend/.env
ls -la backend/functions/.env
ls -la backend/ai-service/.env
ls -la backend/api-service/.env
ls -la frontend/web/.env.local

# Service Account 키 확인
test -f backend/service-account-key.json && echo "✅ OK" || echo "❌ Missing"
```

### 10.3 GCP 프로젝트 설정 확인

```bash
# 현재 프로젝트 확인
gcloud config get-value project

# Firebase 프로젝트 확인
firebase projects:list | grep credible-runner-474101-f6

# Cloud Run 서비스 확인
gcloud run services list --region=asia-northeast3

# Functions 확인
firebase functions:list
```

### 10.4 API 엔드포인트 테스트

```bash
# Cloud Run AI Service Health Check
curl https://<AI-SERVICE-URL>/health

# Cloud Run API Service Health Check
curl https://<API-SERVICE-URL>/health

# Cloud Functions Health Check
curl https://asia-northeast3-credible-runner-474101-f6.cloudfunctions.net/api/health
```

### 10.5 Firestore 연결 테스트

**Firebase Console에서:**

1. Firestore Database 메뉴 접속
2. 테스트 문서 추가:
   - Collection: `test`
   - Document ID: `test-doc`
   - Field: `message` = `"Hello from Firestore"`
3. 문서 읽기 확인

### 10.6 Storage 업로드 테스트

```bash
# 테스트 파일 업로드
gsutil cp test.txt gs://credible-runner-474101-f6.firebasestorage.app/test/

# 업로드 확인
gsutil ls gs://credible-runner-474101-f6.firebasestorage.app/test/
```

---

## 📝 완전한 설정 체크리스트

### ✅ GCP & Firebase 프로젝트
- [ ] GCP 프로젝트 생성 또는 확인
- [ ] Firebase 프로젝트 활성화
- [ ] 필수 API 활성화
- [ ] 결제 계정 연결 (Blaze 플랜)

### ✅ Firebase 서비스
- [ ] Authentication 활성화
- [ ] Firestore Database 생성 (asia-northeast3)
- [ ] Cloud Storage 생성 (asia-northeast3)
- [ ] Firebase 웹 앱 추가
- [ ] FCM 웹 푸시 인증서 생성

### ✅ 환경 변수 파일
- [ ] 루트 `.env` 파일 생성
- [ ] `backend/.env` 파일 생성
- [ ] `backend/functions/.env` 파일 생성
- [ ] `backend/ai-service/.env` 파일 생성
- [ ] `backend/api-service/.env` 파일 생성
- [ ] `frontend/web/.env.local` 파일 생성

### ✅ Service Account & 인증
- [ ] Service Account 키 생성
- [ ] `backend/service-account-key.json` 설치
- [ ] `GOOGLE_APPLICATION_CREDENTIALS` 환경 변수 설정

### ✅ API 키
- [ ] OpenAI API 키 발급
- [ ] Gemini API 키 발급 (선택)
- [ ] JWT Secret 생성

### ✅ Cloud Run 배포
- [ ] AI Service 배포
- [ ] API Service 배포
- [ ] 배포된 URL 확인 및 환경 변수 업데이트

### ✅ Cloud Functions 배포
- [ ] Functions 환경 변수 설정
- [ ] Functions 배포
- [ ] 배포된 Functions URL 확인

### ✅ Firestore 설정
- [ ] 보안 규칙 배포
- [ ] 인덱스 배포
- [ ] Storage 규칙 배포

### ✅ Vercel 배포 (Optional)
- [ ] Web 앱 환경 변수 설정
- [ ] Vercel 배포
- [ ] Vercel 환경 변수 설정

### ✅ 테스트 및 검증
- [ ] 로컬 개발 환경 동작 확인
- [ ] API 엔드포인트 테스트
- [ ] Firestore 연결 확인
- [ ] Storage 업로드 테스트

## 🔧 자주 발생하는 문제 및 해결 방법

### 1. Firebase 권한 오류

**문제**: `Permission denied` 또는 `Insufficient permissions`

```bash
# 해결 1: 프로젝트 재선택
firebase use credible-runner-474101-f6

# 해결 2: 로그아웃 후 재로그인
firebase logout
firebase login

# 해결 3: GCP IAM 권한 확인
gcloud projects get-iam-policy credible-runner-474101-f6
```

### 2. Service Account 키 오류

**문제**: `Could not load the default credentials`

```bash
# 해결 1: 환경 변수 확인
echo $GOOGLE_APPLICATION_CREDENTIALS

# 해결 2: 키 파일 존재 확인
ls -la backend/service-account-key.json

# 해결 3: 환경 변수 재설정
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/backend/service-account-key.json"

# 해결 4: JSON 파일 검증
python -m json.tool backend/service-account-key.json
```

### 3. Cloud Run 배포 실패

**문제**: `ERROR: (gcloud.run.deploy) PERMISSION_DENIED`

```bash
# 해결 1: 권한 확인
gcloud projects get-iam-policy credible-runner-474101-f6

# 해결 2: Cloud Run Admin 역할 추가
gcloud projects add-iam-policy-binding credible-runner-474101-f6 \
  --member="user:your-email@gmail.com" \
  --role="roles/run.admin"

# 해결 3: API 활성화 확인
gcloud services enable run.googleapis.com
```

### 4. Functions 배포 오류

**문제**: `Build failed` 또는 `Deployment failed`

```bash
# 해결 1: Node 버전 확인 (18+ 필요)
node --version

# 해결 2: 클린 빌드
cd backend/functions
rm -rf node_modules package-lock.json
npm install
firebase deploy --only functions

# 해결 3: Functions 로그 확인
firebase functions:log
```

### 5. Vercel 배포 실패

**문제**: `Build Error` 또는 `Environment Variables Missing`

```bash
# 해결 1: 캐시 삭제 후 재배포
vercel --force

# 해결 2: 환경 변수 확인
vercel env ls

# 해결 3: 로컬 빌드 테스트
cd frontend/web
npm run build
```

### 6. Firestore 권한 오류

**문제**: `Missing or insufficient permissions`

```bash
# 해결 1: 보안 규칙 확인
firebase firestore:rules

# 해결 2: 테스트 모드로 임시 변경 (개발 중)
firebase deploy --only firestore:rules

# 해결 3: Firebase Console에서 규칙 직접 수정
# https://console.firebase.google.com/project/credible-runner-474101-f6/firestore/rules
```

### 7. API 키 관련 오류

**문제**: `Invalid API key` 또는 `API key not found`

```bash
# 해결 1: .env 파일 확인
cat backend/ai-service/.env | grep API_KEY

# 해결 2: 환경 변수 다시 로드
source .env

# 해결 3: API 키 유효성 확인 (OpenAI)
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

### 8. Cloud Storage 업로드 오류

**문제**: `403 Forbidden` 또는 `Access Denied`

```bash
# 해결 1: Storage 규칙 확인
firebase deploy --only storage

# 해결 2: Service Account 권한 확인
gcloud projects get-iam-policy credible-runner-474101-f6 | grep storage

# 해결 3: 직접 Storage Admin 역할 추가
gcloud projects add-iam-policy-binding credible-runner-474101-f6 \
  --member="serviceAccount:firebase-adminsdk-xxxxx@credible-runner-474101-f6.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
```

---

## 🆘 도움말 및 유용한 명령어

### GCP 관련

```bash
# 현재 프로젝트 확인
gcloud config get-value project

# 프로젝트 전환
gcloud config set project credible-runner-474101-f6

# 활성화된 API 목록
gcloud services list --enabled

# 프로젝트 IAM 정책 확인
gcloud projects get-iam-policy credible-runner-474101-f6

# Cloud Run 서비스 목록
gcloud run services list --region=asia-northeast3

# Cloud Run 로그 확인
gcloud run logs tail senior-mhealth-ai --region=asia-northeast3
```

### Firebase 관련

```bash
# Firebase 프로젝트 목록
firebase projects:list

# 현재 사용 중인 프로젝트
firebase use

# Functions 로그 실시간 확인
firebase functions:log --only api

# Functions 환경 변수 확인
firebase functions:config:get

# Firestore 인덱스 상태 확인
firebase firestore:indexes
```

### 환경 변수 관련

```bash
# 모든 .env 파일 검색
find . -name ".env*" -type f

# 환경 변수 파일 내용 확인 (보안 주의!)
grep -h "PROJECT_ID" .env backend/.env backend/*/.env 2>/dev/null

# Secret 생성
openssl rand -base64 32
```

### 디버깅 도구

```bash
# Cloud Run 서비스 상세 정보
gcloud run services describe senior-mhealth-ai \
  --region=asia-northeast3 \
  --format=yaml

# Functions 상세 정보
gcloud functions describe api \
  --region=asia-northeast3 \
  --format=yaml

# Firestore 데이터 확인 (Firebase CLI)
firebase firestore:get users/test-user-001
```

---

## 📚 참고 문서

### 공식 문서

- **Google Cloud Platform**
  - [GCP 문서](https://cloud.google.com/docs)
  - [Cloud Run 문서](https://cloud.google.com/run/docs)
  - [Cloud Functions 문서](https://cloud.google.com/functions/docs)
  - [Firestore 문서](https://cloud.google.com/firestore/docs)

- **Firebase**
  - [Firebase 문서](https://firebase.google.com/docs)
  - [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
  - [Firestore 보안 규칙](https://firebase.google.com/docs/firestore/security/get-started)
  - [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)

- **개발 도구**
  - [Next.js 문서](https://nextjs.org/docs)
  - [Vercel 문서](https://vercel.com/docs)
  - [FastAPI 문서](https://fastapi.tiangolo.com/)

- **AI API**
  - [OpenAI API 문서](https://platform.openai.com/docs)
  - [Google Gemini API 문서](https://ai.google.dev/docs)
  - [Anthropic Claude API 문서](https://docs.anthropic.com/)

### 프로젝트 내부 문서

- [Week 5 강의 자료](docs/week5.md) - Cloud Functions & Firestore
- [설정 복원 가이드](SETUP_RESTORATION_GUIDE.md) - 분실된 설정 파일 복원
- [백엔드 문서](backend/README.md) - 백엔드 아키텍처 및 구조

### 유용한 링크

- [Firebase Console](https://console.firebase.google.com/project/credible-runner-474101-f6)
- [GCP Console](https://console.cloud.google.com/home/dashboard?project=credible-runner-474101-f6)
- [Cloud Run Services](https://console.cloud.google.com/run?project=credible-runner-474101-f6)
- [Firestore Database](https://console.firebase.google.com/project/credible-runner-474101-f6/firestore)
- [Cloud Storage](https://console.firebase.google.com/project/credible-runner-474101-f6/storage)

---

## 💡 추가 팁

### 개발 효율성

1. **환경 변수 자동 로드**: direnv 사용
   ```bash
   # direnv 설치 (macOS)
   brew install direnv

   # .envrc 파일 생성
   echo "dotenv" > .envrc
   direnv allow
   ```

2. **별칭(Alias) 설정**: 자주 사용하는 명령어 단축
   ```bash
   # ~/.zshrc 또는 ~/.bashrc에 추가
   alias gcp="gcloud config set project credible-runner-474101-f6"
   alias fb="firebase use credible-runner-474101-f6"
   alias deploys="firebase deploy --only functions && gcloud run services list"
   ```

3. **VSCode 확장 프로그램**:
   - Firebase Explorer
   - Cloud Code
   - Docker
   - Python
   - ESLint

### 보안 Best Practices

1. **환경 변수 관리**:
   - `.env` 파일은 절대 Git에 커밋하지 않기
   - `.env.example` 템플릿 파일 유지
   - 프로덕션 환경에서는 Secret Manager 사용

2. **Service Account 키**:
   - 파일 권한을 600으로 설정
   - 정기적으로 키 로테이션
   - 불필요한 권한 제거

3. **API 키**:
   - API 키는 환경 변수로 관리
   - 키 유출 시 즉시 재발급
   - 사용량 모니터링 및 할당량 설정

---

## 🎯 다음 단계

설정이 완료되면 다음 단계로 진행하세요:

1. **Week 6**: Vercel 배포 및 프론트엔드 통합
2. **Week 7**: 실시간 데이터 처리 및 알림
3. **Week 8**: AI 모델 통합 및 최적화
4. **Week 9**: 모니터링 및 로깅
5. **Week 10**: 프로덕션 배포 및 운영

## ⚠️ 보안 주의사항

**절대 커밋하지 말아야 할 파일:**
- `.env` (모든 환경 변수 파일)
- `.env.local`
- `serviceAccountKey.json`
- `firebase_options.dart` (개인 프로젝트 정보 포함)
- `.firebaserc` (개인 프로젝트 ID 포함)

**`.gitignore` 확인:**
```gitignore
# 환경 변수
.env
.env.local
.env.production

# Firebase
.firebaserc
serviceAccountKey.json
firebase_options.dart

# Vercel
.vercel
```

---
