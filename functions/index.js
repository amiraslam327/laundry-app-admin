const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function to delete an admin account from Firebase Authentication
 * 
 * This function is called from the Flutter app after deleting the admin
 * document from Firestore. It deletes the Firebase Auth user.
 * 
 * @param {Object} data - Contains { uid: string }
 * @param {Object} context - Firebase callable function context
 * @returns {Object} { success: boolean }
 */
exports.deleteAdminAccount = functions.https.onCall(async (data, context) => {
  // Verify the caller is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to delete admins'
    );
  }

  // Verify the caller is an admin
  const callerAdminDoc = await admin
    .firestore()
    .collection('admin')
    .doc(context.auth.uid)
    .get();
    
  if (!callerAdminDoc.exists) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can delete other admins'
    );
  }

  const { uid } = data;
  
  if (!uid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'UID is required'
    );
  }

  // Prevent self-deletion (safety check)
  if (context.auth.uid === uid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Cannot delete your own account'
    );
  }

  try {
    // Delete from Firebase Auth
    await admin.auth().deleteUser(uid);
    
    return { 
      success: true,
      message: 'Admin account deleted successfully from Firebase Authentication'
    };
  } catch (error) {
    console.error('Error deleting admin account:', error);
    
    // If user doesn't exist in Auth, that's okay (might have been deleted already)
    if (error.code === 'auth/user-not-found') {
      return {
        success: true,
        message: 'Admin account not found in Auth (may have been deleted already)'
      };
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Error deleting admin account: ' + error.message
    );
  }
});

