<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import Card from '$lib/components/Card.svelte';
	import Button from '$lib/components/Button.svelte';
	import Message from '$lib/components/Message.svelte';
	import Input from '$lib/components/Input.svelte';
	import { DivisionsService } from '$lib/services';
	import type { Division } from '$lib/services';
	import Link from '$lib/components/Link.svelte';

	const divisionId = $derived($page.params.id);

	// State
	let division = $state<Division | null>(null);
	let loading = $state(true);
	let saving = $state(false);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);
	let jsonText = $state('');

	// Load division data
	onMount(async () => {
		if (!divisionId) {
			error = 'No division ID provided.';
			loading = false;
			return;
		}

		try {
			division = await DivisionsService.getById(divisionId);
			if (!division) {
				error = 'Division not found.';
				loading = false;
				return;
			}
			
			// Remove the id field from the JSON display
			const { id, ...divisionWithoutId } = division;
			jsonText = JSON.stringify(divisionWithoutId, null, 2);
		} catch (err) {
			console.error('Error loading division:', err);
			error = 'Failed to load division data. Please check the ID and try again.';
		} finally {
			loading = false;
		}
	});

	// Save changes
	async function saveChanges() {
		if (!divisionId) {
			error = 'No division ID available.';
			return;
		}

		error = null;
		successMessage = null;
		saving = true;

		try {
			// Parse the JSON
			const updatedDivisionData = JSON.parse(jsonText);

			// Update the division (the service will handle adding the ID back)
			await DivisionsService.update(divisionId, updatedDivisionData);

			// Update local state with the ID included
			division = { id: divisionId, ...updatedDivisionData };
			successMessage = 'Division updated successfully!';
		} catch (err) {
			console.error('Error:', err);

			// Check if it's a JSON parse error
			if (err instanceof SyntaxError) {
				error = 'Invalid JSON format. Please check your syntax and try again.';
			} else {
				error = 'Failed to update division. Please try again.';
			}
		} finally {
			saving = false;
		}
	}

	// Reset changes
	function resetChanges() {
		if (division) {
			// Remove the id field when resetting
			const { id, ...divisionWithoutId } = division;
			jsonText = JSON.stringify(divisionWithoutId, null, 2);
			error = null;
			successMessage = null;
		}
	}
</script>

<div class="space-y-6 p-6">
	<div>
		<h1 class="text-2xl font-semibold text-gray-900">Division Details</h1>
		<p class="text-sm text-gray-600">Division ID: {divisionId}</p>
    <p class="text-sm text-gray-600">Organization ID: <Link href={`/organizations/${division?.organizationId}`} name={division?.organizationId || "error getting org"}></Link></p>
	</div>

	{#if loading}
		<Card class="p-6">
			<div class="flex items-center justify-center">
				<div class="text-lg">Loading division data...</div>
			</div>
		</Card>
	{:else if !division}
		<Card class="p-6">
			<Message type="error" message="Division not found." />
		</Card>
	{:else}
		<Card class="p-6">
			<div class="mb-4 flex items-center justify-between">
				<h2 class="text-lg font-medium text-gray-900">Division Data (JSON)</h2>
				<div class="space-x-2">
					<Button variant="secondary" size="sm" onclick={resetChanges} disabled={saving}>
						Reset
					</Button>
					<Button size="sm" onclick={saveChanges} disabled={saving}>
						{saving ? 'Saving...' : 'Save Changes'}
					</Button>
				</div>
			</div>

			<Input
				as="textarea"
				bind:value={jsonText}
				class="h-96 w-full font-mono text-sm"
				variant="outline"
				placeholder="Division JSON data will appear here..."
				disabled={saving}
			/>

			<p class="mt-2 text-xs text-gray-500">
				Edit the JSON above and click "Save Changes" to update the division. Make sure to maintain
				valid JSON format.
			</p>
		</Card>

		<!-- Messages -->
		<Message type="error" message={error || undefined} />
		<Message type="success" message={successMessage || undefined} />
	{/if}
</div>
