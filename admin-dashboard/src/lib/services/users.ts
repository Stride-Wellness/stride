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

// Helper function to safely convert Firestore data to Date
function toSafeDate(value: Timestamp | Date | { toDate(): Date } | null | undefined): Date {
	if (value && typeof value === 'object' && 'toDate' in value && typeof value.toDate === 'function') {
		return value.toDate();
	}
	if (value instanceof Date) {
		return value;
	}
	return new Date();
}

export type EmployeeRole = 'psw' | 'lw' | 'admin' | 'manager';
export type UserType = 'employee' | 'client';
export type UserStatus = 'active' | 'inactive' | 'pending' | 'deleted';

export interface EmployeeProfile {
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
	[key: string]: string | string[] | null | undefined;
}

export interface ClientProfile {
	phone?: string;
	dateOfBirth?: string;
	emergencyContact?: EmergencyContact;
	medicalInfo?: MedicalInfo;
	[key: string]: string | EmergencyContact | MedicalInfo | null | undefined;
}

export interface BaseUser {
	id: string;
	email: string;
	name: string;
	organizationId: string;
	divisionId: string;
	status: UserStatus;
	lastLoginAt?: Date;
	deletedAt?: Date;
	createdAt: Date;
	updatedAt: Date;
}

export interface EmployeeUser extends BaseUser {
	type: 'employee';
	employeeRole: EmployeeRole[];
	profile: EmployeeProfile;
}

export interface ClientUser extends BaseUser {
	type: 'client';
	profile: ClientProfile;
}

export type User = EmployeeUser | ClientUser;

export interface CreateEmployeeUserData {
	email: string;
	name: string;
	organizationId: string;
	divisionId: string;
	employeeRole: EmployeeRole[];
	profile?: EmployeeProfile;
}

export interface CreateClientUserData {
	email: string;
	name: string;
	organizationId: string;
	divisionId: string;
	profile?: ClientProfile;
}

export type CreateUserData = CreateEmployeeUserData | CreateClientUserData;

export interface UpdateEmployeeUserData {
	email?: string;
	name?: string;
	divisionId?: string;
	employeeRole?: EmployeeRole[];
	profile?: EmployeeProfile;
	status?: UserStatus;
	lastLoginAt?: Date;
	deletedAt?: Date | null;
}

export interface UpdateClientUserData {
	email?: string;
	name?: string;
	divisionId?: string;
	profile?: ClientProfile;
	status?: UserStatus;
	lastLoginAt?: Date;
	deletedAt?: Date | null;
}

export type UpdateUserData = UpdateEmployeeUserData | UpdateClientUserData;

export class UsersService {
	private static COLLECTION = 'users';

	/**
	 * Get user by ID
	 */
	static async getById(userId: string): Promise<User | null> {
		try {
			const userRef = doc(db, this.COLLECTION, userId);
			const userSnap = await getDoc(userRef);

			if (!userSnap.exists()) {
				return null;
			}

			const data = userSnap.data();
			const baseUser = {
				id: userSnap.id,
				email: data.email,
				name: data.name,
				organizationId: data.organizationId,
				divisionId: data.divisionId,
				status: data.status,
				lastLoginAt: data.lastLoginAt ? toSafeDate(data.lastLoginAt) : undefined,
				deletedAt: data.deletedAt ? toSafeDate(data.deletedAt) : undefined,
				createdAt: toSafeDate(data.createdAt),
				updatedAt: toSafeDate(data.updatedAt)
			};

			if (data.type === 'employee') {
				return {
					...baseUser,
					type: 'employee',
					employeeRole: data.employeeRole || [],
					profile: data.profile || {}
				} as EmployeeUser;
			} else {
				return {
					...baseUser,
					type: 'client',
					profile: data.profile || {}
				} as ClientUser;
			}
		} catch (error) {
			console.error('Error getting user:', error);
			throw new Error('Failed to get user');
		}
	}

