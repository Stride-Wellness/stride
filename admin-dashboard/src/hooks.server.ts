import type { Handle } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';
import { redirect } from '@sveltejs/kit';
import { paraglideMiddleware } from '$lib/paraglide/server';
import { adminAuth } from '$lib/firebase/admin';
import { AdminsService } from '$lib/services/admins';

const handleAuth: Handle = async ({ event, resolve }) => {
	const token = event.cookies.get('session');
	console.log('here');
	if (token) {
		try {
			const decodedToken = await adminAuth.verifySessionCookie(token);
			// Get full admin user data and verify admin status
			const adminUser = await AdminsService.getById_(decodedToken.uid);
			if (adminUser) {
				event.locals.user = adminUser;
			} else {
				// User exists but is not an admin, clear session
				event.cookies.delete('session', { path: '/' });
			}
		} catch (error) {
			console.error('Error verifying session:', error);
			event.cookies.delete('session', { path: '/' });
		}
	}

	// Check if this is a protected route
	const isProtectedRoute = event.route.id?.includes('(protected)');
	const isLoginRoute = event.url.pathname === '/login';

	// Redirect to login if accessing protected route without auth
	if (isProtectedRoute && !event.locals.user) {
		throw redirect(302, '/login');
	}

	// Redirect to dashboard if logged in user tries to access login
	if (isLoginRoute && event.locals.user) {
		console.log('🔄 Redirecting to dashboard - user already logged in');
		throw redirect(302, '/');
	}

	console.log('✅ Proceeding to resolve');
	return resolve(event);
};

const handleParaglide: Handle = ({ event, resolve }) =>
	paraglideMiddleware(event.request, ({ request, locale }) => {
		event.request = request;
		return resolve(event, {
			transformPageChunk: ({ html }) => html.replace('%paraglide.lang%', locale)
		});
	});

export const handle: Handle = sequence(handleAuth, handleParaglide);