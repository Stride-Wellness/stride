import {
	collection,
	doc,
	getDoc,
	getDocs,
	addDoc,
	updateDoc,
	deleteDoc,
	query,
	where,
	orderBy,
	limit,
	Timestamp
} from 'firebase/firestore';
import { db } from '$lib/firebase/config';

import { toSafeDate } from './utils'; // Import the utility function

export interface DivisionSettings {
	[key: string]: string | number | boolean | null;
}

export interface Division {
	id: string;
	organizationId: string;
	name: string;
	managerId: string;
	divisionType: 'retirement_home' | 'homecare_provider';
	settings: DivisionSettings;
	createdAt: Date;
	updatedAt: Date;
}

export interface CreateDivisionData {
	organizationId: string;
	name: string;
	managerId: string;
	divisionType: 'retirement_home' | 'homecare_provider';
	settings?: DivisionSettings;
}

export interface UpdateDivisionData {
	name?: string;
	managerId?: string;
	divisionType?: 'retirement_home' | 'homecare_provider';
	settings?: DivisionSettings;
}

export class DivisionsService {
	private static COLLECTION = 'divisions';

	/**
	 * Get division by ID
	 */
	static async getById(divisionId: string): Promise<Division | null> {
		try {
			const divisionRef = doc(db, this.COLLECTION, divisionId);
			const divisionSnap = await getDoc(divisionRef);

			if (!divisionSnap.exists()) {
				return null;
			}

			const data = divisionSnap.data();
			return {
				id: divisionSnap.id,
				organizationId: data.organizationId,
				name: data.name,
				managerId: data.managerId,
				divisionType: data.divisionType,
				settings: data.settings || {},
				createdAt: toSafeDate(data.createdAt),
				updatedAt: toSafeDate(data.updatedAt)
			};
		} catch (error) {
			console.error('Error getting division:', error);
			throw new Error('Failed to get division');
		}
	}

	/**
	 * Get all divisions (admin only)
	 */
	static async getAll(limitCount: number = 100): Promise<Division[]> {
		try {
			const divisionsRef = collection(db, this.COLLECTION);
			const q = query(divisionsRef, orderBy('createdAt', 'desc'), limit(limitCount));

			const querySnap = await getDocs(q);
			const divisions: Division[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				divisions.push({
					id: doc.id,
					organizationId: data.organizationId,
					name: data.name,
					managerId: data.managerId,
					divisionType: data.divisionType,
					settings: data.settings || {},
					createdAt: toSafeDate(data.createdAt),
					updatedAt: toSafeDate(data.updatedAt)
				});
			});

			return divisions;
		} catch (error) {
			console.error('Error getting divisions:', error);
			throw new Error('Failed to get divisions');
		}
	}

	/**
	 * Get divisions by organization ID
	 */
	static async getByOrganizationId(organizationId: string): Promise<Division[]> {
		try {
			const divisionsRef = collection(db, this.COLLECTION);
			const q = query(divisionsRef, where('organizationId', '==', organizationId), orderBy('createdAt', 'desc'));

			const querySnap = await getDocs(q);
			const divisions: Division[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				divisions.push({
					id: doc.id,
					organizationId: data.organizationId,
					name: data.name,
					managerId: data.managerId,
					divisionType: data.divisionType,
					settings: data.settings || {},
					createdAt: toSafeDate(data.createdAt),
					updatedAt: toSafeDate(data.updatedAt)
				});
			});

			return divisions;
		} catch (error) {
			console.error('Error getting divisions by organization:', error);
			throw new Error('Failed to get divisions by organization');
		}
	}

	/**
	 * Create new division
	 */
	static async create(data: CreateDivisionData): Promise<Division> {
		try {
			const now = Timestamp.now();
			const divisionData = {
				organizationId: data.organizationId,
				name: data.name,
				managerId: data.managerId,
				divisionType: data.divisionType,
				settings: data.settings || {},
				createdAt: now,
				updatedAt: now
			};

			const docRef = await addDoc(collection(db, this.COLLECTION), divisionData);

			return {
				id: docRef.id,
				...divisionData,
				createdAt: now.toDate(),
				updatedAt: now.toDate()
			};
		} catch (error) {
			console.error('Error creating division:', error);
			throw new Error('Failed to create division');
		}
	}

	/**
	 * Update division
	 */
	static async update(divisionId: string, data: UpdateDivisionData): Promise<void> {
		try {
			const divisionRef = doc(db, this.COLLECTION, divisionId);
			const updateData = {
				...data,
				updatedAt: Timestamp.now()
			};

			await updateDoc(divisionRef, updateData);
		} catch (error) {
			console.error('Error updating division:', error);
			throw new Error('Failed to update division');
		}
	}

	/**
	 * Hard delete division (use with caution)
	 */
	static async hardDelete(divisionId: string): Promise<void> {
		try {
			const divisionRef = doc(db, this.COLLECTION, divisionId);
			await deleteDoc(divisionRef);
		} catch (error) {
			console.error('Error hard deleting division:', error);
			throw new Error('Failed to permanently delete division');
		}
	}
}
