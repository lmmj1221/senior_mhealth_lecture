# Senior MHealth AI Agent 개발 지침

## AI Agent 행동 지침

### 핵심 원칙
- **객관적 판단**: 사용자의 요청이나 판단에 동조하지 않고 전문가 관점에서 객관적으로 판단
- **전체적 관점**: 프로젝트 전체 아키텍처를 고려한 종합적 판단
- **의존성 고려**: 변경사항이 다른 서비스/파일에 미치는 영향과 부작용을 반드시 분석
- **세션 관리**: 복잡한 작업으로 메모리가 혼란스러울 때는 새로운 세션 생성을 요청

### 의사결정 프로세스
1. **요청 분석**: 사용자 요청의 기술적 타당성과 위험성 평가
2. **영향 범위 파악**: 관련 서비스, 파일, 설정의 전체 범위 확인
3. **의존성 검토**: 변경사항이 다른 부분에 미치는 영향 분석
4. **대안 제시**: 위험한 요청의 경우 안전한 대안 제안
5. **실행 계획**: 단계별 실행 계획과 검증 방법 제시

## 프로젝트 개요

### 시스템 아키텍처
```
Mobile App (Flutter) ←→ Web App (Next.js)
         ↓                    ↓
    Cloud Functions (Express.js)
         ↓
    Cloud Run Services
    ├── AI Service (Python FastAPI)
    └── API Service (Node.js)
         ↓
    Firebase Services
    ├── Firestore Database
    ├── Cloud Storage
    ├── Authentication
    └── Cloud Messaging
```

### 핵심 서비스
- **frontend/mobile**: Flutter 모바일 앱 (Android)
- **frontend/web**: Next.js 웹 앱 (Vercel 배포)
- **backend/functions**: Cloud Functions (Express.js)
- **backend/ai-service**: Cloud Run AI Service (Python FastAPI)
- **backend/api-service**: Cloud Run API Service (Node.js)

## 서비스 간 의존성 규칙

### Firebase 설정 변경 시
- **영향 범위**: 모든 서비스 (모바일, 웹, Functions, Cloud Run)
- **필수 확인**:
  - `frontend/mobile/android/app/google-services.json`
  - `frontend/mobile/lib/firebase_options.dart`
  - `frontend/web/.env.local`
  - `backend/functions/.env`
  - `backend/ai-service/.env`
  - `backend/api-service/.env`

### API 엔드포인트 변경 시
- **영향 범위**: 클라이언트 코드 (모바일, 웹)
- **필수 확인**:
  - `frontend/mobile/lib/services/` (API 호출 코드)
  - `frontend/web/src/services/` (API 호출 코드)
  - `backend/functions/index.js` (엔드포인트 정의)
  - `backend/api-service/` (API 서비스)

### Firestore 스키마 변경 시
- **영향 범위**: 모든 데이터 접근 로직
- **필수 확인**:
  - `backend/functions/index.js` (Cloud Functions)
  - `backend/ai-service/` (AI 분석 결과 저장)
  - `frontend/mobile/lib/services/` (데이터 접근)
  - `frontend/web/src/` (데이터 접근)
  - `firestore.rules` (보안 규칙)

### 환경변수 변경 시
- **영향 범위**: 배포 설정, 서비스 설정
- **필수 확인**:
  - 모든 `.env` 파일들
  - `backend/ai-service/env.example`
  - `backend/api-service/env.example`
  - Vercel 환경변수 설정
  - Cloud Run 환경변수 설정

## 파일 수정 규칙

### 문서 업데이트 시
- **week7.md 수정** → `week7-1.md`, `week7-2.md` 동시 확인
- **API 변경** → 관련 주차 문서들 업데이트
- **아키텍처 변경** → `docs/backend.md` 업데이트

### 코드 수정 시
- **Week 1-6 코드**: 절대 수정 금지 (사용자 보고 후 진행)
- **새로운 기능**: 기존 코드와의 호환성 확인
- **API 변경**: 버전 관리 및 하위 호환성 고려

### 설정 파일 수정 시
- **환경변수**: 모든 환경의 일관성 확인
- **Firebase 설정**: 모든 서비스의 설정 동기화
- **배포 설정**: 로컬/개발/프로덕션 환경 고려

## 금지 행동

### 절대 금지
- **Week 1-6 코드 수정**: 사용자 보고 없이 수정 금지
- **Firebase 프로젝트 설정 변경**: 기존 설정 유지
- **핵심 API 엔드포인트 삭제**: 하위 호환성 확인 후 진행
- **데이터베이스 스키마 대폭 변경**: 기존 데이터 마이그레이션 계획 필요

### 주의 필요
- **환경변수 변경**: 모든 서비스에 영향
- **의존성 추가**: 프로젝트 크기 및 성능 고려
- **새로운 서비스 추가**: 기존 아키텍처와의 통합성 확인

## 복잡성 관리

### 새로운 세션 생성 요청 기준
- **5개 이상의 서비스 동시 수정** 필요할 때
- **Firebase 설정 대폭 변경** 필요할 때
- **아키텍처 전면 개편** 필요할 때
- **메모리 사용량 과다**로 혼란스러울 때

### 세션 전환 시 필수 사항
- **현재 작업 상태** 명확히 정리
- **다음 세션에서 필요한 정보** 제공
- **진행 중인 작업의 의존성** 설명

## 검증 체크리스트

### 코드 수정 전
- [ ] 관련 서비스 영향 범위 파악
- [ ] 기존 기능 호환성 확인
- [ ] 테스트 방법 계획
- [ ] 롤백 계획 수립

### 코드 수정 후
- [ ] 모든 관련 서비스 동작 확인
- [ ] 문서 업데이트 완료
- [ ] 환경변수 일관성 확인
- [ ] 배포 설정 검증

## 예외 처리

### 사용자 요청이 위험할 때
1. **위험성 설명**: 구체적인 위험 요소와 영향 범위 제시
2. **대안 제안**: 안전한 대안 방법 제시
3. **단계별 접근**: 위험을 최소화한 단계별 실행 계획
4. **사용자 확인**: 최종 결정은 사용자가 하도록 안내

### 기술적 제약이 있을 때
1. **제약 사항 설명**: 구체적인 기술적 한계 설명
2. **해결 방안 제시**: 가능한 해결 방법들 제시
3. **우선순위 제안**: 가장 효과적인 방법 추천
4. **추가 정보 요청**: 필요한 경우 추가 정보 요청
