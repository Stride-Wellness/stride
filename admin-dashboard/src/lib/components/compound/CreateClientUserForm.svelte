<script lang="ts">
	import { UsersService } from '$lib/services/users';
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

	let createClientEmail = $state('');
	let createClientPassword = $state('');
	let createClientName = $state('');
	let createClientOrgId = $state('');
	let createClientDivId = $state('');
	let createClientPhone = $state('');
	let createClientDOB = $state('');
	let createClientLoading = $state(false);

	async function handleCreateClient(event: Event) {
		event.preventDefault();
		createClientLoading = true;
		error = null;
		successMessage = null;

		if (!createClientEmail || !createClientPassword || !createClientName ||
			!createClientOrgId || !createClientDivId) {
			error = 'Email, password, name, organization, and division are required';
			createClientLoading = false;
			return;
		}

		if (!createClientEmail.includes('@')) {
			error = 'Please enter a valid email address';
			createClientLoading = false;
			return;
		}

		if (createClientPassword.length < 6) {
			error = 'Password must be at least 6 characters';
			createClientLoading = false;
			return;
		}

		try {
			await UsersService.createClient({
				email: createClientEmail,
				password: createClientPassword,
				name: createClientName,
				organizationId: createClientOrgId,
				divisionId: createClientDivId,
				phone: createClientPhone || undefined,
				dateOfBirth: createClientDOB || undefined
			});

			successMessage = 'Resident user created successfully!';

			createClientEmail = '';
			createClientPassword = '';
			createClientName = '';
			createClientOrgId = '';
			createClientDivId = '';
			createClientPhone = '';
			createClientDOB = '';

			callback?.();
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to create resident user';
			console.error('Error creating client:', err);
		} finally {
			createClientLoading = false;
		}
	}
</script>

<Card class="p-6">
	<h2 class="mb-4 text-lg font-medium text-gray-900">Create Resident User</h2>
	<form onsubmit={handleCreateClient} class="space-y-4">
		<Input
			type="email"
			placeholder="Email"
			size="md"
			variant="outline"
			bind:value={createClientEmail}
			required
			disabled={createClientLoading}
		/>
		<Input
			type="password"
			placeholder="Password (min 6 characters)"
			size="md"
			variant="outline"
			bind:value={createClientPassword}
			required
			disabled={createClientLoading}
		/>
		<Input
			type="text"
			placeholder="Full Name"
			size="md"
			variant="outline"
			bind:value={createClientName}
			required
			disabled={createClientLoading}
		/>
		<Input
			type="text"
			placeholder="Organization ID"
			size="md"
			variant="outline"
			bind:value={createClientOrgId}
			required
			disabled={createClientLoading}
		/>
		<Input
			type="text"
			placeholder="Division ID"
			size="md"
			variant="outline"
			bind:value={createClientDivId}
			required
			disabled={createClientLoading}
		/>
		<Input
			type="tel"
			placeholder="Phone (optional)"
			size="md"
			variant="outline"
			bind:value={createClientPhone}
			disabled={createClientLoading}
		/>
		<Input
			type="date"
			placeholder="Date of Birth (optional)"
			size="md"
			variant="outline"
			bind:value={createClientDOB}
			disabled={createClientLoading}
		/>
		<Button type="submit" size="md" class="w-full" disabled={createClientLoading}>
			{createClientLoading ? 'Creating...' : 'Create Resident'}
		</Button>
	</form>
</Card>
