import type { Handle } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';
import { redirect } from '@sveltejs/kit';
import { paraglideMiddleware } from '$lib/paraglide/server';
import { auth } from '$lib/firebase/admin';

const handleAuth: Handle = async ({ event, resolve }) => {
	const token = event.cookies.get('session');

	if (token) {
		try {
			const decodedToken = await auth.verifyIdToken(token);
			event.locals.user = decodedToken;
		} catch {
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
		throw redirect(302, '/');
	}

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