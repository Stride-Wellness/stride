<script lang="ts">
	import type { Organization } from '$lib/services/organizations';
	import { OrganizationsService } from '$lib/services/organizations';
	import Table from '$lib/components/Table.svelte';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Message from '$lib/components/Message.svelte';
	import Card from '$lib/components/Card.svelte';
	import { enhance } from '$app/forms';
	import { onMount } from 'svelte';

	const { form }: { form: any } = $props();

	// State for organizations data
	let organizations = $state<Organization[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);

	// Form state for creating organizations
	let name = $state('');
	let totalSeats = $state(10);
	let stripeUserId = $state('');

	// Form state for updating organization status
	let updateStatusId = $state('');
	let updateStatus = $state<'active' | 'suspended' | 'cancelled'>('active');

	// Form state for updating seats
	let updateSeatsId = $state('');
	let updateSeatsCount = $state(10);

	// Form state for deleting organization
	let deleteOrgId = $state('');

	let selectedOrganizations: Record<string, any>[] = $state([]);

	// Load organizations on mount
	onMount(async () => {
		try {
			organizations = await OrganizationsService.getAll(1000);
		} catch (err) {
			console.error('Error loading organizations:', err);
			error = 'Failed to load organizations. Please refresh the page.';
		} finally {
			loading = false;
		}
	});

	// Helper function to reload organizations
	async function reloadOrganizations() {
		try {
			organizations = await OrganizationsService.getAll(1000);
		} catch (err) {
			console.error('Error reloading organizations:', err);
			error = 'Failed to reload organizations.';
		}
	}

	// Handle create organization
	async function handleCreateOrganization(event: Event) {
		event.preventDefault();

		// Clear previous messages
		error = null;
		successMessage = null;

		// Validation
		if (!name || !stripeUserId || totalSeats < 1) {
			error = 'All fields are required and total seats must be at least 1';
			return;
		}

		if (name.length < 2) {
			error = 'Organization name must be at least 2 characters';
			return;
		}

		try {
			const newOrg = await OrganizationsService.create({
				name,
				totalSeats,
				stripeUserId
			});

			// Reset form
			name = '';
			totalSeats = 10;
			stripeUserId = '';

			// Update local state immediately
			organizations = [...organizations, newOrg];

			successMessage = 'Organization created successfully!';
		} catch (err) {
			console.error('Error creating organization:', err);
			error = 'Failed to create organization. Please try again.';
		}
	}

	// Handle update status
	async function handleUpdateStatus(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!updateStatusId || !updateStatus) {
			error = 'Organization ID and status are required';
			return;
		}

		try {
			await OrganizationsService.update(updateStatusId, { status: updateStatus });

			// Update local state immediately
			const orgIndex = organizations.findIndex((org) => org.id === updateStatusId);
			if (orgIndex !== -1) {
				organizations[orgIndex] = { ...organizations[orgIndex], status: updateStatus };
				organizations = [...organizations]; // Trigger reactivity
			}

			updateStatusId = '';
			updateStatus = 'active';

			successMessage = 'Organization status updated successfully!';
		} catch (err) {
			console.error('Error updating organization status:', err);
			error = 'Failed to update organization status. Please try again.';
		}
	}

	// Handle update seats
	async function handleUpdateSeats(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!updateSeatsId || updateSeatsCount < 1) {
			error = 'Organization ID is required and seat count must be at least 1';
			return;
		}

		try {
			await OrganizationsService.update(updateSeatsId, { totalSeats: updateSeatsCount });

			// Update local state immediately
			const orgIndex = organizations.findIndex((org) => org.id === updateSeatsId);
			if (orgIndex !== -1) {
				organizations[orgIndex] = { ...organizations[orgIndex], totalSeats: updateSeatsCount };
				organizations = [...organizations]; // Trigger reactivity
			}

			updateSeatsId = '';
			updateSeatsCount = 10;

			successMessage = 'Organization seats updated successfully!';
		} catch (err) {
			console.error('Error updating organization seats:', err);
			error = 'Failed to update organization seats. Please try again.';
		}
	}

	// Handle soft delete organization
	async function handleSoftDeleteOrganization(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!deleteOrgId) {
			error = 'Organization ID is required';
			return;
		}

		// Confirm soft deletion
		if (
			!confirm(
				'Are you sure you want to soft delete this organization? This will hide it from the main view but preserve all data. You can restore it later if needed.'
			)
		) {
			return;
		}

		try {
			const orgsToDelete = deleteOrgId.split(',').map((id) => id.trim());
			for (const id of orgsToDelete) {
				await OrganizationsService.softDelete(id);
			}

			// Reload organizations to refresh the list (soft deleted won't show)
			organizations = await OrganizationsService.getAll(1000);

			deleteOrgId = '';

			successMessage = 'Organization soft deleted successfully! Data has been preserved and can be restored.';
		} catch (err: any) {
			console.error('Error soft deleting organization:', err);
			
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to delete this organization.';
						break;
					case 'not-found':
						error = 'Organization not found. It may have already been deleted or the ID is incorrect.';
						break;
					case 'failed-precondition':
						error = 'Cannot delete organization. There may be users or divisions still associated with this organization.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to soft delete organization. Please try again.'}`;
				}
			} else if (err.message) {
				if (err.message.includes('Failed to delete organization')) {
					error = 'Failed to soft delete organization. Please check the organization ID and try again.';
				} else {
					error = err.message;
				}
			} else {
				error = 'An unexpected error occurred while soft deleting the organization.';
			}
		}
	}

	// Handle delete organization
	async function handleDeleteOrganization(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!deleteOrgId) {
			error = 'Organization ID is required';
			return;
		}

		// Confirm deletion
		if (
			!confirm(
				'Are you sure you want to delete this organization? This action cannot be undone and will permanently remove all associated data.'
			)
		) {
			return;
		}

		try {
			const orgsToDelete = deleteOrgId.split(',').map((id) => id.trim());
			for (const id of orgsToDelete) {
				await OrganizationsService.hardDelete(id);
			}

			// Update local state immediately
			organizations = organizations.filter((org) => !orgsToDelete.includes(org.id));

			deleteOrgId = '';

			successMessage = 'Organization deleted successfully!';
		} catch (err) {
			console.error('Error deleting organization:', err);
			error = 'Failed to delete organization. Please try again.';
		}
	}

	// Transform data for table display
	const tableData = $derived(
		organizations.map((org) => ({
			id: { name: org.id, href: `/organizations/${org.id}` },
			name: org.name,
			status: org.status,
			'Total Seats': org.totalSeats,
			'Used Seats': org.usedSeats,
			Utilization: `${Math.round((org.usedSeats / org.totalSeats) * 100)}%`,
			'Stripe ID': org.stripeUserId,
			Created: org.createdAt ? new Date(org.createdAt).toLocaleDateString() : 'N/A',
			Updated: org.updatedAt ? new Date(org.updatedAt).toLocaleDateString() : 'N/A'
		}))
	);

	// Calculate summary stats
	const summaryStats = $derived(() => {
		const total = organizations.length;
		const active = organizations.filter((org) => org.status === 'active').length;
		const suspended = organizations.filter((org) => org.status === 'suspended').length;
		const cancelled = organizations.filter((org) => org.status === 'cancelled').length;
		const totalSeats = organizations.reduce((sum, org) => sum + org.totalSeats, 0);
		const usedSeats = organizations.reduce((sum, org) => sum + org.usedSeats, 0);

		return { total, active, suspended, cancelled, totalSeats, usedSeats };
	});

	$effect(() => {
		deleteOrgId = selectedOrganizations.map((org) => org.id.name).join(', ');
		updateStatusId = selectedOrganizations.map((org) => org.id.name).join(', ');
		updateSeatsId = selectedOrganizations.map((org) => org.id.name).join(', ');
	});
</script>

{#if loading}
	<div class="flex items-center justify-center p-6">
		<div class="text-lg">Loading organizations...</div>
	</div>
{:else}
	<div class="space-y-6 p-6">
		<div class="flex items-center justify-between">
			<h1 class="text-2xl font-semibold text-gray-900">Organizations</h1>
			<p class="text-sm text-gray-600">Manage and monitor client organizations</p>
		</div>
				<!-- Messages -->
		<Message type="error" message={error || undefined} />
		<Message type="success" message={successMessage || undefined} />
		<!-- Summary Cards -->
		<div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Client Organizations</h4>
					<p class="text-2xl font-bold text-gray-900">{summaryStats().total}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Active Organizations</h4>
					<p class="text-2xl font-bold">{summaryStats().active}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Platform Seats</h4>
					<p class="text-2xl font-bold">{summaryStats().totalSeats}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Seats in Use</h4>
					<p class="text-2xl font-bold">{summaryStats().usedSeats}</p>
				</div>
			</Card>
		</div>

		<!-- Create Organization Form -->
		<Card class="p-6">
			<h2>Add New Client Organization</h2>
			<form onsubmit={handleCreateOrganization} class="grid grid-cols-1 gap-4 md:grid-cols-3">
				<Input
					type="text"
					placeholder="Organization Name"
					size="md"
					variant="outline"
					name="name"
					bind:value={name}
					required
				/>
				<Input
					type="text"
					placeholder="Stripe User ID"
					size="md"
					variant="outline"
					name="stripeUserId"
					bind:value={stripeUserId}
					required
				/>
				<Input
					type="number"
					placeholder="Total Seats"
					size="md"
					variant="outline"
					name="totalSeats"
					bind:value={totalSeats}
					min="1"
					required
				/>
				<Button type="submit" size="md" class="md:col-span-3">Create Organization</Button>
			</form>
		</Card>

		<!-- Management Actions -->
		<div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
			<!-- Update Status -->
			<Card class="p-6">
				<h2 class="mb-4 text-lg font-medium text-gray-900">Modify Organization Status</h2>
				<form onsubmit={handleUpdateStatus} class="space-y-4">
					<Input
						type="text"
						placeholder="Organization ID"
						size="md"
						variant="outline"
						name="id"
						bind:value={updateStatusId}
						required
					/>
					<Input
						as="select"
						variants="outline"
						name="status"
						bind:value={updateStatus}
						class="w-full rounded-md border border-gray-300 px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
						required
					>
						<option value="active">Active</option>
						<option value="suspended">Suspended</option>
						<option value="cancelled">Cancelled</option>
					</Input>
					<Button type="submit" size="md" variant="secondary" class="w-full">Update Status</Button>
				</form>
			</Card>

			<!-- Update Seats -->
			<Card class="p-6">
				<h2 class="mb-4 text-lg font-medium text-gray-900">Adjust Seat Allocation</h2>
				<form onsubmit={handleUpdateSeats} class="space-y-4">
					<Input
						type="text"
						placeholder="Organization ID"
						size="md"
						variant="outline"
						name="id"
						bind:value={updateSeatsId}
						required
					/>
					<Input
						type="number"
						placeholder="New Total Seats"
						size="md"
						variant="outline"
						name="totalSeats"
						bind:value={updateSeatsCount}
						min="1"
						required
					/>
					<Button type="submit" size="md" variant="secondary" class="w-full">Update Seats</Button>
				</form>
			</Card>

			<!-- Delete Organization -->
			<Card class="border-red-200 bg-red-50 p-6 flex flex-col justify-between">
				<div>
					<h2 class="mb-4 text-lg font-medium text-red-900">Delete Organization</h2>
					<p class="my-2 text-xs text-red-700">
						Soft delete hides the organization but preserves data. Hard delete permanently removes all data.
					</p>
				</div>
				<div class="space-y-4">
					<Input
						type="text"
						placeholder="Organization ID"
						size="md"
						variant="outline"
						name="deleteId"
						bind:value={deleteOrgId}
						required
					/>
					<!-- Soft Delete Button -->
					<Button
						type="button"
						size="md"
						class="w-full border-yellow-600 bg-yellow-600 text-white hover:border-yellow-700 hover:bg-yellow-700"
						onclick={handleSoftDeleteOrganization}
					>
						Soft Delete Organization (Recoverable)
					</Button>
					<!-- Hard Delete Button -->
					<Button
						type="button"
						size="md"
						class="w-full border-red-600 bg-red-600 text-white hover:border-red-700 hover:bg-red-700"
						onclick={handleDeleteOrganization}
					>
						Hard Delete Organization (Permanent)
					</Button>
				</div>
			</Card>
		</div>



		<!-- Organizations Table -->
		<Card class="p-6">
			<h2 class="mb-4 text-lg font-medium text-gray-900">Client Organizations Overview</h2>
			<Table data={tableData} bind:selected={selectedOrganizations} class="max-h-96" />
		</Card>
	</div>
{/if}
