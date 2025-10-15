# 🐳 Docker 로컬 개발 환경 가이드

Docker Compose를 사용한 로컬 개발 환경 설정 가이드입니다.

## 📋 사전 요구사항

- Docker Desktop 또는 Docker Engine (20.10+)
- Docker Compose (v2.0+)
- 최소 4GB RAM, 10GB 디스크 공간

## 🚀 빠른 시작

### 1. Docker 환경 변수 설정

```bash
# .env.docker 파일 생성
cp .env.docker.example .env.docker

# 필요시 값 수정
nano .env.docker
```

### 2. 전체 스택 실행

```bash
# 모든 서비스 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f
```

### 3. 서비스 확인

실행 후 다음 URL에서 각 서비스를 확인할 수 있습니다:

| 서비스 | URL | 설명 |
|--------|-----|------|
| 🌐 Frontend Web | http://localhost:3000 | Next.js 웹 애플리케이션 |
| 🔥 Firebase Emulator UI | http://localhost:4000 | Firebase 에뮬레이터 대시보드 |
| 🔌 Backend API | http://localhost:8000 | FastAPI 문서 (Swagger) |
| 🤖 AI Service | http://localhost:8001 | AI 서비스 API 문서 |
| 🐘 pgAdmin | http://localhost:5050 | PostgreSQL 관리 도구 |
| 🗄️ PostgreSQL | localhost:5432 | 데이터베이스 |
| 📦 Redis | localhost:6379 | 캐시 서버 |

### 4. 서비스 중지

```bash
# 서비스 중지
docker-compose stop

# 서비스 중지 및 컨테이너 삭제
docker-compose down

# 볼륨까지 모두 삭제 (데이터 초기화)
docker-compose down -v
```

## 🛠️ 개별 서비스 관리

### 특정 서비스만 실행

```bash
# 데이터베이스만 실행
docker-compose up -d postgres redis

# Firebase 에뮬레이터만 실행
docker-compose up -d firebase-emulator

# Backend 서비스만 실행
docker-compose up -d api-service ai-service
```

### 서비스 재시작

```bash
# 특정 서비스 재시작
docker-compose restart api-service

# 모든 서비스 재시작
docker-compose restart
```

### 로그 확인

```bash
# 모든 서비스 로그
docker-compose logs -f

# 특정 서비스 로그
docker-compose logs -f api-service

# 마지막 100줄만
docker-compose logs --tail=100 api-service
```

## 🔧 개발 워크플로우

### 코드 변경 시

Docker Compose는 볼륨 마운트를 사용하여 실시간 코드 변경을 반영합니다:

- **Backend (Python)**: 코드 변경 시 자동 재시작 (uvicorn --reload)
- **Frontend (Next.js)**: 코드 변경 시 자동 Hot Module Replacement
- **Functions**: Firebase 에뮬레이터가 자동으로 변경 감지

### 의존성 추가 시

의존성을 추가한 경우 컨테이너를 다시 빌드해야 합니다:

```bash
# 특정 서비스 재빌드
docker-compose up -d --build api-service

# 모든 서비스 재빌드
docker-compose up -d --build
```

### 데이터베이스 초기화

```bash
# PostgreSQL 데이터 초기화
docker-compose down -v
docker-compose up -d postgres

# 또는 특정 볼륨만 삭제
docker volume rm senior-mhealth_postgres_data
```

## 📊 pgAdmin 사용 방법

### 1. 접속

- URL: http://localhost:5050
- Email: `admin@senior-mhealth.local` (기본값)
- Password: `admin` (기본값)

### 2. 서버 연결 설정

새 서버 추가:
- **Name**: Senior MHealth Dev
- **Host**: `postgres` (Docker 네트워크 내 호스트명)
- **Port**: `5432`
- **Username**: `postgres`
- **Password**: `postgres`

## 🔥 Firebase Emulator 사용

### Emulator Suite UI

http://localhost:4000 에서 다음을 확인할 수 있습니다:
- Authentication 사용자 관리
- Firestore 데이터 브라우징
- Cloud Storage 파일 관리
- Cloud Functions 로그

### 프론트엔드 연결

환경 변수가 자동으로 설정되어 에뮬레이터를 사용합니다:

```typescript
// frontend/web/.env.local (자동 설정됨)
NEXT_PUBLIC_USE_EMULATOR=true
NEXT_PUBLIC_FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
NEXT_PUBLIC_FIRESTORE_EMULATOR_HOST=localhost:8085
```

## 🐛 문제 해결

### 포트 충돌

이미 사용 중인 포트가 있다면 `.env.docker`에서 포트를 변경하세요:

```bash
# 예: 프론트엔드 포트 변경
WEB_PORT=3001
```

### 컨테이너 시작 실패

```bash
# 로그 확인
docker-compose logs [service-name]

# 컨테이너 상태 확인
docker-compose ps

# 컨테이너 재생성
docker-compose up -d --force-recreate [service-name]
```

### 네트워크 문제

```bash
# 네트워크 재생성
docker-compose down
docker network prune
docker-compose up -d
```

### 디스크 공간 부족

```bash
# 사용하지 않는 이미지/컨테이너 정리
docker system prune -a

# 특정 볼륨만 삭제
docker-compose down -v
```

## 📝 추가 설정

### 실제 Firebase 프로젝트 연결

에뮬레이터 대신 실제 Firebase를 사용하려면:

1. `.env.docker` 수정:
```bash
GCP_PROJECT_ID=your-actual-project-id
FIREBASE_API_KEY=your-firebase-api-key
```

2. `docker-compose.yml`의 `NEXT_PUBLIC_USE_EMULATOR` 제거 또는 false로 설정

### 프로덕션 빌드 테스트

```bash
# 프로덕션 모드로 빌드
docker-compose -f docker-compose.prod.yml up --build
```

## 🔐 보안 주의사항

- `.env.docker` 파일은 절대 Git에 커밋하지 마세요
- 프로덕션 환경에서는 강력한 비밀번호 사용
- pgAdmin은 로컬 개발 환경에서만 사용

## 💡 유용한 명령어

```bash
# 실행 중인 컨테이너에 접속
docker-compose exec api-service sh
docker-compose exec postgres psql -U postgres

# 컨테이너 리소스 사용량 확인
docker stats

# 모든 서비스 상태 확인
docker-compose ps

# 특정 서비스 스케일링
docker-compose up -d --scale api-service=3
```

## 📚 추가 자료

- [Docker Compose 공식 문서](https://docs.docker.com/compose/)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [Next.js Docker 배포](https://nextjs.org/docs/deployment#docker-image)
