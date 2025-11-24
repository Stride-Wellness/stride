<script lang="ts">
	import { OrganizationsService } from '$lib/services/organizations';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Card from '$lib/components/Card.svelte';

	let {
		error = $bindable(),
		successMessage = $bindable(),
		constantOrganizationId,
		prefilledIds,
		callback
	}: {
		error: string | null;
		successMessage: string | null;
		prefilledIds?: string[];
		constantOrganizationId?: string;
		callback?: () => void;
	} = $props();

	let deleteOrgId = $derived(constantOrganizationId || prefilledIds?.join(', ') || '');
	let softDeleteLoading = $state(false);
	let hardDeleteLoading = $state(false);

	async function handleSoftDeleteOrganization(event: Event) {
		event.preventDefault();
		softDeleteLoading = true;
		error = null;
		successMessage = null;

		if (!deleteOrgId) {
			error = 'Organization ID is required';
			softDeleteLoading = false;
			return;
		}

		if (
			!confirm(
				'Are you sure you want to soft delete this organization? This will hide it from the main view but preserve all data. You can restore it later if needed.'
			)
		) {
			softDeleteLoading = false;
			return;
		}

		try {
			const orgsToDelete = deleteOrgId.split(',').map((id) => id.trim());
			for (const id of orgsToDelete) {
				await OrganizationsService.softDelete(id);
			}

			successMessage = 'Organization soft deleted successfully! Data has been preserved and can be restored.';

			deleteOrgId = constantOrganizationId || '';

			callback?.();
		} catch (err: any) {
			console.error('Error soft deleting organization:', err);

			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to delete this organization.';
						break;
					case 'not-found':
						error = 'Organization not found. It may have already been deleted or the ID is incorrect.';
						break;
					case 'failed-precondition':
						error = 'Cannot delete organization. There may be users or divisions still associated with this organization.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to soft delete organization. Please try again.'}`;
				}
			} else if (err.message) {
				error = err.message.includes('Failed to delete organization')
					? 'Failed to soft delete organization. Please check the organization ID and try again.'
					: err.message;
			} else {
				error = 'An unexpected error occurred while soft deleting the organization.';
			}
		} finally {
			softDeleteLoading = false;
		}
	}

	async function handleDeleteOrganization(event: Event) {
		event.preventDefault();
		hardDeleteLoading = true;
		error = null;
		successMessage = null;

		if (!deleteOrgId) {
			error = 'Organization ID is required';
			hardDeleteLoading = false;
			return;
		}

		if (
			!confirm(
				'Are you sure you want to delete this organization? This action cannot be undone and will permanently remove all associated data.'
			)
		) {
			hardDeleteLoading = false;
			return;
		}

		try {
			const orgsToDelete = deleteOrgId.split(',').map((id) => id.trim());
			for (const id of orgsToDelete) {
				await OrganizationsService.hardDelete(id);
			}

			successMessage = 'Organization deleted successfully!';

			if (!constantOrganizationId) deleteOrgId = '';

			callback?.();
		} catch (err) {
			console.error('Error deleting organization:', err);
			error = 'Failed to delete organization. Please try again.';
		} finally {
			hardDeleteLoading = false;
		}
	}
</script>

<Card class="border-red-200 bg-red-50 p-6 flex flex-col justify-between">
	<div>
		<h2 class="mb-4 text-lg font-medium text-red-900">Delete Organization</h2>
		<p class="my-2 text-xs text-red-700">
			Soft delete hides the organization but preserves data. Hard delete permanently removes all data.
		</p>
	</div>
	<div class="space-y-4">
		<Input
			type="text"
			placeholder="Organization ID"
			size="md"
			variant="outline"
			name="deleteId"
			bind:value={deleteOrgId}
			required
			disabled={softDeleteLoading || hardDeleteLoading || !!constantOrganizationId}
		/>
		<Button
			type="button"
			size="md"
			class="w-full border-yellow-600 bg-yellow-600 text-white hover:border-yellow-700 hover:bg-yellow-700"
			onclick={handleSoftDeleteOrganization}
			disabled={softDeleteLoading || hardDeleteLoading}
		>
			{softDeleteLoading ? 'Soft Deleting...' : 'Soft Delete Organization (Recoverable)'}
		</Button>
		<Button
			type="button"
			size="md"
			class="w-full border-red-600 bg-red-600 text-white hover:border-red-700 hover:bg-red-700"
			onclick={handleDeleteOrganization}
			disabled={softDeleteLoading || hardDeleteLoading}
		>
			{hardDeleteLoading ? 'Hard Deleting...' : 'Hard Delete Organization (Permanent)'}
		</Button>
	</div>
</Card>
