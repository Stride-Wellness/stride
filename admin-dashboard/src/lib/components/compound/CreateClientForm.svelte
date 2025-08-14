<script lang="ts">
	import type {
		User,
		ClientUser,
		UserType,
		UserStatus
	} from '$lib/services/users';
	import { UsersService } from '$lib/services/users';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Card from '$lib/components/Card.svelte';

	let {
		variant = 'independent',
		error = $bindable(),
		successMessage = $bindable(),
		constantEmail,
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
		constantName?: string;
		constantOrganizationId?: string;
		constantDivisionId?: string;
		constantPhone?: string;
		constantDateOfBirth?: string;
		callback?: (newUser: User) => void;
	} = $props();

	// Form state for creating client users
	let clientName = $state(constantName);
	let clientEmail = $state(constantEmail);
	let clientOrganizationId = $state(constantOrganizationId);
	let clientDivisionId = $state(constantDivisionId);
	let clientPhone = $state(constantPhone);
	let clientDateOfBirth = $state(constantDateOfBirth);

	// Handle create client user
	async function handleCreateClient(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!clientName || !clientEmail || !clientOrganizationId || !clientDivisionId) {
			error = 'Name, email, organization ID, and division ID are required';
			return;
		}

		if (clientName.length < 2) {
			error = 'Name must be at least 2 characters';
			return;
		}

		try {
			const profile =
				clientPhone || clientDateOfBirth
					? {
							...(clientPhone && { phone: clientPhone }),
							...(clientDateOfBirth && { dateOfBirth: clientDateOfBirth })
						}
					: undefined;

			const newUser = await UsersService.createClient({
				name: clientName,
				email: clientEmail,
				organizationId: clientOrganizationId,
				divisionId: clientDivisionId,
				profile
			});

			// Reset form
			clientName = '';
			clientEmail = '';
			clientOrganizationId = '';
			clientDivisionId = '';
			clientPhone = '';
			clientDateOfBirth = '';

			// Update local state - use spread to trigger reactivity
			callback?.(newUser);
			successMessage = 'Client user created successfully!';
		} catch (err) {
			console.error('Error creating client user:', err);
			error = 'Failed to create client user. Please try again.';
		}
	}
</script>

{#if variant === 'independent'}
<!-- Create Client Form -->
<Card class="p-6">
	<h2>Add New Client</h2>
	<form onsubmit={handleCreateClient} class="space-y-4">
		<Input
			type="text"
			placeholder="Client Name"
			size="md"
			variant="outline"
			bind:value={clientName}
			disabled={constantName}
			required
		/>

		<Input
			type="email"
			placeholder="Client Email"
			size="md"
			variant="outline"
			bind:value={clientEmail}
			disabled={constantEmail}
			required
		/>

		<Input
			type="text"
			placeholder="Organization ID"
			size="md"
			variant="outline"
			bind:value={clientOrganizationId}
			disabled={constantOrganizationId}
			required
		/>

		<Input
			type="text"
			placeholder="Division ID"
			size="md"
			variant="outline"
			bind:value={clientDivisionId}
			disabled={constantDivisionId}
			required
		/>

		<Input
			type="tel"
			placeholder="Phone (optional)"
			size="md"
			variant="outline"
			bind:value={clientPhone}
			disabled={constantPhone}
		/>

		<Input
			type="date"
			placeholder="Date of Birth (optional)"
			size="md"
			variant="outline"
			bind:value={clientDateOfBirth}
			disabled={constantDateOfBirth}
		/>

		<Button type="submit" size="md" class="w-full">Create Client</Button>
	</form>
</Card>
{:else if variant === 'complementary'}
<!-- Complementary Client Form (for table top) -->
<div class="">
	<form onsubmit={handleCreateClient} class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-7 gap-4 items-end">
		<Input
			type="text"
			placeholder="Client Name"
			size="md"
			variant="outline"
			bind:value={clientName}
			disabled={constantName}
			required
		/>
		
		<Input
			type="email"
			placeholder="Client Email"
			size="md"
			variant="outline"
			bind:value={clientEmail}
			disabled={constantEmail}
			required
		/>
		
		<Input
			type="text"
			placeholder="Organization ID"
			size="md"
			variant="outline"
			bind:value={clientOrganizationId}
			disabled={constantOrganizationId}
			required
		/>
		
		<Input
			type="text"
			placeholder="Division ID"
			size="md"
			variant="outline"
			bind:value={clientDivisionId}
			disabled={constantDivisionId}
			required
		/>
		
		<Input
			type="tel"
			placeholder="Phone"
			size="md"
			variant="outline"
			bind:value={clientPhone}
			disabled={constantPhone}
		/>
		
		<Input
			type="date"
			placeholder="Date of Birth"
			size="md"
			variant="outline"
			bind:value={clientDateOfBirth}
			disabled={constantDateOfBirth}
		/>
		
		<Button type="submit" size="md" class="lg:col-span-1">Add Client</Button>
	</form>
</div>
{/if}
