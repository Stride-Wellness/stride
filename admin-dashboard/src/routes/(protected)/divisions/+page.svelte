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

	const { form }: { form: any } = $props();

	// State for divisions data
	let divisions = $state<Division[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);

	// Form state for creating divisions
	let name = $state('');
	let organizationId = $state('');
	let managerId = $state('');
	let divisionType = $state<'retirement_home' | 'homecare_provider'>('retirement_home');

	// Form state for deleting division
	let deleteDivisionId = $state('');

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

	// Handle create division
	async function handleCreateDivision(event: Event) {
		event.preventDefault();

		// Clear previous messages
		error = null;
		successMessage = null;

		// Validation
		if (!name || !organizationId) {
			error = 'Name and Organization ID are required';
			return;
		}

		if (name.length < 2) {
			error = 'Division name must be at least 2 characters';
			return;
		}

		try {
			const newDivision = await DivisionsService.create({
				name,
				organizationId,
				managerId: managerId || null, // Allow empty manager ID
				divisionType
			});

			// Reset form
			name = '';
			organizationId = '';
			managerId = '';
			divisionType = 'retirement_home';

			// Update local state immediately
			divisions = [...divisions, newDivision];

			successMessage = 'Division created successfully!';
		} catch (err: any) {
			console.error('Error creating division:', err);
			
			// Parse specific Firebase/Firestore errors
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions or the organization/manager may not exist.';
						break;
					case 'not-found':
						error = 'Organization or manager not found. Please verify the IDs are correct.';
						break;
					case 'already-exists':
						error = 'A division with this name already exists in the organization.';
						break;
					case 'invalid-argument':
						error = 'Invalid data provided. Please check all fields are correctly filled.';
						break;
					case 'failed-precondition':
						error = 'Division creation failed validation. The manager must exist, belong to the organization, and have manager role.';
						break;
					case 'resource-exhausted':
						error = 'Too many requests. Please wait a moment and try again.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to create division. Please try again.'}`;
				}
			} else if (err.message) {
				// Handle generic errors from the service
				if (err.message.includes('Failed to create division')) {
					error = 'Failed to create division. Please verify the organization and manager IDs exist and try again.';
				} else {
					error = err.message;
				}
			} else {
				error = 'An unexpected error occurred. Please try again.';
			}
		}
	}

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

	// Transform data for table display
	const tableData = $derived(
		divisions.map((division) => ({
			id: { name: division.id, href: `/divisions/${division.id}` },
			name: division.name,
			'Organization ID': division.organizationId,
			'Manager ID': division.managerId,
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

		return { total, retirementHomes, homecareProviders };
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
		<div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
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
		</div>

		<!-- Create Division Form -->
		<Card class="p-6">
			<h2>Add New Division</h2>
			<form onsubmit={handleCreateDivision} class="grid grid-cols-1 gap-4 md:grid-cols-2">
				<Input
					type="text"
					placeholder="Division Name"
					size="md"
					variant="outline"
					name="name"
					bind:value={name}
					required
				/>
				<Input
					type="text"
					placeholder="Organization ID"
					size="md"
					variant="outline"
					name="organizationId"
					bind:value={organizationId}
					required
				/>
				<Input
					type="text"
					placeholder="Manager ID (optional - can be assigned later)"
					size="md"
					variant="outline"
					name="managerId"
					bind:value={managerId}
				/>
				<Input
					as="select"
					variant="outline"
					name="divisionType"
					bind:value={divisionType}
					required
				>
					<option value="retirement_home">Retirement Home</option>
					<option value="homecare_provider">Homecare Provider</option>
				</Input>
				<Button type="submit" size="md" class="md:col-span-2">Create Division</Button>
			</form>
		</Card>

		<!-- Management Actions -->
		<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
			<!-- Placeholder for future actions -->
			<Card class="p-6">
				<h2 class="mb-4 text-lg font-medium text-gray-900">Division Management</h2>
				<p class="text-gray-600">Additional management options will be available here.</p>
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
