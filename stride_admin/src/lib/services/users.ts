import { httpsCallable } from 'firebase/functions';
import { functions } from '$lib/firebase/config';
import { toSafeDate } from './utils';

// ============================================================================
// Types & Enums
// ============================================================================

export type ProviderRole = 'psw' | 'lw' | 'admin' | 'manager';
export type UserType = 'provider' | 'client';
export type UserStatus = 'active' | 'inactive' | 'pending' | 'deleted';

export interface ProviderProfile {
	[key: string]: string | number | boolean | null;
}

export interface EmergencyContact {
	name: string;
	phone: string;
	relationship: string;
}

export interface MedicalInfo {
	conditions: string[];
	medications: string[];
	mobility: 'independent' | 'cane' | 'walker' | 'wheelchair';
	notes: string;
	additionalInfo?: Record<string, unknown>;
}

export interface ClientProfile {
	phone?: string;
	dateOfBirth?: string;
	emergencyContact?: EmergencyContact;
	medicalInfo?: MedicalInfo;
	additionalInfo?: Record<string, unknown>;
}

export interface BaseUser {
	id: string;
	email: string;
	name: string;
	organizationId: string;
	divisionId: string;
	status: UserStatus;
	lastLoginAt?: Date;
	lastSignIn?: Date; // Alias kept for backward compatibility
	deletedAt?: Date;
	createdAt: Date;
	updatedAt: Date;
}

export interface ProviderUser extends BaseUser {
	type: 'provider';
	providerRole: ProviderRole[];
	profile: ProviderProfile;
}

export interface ClientUser extends BaseUser {
	type: 'client';
	profile: ClientProfile;
}

export type User = ProviderUser | ClientUser;

// ============================================================================
// Request Types (for Cloud Functions)
// ============================================================================

export interface CreateProviderUserData {
	email: string;
	password: string;
	name: string;
	organizationId: string;
	divisionId: string;
	providerRole: ProviderRole[];
	profile?: ProviderProfile;
}

export interface CreateClientUserData {
	email: string;
	password: string;
	name: string;
	organizationId: string;
	divisionId: string;
	phone?: string;
	dateOfBirth?: string;
	profile?: ClientProfile;
}

export interface UpdateProviderUserData {
	userId: string;
	name?: string;
	status?: UserStatus;
	providerRole?: ProviderRole[];
	profile?: ProviderProfile;
}

export interface UpdateClientUserData {
	userId: string;
	name?: string;
	status?: UserStatus;
	profile?: ClientProfile;
}

export interface DeleteUserData {
	userId: string;
	hardDelete?: boolean;
}

export interface ResetPasswordData {
	userId: string;
}

export interface UpdateEmailData {
	userId: string;
	newEmail: string;
}

export interface GetUsersData {
	limit?: number;
	userIds?: string[];
	organizationId?: string;
	divisionId?: string;
	userType?: UserType;
	status?: UserStatus;
	includeDeleted?: boolean;
}

// Cloud Function response types
interface CloudFunctionResponse {
	success: boolean;
	message: string;
	userId?: string;
	resetLink?: string;
}

interface GetUsersResponse {
	success: boolean;
	users: User[];
	count: number;
}

interface GetUserResponse {
	success: boolean;
	user: User;
}

interface GetUserStatsResponse {
	success: boolean;
	stats: {
		total: number;
		providers: number;
		clients: number;
		active: number;
		inactive: number;
		pending: number;
		deleted: number;
	};
}

// ============================================================================
// Users Service
// ============================================================================

export class UsersService {
	// ============================================================================
	// Private Helper Methods
	// ============================================================================

	/**
	 * Parse user data from Cloud Function response
	 */
	private static _parseUser(userData: User): User {
		const lastLoginRaw =
			(userData as unknown as { lastLoginAt?: Date; lastLogin?: Date }).lastLoginAt ??
			(userData as unknown as { lastLogin?: Date }).lastLogin ??
			userData.lastSignIn;

		const lastLoginAt = lastLoginRaw ? toSafeDate(lastLoginRaw) : undefined;
		const deletedAt = userData.deletedAt ? toSafeDate(userData.deletedAt) : undefined;
		const createdAt = userData.createdAt ? toSafeDate(userData.createdAt) : toSafeDate(new Date());
		const updatedAt = userData.updatedAt ? toSafeDate(userData.updatedAt) : toSafeDate(new Date());

		const baseUser = {
			id: userData.id,
			email: userData.email,
			name: userData.name,
			organizationId: userData.organizationId,
			divisionId: userData.divisionId,
			status: userData.status as UserStatus,
			lastLoginAt,
			lastSignIn: lastLoginAt,
			deletedAt,
			createdAt,
			updatedAt
		};

		if (userData.type === 'provider') {
			return {
				...baseUser,
				type: 'provider',
				providerRole: userData.providerRole || [],
				profile: userData.profile || {}
			} as ProviderUser;
		} else {
			return {
				...baseUser,
				type: 'client',
				profile: userData.profile || {}
			} as ClientUser;
		}
	}

