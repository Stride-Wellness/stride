<script lang="ts">
	import type { Division } from '$lib/services';
	import { DivisionsService } from '$lib/services';
	import Table from '$lib/components/Table.svelte';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Message from '$lib/components/Message.svelte';
	import Card from '$lib/components/Card.svelte';
	import { enhance } from '$app/forms';
	import { onMount } from 'svelte';
	import CreateDivisionForm from '$lib/components/compound/CreateDivisionForm.svelte';

	const { form }: { form: any } = $props();

	// State for divisions data
	let divisions = $state<Division[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);

	// Form state for deleting division
	let deleteDivisionId = $state('');

	// Form state for assigning manager
	let assignDivisionId = $state('');
	let assignManagerId = $state('');

	// Load divisions on mount
	onMount(async () => {
		try {
			divisions = await DivisionsService.getAll(1000);
		} catch (err: any) {
			console.error('Error loading divisions:', err);
			
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have access to view divisions.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in to view divisions.';
						break;
					default:
						error = `Error loading divisions: ${err.message || 'Please refresh the page and try again.'}`;
				}
			} else if (err.message) {
				if (err.message.includes('Failed to get divisions')) {
					error = 'Failed to load divisions. Please check your internet connection and refresh the page.';
				} else {
					error = err.message;
				}
			} else {
				error = 'Failed to load divisions. Please refresh the page.';
			}
		} finally {
			loading = false;
		}
	});

	// Handle soft delete division
	async function handleSoftDeleteDivision(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!deleteDivisionId) {
			error = 'Division ID is required';
			return;
		}

		// Confirm soft deletion
		if (
			!confirm(
				'Are you sure you want to soft delete this division? This will hide it from the main view but preserve all data. You can restore it later if needed.'
			)
		) {
			return;
		}

		try {
			await DivisionsService.softDelete(deleteDivisionId, false); // Don't cascade to users by default

			// Reload divisions to refresh the list (soft deleted won't show)
			divisions = await DivisionsService.getAll(1000);

			deleteDivisionId = '';

			successMessage = 'Division soft deleted successfully! Data has been preserved and can be restored.';
		} catch (err: any) {
			console.error('Error soft deleting division:', err);
			
			// Parse specific Firebase/Firestore errors
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to delete this division.';
						break;
					case 'not-found':
						error = 'Division not found. It may have already been deleted or the ID is incorrect.';
						break;
					case 'failed-precondition':
						error = 'Cannot delete division. Please check the division ID and try again.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to soft delete division. Please try again.'}`;
				}
			} else if (err.message) {
				if (err.message.includes('Failed to delete division')) {
					error = 'Failed to soft delete division. Please check the division ID and try again.';
				} else {
					error = err.message;
				}
			} else {
				error = 'An unexpected error occurred while soft deleting the division.';
			}
		}
	}

	// Handle delete division
	async function handleDeleteDivision(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!deleteDivisionId) {
			error = 'Division ID is required';
			return;
		}

		// Confirm deletion
		if (
			!confirm(
				'Are you sure you want to delete this division? This action cannot be undone and will permanently remove all associated data.'
			)
		) {
			return;
		}

		try {
			await DivisionsService.hardDelete(deleteDivisionId);

			// Update local state immediately
			divisions = divisions.filter((division) => division.id !== deleteDivisionId);

			deleteDivisionId = '';

			successMessage = 'Division deleted successfully!';
		} catch (err: any) {
			console.error('Error deleting division:', err);
			
			// Parse specific Firebase/Firestore errors
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to delete this division.';
						break;
					case 'not-found':
						error = 'Division not found. It may have already been deleted or the ID is incorrect.';
						break;
					case 'failed-precondition':
						error = 'Cannot delete division. There may be users or assignments still associated with this division.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to delete division. Please try again.'}`;
				}
			} else if (err.message) {
				if (err.message.includes('Failed to permanently delete division')) {
					error = 'Failed to delete division. Please ensure there are no users or assignments linked to this division.';
				} else {
					error = err.message;
				}
			} else {
				error = 'An unexpected error occurred while deleting the division.';
			}
		}
	}

	// Handle assign manager to division
	async function handleAssignManager(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!assignDivisionId || !assignManagerId) {
			error = 'Both Division ID and Manager ID are required';
			return;
		}

		try {
			await DivisionsService.assignManager(assignDivisionId, assignManagerId);

			// Reload divisions to refresh the list
			divisions = await DivisionsService.getAll(1000);

			assignDivisionId = '';
			assignManagerId = '';

			successMessage = 'Manager assigned to division successfully!';
		} catch (err: any) {
			console.error('Error assigning manager:', err);
			
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to assign managers.';
						break;
					case 'not-found':
						error = 'Division or manager not found. Please verify the IDs are correct.';
						break;
					case 'failed-precondition':
						error = 'Manager assignment failed validation. The manager must exist, belong to the same organization, and have manager role.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to assign manager. Please try again.'}`;
				}
			} else if (err.message) {
				error = err.message;
			} else {
				error = 'An unexpected error occurred while assigning the manager.';
			}
		}
	}

	// Transform data for table display
	const tableData = $derived(
		divisions.map((division) => ({
			id: { name: division.id, href: `/divisions/${division.id}` },
			name: division.name,
			'Organization ID': division.organizationId,
			'Manager ID': division.managerId || 'No Manager Assigned',
			'Division Type': division.divisionType,
			Created: division.createdAt ? new Date(division.createdAt).toLocaleDateString() : 'N/A',
			Updated: division.updatedAt ? new Date(division.updatedAt).toLocaleDateString() : 'N/A'
		}))
	);

	// Calculate summary stats
	const summaryStats = $derived(() => {
		const total = divisions.length;
		const retirementHomes = divisions.filter((div) => div.divisionType === 'retirement_home').length;
		const homecareProviders = divisions.filter((div) => div.divisionType === 'homecare_provider').length;
		const withoutManager = divisions.filter((div) => !div.managerId).length;

		return { total, retirementHomes, homecareProviders, withoutManager };
	});
</script>

{#if loading}
	<div class="flex items-center justify-center p-6">
		<div class="text-lg">Loading divisions...</div>
	</div>
{:else}
	<div class="space-y-6 p-6">
		<!-- Error and Success Messages at Top -->
		<Message type="error" message={error || undefined} />
		<Message type="success" message={successMessage || undefined} />

		<div class="flex items-center justify-between">
			<h1 class="text-2xl font-semibold text-gray-900">Divisions</h1>
			<p class="text-sm text-gray-600">Manage organization divisions and locations</p>
		</div>

		<!-- Summary Cards -->
		<div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Total Divisions</h4>
					<p class="text-2xl font-bold text-gray-900">{summaryStats().total}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Retirement Homes</h4>
					<p class="text-2xl font-bold">{summaryStats().retirementHomes}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Homecare Providers</h4>
					<p class="text-2xl font-bold">{summaryStats().homecareProviders}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Without Manager</h4>
					<p class="text-2xl font-bold text-amber-600">{summaryStats().withoutManager}</p>
				</div>
			</Card>
		</div>

		<!-- Create Division Form -->
		<CreateDivisionForm bind:error bind:successMessage callback={(newDivision) => { divisions.push(newDivision); }} />

		<!-- Management Actions -->
		<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
			<!-- Assign Manager -->
			<Card class="p-6">
				<h2 class="mb-4 text-lg font-medium text-gray-900">Assign Manager</h2>
				<p class="my-2 text-xs text-gray-700">
					Assign a manager to a division that doesn't have one assigned yet.
				</p>
				<form onsubmit={handleAssignManager} class="space-y-4">
					<Input
						type="text"
						placeholder="Division ID"
						size="md"
						variant="outline"
						name="assignDivisionId"
						bind:value={assignDivisionId}
						required
					/>
					<Input
						type="text"
						placeholder="Manager ID"
						size="md"
						variant="outline"
						name="assignManagerId"
						bind:value={assignManagerId}
						required
					/>
					<Button
						type="submit"
						size="md"
						class="w-full"
					>
						Assign Manager
					</Button>
				</form>
			</Card>

			<!-- Delete Division -->
			<Card class="border-red-200 bg-red-50 p-6 flex flex-col justify-between">
				<div>
					<h2 class="mb-4 text-lg font-medium text-red-900">Delete Division</h2>
					<p class="my-2 text-xs text-red-700">
						Soft delete hides the division but preserves data. Hard delete permanently removes all data.
					</p>
				</div>
				<div class="space-y-4">
					<Input
						type="text"
						placeholder="Division ID"
						size="md"
						variant="outline"
						name="deleteId"
						bind:value={deleteDivisionId}
						required
					/>
					<!-- Soft Delete Button -->
					<Button
						type="button"
						size="md"
						class="w-full border-yellow-600 bg-yellow-600 text-white hover:border-yellow-700 hover:bg-yellow-700"
						onclick={handleSoftDeleteDivision}
					>
						Soft Delete Division (Recoverable)
					</Button>
					<!-- Hard Delete Button -->
					<Button
						type="button"
						size="md"
						class="w-full border-red-600 bg-red-600 text-white hover:border-red-700 hover:bg-red-700"
						onclick={handleDeleteDivision}
					>
						Hard Delete Division (Permanent)
					</Button>
				</div>
			</Card>
		</div>


		<!-- Divisions Table -->
		<Card class="p-6">
			<h2 class="mb-4 text-lg font-medium text-gray-900">Divisions Overview</h2>
			<Table data={tableData} class="max-h-96" />
		</Card>
	</div>
{/if}
