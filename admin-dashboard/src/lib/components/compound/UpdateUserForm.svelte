<script lang="ts">
	import { UsersService, type UserStatus } from '$lib/services/users';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Card from '$lib/components/Card.svelte';

	let {
		error = $bindable(),
		successMessage = $bindable(),
		constantUserId,
		callback
	}: {
		error: string | null;
		successMessage: string | null;
		constantUserId?: string;
		callback?: () => void;
	} = $props();

	let updateUserId = $state(constantUserId || '');
	let updateName = $state('');
	let updateStatus = $state<UserStatus | ''>('');
	let updateUserType = $state<'provider' | 'client'>('provider');
	let updateLoading = $state(false);

	async function handleUpdate(event: Event) {
		event.preventDefault();
		updateLoading = true;
		error = null;
		successMessage = null;

		if (!updateUserId) {
			error = 'User ID is required';
			updateLoading = false;
			return;
		}

		if (!updateName && !updateStatus) {
			error = 'No fields to update';
			updateLoading = false;
			return;
		}

		try {
			const status = updateStatus !== '' ? updateStatus : undefined;

			if (updateUserType === 'provider') {
				await UsersService.updateProvider({
					userId: updateUserId,
					name: updateName || undefined,
					status
				});
			} else {
				await UsersService.updateClient({
					userId: updateUserId,
					name: updateName || undefined,
					status
				});
			}

			successMessage = 'User updated successfully!';

			if (!constantUserId) {
				updateUserId = '';
				updateName = '';
				updateStatus = '';
			}

			callback?.();
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to update user';
			console.error('Error updating user:', err);
		} finally {
			updateLoading = false;
		}
	}
</script>

<Card class="p-6">
	<h2 class="mb-4 text-lg font-medium text-gray-900">Update User</h2>
	<form onsubmit={handleUpdate} class="space-y-4">
		<Input
			type="text"
			placeholder="User ID"
			size="md"
			variant="outline"
			bind:value={updateUserId}
			required
			disabled={updateLoading || !!constantUserId}
		/>
		<div class="space-y-2">
			<label class="block text-sm font-medium text-gray-700">User Type</label>
			<select
				bind:value={updateUserType}
				class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
				disabled={updateLoading}
			>
				<option value="provider">Provider</option>
				<option value="client">Resident</option>
			</select>
		</div>
		<Input
			type="text"
			placeholder="New Name (optional)"
			size="md"
			variant="outline"
			bind:value={updateName}
			disabled={updateLoading}
		/>
		<div class="space-y-2">
			<label class="block text-sm font-medium text-gray-700">Status (optional)</label>
			<select
				bind:value={updateStatus}
				class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
				disabled={updateLoading}
			>
				<option value="">-- No Change --</option>
				<option value="active">Active</option>
				<option value="inactive">Inactive</option>
				<option value="pending">Pending</option>
			</select>
		</div>
		<Button type="submit" size="md" class="w-full" disabled={updateLoading}>
			{updateLoading ? 'Updating...' : 'Update User'}
		</Button>
	</form>
	{#if !constantUserId}
		<p class="mt-2 text-xs text-gray-500">
			Select a user from the table below to auto-fill the ID and type.
		</p>
	{/if}
</Card>
