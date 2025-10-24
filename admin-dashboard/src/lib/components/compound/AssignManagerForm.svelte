<script lang="ts">
	import { DivisionsService } from '$lib/services';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Card from '$lib/components/Card.svelte';

	let {
		error = $bindable(),
		successMessage = $bindable(),
		constantDivisionId,
		constantManagerId,
		callback
	}: {
		error: string | null;
		successMessage: string | null;
		constantDivisionId?: string;
		constantManagerId?: string;
		callback?: () => void;
	} = $props();

	let assignDivisionId = $state(constantDivisionId || '');
	let assignManagerId = $state(constantManagerId || '');
	let loading = $state(false);

	async function handleAssignManager(event: Event) {
		event.preventDefault();
		loading = true;
		error = null;
		successMessage = null;

		if (!assignDivisionId || !assignManagerId) {
			error = 'Both Division ID and Manager ID are required';
			loading = false;
			return;
		}

		try {
			await DivisionsService.assignManager(assignDivisionId, assignManagerId);

			successMessage = 'Manager assigned to division successfully!';

			// Reset form if not constant values
			if (!constantDivisionId) assignDivisionId = '';
			if (!constantManagerId) assignManagerId = '';

			callback?.();
		} catch (err: any) {
			console.error('Error assigning manager:', err);

			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to assign managers.';
						break;
					case 'not-found':
						error = 'Division or manager not found. Please verify the IDs are correct.';
						break;
					case 'failed-precondition':
						error = 'Manager assignment failed validation. The manager must exist, belong to the same organization, and have manager role.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to assign manager. Please try again.'}`;
				}
			} else if (err.message) {
				error = err.message;
			} else {
				error = 'An unexpected error occurred while assigning the manager.';
			}
		} finally {
			loading = false;
		}
	}
</script>

<Card class="p-6">
	<h2 class="mb-4 text-lg font-medium text-gray-900">Assign Manager</h2>
	<p class="my-2 text-xs text-gray-700">
		Assign a manager to a division that doesn't have one assigned yet.
	</p>
	<form onsubmit={handleAssignManager} class="space-y-4">
		<Input
			type="text"
			placeholder="Division ID"
			size="md"
			variant="outline"
			name="assignDivisionId"
			bind:value={assignDivisionId}
			required
			disabled={loading || !!constantDivisionId}
		/>
		<Input
			type="text"
			placeholder="Manager ID"
			size="md"
			variant="outline"
			name="assignManagerId"
			bind:value={assignManagerId}
			required
			disabled={loading || !!constantManagerId}
		/>
		<Button type="submit" size="md" class="w-full" disabled={loading}>
			{loading ? 'Assigning...' : 'Assign Manager'}
		</Button>
	</form>
</Card>