	// ============================================================================
	// Public Read Methods (Use Cloud Functions with Auth metadata)
	// ============================================================================

	/**
	 * Get all users with Auth metadata (lastSignIn)
	 * Excludes deleted users by default
	 */
	static async getAll(limitCount: number = 100, includeDeleted: boolean = false): Promise<User[]> {
		try {
			const getUsersFn = httpsCallable<GetUsersData, GetUsersResponse>(functions, 'get_users');

			const result = await getUsersFn({
				limit: limitCount,
				includeDeleted
			});
			console.log(result);

			if (!result.data.success) {
				throw new Error('Failed to get users');
			}

			return result.data.users.map((user) => this._parseUser(user));
		} catch (error) {
			console.error('Error getting users:', error);
			throw new Error('Failed to get users');
		}
	}

	/**
	 * Get user by ID with Auth metadata
	 */
	static async getById(userId: string): Promise<User | null> {
		try {
			const getUserFn = httpsCallable<{ userId: string }, GetUserResponse>(
				functions,
				'get_user_by_id'
			);

			const result = await getUserFn({ userId });

			if (!result.data.success) {
				return null;
			}

			return this._parseUser(result.data.user);
		} catch (error) {
			console.error('Error getting user by ID:', error);
			return null;
		}
	}

	/**
	 * Get users by specific IDs (max 10 due to Firestore 'in' query limit)
	 */
	static async getByIds(userIds: string[]): Promise<User[]> {
		try {
			if (userIds.length > 10) {
				throw new Error('Cannot get more than 10 users by ID at once');
			}

			const getUsersFn = httpsCallable<GetUsersData, GetUsersResponse>(functions, 'get_users');

			const result = await getUsersFn({ userIds });

			if (!result.data.success) {
				throw new Error('Failed to get users by IDs');
			}

			return result.data.users.map((user) => this._parseUser(user));
		} catch (error) {
			console.error('Error getting users by IDs:', error);
			throw new Error('Failed to get users by IDs');
		}
	}

	/**
	 * Get users by organization ID
	 * Excludes deleted users by default
	 */
	static async getByOrganizationId(
		organizationId: string,
		includeDeleted: boolean = false
	): Promise<User[]> {
		try {
			const getUsersFn = httpsCallable<GetUsersData, GetUsersResponse>(functions, 'get_users');

			const result = await getUsersFn({
				organizationId,
				includeDeleted,
				limit: 1000
			});

			if (!result.data.success) {
				throw new Error('Failed to get users by organization');
			}

			return result.data.users.map((user) => this._parseUser(user));
		} catch (error) {
			console.error('Error getting users by organization:', error);
			throw new Error('Failed to get users by organization');
		}
	}

	/**
	 * Get users by division ID
	 * Excludes deleted users by default
	 */
	static async getByDivisionId(
		divisionId: string,
		includeDeleted: boolean = false
	): Promise<User[]> {
		try {
			const getUsersFn = httpsCallable<GetUsersData, GetUsersResponse>(functions, 'get_users');

			const result = await getUsersFn({
				divisionId,
				includeDeleted,
				limit: 1000
			});

			if (!result.data.success) {
				throw new Error('Failed to get users by division');
			}

			return result.data.users.map((user) => this._parseUser(user));
		} catch (error) {
			console.error('Error getting users by division:', error);
			throw new Error('Failed to get users by division');
		}
	}

	/**
	 * Get users by type and organization
	 * Excludes deleted users by default
	 */
	static async getByTypeAndOrganization(
		type: UserType,
		organizationId: string,
		includeDeleted: boolean = false
	): Promise<User[]> {
		try {
			const getUsersFn = httpsCallable<GetUsersData, GetUsersResponse>(functions, 'get_users');

			const result = await getUsersFn({
				userType: type,
				organizationId,
				includeDeleted,
				limit: 1000
			});

			if (!result.data.success) {
				throw new Error('Failed to get users by type and organization');
			}

			return result.data.users.map((user) => this._parseUser(user));
		} catch (error) {
			console.error('Error getting users by type and organization:', error);
			throw new Error('Failed to get users by type and organization');
		}
	}