	/**
	 * Get all users (admin only) - excludes deleted users by default
	 */
	static async getAll(limitCount: number = 100, includeDeleted: boolean = false): Promise<User[]> {
		try {
			const usersRef = collection(db, this.COLLECTION);
			let q = query(usersRef, orderBy('createdAt', 'desc'), limit(limitCount));

			// Filter out deleted users unless explicitly requested
			if (!includeDeleted) {
				q = query(
					usersRef,
					where('status', '!=', 'deleted'),
					orderBy('createdAt', 'desc'),
					limit(limitCount)
				);
			}

			const querySnap = await getDocs(q);
			const users: User[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				const baseUser = {
					id: doc.id,
					email: data.email,
					name: data.name,
					organizationId: data.organizationId,
					divisionId: data.divisionId,
					status: data.status,
					lastLoginAt: data.lastLoginAt ? toSafeDate(data.lastLoginAt) : undefined,
					deletedAt: data.deletedAt ? toSafeDate(data.deletedAt) : undefined,
					createdAt: toSafeDate(data.createdAt),
					updatedAt: toSafeDate(data.updatedAt)
				};

				if (data.type === 'employee') {
					users.push({
						...baseUser,
						type: 'employee',
						employeeRole: data.employeeRole || [],
						profile: data.profile || {}
					} as EmployeeUser);
				} else {
					users.push({
						...baseUser,
						type: 'client',
						profile: data.profile || {}
					} as ClientUser);
				}
			});

			return users;
		} catch (error) {
			console.error('Error getting users:', error);
			throw new Error('Failed to get users');
		}
	}

	/**
	 * Get users by organization ID - excludes deleted users by default
	 */
	static async getByOrganizationId(
		organizationId: string,
		includeDeleted: boolean = false
	): Promise<User[]> {
		try {
			const usersRef = collection(db, this.COLLECTION);
			let q = query(
				usersRef,
				where('organizationId', '==', organizationId),
				orderBy('createdAt', 'desc')
			);

			// Filter out deleted users unless explicitly requested
			if (!includeDeleted) {
				q = query(
					usersRef,
					where('organizationId', '==', organizationId),
					where('status', '!=', 'deleted'),
					orderBy('createdAt', 'desc')
				);
			}

			const querySnap = await getDocs(q);
			const users: User[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				const baseUser = {
					id: doc.id,
					email: data.email,
					name: data.name,
					organizationId: data.organizationId,
					divisionId: data.divisionId,
					status: data.status,
					lastLoginAt: data.lastLoginAt ? toSafeDate(data.lastLoginAt) : undefined,
					deletedAt: data.deletedAt ? toSafeDate(data.deletedAt) : undefined,
					createdAt: toSafeDate(data.createdAt),
					updatedAt: toSafeDate(data.updatedAt)
				};

				if (data.type === 'employee') {
					users.push({
						...baseUser,
						type: 'employee',
						employeeRole: data.employeeRole || [],
						profile: data.profile || {}
					} as EmployeeUser);
				} else {
					users.push({
						...baseUser,
						type: 'client',
						profile: data.profile || {}
					} as ClientUser);
				}
			});

			return users;
		} catch (error) {
			console.error('Error getting users by organization:', error);
			throw new Error('Failed to get users by organization');
		}
	}

	/**
	 * Get users by division ID - excludes deleted users by default
	 */
	static async getByDivisionId(
		divisionId: string,
		includeDeleted: boolean = false
	): Promise<User[]> {
		try {
			const usersRef = collection(db, this.COLLECTION);
			let q = query(usersRef, where('divisionId', '==', divisionId), orderBy('createdAt', 'desc'));

			// Filter out deleted users unless explicitly requested
			if (!includeDeleted) {
				q = query(
					usersRef,
					where('divisionId', '==', divisionId),
					where('status', '!=', 'deleted'),
					orderBy('createdAt', 'desc')
				);
			}

			const querySnap = await getDocs(q);
			const users: User[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				const baseUser = {
					id: doc.id,
					email: data.email,
					name: data.name,
					organizationId: data.organizationId,
					divisionId: data.divisionId,
					status: data.status,
					lastLoginAt: data.lastLoginAt ? toSafeDate(data.lastLoginAt) : undefined,
					deletedAt: data.deletedAt ? toSafeDate(data.deletedAt) : undefined,
					createdAt: toSafeDate(data.createdAt),
					updatedAt: toSafeDate(data.updatedAt)
				};

				if (data.type === 'employee') {
					users.push({
						...baseUser,
						type: 'employee',
						employeeRole: data.employeeRole || [],
						profile: data.profile || {}
					} as EmployeeUser);
				} else {
					users.push({
						...baseUser,
						type: 'client',
						profile: data.profile || {}
					} as ClientUser);
				}
			});

			return users;
		} catch (error) {
			console.error('Error getting users by division:', error);
			throw new Error('Failed to get users by division');
		}
	}

	/**
	 * Get users by type and organization - excludes deleted users by default
	 */
	static async getByTypeAndOrganization(
		type: UserType,
		organizationId: string,
		includeDeleted: boolean = false
	): Promise<User[]> {
		try {
			const usersRef = collection(db, this.COLLECTION);
			let q = query(
				usersRef,
				where('type', '==', type),
				where('organizationId', '==', organizationId),
				orderBy('createdAt', 'desc')
			);

			// Filter out deleted users unless explicitly requested
			if (!includeDeleted) {
				q = query(
					usersRef,
					where('type', '==', type),
					where('organizationId', '==', organizationId),
					where('status', '!=', 'deleted'),
					orderBy('createdAt', 'desc')
				);
			}

			const querySnap = await getDocs(q);
			const users: User[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				const baseUser = {
					id: doc.id,
					email: data.email,
					name: data.name,
					organizationId: data.organizationId,
					divisionId: data.divisionId,
					status: data.status,
					lastLoginAt: data.lastLoginAt ? toSafeDate(data.lastLoginAt) : undefined,
					deletedAt: data.deletedAt ? toSafeDate(data.deletedAt) : undefined,
					createdAt: toSafeDate(data.createdAt),
					updatedAt: toSafeDate(data.updatedAt)
				};

				if (data.type === 'employee') {
					users.push({
						...baseUser,
						type: 'employee',
						employeeRole: data.employeeRole || [],
						profile: data.profile || {}
					} as EmployeeUser);
				} else {
					users.push({
						...baseUser,
						type: 'client',
						profile: data.profile || {}
					} as ClientUser);
				}
			});

			return users;
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
			const usersRef = collection(db, this.COLLECTION);
			const q = query(
				usersRef,
				where('status', '==', status),
				where('organizationId', '==', organizationId),
				orderBy('createdAt', 'desc')
			);

			const querySnap = await getDocs(q);
			const users: User[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				const baseUser = {
					id: doc.id,
					email: data.email,
					name: data.name,
					organizationId: data.organizationId,
					divisionId: data.divisionId,
					status: data.status,
					lastLoginAt: data.lastLoginAt ? toSafeDate(data.lastLoginAt) : undefined,
					deletedAt: data.deletedAt ? toSafeDate(data.deletedAt) : undefined,
					createdAt: toSafeDate(data.createdAt),
					updatedAt: toSafeDate(data.updatedAt)
				};

				if (data.type === 'employee') {
					users.push({
						...baseUser,
						type: 'employee',
						employeeRole: data.employeeRole || [],
						profile: data.profile || {}
					} as EmployeeUser);
				} else {
					users.push({
						...baseUser,
						type: 'client',
						profile: data.profile || {}
					} as ClientUser);
				}
			});

			return users;
		} catch (error) {
			console.error('Error getting users by status and organization:', error);
			throw new Error('Failed to get users by status and organization');
		}
	}

	/**
	 * Create new employee user
	 */
	static async createEmployee(data: CreateEmployeeUserData): Promise<EmployeeUser> {
		try {
			const now = Timestamp.now();
			const userData = {
				email: data.email,
				name: data.name,
				type: 'employee' as const,
				employeeRole: data.employeeRole,
				organizationId: data.organizationId,
				divisionId: data.divisionId,
				profile: data.profile || {},
				status: 'active' as const,
				createdAt: now,
				updatedAt: now
			};

			const docRef = await addDoc(collection(db, this.COLLECTION), userData);

			return {
				id: docRef.id,
				...userData,
				createdAt: now.toDate(),
				updatedAt: now.toDate()
			};
		} catch (error) {
			console.error('Error creating employee user:', error);
			throw new Error('Failed to create employee user');
		}
	}

	/**
	 * Create new client user
	 */
	static async createClient(data: CreateClientUserData): Promise<ClientUser> {
		try {
			const now = Timestamp.now();
			const userData = {
				email: data.email,
				name: data.name,
				type: 'client' as const,
				organizationId: data.organizationId,
				divisionId: data.divisionId,
				profile: data.profile || {},
				status: 'active' as const,
				createdAt: now,
				updatedAt: now
			};

			const docRef = await addDoc(collection(db, this.COLLECTION), userData);

			return {
				id: docRef.id,
				...userData,
				createdAt: now.toDate(),
				updatedAt: now.toDate()
			};
		} catch (error) {
			console.error('Error creating client user:', error);
			throw new Error('Failed to create client user');
		}
	}

	/**
	 * Update user
	 */
	static async update(userId: string, data: UpdateUserData): Promise<void> {
		try {
			const userRef = doc(db, this.COLLECTION, userId);
			const updateData = {
				...data,
				updatedAt: Timestamp.now()
			};

			await updateDoc(userRef, updateData);
		} catch (error) {
			console.error('Error updating user:', error);
			throw new Error('Failed to update user');
		}
	}

	/**
	 * Update last login timestamp
	 */
	static async updateLastLogin(userId: string): Promise<void> {
		try {
			const userRef = doc(db, this.COLLECTION, userId);
			await updateDoc(userRef, {
				lastLoginAt: Timestamp.now(),
				updatedAt: Timestamp.now()
			});
		} catch (error) {
			console.error('Error updating last login:', error);
			throw new Error('Failed to update last login');
		}
	}

	/**
	 * Soft delete user (set status to deleted and add deletedAt timestamp)
	 */
	static async softDelete(userId: string): Promise<void> {
		try {
			await this.update(userId, {
				status: 'deleted',
				deletedAt: new Date()
			});
		} catch (error) {
			console.error('Error soft deleting user:', error);
			throw new Error('Failed to delete user');
		}
	}

	/**
	 * Restore soft deleted user
	 */
	static async restore(userId: string): Promise<void> {
		try {
			const userRef = doc(db, this.COLLECTION, userId);
			await updateDoc(userRef, {
				status: 'active',
				deletedAt: null,
				updatedAt: Timestamp.now()
			});
		} catch (error) {
			console.error('Error restoring user:', error);
			throw new Error('Failed to restore user');
		}
	}

	/**
	 * Check if user has any active assignments (to prevent hard delete)
	 */
	static async hasActiveAssignments(userId: string): Promise<boolean> {
		try {
			// This would need the AssignmentsService to be implemented
			// For now, return false to allow hard delete
			// TODO: Implement assignment checking once AssignmentsService is available
			console.log('Checking assignments for user:', userId);
			return false;
		} catch (error) {
			console.error('Error checking user assignments:', error);
			return true; // Err on the side of caution
		}
	}

	/**
	 * Hard delete user (use with caution) - only if no active references
	 */
	static async hardDelete(userId: string): Promise<void> {
		try {
			// Check for active assignments before allowing hard delete
			const hasAssignments = await this.hasActiveAssignments(userId);
			if (hasAssignments) {
				throw new Error(
					'Cannot hard delete user with active assignments. Use soft delete instead.'
				);
			}

			const userRef = doc(db, this.COLLECTION, userId);
			await deleteDoc(userRef);
		} catch (error) {
			console.error('Error hard deleting user:', error);
			throw new Error('Failed to permanently delete user');
		}
	}

	/**
	 * Check if user is employee
	 */
	static isEmployee(user: User): user is EmployeeUser {
		return user.type === 'employee';
	}

	/**
	 * Check if user is client
	 */
	static isClient(user: User): user is ClientUser {
		return user.type === 'client';
	}

	/**
	 * Check if employee has specific role
	 */
	static hasRole(user: EmployeeUser, role: EmployeeRole): boolean {
		return user.employeeRole.includes(role);
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
}
