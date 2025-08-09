<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import Card from '$lib/components/Card.svelte';
	import Button from '$lib/components/Button.svelte';
	import Message from '$lib/components/Message.svelte';
	import Input from '$lib/components/Input.svelte';
	import Table from '$lib/components/Table.svelte';
	import { OrganizationsService } from '$lib/services/organizations';
	import type { Organization } from '$lib/services/organizations';
	import { DivisionsService } from '$lib/services/divisions';
	import type { Division } from '$lib/services/divisions';

	const organizationId = $derived($page.params.id);

	// State
	let organization = $state<Organization | null>(null);
	let divisions = $state<Division[]>([]);
	let loading = $state(true);
	let saving = $state(false);
	let divisionsLoading = $state(false);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);
	let jsonText = $state('');
	
	// Division form state
	let newDivisionName = $state('');
	let newDivisionManagerId = $state('');
	let newDivisionType = $state<'retirement_home' | 'homecare_provider'>('retirement_home');
	let creatingDivision = $state(false);

	// Load organization data
	onMount(async () => {
		if (!organizationId) {
			error = 'No organization ID provided.';
			loading = false;
			return;
		}

		try {
			organization = await OrganizationsService.getById(organizationId);
			jsonText = JSON.stringify(organization, null, 2);
			
			// Load divisions for this organization
			await loadDivisions();
		} catch (err) {
			console.error('Error loading organization:', err);
			error = 'Failed to load organization data. Please check the ID and try again.';
		} finally {
			loading = false;
		}
	});

	// Save changes
	async function saveChanges() {
		if (!organizationId) {
			error = 'No organization ID available.';
			return;
		}

		error = null;
		successMessage = null;
		saving = true;

		try {
			// Parse the JSON
			const updatedOrg = JSON.parse(jsonText);
			
			// Validate that it has an ID and matches the current organization ID
			if (!updatedOrg.id || updatedOrg.id !== organizationId) {
				error = 'Invalid JSON: ID field is missing or does not match the current organization ID.';
				return;
			}

			// Update the organization
			await OrganizationsService.update(organizationId, updatedOrg);

			// Update local state
			organization = updatedOrg;
			successMessage = 'Organization updated successfully!';
		} catch (err) {
			console.error('Error:', err);
			
			// Check if it's a JSON parse error
			if (err instanceof SyntaxError) {
				error = 'Invalid JSON format. Please check your syntax and try again.';
			} else {
				error = 'Failed to update organization. Please try again.';
			}
		} finally {
			saving = false;
		}
	}

	// Reset changes
	function resetChanges() {
		if (organization) {
			jsonText = JSON.stringify(organization, null, 2);
			error = null;
			successMessage = null;
		}
	}

	// Load divisions
	async function loadDivisions() {
		if (!organizationId) return;
		
		divisionsLoading = true;
		try {
			divisions = await DivisionsService.getByOrganizationId(organizationId);
		} catch (err) {
			console.error('Error loading divisions:', err);
			// Don't set error state here, it's not critical
		} finally {
			divisionsLoading = false;
		}
	}

	// Create new division
	async function createDivision() {
		if (!organizationId || !newDivisionName.trim() || !newDivisionManagerId.trim()) return;
		
		creatingDivision = true;
		error = null;
		
		try {
			const divisionData = {
				name: newDivisionName.trim(),
				managerId: newDivisionManagerId.trim(),
				divisionType: newDivisionType,
				organizationId: organizationId
			};
			
			await DivisionsService.create(divisionData);
			
			// Reset form
			newDivisionName = '';
			newDivisionManagerId = '';
			newDivisionType = 'retirement_home';
			
			// Reload divisions
			await loadDivisions();
			
			successMessage = 'Division created successfully!';
		} catch (err) {
			console.error('Error creating division:', err);
			error = 'Failed to create division. Please try again.';
		} finally {
			creatingDivision = false;
		}
	}

	// Delete division
	async function deleteDivision(divisionId: string) {
		if (!confirm('Are you sure you want to delete this division? This action cannot be undone.')) {
			return;
		}
		
		try {
			await DivisionsService.hardDelete(divisionId);
			await loadDivisions();
			successMessage = 'Division deleted successfully!';
		} catch (err) {
			console.error('Error deleting division:', err);
			error = 'Failed to delete division. Please try again.';
		}
	}