	/**
	 * Get users by status and organization
	 */
	static async getByStatusAndOrganization(
		status: UserStatus,
		organizationId: string
	): Promise<User[]> {
		try {
			const getUsersFn = httpsCallable<GetUsersData, GetUsersResponse>(functions, 'get_users');

			const result = await getUsersFn({
				status,
				organizationId,
				limit: 1000
			});

			if (!result.data.success) {
				throw new Error('Failed to get users by status and organization');
			}

			return result.data.users.map((user) => this._parseUser(user));
		} catch (error) {
			console.error('Error getting users by status and organization:', error);
			throw new Error('Failed to get users by status and organization');
		}
	}

	/**
	 * Search users by name (client-side filtering)
	 */
	static async search(searchTerm: string, organizationId?: string): Promise<User[]> {
		try {
			const users = organizationId
				? await this.getByOrganizationId(organizationId, false)
				: await this.getAll(1000, false);

			const lowercaseSearch = searchTerm.toLowerCase();

			return users.filter((user) => user.name.toLowerCase().includes(lowercaseSearch));
		} catch (error) {
			console.error('Error searching users:', error);
			throw new Error('Failed to search users');
		}
	}

	/**
	 * Get user statistics
	 */
	static async getStats(organizationId?: string): Promise<{
		total: number;
		providers: number;
		clients: number;
		active: number;
		inactive: number;
		pending: number;
		deleted: number;
	}> {
		try {
			const getStatsFn = httpsCallable<{ organizationId?: string }, GetUserStatsResponse>(
				functions,
				'get_user_stats'
			);

			const result = await getStatsFn({ organizationId });

			if (!result.data.success) {
				throw new Error('Failed to get user statistics');
			}

			return result.data.stats;
		} catch (error) {
			console.error('Error getting user stats:', error);
			throw new Error('Failed to get user statistics');
		}
	}

	// ============================================================================
	// Public Write Methods (Use Cloud Functions)
	// ============================================================================

	/**
	 * Create a new provider user (via Cloud Function)
	 * Creates both Firebase Auth user and Firestore document
	 */
	static async createProvider(data: CreateProviderUserData): Promise<string> {
		try {
			const createProviderFn = httpsCallable<CreateProviderUserData, CloudFunctionResponse>(
				functions,
				'create_provider'
			);

			const result = await createProviderFn({
				email: data.email,
				password: data.password,
				name: data.name,
				organizationId: data.organizationId,
				divisionId: data.divisionId,
				providerRole: data.providerRole,
				profile: data.profile
			});

			if (!result.data.success) {
				throw new Error(result.data.message);
			}

			return result.data.userId!;
		} catch (error: unknown) {
			console.error('Error creating provider:', error);
			const message = error instanceof Error ? error.message : 'Failed to create provider user';
			throw new Error(message);
		}
	}

	/**
	 * Create a new client user (via Cloud Function)
	 * Creates both Firebase Auth user and Firestore document
	 */
	static async createClient(data: CreateClientUserData): Promise<string> {
		try {
			const createClientFn = httpsCallable<CreateClientUserData, CloudFunctionResponse>(
				functions,
				'create_client'
			);

			const result = await createClientFn({
				email: data.email,
				password: data.password,
				name: data.name,
				organizationId: data.organizationId,
				divisionId: data.divisionId,
				phone: data.phone,
				dateOfBirth: data.dateOfBirth,
				profile: data.profile
			});

			if (!result.data.success) {
				throw new Error(result.data.message);
			}

			return result.data.userId!;
		} catch (error: unknown) {
			console.error('Error creating client:', error);
			const message = error instanceof Error ? error.message : 'Failed to create client user';
			throw new Error(message);
		}
	}

	/**
	 * Update provider user (via Cloud Function)
	 * Updates both Firebase Auth and Firestore
	 */
	static async updateProvider(data: UpdateProviderUserData): Promise<void> {
		try {
			if (!data.name && !data.status && !data.providerRole && !data.profile) {
				throw new Error('No fields to update');
			}

			const updateProviderFn = httpsCallable<UpdateProviderUserData, CloudFunctionResponse>(
				functions,
				'update_provider'
			);

			const result = await updateProviderFn({
				userId: data.userId,
				name: data.name,
				status: data.status,
				providerRole: data.providerRole,
				profile: data.profile
			});

			if (!result.data.success) {
				throw new Error(result.data.message);
			}
		} catch (error: unknown) {
			console.error('Error updating provider:', error);
			const message = error instanceof Error ? error.message : 'Failed to update provider user';
			throw new Error(message);
		}
	}

