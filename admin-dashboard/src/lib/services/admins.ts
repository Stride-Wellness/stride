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
import type { AdminUser } from '$lib/types';

export interface CreateAdminData {
	email: string;
	name: string;
	privilege: number;
}

export interface UpdateAdminData {
	name?: string;
	privilege?: number;
	disabled?: boolean;
}

export class AdminsService {
	private static COLLECTION = 'admins';

	/**
	 * Get all admin users
	 */
	static async getAll(limitCount: number = 100): Promise<AdminUser[]> {
		try {
			const adminsRef = collection(db, this.COLLECTION);
			const q = query(adminsRef, orderBy('createdAt', 'desc'), limit(limitCount));

			const querySnap = await getDocs(q);
			const admins: AdminUser[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				admins.push({
					id: doc.id,
					email: data.email,
					name: data.name,
					privilege: data.privilege,
					emailVerified: data.emailVerified || false,
					disabled: data.disabled || false,
					lastSignIn: data.lastSignIn?.toDate() || null,
					createdAt: data.createdAt?.toDate() || new Date(),
					updatedAt: data.updatedAt?.toDate() || new Date()
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
	static async getById(adminId: string): Promise<AdminUser | null> {
		try {
			const adminRef = doc(db, this.COLLECTION, adminId);
			const adminSnap = await getDoc(adminRef);

			if (!adminSnap.exists()) {
				return null;
			}

			const data = adminSnap.data();
			return {
				id: adminSnap.id,
				email: data.email,
				name: data.name,
				privilege: data.privilege,
				emailVerified: data.emailVerified || false,
				disabled: data.disabled || false,
				lastSignIn: data.lastSignIn?.toDate() || null,
				createdAt: data.createdAt?.toDate() || new Date(),
				updatedAt: data.updatedAt?.toDate() || new Date()
			};
		} catch (error) {
			console.error('Error getting admin by ID:', error);
			throw new Error('Failed to get admin user');
		}
	}

	/**
	 * Create new admin user (calls server action)
	 */
	static async create(data: CreateAdminData): Promise<AdminUser> {
		try {
			const now = Timestamp.now();
			const adminData = {
				email: data.email,
				name: data.name,
				privilege: data.privilege,
				emailVerified: false,
				disabled: false,
				lastSignIn: null,
				createdAt: now,
				updatedAt: now
			};

			const docRef = await addDoc(collection(db, this.COLLECTION), adminData);

			return {
				id: docRef.id,
				...adminData,
				lastSignIn: null,
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
		active: number;
		disabled: number;
		verified: number;
		highPrivilege: number;
		byPrivilegeLevel: Record<number, number>;
	}> {
		try {
			const admins = await this.getAll(1000);

			const stats = {
				total: admins.length,
				active: admins.filter(admin => !admin.disabled).length,
				disabled: admins.filter(admin => admin.disabled).length,
				verified: admins.filter(admin => admin.emailVerified).length,
				highPrivilege: admins.filter(admin => admin.privilege <= 1).length,
				byPrivilegeLevel: {} as Record<number, number>
			};

			// Count by privilege level
			admins.forEach(admin => {
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
			if (!admin || admin.disabled) return false;
			
			return admin.privilege <= requiredLevel;
		} catch (error) {
			console.error('Error checking permissions:', error);
			return false;
		}
	}

	/**
	 * Get admins by privilege level
	 */
	static async getByPrivilegeLevel(privilegeLevel: number): Promise<AdminUser[]> {
		try {
			const admins = await this.getAll(1000);
			return admins.filter(admin => admin.privilege === privilegeLevel);
		} catch (error) {
			console.error('Error getting admins by privilege level:', error);
			throw new Error('Failed to get admins by privilege level');
		}
	}

	/**
	 * Search admins by email or name
	 */
	static async search(searchTerm: string): Promise<AdminUser[]> {
		try {
			const admins = await this.getAll(1000);
			const lowercaseSearch = searchTerm.toLowerCase();
			
			return admins.filter(admin => 
				admin.email.toLowerCase().includes(lowercaseSearch) ||
				admin.name.toLowerCase().includes(lowercaseSearch)
			);
		} catch (error) {
			console.error('Error searching admins:', error);
			throw new Error('Failed to search admin users');
		}
	}
}
