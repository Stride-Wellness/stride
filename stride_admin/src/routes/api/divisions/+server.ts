import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { adminDb } from '$lib/firebase/admin';

export const GET: RequestHandler = async ({ url }) => {
	try {
		const organizationId = url.searchParams.get('organizationId');
		
		const divisionsRef = adminDb.collection('divisions');
		
		let queryRef;
		if (organizationId) {
			queryRef = divisionsRef.where('organizationId', '==', organizationId);
		} else {
			queryRef = divisionsRef;
		}
		
		const snapshot = await queryRef.get();
		const divisions = snapshot.docs.map(doc => ({
			id: doc.id,
			...doc.data()
		}));
		
		return json({ divisions });
	} catch (error) {
		console.error('Error fetching divisions:', error);
		return json({ error: 'Failed to fetch divisions' }, { status: 500 });
	}
};