	/**
	 * Update client user (via Cloud Function)
	 * Updates both Firebase Auth and Firestore
	 */
	static async updateClient(data: UpdateClientUserData): Promise<void> {
		try {
			if (!data.name && !data.status && !data.profile) {
				throw new Error('No fields to update');
			}

			const updateClientFn = httpsCallable<UpdateClientUserData, CloudFunctionResponse>(
				functions,
				'update_client'
			);

			const result = await updateClientFn({
				userId: data.userId,
				name: data.name,
				status: data.status,
				profile: data.profile
			});

			if (!result.data.success) {
				throw new Error(result.data.message);
			}
		} catch (error: unknown) {
			console.error('Error updating client:', error);
			const message = error instanceof Error ? error.message : 'Failed to update client user';
			throw new Error(message);
		}
	}

	/**
	 * Delete user (via Cloud Function)
	 * Soft delete by default, hard delete removes from Auth and Firestore
	 */
	static async delete(userId: string, hardDelete: boolean = false): Promise<void> {
		try {
			const deleteUserFn = httpsCallable<DeleteUserData, CloudFunctionResponse>(
				functions,
				'delete_user'
			);
			const result = await deleteUserFn({
				userId,
				hardDelete
			});

			if (!result.data.success) {
				throw new Error(result.data.message);
			}
		} catch (error: unknown) {
			console.error('Error deleting user:', error);
			const message = error instanceof Error ? error.message : 'Failed to delete user';
			throw new Error(message);
		}
	}

	/**
	 * Soft delete helper (matches Flutter repo semantics)
	 */
	static async softDelete(userId: string): Promise<void> {
		return this.delete(userId, false);
	}

	/**
	 * Hard delete helper (matches Flutter repo semantics)
	 */
	static async hardDelete(userId: string): Promise<void> {
		return this.delete(userId, true);
	}

	/**
	 * Reset user password (via Cloud Function)
	 * Generates and sends password reset email
	 */
	static async resetPassword(userId: string): Promise<void> {
		try {
			const resetPasswordFn = httpsCallable<ResetPasswordData, CloudFunctionResponse>(
				functions,
				'reset_user_password'
			);

			const result = await resetPasswordFn({ userId });

			if (!result.data.success) {
				throw new Error(result.data.message);
			}
		} catch (error: unknown) {
			console.error('Error resetting password:', error);
			const message = error instanceof Error ? error.message : 'Failed to reset user password';
			throw new Error(message);
		}
	}

	/**
	 * Update user email (via Cloud Function)
	 * Updates both Firebase Auth and Firestore
	 */
	static async updateEmail(userId: string, newEmail: string): Promise<void> {
		try {
			const updateEmailFn = httpsCallable<UpdateEmailData, CloudFunctionResponse>(
				functions,
				'update_user_email'
			);

			const result = await updateEmailFn({
				userId,
				newEmail
			});

			if (!result.data.success) {
				throw new Error(result.data.message);
			}
		} catch (error: unknown) {
			console.error('Error updating email:', error);
			const message = error instanceof Error ? error.message : 'Failed to update user email';
			throw new Error(message);
		}
	}

	// ============================================================================
	// Helper Methods
	// ============================================================================

	/**
	 * Check if user is provider
	 */
	static isProvider(user: User): user is ProviderUser {
		return user.type === 'provider';
	}

	/**
	 * Check if user is client
	 */
	static isClient(user: User): user is ClientUser {
		return user.type === 'client';
	}

	/**
	 * Check if provider has specific role
	 */
	static hasRole(user: ProviderUser, role: ProviderRole): boolean {
		return user.providerRole.includes(role);
	}

	/**
	 * Count active users by organization
	 */
	static async countActiveByOrganization(organizationId: string): Promise<number> {
		try {
			const users = await this.getByStatusAndOrganization('active', organizationId);
			return users.length;
		} catch (error) {
			console.error('Error counting active users:', error);
			return 0;
		}
	}

	/**
	 * Count users by type and organization
	 */
	static async countByTypeAndOrganization(type: UserType, organizationId: string): Promise<number> {
		try {
			const users = await this.getByTypeAndOrganization(type, organizationId, false);
			return users.length;
		} catch (error) {
			console.error('Error counting users by type:', error);
			return 0;
		}
	}
}
