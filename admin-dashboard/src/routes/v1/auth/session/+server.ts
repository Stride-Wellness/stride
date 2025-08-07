// src/routes/api/auth/session/+server.ts
import { json } from '@sveltejs/kit';
import { auth } from '$lib/firebase/admin';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request, cookies }) => {
  const { idToken } = await request.json();
  
  try {
    // Verify the token
    await auth.verifyIdToken(idToken);
    
    // Create session cookie (5 days)
    const sessionCookie = await auth.createSessionCookie(idToken, { 
      expiresIn: 60 * 60 * 24 * 5 * 1000 
    });
    
    // Set secure cookie
    cookies.set('session', sessionCookie, {
      path: '/',
      httpOnly: true,
      secure: true,
      sameSite: 'strict',
      maxAge: 60 * 60 * 24 * 5
    });
    
    return json({ success: true });
  } catch (error) {
    console.error('Session creation error:', error);
    return json({ error: 'Invalid token' }, { status: 401 });
  }
};