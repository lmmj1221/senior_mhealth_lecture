#!/bin/bash

# Firebase 배포 스크립트
# 사용법: ./deploy-firebase.sh

set -e

echo "================================================"
echo "Firebase Firestore & Storage 배포 스크립트"
echo "Project: my-project-54928-b9704"
echo "================================================"
echo ""

# 현재 디렉토리 확인
if [ ! -f "firebase.json" ]; then
    echo "❌ Error: firebase.json 파일을 찾을 수 없습니다."
    echo "프로젝트 루트 디렉토리에서 실행하세요."
    exit 1
fi

# Firebase 로그인 확인
echo "🔐 Firebase 로그인 상태 확인 중..."
if ! firebase projects:list > /dev/null 2>&1; then
    echo "❌ Firebase 로그인이 필요합니다."
    echo ""
    echo "다음 명령어를 실행하여 로그인하세요:"
    echo "  firebase login"
    echo ""
    exit 1
fi

echo "✅ Firebase 로그인 확인 완료"
echo ""

# 프로젝트 선택
echo "📋 프로젝트 설정: my-project-54928-b9704"
firebase use my-project-54928-b9704

echo ""
echo "================================================"
echo "배포 옵션을 선택하세요:"
echo "================================================"
echo "1. Firestore 규칙만 배포"
echo "2. Firestore 인덱스만 배포"
echo "3. Storage 규칙만 배포"
echo "4. Firestore 전체 배포 (규칙 + 인덱스)"
echo "5. 모두 배포 (Firestore + Storage)"
echo "6. 종료"
echo ""
read -p "선택 (1-6): " choice

case $choice in
    1)
        echo ""
        echo "📤 Firestore 규칙 배포 중..."
        firebase deploy --only firestore:rules
        ;;
    2)
        echo ""
        echo "📤 Firestore 인덱스 배포 중..."
        firebase deploy --only firestore:indexes
        ;;
    3)
        echo ""
        echo "📤 Storage 규칙 배포 중..."
        firebase deploy --only storage
        ;;
    4)
        echo ""
        echo "📤 Firestore 전체 배포 중..."
        firebase deploy --only firestore
        ;;
    5)
        echo ""
        echo "📤 모두 배포 중 (Firestore + Storage)..."
        firebase deploy --only firestore,storage
        ;;
    6)
        echo "종료합니다."
        exit 0
        ;;
    *)
        echo "❌ 잘못된 선택입니다."
        exit 1
        ;;
esac

echo ""
echo "================================================"
echo "✅ 배포 완료!"
echo "================================================"
echo ""
echo "배포 확인:"
echo "- Firestore 규칙: https://console.firebase.google.com/project/my-project-54928-b9704/firestore/rules"
echo "- Firestore 인덱스: https://console.firebase.google.com/project/my-project-54928-b9704/firestore/indexes"
echo "- Storage 규칙: https://console.firebase.google.com/project/my-project-54928-b9704/storage/rules"
echo ""
