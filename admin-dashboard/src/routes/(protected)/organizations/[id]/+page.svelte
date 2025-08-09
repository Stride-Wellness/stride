<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import Card from '$lib/components/Card.svelte';
	import Button from '$lib/components/Button.svelte';
	import Message from '$lib/components/Message.svelte';
	import Input from '$lib/components/Input.svelte';
	import { OrganizationsService } from '$lib/services/organizations';
	import type { Organization } from '$lib/services/organizations';

	const organizationId = $derived($page.params.id);

	// State
	let organization = $state<Organization | null>(null);
	let loading = $state(true);
	let saving = $state(false);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);
	let jsonText = $state('');

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
</script>

<div class="space-y-6 p-6">
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-semibold text-gray-900">Organization Details</h1>
			<p class="text-sm text-gray-600">Organization ID: {organizationId}</p>
		</div>
		<Button href="/organizations" as="a" variant="secondary" size="md">
			← Back to Organizations
		</Button>
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

		<!-- Messages -->
		<Message type="error" message={error || undefined} />
		<Message type="success" message={successMessage || undefined} />
	{/if}
</div>
