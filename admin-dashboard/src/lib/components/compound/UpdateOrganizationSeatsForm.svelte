<script lang="ts">
	import { OrganizationsService } from '$lib/services/organizations';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Card from '$lib/components/Card.svelte';

	let {
		variant = 'independent',
		error = $bindable(),
		successMessage = $bindable(),
		constantOrganizationId,
		callback
	}: {
		variant?: 'independent' | 'complementary';
		error: string | null;
		successMessage: string | null;
		constantOrganizationId?: string;
		callback?: () => void;
	} = $props();

	let updateSeatsId = $derived(constantOrganizationId || '');
	let updateSeatsCount = $state(10);
	let loading = $state(false);

	async function handleUpdateSeats(event: Event) {
		event.preventDefault();
		loading = true;
		error = null;
		successMessage = null;

		if (!updateSeatsId || updateSeatsCount < 1) {
			error = 'Organization ID is required and seat count must be at least 1';
			loading = false;
			return;
		}

		try {
			await OrganizationsService.update(updateSeatsId, { totalSeats: updateSeatsCount });

			successMessage = 'Organization seats updated successfully!';

			if (!constantOrganizationId) {
				updateSeatsId = '';
				updateSeatsCount = 10;
			}

			callback?.();
		} catch (err) {
			console.error('Error updating organization seats:', err);
			error = 'Failed to update organization seats. Please try again.';
		} finally {
			loading = false;
		}
	}
</script>

{#if variant === 'independent'}
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
			disabled={loading || !!constantOrganizationId}
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
			disabled={loading}
		/>
		<Button type="submit" size="md" variant="secondary" class="w-full" disabled={loading}>
			{loading ? 'Updating...' : 'Update Seats'}
		</Button>
	</form>
</Card>
{:else if variant === 'complementary'}
<div class="">
	<form onsubmit={handleUpdateSeats} class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 items-end">
		<Input
			type="text"
			placeholder="Organization ID"
			size="md"
			variant="outline"
			bind:value={updateSeatsId}
			required
			disabled={loading || !!constantOrganizationId}
		/>
		<Input
			type="number"
			placeholder="New Total Seats"
			size="md"
			variant="outline"
			bind:value={updateSeatsCount}
			min="1"
			required
			disabled={loading}
		/>
		<Button type="submit" size="md" variant="secondary" disabled={loading}>
			{loading ? 'Updating...' : 'Update Seats'}
		</Button>
	</form>
</div>
{/if}
