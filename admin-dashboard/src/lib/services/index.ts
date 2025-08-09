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

export interface OrganizationSettings {
	[key: string]: string | number | boolean | null;
}

export interface Organization {
	id: string;
	name: string;
	totalSeats: number;
	usedSeats: number;
	status: 'active' | 'suspended' | 'cancelled';
	stripeUserId: string;
	settings: OrganizationSettings;
	createdAt: Date;
	updatedAt: Date;
}

export interface CreateOrganizationData {
	name: string;
	totalSeats: number;
	stripeUserId: string;
	settings?: OrganizationSettings;
}

export interface UpdateOrganizationData {
	name?: string;
	totalSeats?: number;
	status?: 'active' | 'suspended' | 'cancelled';
	stripeUserId?: string;
	settings?: OrganizationSettings;
}

export class OrganizationsService {
	private static COLLECTION = 'organizations';

	/**
	 * Get organization by ID
	 */
	static async getById(organizationId: string): Promise<Organization | null> {
		try {
			const orgRef = doc(db, this.COLLECTION, organizationId);
			const orgSnap = await getDoc(orgRef);

			if (!orgSnap.exists()) {
				return null;
			}

			const data = orgSnap.data();
			return {
				id: orgSnap.id,
				name: data.name,
				totalSeats: data.totalSeats,
				usedSeats: data.usedSeats || 0,
				status: data.status,
				stripeUserId: data.stripeUserId,
				settings: data.settings || {},
				createdAt: data.createdAt?.toDate() || new Date(),
				updatedAt: data.updatedAt?.toDate() || new Date()
			};
		} catch (error) {
			console.error('Error getting organization:', error);
			throw new Error('Failed to get organization');
		}
	}

	/**
	 * Get all organizations (admin only)
	 */
	static async getAll(limitCount: number = 100): Promise<Organization[]> {
		try {
			const orgsRef = collection(db, this.COLLECTION);
			const q = query(orgsRef, orderBy('createdAt', 'desc'), limit(limitCount));

			const querySnap = await getDocs(q);
			const organizations: Organization[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				organizations.push({
					id: doc.id,
					name: data.name,
					totalSeats: data.totalSeats,
					usedSeats: data.usedSeats || 0,
					status: data.status,
					stripeUserId: data.stripeUserId,
					settings: data.settings || {},
					createdAt: data.createdAt?.toDate() || new Date(),
					updatedAt: data.updatedAt?.toDate() || new Date()
				});
			});

			return organizations;
		} catch (error) {
			console.error('Error getting organizations:', error);
			throw new Error('Failed to get organizations');
		}
	}

	/**
	 * Get organizations by status
	 */
	static async getByStatus(status: 'active' | 'suspended' | 'cancelled'): Promise<Organization[]> {
		try {
			const orgsRef = collection(db, this.COLLECTION);
			const q = query(orgsRef, where('status', '==', status), orderBy('createdAt', 'desc'));

			const querySnap = await getDocs(q);
			const organizations: Organization[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				organizations.push({
					id: doc.id,
					name: data.name,
					totalSeats: data.totalSeats,
					usedSeats: data.usedSeats || 0,
					status: data.status,
					stripeUserId: data.stripeUserId,
					settings: data.settings || {},
					createdAt: data.createdAt?.toDate() || new Date(),
					updatedAt: data.updatedAt?.toDate() || new Date()
				});
			});

			return organizations;
		} catch (error) {
			console.error('Error getting organizations by status:', error);
			throw new Error('Failed to get organizations by status');
		}
	}

	/**
	 * Create new organization
	 */
	static async create(data: CreateOrganizationData): Promise<Organization> {
		try {
			const now = Timestamp.now();
			const orgData = {
				name: data.name,
				totalSeats: data.totalSeats,
				usedSeats: 0,
				status: 'active' as const,
				stripeUserId: data.stripeUserId,
				settings: data.settings || {},
				createdAt: now,
				updatedAt: now
			};

			const docRef = await addDoc(collection(db, this.COLLECTION), orgData);

			return {
				id: docRef.id,
				...orgData,
				createdAt: now.toDate(),
				updatedAt: now.toDate()
			};
		} catch (error) {
			console.error('Error creating organization:', error);
			throw new Error('Failed to create organization');
		}
	}

	/**
	 * Update organization
	 */
	static async update(organizationId: string, data: UpdateOrganizationData): Promise<void> {
		try {
			const orgRef = doc(db, this.COLLECTION, organizationId);
			const updateData = {
				...data,
				updatedAt: Timestamp.now()
			};

			await updateDoc(orgRef, updateData);
		} catch (error) {
			console.error('Error updating organization:', error);
			throw new Error('Failed to update organization');
		}
	}

	/**
	 * Update seat usage (called when users are added/removed)
	 */
	static async updateSeatUsage(organizationId: string, usedSeats: number): Promise<void> {
		try {
			const orgRef = doc(db, this.COLLECTION, organizationId);
			await updateDoc(orgRef, {
				usedSeats: usedSeats,
				updatedAt: Timestamp.now()
			});
		} catch (error) {
			console.error('Error updating seat usage:', error);
			throw new Error('Failed to update seat usage');
		}
	}

	/**
	 * Delete organization (soft delete by setting status to cancelled)
	 */
	static async softDelete(organizationId: string): Promise<void> {
		try {
			await this.update(organizationId, { status: 'cancelled' });
		} catch (error) {
			console.error('Error soft deleting organization:', error);
			throw new Error('Failed to delete organization');
		}
	}

	/**
	 * Hard delete organization (use with caution)
	 */
	static async hardDelete(organizationId: string): Promise<void> {
		try {
			const orgRef = doc(db, this.COLLECTION, organizationId);
			await deleteDoc(orgRef);
		} catch (error) {
			console.error('Error hard deleting organization:', error);
			throw new Error('Failed to permanently delete organization');
		}
	}

	/**
	 * Check if organization has available seats
	 */
	static async hasAvailableSeats(organizationId: string): Promise<boolean> {
		try {
			const org = await this.getById(organizationId);
			if (!org) return false;

			return org.usedSeats < org.totalSeats;
		} catch (error) {
			console.error('Error checking available seats:', error);
			return false;
		}
	}

	/**
	 * Get seat utilization percentage
	 */
	static async getSeatUtilization(organizationId: string): Promise<number> {
		try {
			const org = await this.getById(organizationId);
			if (!org || org.totalSeats === 0) return 0;

			return Math.round((org.usedSeats / org.totalSeats) * 100);
		} catch (error) {
			console.error('Error calculating seat utilization:', error);
			return 0;
		}
	}
}

export { AdminsService } from './admins';
export type { CreateAdminData, UpdateAdminData } from './admins';
