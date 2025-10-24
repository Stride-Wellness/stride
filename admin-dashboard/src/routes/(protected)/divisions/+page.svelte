<script lang="ts">
	import type { Division } from '$lib/services';
	import { DivisionsService } from '$lib/services';
	import Table from '$lib/components/Table.svelte';
	import Message from '$lib/components/Message.svelte';
	import Card from '$lib/components/Card.svelte';
	import { onMount } from 'svelte';
	import CreateDivisionForm from '$lib/components/compound/CreateDivisionForm.svelte';
	import AssignManagerForm from '$lib/components/compound/AssignManagerForm.svelte';
	import DeleteDivisionForm from '$lib/components/compound/DeleteDivisionForm.svelte';
	import Tabs from '$lib/components/Tabs.svelte';
	import TabPanel from '$lib/components/TabPanel.svelte';

	// State for divisions data
	let divisions = $state<Division[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);

	let selectedDivisions: Record<string, any>[] = $state([]);

	// Load divisions on mount
	onMount(async () => {
		await loadDivisions();
	});

	async function loadDivisions() {
		loading = true;
		error = null;
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

	// Get selected division IDs
	const selectedDivisionIds = $derived(selectedDivisions.map((div) => div.id.name).join(', '));
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

		
		<Tabs>
			<TabPanel label="Create Division">
				<!-- Create Division Form -->
				<CreateDivisionForm 
					bind:error 
					bind:successMessage 
					callback={(newDivision) => { 
						divisions.push(newDivision); 
					}} 
				/>
			</TabPanel>
			<TabPanel label="Assign Manager">
			<!-- Assign Manager -->
			<AssignManagerForm
				bind:error
				bind:successMessage
				constantDivisionId={selectedDivisionIds}
				callback={loadDivisions}
			/>
			</TabPanel>
			<TabPanel label="Delete Division">
			<!-- Delete Division -->
			<DeleteDivisionForm
				bind:error
				bind:successMessage
				constantDivisionId={selectedDivisionIds}
				callback={loadDivisions}
			/>
			</TabPanel>
		</Tabs>

		<!-- Divisions Table -->
		<Card class="p-6">
			<h2 class="mb-4 text-lg font-medium text-gray-900">Divisions Overview</h2>
			<Table data={tableData} bind:selected={selectedDivisions} class="max-h-96" />
		</Card>
	</div>
{/if}
