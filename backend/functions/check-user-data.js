const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function checkUserData() {
  const userId = '79HUz97fhWf3JcsKePTW5T4KsjA2';

  console.log('=== Checking Firestore Data ===');
  console.log(`User ID: ${userId}\n`);

  try {
    // Check user document
    console.log('1. Checking users/{userId} document...');
    const userDoc = await db.collection('users').doc(userId).get();
    if (userDoc.exists) {
      console.log('✅ User document exists');
      console.log('Data:', JSON.stringify(userDoc.data(), null, 2));
    } else {
      console.log('❌ User document does NOT exist');
    }

    // Check seniors subcollection
    console.log('\n2. Checking users/{userId}/seniors subcollection...');
    const seniorsSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('seniors')
      .get();

    console.log(`Found ${seniorsSnapshot.docs.length} senior document(s)`);

    seniorsSnapshot.docs.forEach((doc, index) => {
      console.log(`\nSenior ${index + 1}:`);
      console.log('Document ID:', doc.id);
      console.log('Data:', JSON.stringify(doc.data(), null, 2));
    });

    // Check top-level seniors collection (legacy)
    console.log('\n3. Checking top-level seniors collection...');
    const topLevelSeniorsSnapshot = await db
      .collection('seniors')
      .where('userId', '==', userId)
      .get();

    console.log(`Found ${topLevelSeniorsSnapshot.docs.length} senior document(s) in top-level collection`);

    topLevelSeniorsSnapshot.docs.forEach((doc, index) => {
      console.log(`\nSenior ${index + 1}:`);
      console.log('Document ID:', doc.id);
      console.log('Data:', JSON.stringify(doc.data(), null, 2));
    });

  } catch (error) {
    console.error('Error:', error);
  }

  process.exit(0);
}

checkUserData();
