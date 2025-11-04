# 올바른 Firebase 환경 변수 추가
$vars = @(
    @{name="NEXT_PUBLIC_FIREBASE_API_KEY"; value="AIzaSyCMZ5G72UJR_Wtw5kHbkxE7u1ykWyE7PF4"},
    @{name="NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN"; value="senior-mhealth-202373080.firebaseapp.com"},
    @{name="NEXT_PUBLIC_FIREBASE_PROJECT_ID"; value="senior-mhealth-202373080"},
    @{name="NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET"; value="senior-mhealth-202373080.firebasestorage.app"},
    @{name="NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID"; value="739201926447"},
    @{name="NEXT_PUBLIC_FIREBASE_APP_ID"; value="1:739201926447:web:7392cc28b672c1169a4dda"},
    @{name="NEXT_PUBLIC_API_URL"; value="https://asia-northeast3-senior-mhealth-202373080.cloudfunctions.net/api"}
)

foreach($var in $vars) {
    Write-Host "Adding $($var.name)..." -ForegroundColor Cyan
    
    foreach($env in @("production", "preview", "development")) {
        # NoNewline으로 줄바꿈 제거
        $var.value | Out-String | ForEach-Object { $_.Trim() } | vercel env add $var.name $env | Out-Null
    }
    
    Write-Host "  ✅ Done" -ForegroundColor Green
}

Write-Host "`n🎉 All variables added successfully!" -ForegroundColor Green
