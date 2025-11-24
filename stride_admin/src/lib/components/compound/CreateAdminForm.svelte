<script lang="ts">
	import { AdminPrivilegeLevel, AdminsService, type Admin } from '$lib/services/admins';
	import { page } from '$app/stores';
	import Table from '$lib/components/Table.svelte';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Message from '$lib/components/Message.svelte';
	import Card from '$lib/components/Card.svelte';
	import { onMount } from 'svelte';
	import Tabs from '$lib/components/Tabs.svelte';
	import TabPanel from '$lib/components/TabPanel.svelte';
	import { getPrivilegeName } from '$lib/utils';

  let {
    variant = 'independent',
    error = $bindable(),
    successMessage = $bindable(),
    constantEmail,
    constantPassword,
    constantName,
    constantPrivilege,
    callback
  }: {
    variant?: 'independent' | 'complementary';
    error: string | null;
    successMessage: string | null;
    constantEmail?: string;
    constantPassword?: string;
    constantName?: string;
    constantPrivilege?: AdminPrivilegeLevel;
    callback?: (newAdminId: string) => void;
  } = $props();

	const currentUser = $derived($page.data.user as Admin | undefined);
	const currentUserPrivilege = $derived(currentUser?.privilege ?? AdminPrivilegeLevel.DISABLED);
  
	// Create form fields
	let createEmail = $derived(constantEmail || '');
	let createPassword = $derived(constantPassword || '');
	let createName = $derived(constantName || '');
	let createPrivilege = $derived(constantPrivilege || AdminPrivilegeLevel.READ_ONLY);
	let createLoading = $state(false);
  	// Form handlers
	async function handleCreate(event: Event) {
		event.preventDefault();
		createLoading = true;
		error = '';
		successMessage = '';

		// Validation
		if (!createEmail || !createPassword || !createName) {
			error = 'All fields are required';
			createLoading = false;
			return;
		}

		if (!createEmail.includes('@')) {
			error = 'Please enter a valid email address';
			createLoading = false;
			return;
		}

		if (createPassword.length < 6) {
			error = 'Password must be at least 6 characters';
			createLoading = false;
			return;
		}

		if (!AdminsService.canModify(currentUserPrivilege, createPrivilege)) {
			error = `You cannot create admin users with privilege level ${getPrivilegeName(createPrivilege)}`;
			createLoading = false;
			return;
		}

		try {
			const adminId = await AdminsService.create({
				email: createEmail,
				password: createPassword,
				name: createName,
				privilege: createPrivilege
			});

			successMessage = 'Administrator created successfully!';

			// Reset form
			createEmail = constantEmail || '';
			createPassword = constantPassword || '';
			createName = constantName || '';
			createPrivilege = constantPrivilege || AdminPrivilegeLevel.READ_ONLY;

			// Reload admins
			callback?.(adminId);
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to create admin user';
			console.error('Error creating admin:', err);
		} finally {
			createLoading = false;
		}
	}

	// Get available privilege levels for current user
	const availablePrivilegeLevels = $derived(
		AdminsService.getAvailablePrivilegeLevels(currentUserPrivilege)
	);

</script>
  
{#if variant === 'independent'}
<!-- Create Admin -->
<Card class="p-6">
	<h2 class="mb-4 text-lg font-medium text-gray-900">Create Administrator</h2>
	<form onsubmit={handleCreate} class="space-y-4">
		<Input
			type="email"
			placeholder="Email"
			size="md"
			variant="outline"
			bind:value={createEmail}
			required
			disabled={createLoading || !!constantEmail}
		/>
		<Input
			type="password"
			placeholder="Password (min 6 characters)"
			size="md"
			variant="outline"
			bind:value={createPassword}
			required
			disabled={createLoading || !!constantPassword}
		/>
		<Input
			type="text"
			placeholder="Full Name"
			size="md"
			variant="outline"
			bind:value={createName}
			required
			disabled={createLoading || !!constantName}
		/>
		<div class="space-y-2">
			<label class="block text-sm font-medium text-gray-700">Privilege Level</label>
			<select
				bind:value={createPrivilege}
				class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
				required
				disabled={createLoading || !!constantPrivilege}
			>
				{#each availablePrivilegeLevels as level}
					<option value={level}>{getPrivilegeName(level)}</option>
				{/each}
			</select>
		</div>
		<Button type="submit" size="md" class="w-full" disabled={createLoading}>
			{createLoading ? 'Creating...' : 'Create Administrator'}
		</Button>
	</form>
</Card>
{:else if variant === 'complementary'}
<div class="">
	<form onsubmit={handleCreate} class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 items-end">
		<Input
			type="email"
			placeholder="Email"
			size="md"
			variant="outline"
			bind:value={createEmail}
			required
			disabled={createLoading || !!constantEmail}
		/>
		<Input
			type="password"
			placeholder="Password"
			size="md"
			variant="outline"
			bind:value={createPassword}
			required
			disabled={createLoading || !!constantPassword}
		/>
		<Input
			type="text"
			placeholder="Full Name"
			size="md"
			variant="outline"
			bind:value={createName}
			required
			disabled={createLoading || !!constantName}
		/>
		<select
			bind:value={createPrivilege}
			class="rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
			required
			disabled={createLoading || !!constantPrivilege}
		>
			{#each availablePrivilegeLevels as level}
				<option value={level}>{getPrivilegeName(level)}</option>
			{/each}
		</select>
		<Button type="submit" size="md" disabled={createLoading}>
			{createLoading ? 'Creating...' : 'Create'}
		</Button>
	</form>
</div>
{/if}