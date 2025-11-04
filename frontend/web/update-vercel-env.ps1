# Vercel 환경 변수 업데이트 스크립트

$envVars = @{
    "NEXT_PUBLIC_FIREBASE_API_KEY" = "AIzaSyCMZ5G72UJR_Wtw5kHbkxE7u1ykWyE7PF4"
    "NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN" = "senior-mhealth-202373080.firebaseapp.com"
    "NEXT_PUBLIC_FIREBASE_PROJECT_ID" = "senior-mhealth-202373080"
    "NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET" = "senior-mhealth-202373080.firebasestorage.app"
    "NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID" = "739201926447"
    "NEXT_PUBLIC_FIREBASE_APP_ID" = "1:739201926447:web:7392cc28b672c1169a4dda"
    "NEXT_PUBLIC_API_URL" = "https://asia-northeast3-senior-mhealth-202373080.cloudfunctions.net/api"
}

$environments = @("production", "preview", "development")

foreach ($varName in $envVars.Keys) {
    $varValue = $envVars[$varName]
    
    Write-Host "`n🔧 Setting $varName..." -ForegroundColor Cyan
    
    foreach ($env in $environments) {
        Write-Host "  → $env" -ForegroundColor Yellow
        
        # 값을 stdin으로 전달
        $varValue | vercel env add $varName $env 2>&1 | Out-Null
    }
}

Write-Host "`n✅ All environment variables updated!" -ForegroundColor Green
Write-Host "🔄 Now redeploy with: vercel --prod" -ForegroundColor Cyan
