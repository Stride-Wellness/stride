import { httpsCallable } from 'firebase/functions';
import { functions } from '$lib/firebase/config';
import { toSafeDate } from './utils';

// Match Python AdminPrivilegeLevel enum
export enum AdminPrivilegeLevel {
	SUPER_ADMIN = 0,
	ADMIN = 1,
	MODERATOR = 2,
	READ_ONLY = 3,
	DISABLED = 4
}

export interface Admin {
	id: string;
	name: string;
	privilege: AdminPrivilegeLevel;
	createdAt: Date;
	createdBy: string;
	updatedAt: Date;
	lastSignIn?: Date; // Optional - from Auth metadata
}

export interface CreateAdminData {
	email: string;
	password: string;
	name: string;
	privilege?: AdminPrivilegeLevel;
}

export interface UpdateAdminData {
	userId: string;
	name?: string;
	privilege?: AdminPrivilegeLevel;
}

export interface DeleteAdminData {
	userId: string;
}

export interface GetAdminsData {
	limit?: number;
	userIds?: string[];
	privilegeLevel?: AdminPrivilegeLevel;
}

// Cloud Function response types
interface CloudFunctionResponse {
	success: boolean;
	message: string;
	userId?: string;
}

interface GetAdminsResponse {
	success: boolean;
	admins: Admin[];
	count: number;
}

interface GetAdminResponse {
	success: boolean;
	admin: Admin;
}

export class AdminsService {
	// ============================================================================
	// Public Read Methods (Use Cloud Functions with Auth metadata)
	// ============================================================================

	/**
	 * Get all admin users with Auth metadata (lastSignIn)
	 */
	static async getAll(
		limitCount: number = 100,
		privilegeLevel?: AdminPrivilegeLevel
	): Promise<Admin[]> {
		try {
			const getAdminsFn = httpsCallable<GetAdminsData, GetAdminsResponse>(functions, 'get_admins');

			const result = await getAdminsFn({
				limit: limitCount,
				privilegeLevel
			});

			if (!result.data.success) {
				throw new Error('Failed to get admins');
			}

			// Parse admins with Auth metadata
			return result.data.admins.map((admin) => ({
				id: admin.id,
				name: admin.name,
				privilege: admin.privilege as AdminPrivilegeLevel,
				createdAt: toSafeDate(admin.createdAt),
				createdBy: admin.createdBy,
				updatedAt: toSafeDate(admin.updatedAt),
				lastSignIn: admin.lastSignIn ? toSafeDate(admin.lastSignIn) : undefined
			}));
		} catch (error) {
			console.error('Error getting admins:', error);
			throw new Error('Failed to get admin users');
		}
	}

	/**
	 * Get admin user by ID with Auth metadata
	 */
	static async getById(adminId: string): Promise<Admin | null> {
		try {
			const getAdminFn = httpsCallable<{ userId: string }, GetAdminResponse>(
				functions,
				'get_admin_by_id'
			);

			const result = await getAdminFn({ userId: adminId });

			if (!result.data.success) {
				return null;
			}

			const admin = result.data.admin;
			return {
				id: admin.id,
				name: admin.name,
				privilege: admin.privilege as AdminPrivilegeLevel,
				createdAt: toSafeDate(admin.createdAt),
				createdBy: admin.createdBy,
				updatedAt: toSafeDate(admin.updatedAt),
				lastSignIn: admin.lastSignIn ? toSafeDate(admin.lastSignIn) : undefined
			};
		} catch (error) {
			console.error('Error getting admin by ID:', error);
			return null;
		}
	}

	/**
	 * Get admin user by ID with Auth metadata
	 */
	static async getById_(adminId: string): Promise<Admin | null> {
		if (typeof window !== 'undefined') {
			throw new Error('getByIdFromFirestore can only be called server-side');
		}

		try {
			// Import Admin SDK (only available server-side)
			const { adminDb } = await import('$lib/firebase/admin');

			const adminDoc = await adminDb.collection('admins').doc(adminId).get();

			if (!adminDoc.exists) {
				return null;
			}

			const data = adminDoc.data();
			if (!data) {
				return null;
			}

			return {
				id: adminDoc.id,
				name: data.name,
				privilege: data.privilege as AdminPrivilegeLevel,
				createdAt: data.createdAt?.toDate() || new Date(),
				createdBy: data.createdBy,
				updatedAt: data.updatedAt?.toDate() || new Date(),
				lastSignIn: undefined // No Auth metadata in direct Firestore reads
			};
		} catch (error) {
			console.error('Error getting admin from Firestore:', error);
			return null;
		}
	}

	/**
	 * Get admins by specific IDs (max 10 due to Firestore 'in' query limit)
	 */
	static async getByIds(adminIds: string[]): Promise<Admin[]> {
		try {
			if (adminIds.length > 10) {
				throw new Error('Cannot get more than 10 admins by ID at once');
			}

			const getAdminsFn = httpsCallable<GetAdminsData, GetAdminsResponse>(functions, 'get_admins');

			const result = await getAdminsFn({
				userIds: adminIds
			});

			if (!result.data.success) {
				throw new Error('Failed to get admins by IDs');
			}

			return result.data.admins.map((admin) => ({
				id: admin.id,
				name: admin.name,
				privilege: admin.privilege as AdminPrivilegeLevel,
				createdAt: toSafeDate(admin.createdAt),
				createdBy: admin.createdBy,
				updatedAt: toSafeDate(admin.updatedAt),
				lastSignIn: admin.lastSignIn ? toSafeDate(admin.lastSignIn) : undefined
			}));
		} catch (error) {
			console.error('Error getting admins by IDs:', error);
			throw new Error('Failed to get admins by IDs');
		}
	}

