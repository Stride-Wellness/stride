<script lang="ts">
	import type { Assignment } from '$lib/services/assignments';
	import { AssignmentsService } from '$lib/services';
	import Table from '$lib/components/Table.svelte';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Message from '$lib/components/Message.svelte';
	import Card from '$lib/components/Card.svelte';
	import { enhance } from '$app/forms';
	import { onMount } from 'svelte';

	const { form }: { form: any } = $props();

	// State for assignments data
	let assignments = $state<Assignment[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);

	// Form state for creating assignments
	let clientId = $state('');
	let workerId = $state('');
	let divisionId = $state('');
	let assignedBy = $state('');
	let canModifyExercises = $state(false);
	let canViewMedicalInfo = $state(false);
	let canScheduleSessions = $state(false);

	// Form state for updating assignment status
	let updateStatusId = $state('');
	let updateStatus = $state<'active' | 'inactive' | 'completed'>('active');

	// Form state for deleting assignment
	let deleteAssignmentId = $state('');

	let selectedAssignments: Record<string, any>[] = $state([]);

	// Load assignments on mount
	onMount(async () => {
		try {
			assignments = await AssignmentsService.getAll(1000);
		} catch (err: any) {
			console.error('Error loading assignments:', err);
			
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have access to view assignments.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in to view assignments.';
						break;
					default:
						error = `Error loading assignments: ${err.message || 'Please refresh the page and try again.'}`;
				}
			} else if (err.message) {
				if (err.message.includes('Failed to get assignments')) {
					error = 'Failed to load assignments. Please check your internet connection and refresh the page.';
				} else {
					error = err.message;
				}
			} else {
				error = 'Failed to load assignments. Please refresh the page.';
			}
		} finally {
			loading = false;
		}
	});

	// Handle create assignment
	async function handleCreateAssignment(event: Event) {
		event.preventDefault();

		// Clear previous messages
		error = null;
		successMessage = null;

		// Validation
		if (!clientId || !workerId || !divisionId || !assignedBy) {
			error = 'All fields are required';
			return;
		}

		try {
			const newAssignment = await AssignmentsService.create({
				clientId,
				workerId,
				divisionId,
				assignedBy,
				permissions: {
					canModifyExercises,
					canViewMedicalInfo,
					canScheduleSessions
				}
			});

			// Reset form
			clientId = '';
			workerId = '';
			divisionId = '';
			assignedBy = '';
			canModifyExercises = false;
			canViewMedicalInfo = false;
			canScheduleSessions = false;

			// Update local state immediately
			assignments = [...assignments, newAssignment];

			successMessage = 'Assignment created successfully!';
		} catch (err: any) {
			console.error('Error creating assignment:', err);
			
			// Parse specific Firebase/Firestore errors
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions or the organization/users may not exist.';
						break;
					case 'not-found':
						error = 'Organization, client, worker, or division not found. Please verify the IDs are correct.';
						break;
					case 'already-exists':
						error = 'This assignment already exists.';
						break;
					case 'invalid-argument':
						error = 'Invalid data provided. Please check all fields are correctly filled.';
						break;
					case 'failed-precondition':
						error = 'Assignment creation failed validation. All users must exist, belong to the organization and division.';
						break;
					case 'resource-exhausted':
						error = 'Too many requests. Please wait a moment and try again.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to create assignment. Please try again.'}`;
				}
			} else if (err.message) {
				if (err.message.includes('Failed to create assignment')) {
					error = 'Failed to create assignment. Please verify all user and organization IDs exist and try again.';
				} else {
					error = err.message;
				}
			} else {
				error = 'An unexpected error occurred. Please try again.';
			}
		}
	}

	// Handle update status
	async function handleUpdateStatus(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!updateStatusId || !updateStatus) {
			error = 'Assignment ID and status are required';
			return;
		}

		try {
			await AssignmentsService.update(updateStatusId, { status: updateStatus });

			// Update local state immediately
			const assignmentIndex = assignments.findIndex((assignment) => assignment.id === updateStatusId);
			if (assignmentIndex !== -1) {
				assignments[assignmentIndex] = { ...assignments[assignmentIndex], status: updateStatus };
				assignments = [...assignments]; // Trigger reactivity
			}

			updateStatusId = '';
			updateStatus = 'active';

			successMessage = 'Assignment status updated successfully!';
		} catch (err) {
			console.error('Error updating assignment status:', err);
			error = 'Failed to update assignment status. Please try again.';
		}
	}

	// Handle delete assignment
	async function handleDeleteAssignment(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!deleteAssignmentId) {
			error = 'Assignment ID is required';
			return;
		}

		// Confirm deletion
		if (
			!confirm(
				'Are you sure you want to delete this assignment? This action cannot be undone and will permanently remove the assignment.'
			)
		) {
			return;
		}

		try {
			const assignmentsToDelete = deleteAssignmentId.split(',').map((id) => id.trim());
			for (const id of assignmentsToDelete) {
				await AssignmentsService.delete(id);
			}

			// Update local state immediately
			assignments = assignments.filter((assignment) => !assignmentsToDelete.includes(assignment.id));

			deleteAssignmentId = '';

			successMessage = 'Assignment deleted successfully!';
		} catch (err: any) {
			console.error('Error deleting assignment:', err);
			
			// Parse specific Firebase/Firestore errors
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to delete this assignment.';
						break;
					case 'not-found':
						error = 'Assignment not found. It may have already been deleted or the ID is incorrect.';
						break;
					case 'failed-precondition':
						error = 'Cannot delete assignment. Please check the assignment ID and try again.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to delete assignment. Please try again.'}`;
				}
			} else if (err.message) {
				if (err.message.includes('Failed to delete assignment')) {
					error = 'Failed to delete assignment. Please check the assignment ID and try again.';
				} else {
					error = err.message;
				}
			} else {
				error = 'An unexpected error occurred while deleting the assignment.';
			}
		}
	}

	// Transform data for table display
	const tableData = $derived(
		assignments.map((assignment) => ({
			id: { name: assignment.id, href: `/assignments/${assignment.id}` },
			'Client ID': assignment.clientId,
			'Worker ID': assignment.workerId,
			'Division ID': assignment.divisionId,
			'Assigned By': assignment.assignedBy,
			Status: assignment.status,
			'Can Modify Exercises': assignment.permissions.canModifyExercises ? 'Yes' : 'No',
			'Can View Medical': assignment.permissions.canViewMedicalInfo ? 'Yes' : 'No',
			'Can Schedule': assignment.permissions.canScheduleSessions ? 'Yes' : 'No',
			'Assigned At': assignment.assignedAt ? new Date(assignment.assignedAt).toLocaleDateString() : 'N/A',
			'Last Session': assignment.lastSessionAt ? new Date(assignment.lastSessionAt).toLocaleDateString() : 'Never',
			Created: assignment.createdAt ? new Date(assignment.createdAt).toLocaleDateString() : 'N/A',
			Updated: assignment.updatedAt ? new Date(assignment.updatedAt).toLocaleDateString() : 'N/A'
		}))
	);

	// Calculate summary stats
	const summaryStats = $derived(() => {
		const total = assignments.length;
		const active = assignments.filter((assignment) => assignment.status === 'active').length;
		const inactive = assignments.filter((assignment) => assignment.status === 'inactive').length;
		const completed = assignments.filter((assignment) => assignment.status === 'completed').length;

		return { total, active, inactive, completed };
	});

	$effect(() => {
		deleteAssignmentId = selectedAssignments.map((assignment) => assignment.id.name).join(', ');
		updateStatusId = selectedAssignments.map((assignment) => assignment.id.name).join(', ');
	});
