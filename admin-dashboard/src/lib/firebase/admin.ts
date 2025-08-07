import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FIREBASE_ADMIN_SDK_KEY } from '$env/static/private';

let adminApp;

if (getApps().length === 0) {
  adminApp = initializeApp({
    credential: cert(JSON.parse(FIREBASE_ADMIN_SDK_KEY)),
  });
} else {
  adminApp = getApps()[0];
}

export const auth = getAuth(adminApp);