	/**
	 * Search admins by name (client-side filtering)
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

	/**
	 * Get admins by privilege level
	 */
	static async getByPrivilegeLevel(privilegeLevel: AdminPrivilegeLevel): Promise<Admin[]> {
		try {
			return await this.getAll(1000, privilegeLevel);
		} catch (error) {
			console.error('Error getting admins by privilege level:', error);
			throw new Error('Failed to get admins by privilege level');
		}
	}

	/**
	 * Get admin statistics
	 */
	static async getStats(): Promise<{
		total: number;
		byPrivilegeLevel: Record<AdminPrivilegeLevel, number>;
	}> {
		try {
			const admins = await this.getAll(1000);

			const stats = {
				total: admins.length,
				byPrivilegeLevel: {} as Record<AdminPrivilegeLevel, number>
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
	static async hasPermission(
		adminId: string,
		requiredLevel: AdminPrivilegeLevel
	): Promise<boolean> {
		try {
			const admin = await this.getById(adminId);
			if (!admin) return false;

			// Lower number = higher privilege (0 is SUPER_ADMIN)
			return admin.privilege <= requiredLevel;
		} catch (error) {
			console.error('Error checking permissions:', error);
			return false;
		}
	}

	// ============================================================================
	// Public Write Methods (Use Cloud Functions)
	// ============================================================================

	/**
	 * Create a new admin user (via Cloud Function)
	 * Creates both Firebase Auth user and Firestore document
	 */
	static async create(data: CreateAdminData): Promise<string> {
		try {
			const createAdminFn = httpsCallable<CreateAdminData, CloudFunctionResponse>(
				functions,
				'create_admin'
			);

			const result = await createAdminFn({
				email: data.email,
				password: data.password,
				name: data.name,
				privilege: data.privilege ?? AdminPrivilegeLevel.READ_ONLY
			});

			if (!result.data.success) {
				throw new Error(result.data.message);
			}

			return result.data.userId!;
		} catch (error: unknown) {
			console.error('Error creating admin:', error);
			const message = error instanceof Error ? error.message : 'Failed to create admin user';
			throw new Error(message);
		}
	}

	/**
	 * Update admin user (via Cloud Function)
	 * Updates both Firebase Auth and Firestore
	 */
	static async update(data: UpdateAdminData): Promise<void> {
		try {
			if (!data.name && data.privilege === undefined) {
				throw new Error('No fields to update');
			}

			const updateAdminFn = httpsCallable<UpdateAdminData, CloudFunctionResponse>(
				functions,
				'update_admin'
			);

			const result = await updateAdminFn({
				userId: data.userId,
				name: data.name,
				privilege: data.privilege
			});

			if (!result.data.success) {
				throw new Error(result.data.message);
			}
		} catch (error: unknown) {
			console.error('Error updating admin:', error);
			const message = error instanceof Error ? error.message : 'Failed to update admin user';
			throw new Error(message);
		}
	}

	/**
	 * Delete admin user (via Cloud Function)
	 * Hard delete - removes from both Auth and Firestore
	 */
	static async delete(data: DeleteAdminData): Promise<void> {
		try {
			const deleteAdminFn = httpsCallable<DeleteAdminData, CloudFunctionResponse>(
				functions,
				'delete_admin'
			);

			const result = await deleteAdminFn({
				userId: data.userId
			});

			if (!result.data.success) {
				throw new Error(result.data.message);
			}
		} catch (error: unknown) {
			console.error('Error deleting admin:', error);
			const message = error instanceof Error ? error.message : 'Failed to delete admin user';
			throw new Error(message);
		}
	}

	// ============================================================================
	// Helper Methods
	// ============================================================================

	/**
	 * Get privilege level name
	 */
	static getPrivilegeName(level: AdminPrivilegeLevel): string {
		return AdminPrivilegeLevel[level];
	}

	/**
	 * Check if privilege level can modify another level
	 */
	static canModify(adminLevel: AdminPrivilegeLevel, targetLevel: AdminPrivilegeLevel): boolean {
		// Lower number = higher privilege
		// Can only modify admins with higher number (lower privilege)
		return adminLevel < targetLevel;
	}

	/**
	 * Get available privilege levels for an admin
	 * (Can only create/assign levels lower than their own)
	 */
	static getAvailablePrivilegeLevels(adminLevel: AdminPrivilegeLevel): AdminPrivilegeLevel[] {
		const levels: AdminPrivilegeLevel[] = [];

		for (let level = adminLevel + 1; level <= AdminPrivilegeLevel.READ_ONLY; level++) {
			levels.push(level as AdminPrivilegeLevel);
		}

		return levels;
	}
}
