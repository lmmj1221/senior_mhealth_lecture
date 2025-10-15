#!/bin/bash

# 테스트 스크립트 정리 도구
# Week 6 완료 후 불필요한 테스트 파일을 정리합니다

echo "🧹 Cleaning up test scripts..."

# 임시 파일 목록
files_to_remove=(
  "auth_users.json"
  "test_call.json"
)

# 선택적 제거 파일 (유지하고 싶으면 주석 처리)
optional_files=(
  "create_test_call.js"
  "upload_test_file.js"
  "check_firestore.js"
)

# 임시 파일 제거
for file in "${files_to_remove[@]}"; do
  if [ -f "$file" ]; then
    rm "$file"
    echo "✅ Removed: $file"
  fi
done

# 선택적 파일 제거 확인
echo ""
echo "📋 Optional files (kept for future use):"
for file in "${optional_files[@]}"; do
  if [ -f "$file" ]; then
    echo "   - $file"
  fi
done

echo ""
echo "💡 Tip: To remove optional files, delete them manually:"
echo "   rm create_test_call.js upload_test_file.js check_firestore.js"
echo ""
echo "✨ Cleanup complete!"
