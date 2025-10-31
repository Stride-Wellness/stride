<script lang="ts">
	import { UsersService } from '$lib/services/users';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Card from '$lib/components/Card.svelte';

	let {
		variant = 'independent',
		error = $bindable(),
		successMessage = $bindable(),
		constantEmail,
		constantPassword,
		constantName,
		constantOrganizationId,
		constantDivisionId,
		constantPhone,
		constantDateOfBirth,
		callback
	}: {
		variant?: 'independent' | 'complementary';
		error: string | null;
		successMessage: string | null;
		constantEmail?: string;
		constantPassword?: string;
		constantName?: string;
		constantOrganizationId?: string;
		constantDivisionId?: string;
		constantPhone?: string;
		constantDateOfBirth?: string;
		callback?: () => void;
	} = $props();

	let createClientEmail = $derived(constantEmail || '');
	let createClientPassword = $derived(constantPassword || '');
	let createClientName = $derived(constantName || '');
	let createClientOrgId = $derived(constantOrganizationId || '');
	let createClientDivId = $derived(constantDivisionId || '');
	let createClientPhone = $derived(constantPhone || '');
	let createClientDOB = $derived(constantDateOfBirth || '');
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

			createClientEmail = constantEmail || '';
			createClientPassword = constantPassword || '';
			createClientName = constantName || '';
			createClientOrgId = constantOrganizationId || '';
			createClientDivId = constantDivisionId || '';
			createClientPhone = constantPhone || '';
			createClientDOB = constantDateOfBirth || '';

			callback?.();
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to create resident user';
			console.error('Error creating client:', err);
		} finally {
			createClientLoading = false;
		}
	}
</script>

{#if variant === 'independent'}
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
			disabled={createClientLoading || !!constantEmail}
		/>
		<Input
			type="password"
			placeholder="Password (min 6 characters)"
			size="md"
			variant="outline"
			bind:value={createClientPassword}
			required
			disabled={createClientLoading || !!constantPassword}
		/>
		<Input
			type="text"
			placeholder="Full Name"
			size="md"
			variant="outline"
			bind:value={createClientName}
			required
			disabled={createClientLoading || !!constantName}
		/>
		<Input
			type="text"
			placeholder="Organization ID"
			size="md"
			variant="outline"
			bind:value={createClientOrgId}
			required
			disabled={createClientLoading || !!constantOrganizationId}
		/>
		<Input
			type="text"
			placeholder="Division ID"
			size="md"
			variant="outline"
			bind:value={createClientDivId}
			required
			disabled={createClientLoading || !!constantDivisionId}
		/>
		<Input
			type="tel"
			placeholder="Phone (optional)"
			size="md"
			variant="outline"
			bind:value={createClientPhone}
			disabled={createClientLoading || !!constantPhone}
		/>
		<Input
			type="date"
			placeholder="Date of Birth (optional)"
			size="md"
			variant="outline"
			bind:value={createClientDOB}
			disabled={createClientLoading || !!constantDateOfBirth}
		/>
		<Button type="submit" size="md" class="w-full" disabled={createClientLoading}>
			{createClientLoading ? 'Creating...' : 'Create Resident'}
		</Button>
	</form>
</Card>
{:else if variant === 'complementary'}
<div class="">
	<form onsubmit={handleCreateClient} class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-4 items-end">
		<Input
			type="email"
			placeholder="Email"
			size="md"
			variant="outline"
			bind:value={createClientEmail}
			required
			disabled={createClientLoading || !!constantEmail}
		/>
		<Input
			type="password"
			placeholder="Password"
			size="md"
			variant="outline"
			bind:value={createClientPassword}
			required
			disabled={createClientLoading || !!constantPassword}
		/>
		<Input
			type="text"
			placeholder="Full Name"
			size="md"
			variant="outline"
			bind:value={createClientName}
			required
			disabled={createClientLoading || !!constantName}
		/>
		<Input
			type="text"
			placeholder="Organization ID"
			size="md"
			variant="outline"
			bind:value={createClientOrgId}
			required
			disabled={createClientLoading || !!constantOrganizationId}
		/>
		<Input
			type="text"
			placeholder="Division ID"
			size="md"
			variant="outline"
			bind:value={createClientDivId}
			required
			disabled={createClientLoading || !!constantDivisionId}
		/>
		<Button type="submit" size="md" disabled={createClientLoading}>
			{createClientLoading ? 'Creating...' : 'Create'}
		</Button>
	</form>
	<p class="mt-2 text-xs text-gray-500">
		Phone and DOB can be added later. Use independent form for full options.
	</p>
</div>
{/if}