</script>

{#if loading}
	<div class="flex items-center justify-center p-6">
		<div class="text-lg">Loading assignments...</div>
	</div>
{:else}
	<div class="space-y-6 p-6">
		<!-- Error and Success Messages at Top -->
		<Message type="error" message={error || undefined} />
		<Message type="success" message={successMessage || undefined} />

		<div class="flex items-center justify-between">
			<h1 class="text-2xl font-semibold text-gray-900">Assignments</h1>
			<p class="text-sm text-gray-600">Manage worker-client assignments and permissions</p>
		</div>

		<!-- Summary Cards -->
		<div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Total Assignments</h4>
					<p class="text-2xl font-bold">{summaryStats().total}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Active Assignments</h4>
					<p class="text-2xl font-bold">{summaryStats().active}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Inactive Assignments</h4>
					<p class="text-2xl font-bold">{summaryStats().inactive}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Completed Assignments</h4>
					<p class="text-2xl font-bold">{summaryStats().completed}</p>
				</div>
			</Card>
		</div>

		<!-- Create Assignment Form -->
		<Card class="p-6">
			<h2>Create New Assignment</h2>
			<form onsubmit={handleCreateAssignment} class="space-y-4">
				<div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
					<Input
						type="text"
						placeholder="Client ID"
						size="md"
						variant="outline"
						name="clientId"
						bind:value={clientId}
						required
					/>
					<Input
						type="text"
						placeholder="Worker ID"
						size="md"
						variant="outline"
						name="workerId"
						bind:value={workerId}
						required
					/>
					<Input
						type="text"
						placeholder="Division ID"
						size="md"
						variant="outline"
						name="divisionId"
						bind:value={divisionId}
						required
					/>
					<Input
						type="text"
						placeholder="Assigned By (User ID)"
						size="md"
						variant="outline"
						name="assignedBy"
						bind:value={assignedBy}
						required
					/>
				</div>
				
				<!-- Permissions -->
				<div class="space-y-3">
					<h3 class="text-sm font-medium text-gray-900">Assignment Permissions</h3>
					<div class="flex flex-wrap gap-4">
						<label class="flex items-center space-x-2">
							<input
								type="checkbox"
								bind:checked={canModifyExercises}
								class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
							/>
							<span class="text-sm text-gray-700">Can Modify Exercises</span>
						</label>
						<label class="flex items-center space-x-2">
							<input
								type="checkbox"
								bind:checked={canViewMedicalInfo}
								class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
							/>
							<span class="text-sm text-gray-700">Can View Medical Info</span>
						</label>
						<label class="flex items-center space-x-2">
							<input
								type="checkbox"
								bind:checked={canScheduleSessions}
								class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
							/>
							<span class="text-sm text-gray-700">Can Schedule Sessions</span>
						</label>
					</div>
				</div>
				
				<Button type="submit" size="md" class="w-full">Create Assignment</Button>
			</form>
		</Card>

		<!-- Management Actions -->
		<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
			<!-- Update Status -->
			<Card class="p-6">
				<h2 class="mb-4 text-lg font-medium text-gray-900">Update Assignment Status</h2>
				<form onsubmit={handleUpdateStatus} class="space-y-4">
					<Input
						type="text"
						placeholder="Assignment ID"
						size="md"
						variant="outline"
						name="id"
						bind:value={updateStatusId}
						required
					/>
					<Input
						as="select"
						variant="outline"
						name="status"
						bind:value={updateStatus}
						required
					>
						<option value="active">Active</option>
						<option value="inactive">Inactive</option>
						<option value="completed">Completed</option>
					</Input>
					<Button type="submit" size="md" variant="secondary" class="w-full">Update Status</Button>
				</form>
			</Card>

			<!-- Delete Assignment -->
			<Card class="border-red-200 bg-red-50 p-6 flex flex-col justify-between">
				<div>
					<h2 class="mb-4 text-lg font-medium text-red-900">Delete Assignment</h2>
					<p class="my-2 text-xs text-red-700">
						This will permanently delete the assignment and cannot be undone.
					</p>
				</div>
				<div class="space-y-4">
					<Input
						type="text"
						placeholder="Assignment ID"
						size="md"
						variant="outline"
						name="deleteId"
						bind:value={deleteAssignmentId}
						required
					/>
					<!-- Delete Button -->
					<Button
						type="button"
						size="md"
						class="w-full border-red-600 bg-red-600 text-white hover:border-red-700 hover:bg-red-700"
						onclick={handleDeleteAssignment}
					>
						Delete Assignment (Permanent)
					</Button>
				</div>
			</Card>
		</div>

		<!-- Assignments Table -->
		<Card class="p-6">
			<h2 class="mb-4 text-lg font-medium text-gray-900">Assignments Overview</h2>
			<Table data={tableData} bind:selected={selectedAssignments} class="max-h-96" />
		</Card>
	</div>
{/if}
