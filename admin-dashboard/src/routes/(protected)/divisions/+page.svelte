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
		} catch (err) {
			console.error('Error loading divisions:', err);
			error = 'Failed to load divisions. Please refresh the page.';
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
		if (!name || !organizationId || !managerId) {
			error = 'All fields are required';
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
				managerId,
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
		} catch (err) {
			console.error('Error creating division:', err);
			error = 'Failed to create division. Please try again.';
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
		} catch (err) {
			console.error('Error deleting division:', err);
			error = 'Failed to delete division. Please try again.';
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
{:else if error}
	<div class="p-6">
		<Message type="error" message={error} />
	</div>
{:else}
	<div class="space-y-6 p-6">
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
					placeholder="Manager ID"
					size="md"
					variant="outline"
					name="managerId"
					bind:value={managerId}
					required
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
						This will permanently delete all division data including assignments and settings.
					</p>
				</div>
				<form onsubmit={handleDeleteDivision} class="space-y-4">
					<Input
						type="text"
						placeholder="Division ID"
						size="md"
						variant="outline"
						name="deleteId"
						bind:value={deleteDivisionId}
						required
					/>
					<Button
						type="submit"
						size="md"
						class="w-full border-red-600 bg-red-600 text-white hover:border-red-700 hover:bg-red-700"
					>
						Force Delete Division
					</Button>
				</form>
			</Card>
		</div>

		<!-- Messages -->
		<Message type="error" message={error || undefined} />
		<Message type="success" message={successMessage || undefined} />

		<!-- Divisions Table -->
		<Card class="p-6">
			<h2 class="mb-4 text-lg font-medium text-gray-900">Divisions Overview</h2>
			<Table data={tableData} class="max-h-96" />
		</Card>
	</div>
{/if}
