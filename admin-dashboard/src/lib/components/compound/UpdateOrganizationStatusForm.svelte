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

	let updateStatusId = $derived(constantOrganizationId || '');
	let updateStatus = $state<'active' | 'suspended' | 'cancelled'>('active');
	let loading = $state(false);

	async function handleUpdateStatus(event: Event) {
		event.preventDefault();
		loading = true;
		error = null;
		successMessage = null;

		if (!updateStatusId || !updateStatus) {
			error = 'Organization ID and status are required';
			loading = false;
			return;
		}

		try {
			await OrganizationsService.update(updateStatusId, { status: updateStatus });

			successMessage = 'Organization status updated successfully!';

			if (!constantOrganizationId) {
				updateStatusId = '';
				updateStatus = 'active';
			}

			callback?.();
		} catch (err) {
			console.error('Error updating organization status:', err);
			error = 'Failed to update organization status. Please try again.';
		} finally {
			loading = false;
		}
	}
</script>

{#if variant === 'independent'}
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
			disabled={loading || !!constantOrganizationId}
		/>
		<select
			bind:value={updateStatus}
			class="w-full rounded-md border border-gray-300 px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
			required
			disabled={loading}
		>
			<option value="active">Active</option>
			<option value="suspended">Suspended</option>
			<option value="cancelled">Cancelled</option>
		</select>
		<Button type="submit" size="md" variant="secondary" class="w-full" disabled={loading}>
			{loading ? 'Updating...' : 'Update Status'}
		</Button>
	</form>
</Card>
{:else if variant === 'complementary'}
<div class="">
	<form onsubmit={handleUpdateStatus} class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 items-end">
		<Input
			type="text"
			placeholder="Organization ID"
			size="md"
			variant="outline"
			bind:value={updateStatusId}
			required
			disabled={loading || !!constantOrganizationId}
		/>
		<select
			bind:value={updateStatus}
			class="rounded-md border border-gray-300 px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
			required
			disabled={loading}
		>
			<option value="active">Active</option>
			<option value="suspended">Suspended</option>
			<option value="cancelled">Cancelled</option>
		</select>
		<Button type="submit" size="md" variant="secondary" disabled={loading}>
			{loading ? 'Updating...' : 'Update Status'}
		</Button>
	</form>
</div>
{/if}
