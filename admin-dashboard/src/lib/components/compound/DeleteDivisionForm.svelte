<script lang="ts">
	import { DivisionsService } from '$lib/services';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Card from '$lib/components/Card.svelte';

	let {
		error = $bindable(),
		successMessage = $bindable(),
		constantDivisionId,
		callback
	}: {
		error: string | null;
		successMessage: string | null;
		constantDivisionId?: string;
		callback?: () => void;
	} = $props();

	let deleteDivisionId = $state(constantDivisionId || '');
	let softDeleteLoading = $state(false);
	let hardDeleteLoading = $state(false);

	async function handleSoftDeleteDivision(event: Event) {
		event.preventDefault();
		softDeleteLoading = true;
		error = null;
		successMessage = null;

		if (!deleteDivisionId) {
			error = 'Division ID is required';
			softDeleteLoading = false;
			return;
		}

		if (
			!confirm(
				'Are you sure you want to soft delete this division? This will hide it from the main view but preserve all data. You can restore it later if needed.'
			)
		) {
			softDeleteLoading = false;
			return;
		}

		try {
			await DivisionsService.softDelete(deleteDivisionId, false);

			successMessage = 'Division soft deleted successfully! Data has been preserved and can be restored.';

			if (!constantDivisionId) deleteDivisionId = '';

			callback?.();
		} catch (err: any) {
			console.error('Error soft deleting division:', err);

			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to delete this division.';
						break;
					case 'not-found':
						error = 'Division not found. It may have already been deleted or the ID is incorrect.';
						break;
					case 'failed-precondition':
						error = 'Cannot delete division. Please check the division ID and try again.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to soft delete division. Please try again.'}`;
				}
			} else if (err.message) {
				error = err.message.includes('Failed to delete division')
					? 'Failed to soft delete division. Please check the division ID and try again.'
					: err.message;
			} else {
				error = 'An unexpected error occurred while soft deleting the division.';
			}
		} finally {
			softDeleteLoading = false;
		}
	}

	async function handleDeleteDivision(event: Event) {
		event.preventDefault();
		hardDeleteLoading = true;
		error = null;
		successMessage = null;

		if (!deleteDivisionId) {
			error = 'Division ID is required';
			hardDeleteLoading = false;
			return;
		}

		if (
			!confirm(
				'Are you sure you want to delete this division? This action cannot be undone and will permanently remove all associated data.'
			)
		) {
			hardDeleteLoading = false;
			return;
		}

		try {
			const divisionsToDelete = deleteDivisionId.split(',').map((id) => id.trim());
			for (const id of divisionsToDelete) {
				await DivisionsService.hardDelete(id);
			}

			successMessage = 'Division deleted successfully!';

			if (!constantDivisionId) deleteDivisionId = '';

			callback?.();
		} catch (err: any) {
			console.error('Error deleting division:', err);

			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to delete this division.';
						break;
					case 'not-found':
						error = 'Division not found. It may have already been deleted or the ID is incorrect.';
						break;
					case 'failed-precondition':
						error = 'Cannot delete division. There may be users or assignments still associated with this division.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to delete division. Please try again.'}`;
				}
			} else if (err.message) {
				error = err.message.includes('Failed to permanently delete division')
					? 'Failed to delete division. Please ensure there are no users or assignments linked to this division.'
					: err.message;
			} else {
				error = 'An unexpected error occurred while deleting the division.';
			}
		} finally {
			hardDeleteLoading = false;
		}
	}
</script>

<Card class="border-red-200 bg-red-50 p-6 flex flex-col justify-between">
	<div>
		<h2 class="mb-4 text-lg font-medium text-red-900">Delete Division</h2>
		<p class="my-2 text-xs text-red-700">
			Soft delete hides the division but preserves data. Hard delete permanently removes all data.
		</p>
	</div>
	<div class="space-y-4">
		<Input
			type="text"
			placeholder="Division ID"
			size="md"
			variant="outline"
			name="deleteId"
			bind:value={deleteDivisionId}
			required
			disabled={softDeleteLoading || hardDeleteLoading || !!constantDivisionId}
		/>
		<Button
			type="button"
			size="md"
			class="w-full border-yellow-600 bg-yellow-600 text-white hover:border-yellow-700 hover:bg-yellow-700"
			onclick={handleSoftDeleteDivision}
			disabled={softDeleteLoading || hardDeleteLoading}
		>
			{softDeleteLoading ? 'Soft Deleting...' : 'Soft Delete Division (Recoverable)'}
		</Button>
		<Button
			type="button"
			size="md"
			class="w-full border-red-600 bg-red-600 text-white hover:border-red-700 hover:bg-red-700"
			onclick={handleDeleteDivision}
			disabled={softDeleteLoading || hardDeleteLoading}
		>
			{hardDeleteLoading ? 'Hard Deleting...' : 'Hard Delete Division (Permanent)'}
		</Button>
	</div>
</Card>
