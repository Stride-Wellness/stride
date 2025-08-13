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
import { toSafeDate } from './utils';

export interface AssignmentPermissions {
	canModifyExercises: boolean;
	canViewMedicalInfo: boolean;
	canScheduleSessions: boolean;
}

export interface Assignment {
	id: string;
	organizationId: string;
	clientId: string;
	workerId: string;
	divisionId: string; // Based on database design, should be divisionId not locationId
	assignedBy: string;
	status: 'active' | 'inactive' | 'completed';
	permissions: AssignmentPermissions;
	assignedAt: Date;
	lastSessionAt?: Date;
	createdAt: Date;
	updatedAt: Date;
}

export interface CreateAssignmentData {
	organizationId: string;
	clientId: string;
	workerId: string;
	divisionId: string;
	assignedBy: string;
	permissions?: AssignmentPermissions;
}

export interface UpdateAssignmentData {
	status?: 'active' | 'inactive' | 'completed';
	permissions?: AssignmentPermissions;
	lastSessionAt?: Date;
}

export class AssignmentsService {
	private static COLLECTION = 'assignments';

	/**
	 * Get assignment by ID
	 */
	static async getById(assignmentId: string): Promise<Assignment | null> {
		try {
			const assignmentRef = doc(db, this.COLLECTION, assignmentId);
			const assignmentSnap = await getDoc(assignmentRef);

			if (!assignmentSnap.exists()) {
				return null;
			}

			const data = assignmentSnap.data();
			return {
				id: assignmentSnap.id,
				organizationId: data.organizationId,
				clientId: data.clientId,
				workerId: data.workerId,
				divisionId: data.divisionId,
				assignedBy: data.assignedBy,
				status: data.status,
				permissions: data.permissions || {
					canModifyExercises: false,
					canViewMedicalInfo: false,
					canScheduleSessions: false
				},
				assignedAt: toSafeDate(data.assignedAt),
				lastSessionAt: data.lastSessionAt ? toSafeDate(data.lastSessionAt) : undefined,
				createdAt: toSafeDate(data.createdAt),
				updatedAt: toSafeDate(data.updatedAt)
			};
		} catch (error) {
			console.error('Error getting assignment:', error);
			throw new Error('Failed to get assignment');
		}
	}