</script>

<div class="space-y-6 p-6">
	<div class="">
			<h1 class="text-2xl font-semibold text-gray-900">Organization Details</h1>
			<p class="text-sm text-gray-600">Organization ID: {organizationId}</p>
	</div>

	{#if loading}
		<Card class="p-6">
			<div class="flex items-center justify-center">
				<div class="text-lg">Loading organization data...</div>
			</div>
		</Card>
	{:else if !organization}
		<Card class="p-6">
			<Message type="error" message="Organization not found." />
		</Card>
	{:else}
				<!-- Messages -->
		<Message type="error" message={error || undefined} />
		<Message type="success" message={successMessage || undefined} />

		<!-- Organization JSON Editor -->
		<Card class="p-6">
			<div class="flex items-center justify-between mb-4">
				<h2 class="text-lg font-medium text-gray-900">Organization Data (JSON)</h2>
				<div class="space-x-2">
					<Button 
						variant="secondary" 
						size="sm" 
						onclick={resetChanges}
						disabled={saving}
					>
						Reset
					</Button>
					<Button 
						size="sm" 
						onclick={saveChanges}
						disabled={saving}
					>
						{saving ? 'Saving...' : 'Save Changes'}
					</Button>
				</div>
			</div>
			
			<Input
				as="textarea"
				bind:value={jsonText}
				class="w-full h-96 font-mono text-sm"
				variant="outline"
				placeholder="Organization JSON data will appear here..."
				disabled={saving}
			/>
			
			<p class="mt-2 text-xs text-gray-500">
				Edit the JSON above and click "Save Changes" to update the organization. 
				Make sure to maintain valid JSON format.
			</p>
		</Card>


    <!-- Divisions Section -->
		<Card class="p-6">
			<div class="flex items-center justify-between mb-4">
				<h2 class="text-lg font-medium text-gray-900">Divisions</h2>
				<div class="text-sm text-gray-600">
					{divisions.length} division{divisions.length !== 1 ? 's' : ''}
				</div>
			</div>
			
			<!-- Create Division Form -->
			<div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6 py-4">
				<Input
					label="Division Name"
					bind:value={newDivisionName}
					placeholder="Enter division name"
					disabled={creatingDivision}
				/>
				<Input
					label="Manager ID"
					bind:value={newDivisionManagerId}
					placeholder="Enter manager ID"
					disabled={creatingDivision}
				/>
				<Input
					as="select"
					label="Division Type"
					bind:value={newDivisionType}
					disabled={creatingDivision}
					options={[
						{ value: 'retirement_home', label: 'Retirement Home' },
						{ value: 'homecare_provider', label: 'Homecare Provider' }
					]}
				/>
				<div class="flex items-end">
					<Button 
						onclick={createDivision}
						disabled={creatingDivision || !newDivisionName.trim() || !newDivisionManagerId.trim()}
						class="w-full"
					>
						{creatingDivision ? 'Creating...' : 'Create Division'}
					</Button>
				</div>
			</div>
			
			<!-- Divisions Table -->
			{#if divisionsLoading}
				<div class="text-center py-8">
					<div class="text-gray-500">Loading divisions...</div>
				</div>
			{:else if divisions.length === 0}
				<div class="text-center py-8">
					<div class="text-gray-500">No divisions found. Create one above to get started.</div>
				</div>
			{:else}
				<Table
					data={divisions.map(division => ({
						name: { name: division.name, href: `/divisions/${division.id}` },
						'Manager ID': division.managerId,
						'Type': division.divisionType === 'retirement_home' ? 'Retirement Home' : 'Homecare Provider',
						created: new Date(division.createdAt).toLocaleDateString()
					}))}
				/>
			
			{/if}
		</Card>
	{/if}
</div>
