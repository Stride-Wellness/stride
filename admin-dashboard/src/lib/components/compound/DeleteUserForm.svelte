<script lang="ts">
	import type { UserType } from '$lib/services/users';
	import { UsersService } from '$lib/services/users';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Card from '$lib/components/Card.svelte';

	let {
		error = $bindable(),
		successMessage = $bindable(),
		prefilledIds,
		constantUserId,
		callback
	}: {
		error?: string;
		prefilledIds?: string[];
		successMessage?: string;
		constantUserId?: string;
		callback?: () => void;
	} = $props();

	// Form state
	let userId = $derived(constantUserId || prefilledIds?.join(', ') || '');
	let userType = $state<UserType>('provider');
	let softDeleteLoading = $state(false);
	let hardDeleteLoading = $state(false);

	// Update userId when prefilledUserId changes
	$effect(() => {
		if (constantUserId) {
			userId = constantUserId;
		}
	});

	async function handleSoftDelete(event: Event) {
		event.preventDefault();
		softDeleteLoading = true;
		error = '';
		successMessage = '';

		if (!userId) {
			error = 'User ID is required';
			softDeleteLoading = false;
			return;
		}

		if (
			!confirm(
				'Are you sure you want to soft delete this user? This will hide them from the main view but preserve all data. You can restore it later if needed.'
			)
		) {
			softDeleteLoading = false;
			return;
		}

		try {
			await UsersService.delete(userId, false);

			successMessage = 'User soft deleted successfully! Data has been preserved and can be restored.';

			// Reset form

				userId = constantUserId || '';
			

			// Call callback if provided
			if (callback) {
				callback();
			}
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to soft delete user';
			console.error('Error soft deleting user:', err);
		} finally {
			softDeleteLoading = false;
		}
	}

	async function handleHardDelete(event: Event) {
		event.preventDefault();
		hardDeleteLoading = true;
		error = '';
		successMessage = '';

		if (!userId) {
			error = 'User ID is required';
			hardDeleteLoading = false;
			return;
		}

		if (
			!confirm(
				'Are you sure you want to permanently delete this user? This action cannot be undone and will permanently remove all associated data from both Firestore and Authentication.'
			)
		) {
			hardDeleteLoading = false;
			return;
		}

		try {
			await UsersService.delete(userId, true);

			successMessage = 'User permanently deleted successfully!';

			// Reset form

				userId = constantUserId || '';


			// Call callback if provided
			if (callback) {
				callback();
			}
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to permanently delete user';
			console.error('Error permanently deleting user:', err);
		} finally {
			hardDeleteLoading = false;
		}
	}
</script>

<Card class="border-red-200 bg-red-50 p-6 flex flex-col justify-between">
	<div>
		<h2 class="mb-4 text-lg font-medium text-red-900">Delete User</h2>
		<p class="my-2 text-xs text-red-700">
			Soft delete hides the user but preserves data. Hard delete permanently removes all data.
		</p>
	</div>
	<div class="space-y-4">
		<Input
			type="text"
			placeholder="User ID"
			size="md"
			variant="outline"
			bind:value={userId}
			required
			disabled={softDeleteLoading || hardDeleteLoading || !!constantUserId}
		/>

		<Button
			type="button"
			size="md"
			class="w-full border-yellow-600 bg-yellow-600 text-white hover:border-yellow-700 hover:bg-yellow-700"
			onclick={handleSoftDelete}
			disabled={softDeleteLoading || hardDeleteLoading}
		>
			{softDeleteLoading ? 'Soft Deleting...' : 'Soft Delete User (Recoverable)'}
		</Button>
		<Button
			type="button"
			size="md"
			class="w-full border-red-600 bg-red-600 text-white hover:border-red-700 hover:bg-red-700"
			onclick={handleHardDelete}
			disabled={softDeleteLoading || hardDeleteLoading}
		>
			{hardDeleteLoading ? 'Hard Deleting...' : 'Hard Delete User (Permanent)'}
		</Button>
	</div>
</Card>
