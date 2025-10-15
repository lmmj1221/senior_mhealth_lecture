# Firebase 배포 명령어 모음

## 🚀 빠른 배포

### 방법 1: 배포 스크립트 사용 (추천)

```bash
# 대화형 메뉴로 배포
./deploy-firebase.sh
```

### 방법 2: 직접 명령어 실행

#### 1. Firebase 로그인 (최초 1회)
```bash
firebase login
```

#### 2. 프로젝트 선택
```bash
firebase use my-project-54928-b9704
```

#### 3. 배포 실행

**모두 배포 (추천):**
```bash
firebase deploy --only firestore,storage
```

**개별 배포:**
```bash
# Firestore 규칙만
firebase deploy --only firestore:rules

# Firestore 인덱스만
firebase deploy --only firestore:indexes

# Storage 규칙만
firebase deploy --only storage

# Firestore 전체 (규칙 + 인덱스)
firebase deploy --only firestore
```

---

## 📋 현재 프로젝트 설정

- **프로젝트 ID**: `my-project-54928-b9704`
- **프로젝트 번호**: `117743917401`
- **리전**: `asia-northeast3` (서울)

---

## 🔍 배포 확인

배포 후 다음 URL에서 확인하세요:

1. **Firestore 규칙**
   ```
   https://console.firebase.google.com/project/my-project-54928-b9704/firestore/rules
   ```

2. **Firestore 인덱스**
   ```
   https://console.firebase.google.com/project/my-project-54928-b9704/firestore/indexes
   ```

3. **Storage 규칙**
   ```
   https://console.firebase.google.com/project/my-project-54928-b9704/storage/rules
   ```

---

## 🔧 문제 해결

### 로그인 오류
```bash
# 로그아웃 후 재로그인
firebase logout
firebase login
```

### 프로젝트 권한 오류
```bash
# 프로젝트 목록 확인
firebase projects:list

# 올바른 프로젝트 선택
firebase use my-project-54928-b9704
```

### 배포 파일 확인
```bash
# 필요한 파일들이 있는지 확인
ls -la firestore.rules
ls -la backend/functions/firestore.indexes.json
ls -la backend/functions/storage.rules
```

---

## 📦 전체 배포 (Functions 포함)

나중에 Functions도 함께 배포하려면:

```bash
# Firestore, Storage, Functions 모두 배포
firebase deploy --only firestore,storage,functions

# 또는 모든 것 배포
firebase deploy
```

---

## 🎯 배포 체크리스트

배포 전 확인:
- [ ] `firebase login` 완료
- [ ] `firebase use my-project-54928-b9704` 실행
- [ ] `firestore.rules` 파일 존재
- [ ] `backend/functions/firestore.indexes.json` 파일 존재
- [ ] `backend/functions/storage.rules` 파일 존재

배포 후 확인:
- [ ] Firebase Console에서 Firestore 규칙 확인
- [ ] Firebase Console에서 Firestore 인덱스 확인
- [ ] Firebase Console에서 Storage 규칙 확인
- [ ] 규칙이 올바르게 적용되었는지 테스트

---

## 💡 팁

### 로컬 에뮬레이터에서 테스트

배포 전에 로컬에서 테스트:

```bash
# 에뮬레이터 시작
firebase emulators:start

# 또는 특정 서비스만
firebase emulators:start --only firestore,storage
```

에뮬레이터 UI: http://localhost:4000

### 배포 로그 확인

```bash
# 실시간 로그
firebase functions:log

# 특정 함수 로그
firebase functions:log --only functionName
```

---

## 🔗 관련 문서

- [Firebase CLI 문서](https://firebase.google.com/docs/cli)
- [Firestore 보안 규칙](https://firebase.google.com/docs/firestore/security/get-started)
- [Storage 보안 규칙](https://firebase.google.com/docs/storage/security)
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - 전체 설정 가이드