	/**
	 * Get assignments by organization ID
	 */
	static async getByOrganizationId(organizationId: string): Promise<Assignment[]> {
		try {
			const assignmentsRef = collection(db, this.COLLECTION);
			const q = query(
				assignmentsRef,
				where('organizationId', '==', organizationId),
				orderBy('createdAt', 'desc')
			);

			const querySnap = await getDocs(q);
			const assignments: Assignment[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				assignments.push({
					id: doc.id,
					organizationId: data.organizationId,
					clientId: data.clientId,
					workerId: data.workerId,
					divisionId: data.divisionId,
					assignedBy: data.assignedBy,
					status: data.status,
					permissions: data.permissions || {
						canModifyExercises: false,
						canViewMedicalInfo: false,
						canScheduleSessions: false
					},
					assignedAt: toSafeDate(data.assignedAt),
					lastSessionAt: data.lastSessionAt ? toSafeDate(data.lastSessionAt) : undefined,
					createdAt: toSafeDate(data.createdAt),
					updatedAt: toSafeDate(data.updatedAt)
				});
			});

			return assignments;
		} catch (error) {
			console.error('Error getting assignments by organization:', error);
			throw new Error('Failed to get assignments by organization');
		}
	}

	/**
	 * Get assignments by worker ID
	 */
	static async getByWorkerId(workerId: string): Promise<Assignment[]> {
		try {
			const assignmentsRef = collection(db, this.COLLECTION);
			const q = query(
				assignmentsRef,
				where('workerId', '==', workerId),
				orderBy('createdAt', 'desc')
			);

			const querySnap = await getDocs(q);
			const assignments: Assignment[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				assignments.push({
					id: doc.id,
					organizationId: data.organizationId,
					clientId: data.clientId,
					workerId: data.workerId,
					divisionId: data.divisionId,
					assignedBy: data.assignedBy,
					status: data.status,
					permissions: data.permissions || {
						canModifyExercises: false,
						canViewMedicalInfo: false,
						canScheduleSessions: false
					},
					assignedAt: toSafeDate(data.assignedAt),
					lastSessionAt: data.lastSessionAt ? toSafeDate(data.lastSessionAt) : undefined,
					createdAt: toSafeDate(data.createdAt),
					updatedAt: toSafeDate(data.updatedAt)
				});
			});

			return assignments;
		} catch (error) {
			console.error('Error getting assignments by worker:', error);
			throw new Error('Failed to get assignments by worker');
		}
	}

	/**
	 * Get assignments by client ID
	 */
	static async getByClientId(clientId: string): Promise<Assignment[]> {
		try {
			const assignmentsRef = collection(db, this.COLLECTION);
			const q = query(
				assignmentsRef,
				where('clientId', '==', clientId),
				orderBy('createdAt', 'desc')
			);

			const querySnap = await getDocs(q);
			const assignments: Assignment[] = [];

			querySnap.forEach((doc) => {
				const data = doc.data();
				assignments.push({
					id: doc.id,
					organizationId: data.organizationId,
					clientId: data.clientId,
					workerId: data.workerId,
					divisionId: data.divisionId,
					assignedBy: data.assignedBy,
					status: data.status,
					permissions: data.permissions || {
						canModifyExercises: false,
						canViewMedicalInfo: false,
						canScheduleSessions: false
					},
					assignedAt: toSafeDate(data.assignedAt),
					lastSessionAt: data.lastSessionAt ? toSafeDate(data.lastSessionAt) : undefined,
					createdAt: toSafeDate(data.createdAt),
					updatedAt: toSafeDate(data.updatedAt)
				});
			});

			return assignments;
		} catch (error) {
			console.error('Error getting assignments by client:', error);
			throw new Error('Failed to get assignments by client');
		}
	}

	/**
	 * Create new assignment
	 */
	static async create(data: CreateAssignmentData): Promise<Assignment> {
		try {
			const now = Timestamp.now();
			const assignmentData = {
				organizationId: data.organizationId,
				clientId: data.clientId,
				workerId: data.workerId,
				divisionId: data.divisionId,
				assignedBy: data.assignedBy,
				status: 'active' as const,
				permissions: data.permissions || {
					canModifyExercises: false,
					canViewMedicalInfo: false,
					canScheduleSessions: false
				},
				assignedAt: now,
				createdAt: now,
				updatedAt: now
			};

			const docRef = await addDoc(collection(db, this.COLLECTION), assignmentData);

			return {
				id: docRef.id,
				...assignmentData,
				assignedAt: now.toDate(),
				createdAt: now.toDate(),
				updatedAt: now.toDate()
			};
		} catch (error) {
			console.error('Error creating assignment:', error);
			throw new Error('Failed to create assignment');
		}
	}

	/**
	 * Update assignment
	 */
	static async update(assignmentId: string, data: UpdateAssignmentData): Promise<void> {
		try {
			const assignmentRef = doc(db, this.COLLECTION, assignmentId);
			const updateData = {
				...data,
				updatedAt: Timestamp.now()
			};

			await updateDoc(assignmentRef, updateData);
		} catch (error) {
			console.error('Error updating assignment:', error);
			throw new Error('Failed to update assignment');
		}
	}

	/**
	 * Delete assignment
	 */
	static async delete(assignmentId: string): Promise<void> {
		try {
			const assignmentRef = doc(db, this.COLLECTION, assignmentId);
			await deleteDoc(assignmentRef);
		} catch (error) {
			console.error('Error deleting assignment:', error);
			throw new Error('Failed to delete assignment');
		}
	}

	/**
	 * Update last session timestamp
	 */
	static async updateLastSession(assignmentId: string): Promise<void> {
		try {
			await this.update(assignmentId, {
				lastSessionAt: new Date()
			});
		} catch (error) {
			console.error('Error updating last session:', error);
			throw new Error('Failed to update last session');
		}
	}

	/**
	 * Check if worker is assigned to client
	 */
	static async isWorkerAssignedToClient(workerId: string, clientId: string): Promise<boolean> {
		try {
			const assignmentsRef = collection(db, this.COLLECTION);
			const q = query(
				assignmentsRef,
				where('workerId', '==', workerId),
				where('clientId', '==', clientId),
				where('status', '==', 'active'),
				limit(1)
			);

			const querySnap = await getDocs(q);
			return !querySnap.empty;
		} catch (error) {
			console.error('Error checking assignment:', error);
			return false;
		}
	}
}
