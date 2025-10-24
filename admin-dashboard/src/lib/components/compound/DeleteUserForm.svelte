<script lang="ts">
	import type { UserType } from '$lib/services/users';
	import { UsersService } from '$lib/services/users';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Card from '$lib/components/Card.svelte';

	let {
		error = $bindable(),
		successMessage = $bindable(),
		prefilledUserId,
		callback
	}: {
		error?: string;
		successMessage?: string;
		prefilledUserId?: string;
		callback?: () => void;
	} = $props();

	// Form state
	let userId = $state(prefilledUserId || '');
	let userType = $state<UserType>('provider');
	let hardDelete = $state(false);
	let loading = $state(false);

	// Update userId when prefilledUserId changes
	$effect(() => {
		if (prefilledUserId) {
			userId = prefilledUserId;
		}
	});

	async function handleSubmit(event: Event) {
		event.preventDefault();
		loading = true;
		error = '';
		successMessage = '';

		if (!userId) {
			error = 'User ID is required';
			loading = false;
			return;
		}

		if (
			!confirm(
				`Are you sure you want to ${hardDelete ? 'permanently' : 'soft'} delete this user? ${hardDelete ? 'This action cannot be undone.' : 'This can be restored later.'}`
			)
		) {
			loading = false;
			return;
		}

		try {
			if (userType === 'provider') {
				await UsersService.deleteProvider(userId, hardDelete);
			} else {
				await UsersService.deleteClient(userId, hardDelete);
			}

			successMessage = `User ${hardDelete ? 'permanently deleted' : 'soft deleted'} successfully!`;

			// Reset form
			userId = '';
			hardDelete = false;

			// Call callback if provided
			if (callback) {
				callback();
			}
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to delete user';
			console.error('Error deleting user:', err);
		} finally {
			loading = false;
		}
	}
</script>

<Card class="border-red-200 bg-red-50 p-6">
	<h2 class="mb-4 text-lg font-medium text-red-900">Delete User</h2>
	<form onsubmit={handleSubmit} class="space-y-4">
		<Input
			type="text"
			placeholder="User ID"
			size="md"
			variant="outline"
			bind:value={userId}
			required
			disabled={loading}
		/>
		<div class="space-y-2">
			<label for="deleteUserType" class="block text-sm font-medium text-red-900">User Type</label>
			<select
				id="deleteUserType"
				bind:value={userType}
				class="w-full rounded-md border border-red-300 px-3 py-2 focus:border-red-500 focus:outline-none focus:ring-1 focus:ring-red-500"
				disabled={loading}
			>
				<option value="provider">Provider</option>
				<option value="client">Resident</option>
			</select>
		</div>
		<div class="flex items-center space-x-2">
			<input
				type="checkbox"
				id="hardDelete"
				bind:checked={hardDelete}
				class="rounded"
				disabled={loading}
			/>
			<label for="hardDelete" class="text-sm text-red-900">
				Hard delete (permanently remove from Auth)
			</label>
		</div>
		<Button
			type="submit"
			size="md"
			class="w-full border-red-600 bg-red-600 text-white hover:border-red-700 hover:bg-red-700"
			disabled={loading}
		>
			{loading ? 'Deleting...' : hardDelete ? 'Permanently Delete' : 'Soft Delete'} User
		</Button>
	</form>
	<p class="mt-2 text-xs text-red-700">
		Soft delete preserves data and can be restored. Hard delete is permanent.
	</p>
</Card>
