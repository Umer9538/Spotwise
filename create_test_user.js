const admin = require('firebase-admin');
const { execSync } = require('child_process');

// Get access token from firebase CLI
function getAccessToken() {
  try {
    const result = execSync('firebase login:ci --no-localhost 2>/dev/null || echo ""');
    return result.toString().trim();
  } catch (e) {
    return null;
  }
}

// Initialize with project ID (uses ADC)
admin.initializeApp({
  projectId: 'spotwise-12f82',
  credential: admin.credential.applicationDefault(),
});

const auth = admin.auth();
const db = admin.firestore();

async function createTestUser() {
  const email = 'student@psu.edu.sa';
  const password = 'Student123!';
  const userId = 'test_student_001';

  try {
    // Delete existing user if exists
    try {
      await auth.deleteUser(userId);
      console.log('Deleted existing user');
    } catch (e) {
      // User doesn't exist, that's fine
    }

    // Create Auth user
    const userRecord = await auth.createUser({
      uid: userId,
      email: email,
      password: password,
      emailVerified: true,
      displayName: 'Test Student',
    });
    console.log('Created Auth user:', userRecord.uid);

    // Create Firestore document
    const userData = {
      user_id: userId,
      email: email,
      name: 'Test Student',
      student_id: '12345678',
      role: 'student',
      avatar_url: null,
      created_at: new Date().toISOString(),
      notification_preferences: {
        push_enabled: true,
        reservation_confirmed: true,
        expiry_warning: true,
        spots_available: false,
        email_enabled: true,
      },
    };

    await db.collection('users').doc(userId).set(userData);
    console.log('Created Firestore document');

    console.log('\n========================================');
    console.log('TEST USER CREATED SUCCESSFULLY!');
    console.log('========================================');
    console.log('Email:    ' + email);
    console.log('Password: ' + password);
    console.log('========================================\n');

  } catch (error) {
    console.error('Error creating user:', error.message);
  }

  process.exit(0);
}

createTestUser();
