#!/bin/bash

# 설정 검증 스크립트
# 프로젝트 설정이 올바르게 되어있는지 확인합니다

set -e

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Senior MHealth 설정 검증 스크립트${NC}"
echo -e "${BLUE}===============================================${NC}"

ERRORS=0
WARNINGS=0

# 함수: 에러 출력
error() {
    echo -e "${RED}❌ $1${NC}"
    ((ERRORS++))
}

# 함수: 경고 출력
warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

# 함수: 성공 출력
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# 함수: 정보 출력
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo ""
echo "=== 1. 필수 도구 확인 ==="

# Node.js 확인
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    success "Node.js 설치됨 ($NODE_VERSION)"

    # 버전 확인 (18.0.0 이상)
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
    if [ "$MAJOR_VERSION" -lt 18 ]; then
        error "Node.js 버전이 18.0.0 미만입니다. 업그레이드가 필요합니다."
    fi
else
    error "Node.js가 설치되지 않았습니다"
fi

# Python 확인
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    success "Python 설치됨 ($PYTHON_VERSION)"
else
    warn "Python3가 설치되지 않았습니다 (AI 서비스 사용 시 필요)"
fi

# gcloud CLI 확인
if command -v gcloud &> /dev/null; then
    GCLOUD_VERSION=$(gcloud version --format="value(version)")
    success "Google Cloud SDK 설치됨"
else
    error "Google Cloud SDK가 설치되지 않았습니다"
fi

# Firebase CLI 확인
if command -v firebase &> /dev/null; then
    FIREBASE_VERSION=$(firebase --version)
    success "Firebase CLI 설치됨 ($FIREBASE_VERSION)"
else
    error "Firebase CLI가 설치되지 않았습니다"
fi

echo ""
echo "=== 2. 환경 변수 파일 확인 ==="

# .env 파일 확인
if [ -f ".env" ]; then
    success ".env 파일이 존재합니다"

    # 플레이스홀더 값 확인
    if grep -q "your-project-id" .env 2>/dev/null || grep -q "YOUR_" .env 2>/dev/null; then
        error ".env 파일에 플레이스홀더 값(your-project-id, YOUR_)이 남아있습니다"
    else
        success ".env 파일이 올바르게 설정된 것으로 보입니다"
    fi

    # 필수 환경 변수 확인
    source .env 2>/dev/null || true

    if [ -z "$GCP_PROJECT_ID" ]; then
        error "GCP_PROJECT_ID가 설정되지 않았습니다"
    else
        success "GCP_PROJECT_ID: $GCP_PROJECT_ID"
    fi

    if [ -z "$FIREBASE_PROJECT_ID" ]; then
        warn "FIREBASE_PROJECT_ID가 설정되지 않았습니다"
    fi

    if [ -z "$GCP_REGION" ]; then
        warn "GCP_REGION이 설정되지 않았습니다 (기본값 사용)"
    fi
else
    error ".env 파일이 없습니다. .env.example을 복사하여 .env를 생성하세요"
    info "명령어: cp .env.example .env"
fi

echo ""
echo "=== 3. 프로젝트 설정 파일 확인 ==="

# project.config.json 확인
if [ -f "project.config.json" ]; then
    success "project.config.json 파일이 존재합니다"

    # 플레이스홀더 값 확인
    if grep -q "YOUR_" project.config.json 2>/dev/null; then
        error "project.config.json에 플레이스홀더 값(YOUR_)이 남아있습니다"
    else
        success "project.config.json이 올바르게 설정된 것으로 보입니다"
    fi
else
    warn "project.config.json 파일이 없습니다 (환경 변수만 사용)"
    info "생성 방법: cp project.config.template.json project.config.json"
fi

echo ""
echo "=== 4. Firebase 설정 확인 ==="

# .firebaserc 확인
if [ -f ".firebaserc" ]; then
    success ".firebaserc 파일이 존재합니다"

    if grep -q "YOUR-PROJECT-ID" .firebaserc 2>/dev/null; then
        error ".firebaserc에 플레이스홀더 값이 남아있습니다"
    else
        success ".firebaserc가 올바르게 설정된 것으로 보입니다"
    fi
else
    warn ".firebaserc 파일이 없습니다"
    info "Firebase 프로젝트 설정: firebase use --add"
fi

echo ""
echo "=== 5. 민감한 파일 보안 확인 ==="

# .gitignore 확인
if [ -f ".gitignore" ]; then
    success ".gitignore 파일이 존재합니다"
else
    error ".gitignore 파일이 없습니다"
fi

# 민감한 파일이 Git에 추가되었는지 확인
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Git 저장소인 경우

    # .env 파일이 추적되는지 확인
    if git ls-files --error-unmatch .env > /dev/null 2>&1; then
        error ".env 파일이 Git에 추적되고 있습니다! 즉시 제거해야 합니다"
        info "제거 방법: git rm --cached .env"
    else
        success ".env 파일은 Git에 추적되지 않습니다"
    fi

    # 서비스 계정 키 확인
    if git ls-files | grep -q "service.*account.*key\.json"; then
        error "서비스 계정 키 파일이 Git에 추적되고 있습니다!"
    else
        success "서비스 계정 키는 Git에 추적되지 않습니다"
    fi
fi

echo ""
echo "=== 6. GCP 프로젝트 연결 확인 ==="

if command -v gcloud &> /dev/null && [ ! -z "$GCP_PROJECT_ID" ]; then
    # 현재 gcloud 프로젝트 확인
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")

    if [ "$CURRENT_PROJECT" == "$GCP_PROJECT_ID" ]; then
        success "gcloud가 올바른 프로젝트에 연결되어 있습니다: $GCP_PROJECT_ID"
    else
        warn "gcloud 프로젝트가 일치하지 않습니다"
        info "현재: $CURRENT_PROJECT, 설정: $GCP_PROJECT_ID"
        info "변경 방법: gcloud config set project $GCP_PROJECT_ID"
    fi

    # 프로젝트 존재 확인
    if gcloud projects describe "$GCP_PROJECT_ID" &> /dev/null; then
        success "GCP 프로젝트 접근 가능: $GCP_PROJECT_ID"
    else
        error "GCP 프로젝트에 접근할 수 없습니다: $GCP_PROJECT_ID"
    fi
fi

echo ""
echo "=== 7. Node.js 의존성 확인 ==="

# Backend Functions
if [ -d "backend/functions" ]; then
    if [ -d "backend/functions/node_modules" ]; then
        success "backend/functions의 의존성이 설치되어 있습니다"
    else
        warn "backend/functions의 의존성이 설치되지 않았습니다"
        info "설치 방법: cd backend/functions && npm install"
    fi
fi

# Frontend Web
if [ -d "frontend/web" ]; then
    if [ -d "frontend/web/node_modules" ]; then
        success "frontend/web의 의존성이 설치되어 있습니다"
    else
        warn "frontend/web의 의존성이 설치되지 않았습니다"
        info "설치 방법: cd frontend/web && npm install"
    fi
fi

echo ""
echo "=== 검증 결과 ==="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 모든 검증을 통과했습니다!${NC}"
    echo -e "${GREEN}프로젝트를 시작할 준비가 되었습니다.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  경고 $WARNINGS개가 발견되었습니다.${NC}"
    echo -e "${YELLOW}프로젝트는 작동할 수 있지만, 경고를 확인해주세요.${NC}"
    exit 0
else
    echo -e "${RED}❌ 에러 $ERRORS개, 경고 $WARNINGS개가 발견되었습니다.${NC}"
    echo -e "${RED}위의 에러를 수정한 후 다시 시도해주세요.${NC}"
    exit 1
fi
