# Update Vercel Environment Variables for New Firebase Project
# phrasal-ruler-473203-h7

Write-Host "🔥 Updating Firebase configuration in Vercel..." -ForegroundColor Cyan

# 새 Firebase Config
$envVars = @{
    "NEXT_PUBLIC_FIREBASE_API_KEY" = "AIzaSyDohiPyWHMmROkjQdDRi88zLn2tlEHaZ30"
    "NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN" = "phrasal-ruler-473203-h7.firebaseapp.com"
    "NEXT_PUBLIC_FIREBASE_PROJECT_ID" = "phrasal-ruler-473203-h7"
    "NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET" = "phrasal-ruler-473203-h7.firebasestorage.app"
    "NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID" = "594167675669"
    "NEXT_PUBLIC_FIREBASE_APP_ID" = "1:594167675669:web:70a01b2a44d0977add471c"
    "NEXT_PUBLIC_API_URL" = "https://asia-northeast3-phrasal-ruler-473203-h7.cloudfunctions.net/api"
}

$environments = @("production", "preview", "development")

# Step 1: 기존 환경 변수 삭제
Write-Host "`n📝 Step 1: Removing old environment variables..." -ForegroundColor Yellow

foreach ($key in $envVars.Keys) {
    Write-Host "  Removing $key..." -ForegroundColor Gray
    foreach ($env in $environments) {
        vercel env rm $key $env --yes 2>$null
    }
}

Write-Host "✅ Old variables removed" -ForegroundColor Green

# Step 2: 새 환경 변수 추가
Write-Host "`n📝 Step 2: Adding new environment variables..." -ForegroundColor Yellow

foreach ($key in $envVars.Keys) {
    $value = $envVars[$key]
    Write-Host "  Adding $key..." -ForegroundColor Gray
    
    foreach ($env in $environments) {
        Write-Output $value | vercel env add $key $env | Out-Null
    }
}

Write-Host "✅ New variables added" -ForegroundColor Green

# Step 3: 환경 변수 확인
Write-Host "`n📝 Step 3: Verifying environment variables..." -ForegroundColor Yellow
vercel env pull .env.production

Write-Host "`n🎉 Firebase configuration updated successfully!" -ForegroundColor Green
Write-Host "`n📌 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Commit and push changes to trigger Vercel deployment" -ForegroundColor White
Write-Host "  2. Or manually redeploy: vercel --prod" -ForegroundColor White
Write-Host "`n⚠️  Remember to enable Firebase services:" -ForegroundColor Yellow
Write-Host "  - Authentication (Email/Password)" -ForegroundColor White
Write-Host "  - Firestore Database" -ForegroundColor White
Write-Host "  - Cloud Storage" -ForegroundColor White
Write-Host "  - Cloud Functions" -ForegroundColor White
