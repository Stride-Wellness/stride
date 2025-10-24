<script lang="ts">
	import { UsersService, type ProviderRole } from '$lib/services/users';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Card from '$lib/components/Card.svelte';

	let {
		error = $bindable(),
		successMessage = $bindable(),
		callback
	}: {
		error: string | null;
		successMessage: string | null;
		callback?: () => void;
	} = $props();

	const availableRoles: ProviderRole[] = ['psw', 'lw', 'admin', 'manager'];

	let createProviderEmail = $state('');
	let createProviderPassword = $state('');
	let createProviderName = $state('');
	let createProviderOrgId = $state('');
	let createProviderDivId = $state('');
	let createProviderRoles = $state<ProviderRole[]>([]);
	let createProviderLoading = $state(false);

	function toggleRole(role: ProviderRole) {
		if (createProviderRoles.includes(role)) {
			createProviderRoles = createProviderRoles.filter((r) => r !== role);
		} else {
			createProviderRoles = [...createProviderRoles, role];
		}
	}

	async function handleCreateProvider(event: Event) {
		event.preventDefault();
		createProviderLoading = true;
		error = null;
		successMessage = null;

		if (!createProviderEmail || !createProviderPassword || !createProviderName ||
			!createProviderOrgId || !createProviderDivId) {
			error = 'All fields are required';
			createProviderLoading = false;
			return;
		}

		if (!createProviderEmail.includes('@')) {
			error = 'Please enter a valid email address';
			createProviderLoading = false;
			return;
		}

		if (createProviderPassword.length < 6) {
			error = 'Password must be at least 6 characters';
			createProviderLoading = false;
			return;
		}

		if (createProviderRoles.length === 0) {
			error = 'At least one provider role is required';
			createProviderLoading = false;
			return;
		}

		try {
			await UsersService.createProvider({
				email: createProviderEmail,
				password: createProviderPassword,
				name: createProviderName,
				organizationId: createProviderOrgId,
				divisionId: createProviderDivId,
				providerRole: createProviderRoles
			});

			successMessage = 'Provider user created successfully!';

			createProviderEmail = '';
			createProviderPassword = '';
			createProviderName = '';
			createProviderOrgId = '';
			createProviderDivId = '';
			createProviderRoles = [];

			callback?.();
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to create provider user';
			console.error('Error creating provider:', err);
		} finally {
			createProviderLoading = false;
		}
	}
</script>

<Card class="p-6">
	<h2 class="mb-4 text-lg font-medium text-gray-900">Create Provider User</h2>
	<form onsubmit={handleCreateProvider} class="space-y-4">
		<Input
			type="email"
			placeholder="Email"
			size="md"
			variant="outline"
			bind:value={createProviderEmail}
			required
			disabled={createProviderLoading}
		/>
		<Input
			type="password"
			placeholder="Password (min 6 characters)"
			size="md"
			variant="outline"
			bind:value={createProviderPassword}
			required
			disabled={createProviderLoading}
		/>
		<Input
			type="text"
			placeholder="Full Name"
			size="md"
			variant="outline"
			bind:value={createProviderName}
			required
			disabled={createProviderLoading}
		/>
		<Input
			type="text"
			placeholder="Organization ID"
			size="md"
			variant="outline"
			bind:value={createProviderOrgId}
			required
			disabled={createProviderLoading}
		/>
		<Input
			type="text"
			placeholder="Division ID"
			size="md"
			variant="outline"
			bind:value={createProviderDivId}
			required
			disabled={createProviderLoading}
		/>

		<div class="space-y-2">
			<label class="block text-sm font-medium text-gray-700">Provider Roles (select at least one)</label>
			<div class="space-y-2">
				{#each availableRoles as role}
					<label class="flex items-center">
						<input
							type="checkbox"
							checked={createProviderRoles.includes(role)}
							onchange={() => toggleRole(role)}
							class="mr-2 rounded"
							disabled={createProviderLoading}
						/>
						<span class="text-sm capitalize">{role}</span>
					</label>
				{/each}
			</div>
		</div>

		<Button type="submit" size="md" class="w-full" disabled={createProviderLoading}>
			{createProviderLoading ? 'Creating...' : 'Create Provider'}
		</Button>
	</form>
</Card>
