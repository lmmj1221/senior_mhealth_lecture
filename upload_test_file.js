const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const serviceAccount = require('./backend/service-account-key.json');

// Firebase Admin 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'my-project-54928-b9704.firebasestorage.app'
});

const bucket = admin.storage().bucket();

async function uploadTestFile() {
  const userId = '7wll6D15YZgVrL7jEO1dJhyCUKG3';
  const seniorId = 'test_senior_001';
  const callId = 'test_call_1760506267900';
  const fileName = '통화 녹음 어머니_250505_122325.m4a';

  const localFilePath = path.join(__dirname, 'data', fileName);
  const storagePath = `calls/${userId}/${seniorId}/${callId}/${fileName}`;

  try {
    console.log('📤 Uploading test file to Firebase Storage...');
    console.log('   Local file:', localFilePath);
    console.log('   Storage path:', storagePath);

    // 파일 존재 확인
    if (!fs.existsSync(localFilePath)) {
      throw new Error(`File not found: ${localFilePath}`);
    }

    const fileStats = fs.statSync(localFilePath);
    console.log('   File size:', (fileStats.size / 1024 / 1024).toFixed(2), 'MB');

    // Storage에 업로드
    await bucket.upload(localFilePath, {
      destination: storagePath,
      metadata: {
        contentType: 'audio/m4a',
        metadata: {
          userId: userId,
          seniorId: seniorId,
          callId: callId,
          uploadedBy: 'test_script'
        }
      }
    });

    console.log('✅ File uploaded successfully!');
    console.log('   Storage path:', storagePath);
    console.log('\n🔔 Storage trigger should fire now...');
    console.log('   Check Firebase Functions logs:');
    console.log('   firebase functions:log --only processVoiceFile');

    console.log('\n📊 Check Firestore for updates:');
    console.log('   Path: users/' + userId + '/calls/' + callId);

  } catch (error) {
    console.error('❌ Error uploading file:', error);
    throw error;
  }
}

uploadTestFile()
  .then(() => {
    console.log('\n✨ Upload complete! Waiting 5 seconds before exiting...');
    setTimeout(() => process.exit(0), 5000);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
