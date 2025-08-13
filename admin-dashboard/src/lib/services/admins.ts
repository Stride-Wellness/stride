import {
	collection,
	doc,
	getDoc,
	getDocs,
	addDoc,
	updateDoc,
	deleteDoc,
	query,
	orderBy,
	limit,
	Timestamp
} from 'firebase/firestore';
import { db } from '$lib/firebase/config';
import { toSafeDate } from './utils';

// Update interface to match database design
export interface Admin {
	id: string;
	name: string;
	privilege: number; // 0 = super admin, 1 = admin, 2 = moderator, 3 = read-only
	createdAt: Date;
	createdBy: string;
	updatedAt: Date;
}

export interface CreateAdminData {
	name: string;
	privilege: number;
	createdBy: string;
}

export interface UpdateAdminData {
	name?: string;
	privilege?: number;
}

export class AdminsService {
	private static COLLECTION = 'admins';

	/**
	 * Get all admin users
	 */
	static async getAll(limitCount: number = 100): Promise<Admin[]> {
		try {
			const adminsRef = collection(db, this.COLLECTION);
			const q = query(adminsRef, orderBy('createdAt', 'desc'), limit(limitCount));

			const querySnap = await getDocs(q);
			const admins: Admin[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				admins.push({
					id: doc.id,
					name: data.name,
					privilege: data.privilege,
					createdAt: toSafeDate(data.createdAt),
					createdBy: data.createdBy,
					updatedAt: toSafeDate(data.updatedAt)
				});
			});

			return admins;
		} catch (error) {
			console.error('Error getting admins:', error);
			throw new Error('Failed to get admin users');
		}
	}

	/**
	 * Get admin user by ID
	 */
	static async getById(adminId: string): Promise<Admin | null> {
		try {
			const adminRef = doc(db, this.COLLECTION, adminId);
			const adminSnap = await getDoc(adminRef);

			if (!adminSnap.exists()) {
				return null;
			}

			const data = adminSnap.data();
			return {
				id: adminSnap.id,
				name: data.name,
				privilege: data.privilege,
				createdAt: toSafeDate(data.createdAt),
				createdBy: data.createdBy,
				updatedAt: toSafeDate(data.updatedAt)
			};
		} catch (error) {
			console.error('Error getting admin by ID:', error);
			throw new Error('Failed to get admin user');
		}
	}

	/**
	 * Create new admin user
	 */
	static async create(data: CreateAdminData): Promise<Admin> {
		try {
			const now = Timestamp.now();
			const adminData = {
				name: data.name,
				privilege: data.privilege,
				createdBy: data.createdBy,
				createdAt: now,
				updatedAt: now
			};

			const docRef = await addDoc(collection(db, this.COLLECTION), adminData);

			return {
				id: docRef.id,
				...adminData,
				createdAt: now.toDate(),
				updatedAt: now.toDate()
			};
		} catch (error) {
			console.error('Error creating admin:', error);
			throw new Error('Failed to create admin user');
		}
	}

	/**
	 * Update admin user
	 */
	static async update(adminId: string, data: UpdateAdminData): Promise<void> {
		try {
			const adminRef = doc(db, this.COLLECTION, adminId);
			const updateData = {
				...data,
				updatedAt: Timestamp.now()
			};

			await updateDoc(adminRef, updateData);
		} catch (error) {
			console.error('Error updating admin:', error);
			throw new Error('Failed to update admin user');
		}
	}

	/**
	 * Delete admin user
	 */
	static async delete(adminId: string): Promise<void> {
		try {
			const adminRef = doc(db, this.COLLECTION, adminId);
			await deleteDoc(adminRef);
		} catch (error) {
			console.error('Error deleting admin:', error);
			throw new Error('Failed to delete admin user');
		}
	}

	/**
	 * Get admin statistics
	 */
	static async getStats(): Promise<{
		total: number;
		byPrivilegeLevel: Record<number, number>;
	}> {
		try {
			const admins = await this.getAll(1000);

			const stats = {
				total: admins.length,
				byPrivilegeLevel: {} as Record<number, number>
			};

			// Count by privilege level
			admins.forEach((admin) => {
				const level = admin.privilege;
				stats.byPrivilegeLevel[level] = (stats.byPrivilegeLevel[level] || 0) + 1;
			});

			return stats;
		} catch (error) {
			console.error('Error getting admin stats:', error);
			throw new Error('Failed to get admin statistics');
		}
	}

	/**
	 * Check if user has specific permission level or higher
	 */
	static async hasPermission(adminId: string, requiredLevel: number): Promise<boolean> {
		try {
			const admin = await this.getById(adminId);
			if (!admin) return false;

			return admin.privilege <= requiredLevel;
		} catch (error) {
			console.error('Error checking permissions:', error);
			return false;
		}
	}

	/**
	 * Get admins by privilege level
	 */
	static async getByPrivilegeLevel(privilegeLevel: number): Promise<Admin[]> {
		try {
			const admins = await this.getAll(1000);
			return admins.filter((admin) => admin.privilege === privilegeLevel);
		} catch (error) {
			console.error('Error getting admins by privilege level:', error);
			throw new Error('Failed to get admins by privilege level');
		}
	}

	/**
	 * Search admins by name
	 */
	static async search(searchTerm: string): Promise<Admin[]> {
		try {
			const admins = await this.getAll(1000);
			const lowercaseSearch = searchTerm.toLowerCase();

			return admins.filter((admin) => admin.name.toLowerCase().includes(lowercaseSearch));
		} catch (error) {
			console.error('Error searching admins:', error);
			throw new Error('Failed to search admin users');
		}
	}
}
