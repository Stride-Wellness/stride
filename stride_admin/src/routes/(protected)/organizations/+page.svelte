<script lang="ts">
	import type { Organization } from '$lib/services/organizations';
	import { OrganizationsService } from '$lib/services/organizations';
	import Table from '$lib/components/Table.svelte';
	import Message from '$lib/components/Message.svelte';
	import Card from '$lib/components/Card.svelte';
	import { onMount } from 'svelte';
	import Tabs from '$lib/components/Tabs.svelte';
	import TabPanel from '$lib/components/TabPanel.svelte';
	import CreateOrganizationForm from '$lib/components/compound/CreateOrganizationForm.svelte';
	import UpdateOrganizationStatusForm from '$lib/components/compound/UpdateOrganizationStatusForm.svelte';
	import UpdateOrganizationSeatsForm from '$lib/components/compound/UpdateOrganizationSeatsForm.svelte';
	import DeleteOrganizationForm from '$lib/components/compound/DeleteOrganizationForm.svelte';

	// State for organizations data
	let organizations = $state<Organization[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);

	let selectedOrganizations: Record<string, any>[] = $state([]);

	// Load organizations on mount
	onMount(async () => {
		await loadOrganizations();
	});

	async function loadOrganizations() {
		loading = true;
		error = null;
		try {
			organizations = await OrganizationsService.getAll(1000);
		} catch (err) {
			console.error('Error loading organizations:', err);
			error = 'Failed to load organizations. Please refresh the page.';
		} finally {
			loading = false;
		}
	}

	// Transform data for table display
	const tableData = $derived.by(() => {
		if (organizations.length === 0) return [];

		return organizations.map((org) => ({
			id: { name: org.id, href: `/organizations/${org.id}` },
			name: org.name,
			status: org.status,
			'Total Seats': org.totalSeats,
			'Used Seats': org.usedSeats,
			Utilization: `${Math.round((org.usedSeats / org.totalSeats) * 100)}%`,
			'Stripe ID': org.stripeUserId,
			Created: org.createdAt ? new Date(org.createdAt).toLocaleDateString() : 'N/A',
			Updated: org.updatedAt ? new Date(org.updatedAt).toLocaleDateString() : 'N/A'
		}));
	});

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

	// Get selected organization IDs
	const selectedOrganizationIds = $derived(
		selectedOrganizations.map((org) => org.id.name)
	);
</script>

<div class="space-y-6 p-6">
	<div class="flex items-center justify-between">
		<h1 class="text-2xl font-semibold text-gray-900">Organizations</h1>
		<p class="text-sm text-gray-600">Manage and monitor client organizations</p>
	</div>

	<!-- Messages -->
	<Message type="error" message={error || undefined} />
	<Message type="success" message={successMessage || undefined} />

	<!-- Summary Cards -->
	<div class="grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-5">
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

	<Tabs>
		<TabPanel label="Create Organization">
			<CreateOrganizationForm
				bind:error
				bind:successMessage
				callback={(newOrg) => {
					organizations = [...organizations, newOrg];
				}}
			/>
		</TabPanel>
		<TabPanel label="Update Status">
			<UpdateOrganizationStatusForm bind:error bind:successMessage callback={loadOrganizations} />
		</TabPanel>
		<TabPanel label="Update Seats">
			<UpdateOrganizationSeatsForm bind:error bind:successMessage callback={loadOrganizations} />
		</TabPanel>
		<TabPanel label="Delete Organization">
			<DeleteOrganizationForm bind:error bind:successMessage prefilledIds={selectedOrganizationIds} callback={loadOrganizations} />
		</TabPanel>
	</Tabs>

	<!-- Organizations Table -->
	<Card class="p-6">
		<h2 class="mb-4 text-lg font-medium text-gray-900">Client Organizations Overview</h2>
		{#key organizations.length}
			<Table data={tableData} bind:selected={selectedOrganizations} class="max-h-96" />
		{/key}
	</Card>
</div>
