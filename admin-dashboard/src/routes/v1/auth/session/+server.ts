// src/routes/api/auth/session/+server.ts
import { json } from '@sveltejs/kit';
import { adminAuth } from '$lib/firebase/admin';
import type { RequestHandler } from './$types';
import { dev } from '$app/environment';

export const POST: RequestHandler = async ({ request, cookies }) => {
	console.log('=== SESSION ENDPOINT DEBUG ===');

	try {
		const { idToken } = await request.json();
		console.log('Received ID token:', !!idToken);

		// Verify the token
		const decodedToken = await adminAuth.verifyIdToken(idToken);
		console.log('Token verified for user:', decodedToken.email);

		// Create session cookie (5 days)
		const sessionCookie = await adminAuth.createSessionCookie(idToken, {
			expiresIn: 60 * 60 * 24 * 5 * 1000
		});
		console.log('Session cookie created');

		// Set secure cookie
		cookies.set('session', sessionCookie, {
			path: '/',
			httpOnly: true,
			secure: !dev,
			sameSite: 'strict',
			maxAge: 60 * 60 * 24 * 5
		});
		console.log('Cookie set in response');

		return json({ success: true });
	} catch (error) {
		console.error('Session creation error:', error);
		return json({ error: 'Invalid token' }, { status: 401 });
	}
};