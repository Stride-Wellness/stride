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
	status: 'active' | 'inactive' | 'deleted';
	deletedAt?: Date;
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
	status?: 'active' | 'inactive' | 'deleted';
	deletedAt?: Date | null;
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
				status: data.status || 'active',
				deletedAt: data.deletedAt ? toSafeDate(data.deletedAt) : undefined,
				createdAt: toSafeDate(data.createdAt),
				updatedAt: toSafeDate(data.updatedAt)
			};
		} catch (error) {
			console.error('Error getting division:', error);
			throw new Error('Failed to get division');
		}
	}

	/**
	 * Get all divisions (admin only) - excludes deleted divisions by default
	 */
	static async getAll(
		limitCount: number = 100,
		includeDeleted: boolean = false
	): Promise<Division[]> {
		try {
			const divisionsRef = collection(db, this.COLLECTION);
			let q = query(divisionsRef, orderBy('createdAt', 'desc'), limit(limitCount));

			// Filter out deleted divisions unless explicitly requested
			if (!includeDeleted) {
				q = query(
					divisionsRef,
					where('status', '!=', 'deleted'),
					orderBy('createdAt', 'desc'),
					limit(limitCount)
				);
			}

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
					status: data.status || 'active',
					deletedAt: data.deletedAt ? toSafeDate(data.deletedAt) : undefined,
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
	 * Get divisions by organization ID - excludes deleted divisions by default
	 */
	static async getByOrganizationId(
		organizationId: string,
		includeDeleted: boolean = false
	): Promise<Division[]> {
		try {
			const divisionsRef = collection(db, this.COLLECTION);
			let q = query(
				divisionsRef,
				where('organizationId', '==', organizationId),
				orderBy('createdAt', 'desc')
			);

			// Filter out deleted divisions unless explicitly requested
			if (!includeDeleted) {
				q = query(
					divisionsRef,
					where('organizationId', '==', organizationId),
					where('status', '!=', 'deleted'),
					orderBy('createdAt', 'desc')
				);
			}

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
					status: data.status || 'active',
					deletedAt: data.deletedAt ? toSafeDate(data.deletedAt) : undefined,
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
				status: 'active' as const,
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
	 * Soft delete division (set status to deleted and add deletedAt timestamp)
	 */
	static async softDelete(divisionId: string, cascadeUsers: boolean = false): Promise<void> {
		try {
			// Soft delete the division
			await this.update(divisionId, {
				status: 'deleted',
				deletedAt: new Date()
			});

			// Optionally cascade soft delete to all users in the division
			if (cascadeUsers) {
				const { UsersService } = await import('./users');
				const users = await UsersService.getByDivisionId(divisionId, false); // Get active users only

				// Soft delete all users in this division
				for (const user of users) {
					await UsersService.softDelete(user.id);
				}
			}
		} catch (error) {
			console.error('Error soft deleting division:', error);
			throw new Error('Failed to delete division');
		}
	}

	/**
	 * Restore soft deleted division
	 */
	static async restore(divisionId: string): Promise<void> {
		try {
			const divisionRef = doc(db, this.COLLECTION, divisionId);
			await updateDoc(divisionRef, {
				status: 'active',
				deletedAt: null,
				updatedAt: Timestamp.now()
			});
		} catch (error) {
			console.error('Error restoring division:', error);
			throw new Error('Failed to restore division');
		}
	}

	/**
	 * Check if division has any active users (to prevent hard delete)
	 */
	static async hasActiveUsers(divisionId: string): Promise<boolean> {
		try {
			const { UsersService } = await import('./users');
			const users = await UsersService.getByDivisionId(divisionId, false); // Get active users only
			return users.length > 0;
		} catch (error) {
			console.error('Error checking division users:', error);
			return true; // Err on the side of caution
		}
	}

	/**
	 * Hard delete division (use with caution) - only if no active references
	 */
	static async hardDelete(divisionId: string): Promise<void> {
		try {
			// Check for active users before allowing hard delete
			const hasUsers = await this.hasActiveUsers(divisionId);
			if (hasUsers) {
				throw new Error('Cannot hard delete division with active users. Use soft delete instead.');
			}

			const divisionRef = doc(db, this.COLLECTION, divisionId);
			await deleteDoc(divisionRef);
		} catch (error) {
			console.error('Error hard deleting division:', error);
			throw new Error('Failed to permanently delete division');
		}
	}
}
