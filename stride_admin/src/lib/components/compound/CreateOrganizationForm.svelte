<script lang="ts">
	import { OrganizationsService, type Organization } from '$lib/services/organizations';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Card from '$lib/components/Card.svelte';

	let {
		variant = 'independent',
		error = $bindable(),
		successMessage = $bindable(),
		constantName,
		constantStripeUserId,
		constantTotalSeats,
		callback
	}: {
		variant?: 'independent' | 'complementary';
		error: string | null;
		successMessage: string | null;
		constantName?: string;
		constantStripeUserId?: string;
		constantTotalSeats?: number;
		callback?: (newOrganization: Organization) => void;
	} = $props();

	let name = $derived(constantName || '');
	let totalSeats = $derived(constantTotalSeats || 10);
	let stripeUserId = $derived(constantStripeUserId || '');
	let loading = $state(false);

	async function handleCreateOrganization(event: Event) {
		event.preventDefault();
		loading = true;
		error = null;
		successMessage = null;

		if (!name || !stripeUserId || totalSeats < 1) {
			error = 'All fields are required and total seats must be at least 1';
			loading = false;
			return;
		}

		if (name.length < 2) {
			error = 'Organization name must be at least 2 characters';
			loading = false;
			return;
		}

		try {
			const newOrg = await OrganizationsService.create({
				name,
				totalSeats,
				stripeUserId
			});

			name = constantName || '';
			totalSeats = constantTotalSeats || 10;
			stripeUserId = constantStripeUserId || '';

			successMessage = 'Organization created successfully!';

			callback?.(newOrg);
		} catch (err) {
			console.error('Error creating organization:', err);
			error = 'Failed to create organization. Please try again.';
		} finally {
			loading = false;
		}
	}
</script>

{#if variant === 'independent'}
<Card class="p-6">
	<h2 class="mb-4 text-lg font-medium text-gray-900">Add New Client Organization</h2>
	<form onsubmit={handleCreateOrganization} class="space-y-4">
		<Input
			type="text"
			placeholder="Organization Name"
			size="md"
			variant="outline"
			name="name"
			bind:value={name}
			required
			disabled={loading || !!constantName}
		/>
		<Input
			type="text"
			placeholder="Stripe User ID"
			size="md"
			variant="outline"
			name="stripeUserId"
			bind:value={stripeUserId}
			required
			disabled={loading || !!constantStripeUserId}
		/>
		<Input
			type="number"
			placeholder="Total Seats"
			size="md"
			variant="outline"
			name="totalSeats"
			bind:value={totalSeats}
			min="1"
			required
			disabled={loading || !!constantTotalSeats}
		/>
		<Button type="submit" size="md" class="w-full" disabled={loading}>
			{loading ? 'Creating...' : 'Create Organization'}
		</Button>
	</form>
</Card>
{:else if variant === 'complementary'}
<div class="">
	<form onsubmit={handleCreateOrganization} class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 items-end">
		<Input
			type="text"
			placeholder="Organization Name"
			size="md"
			variant="outline"
			bind:value={name}
			required
			disabled={loading || !!constantName}
		/>
		<Input
			type="text"
			placeholder="Stripe User ID"
			size="md"
			variant="outline"
			bind:value={stripeUserId}
			required
			disabled={loading || !!constantStripeUserId}
		/>
		<Input
			type="number"
			placeholder="Total Seats"
			size="md"
			variant="outline"
			bind:value={totalSeats}
			min="1"
			required
			disabled={loading || !!constantTotalSeats}
		/>
		<Button type="submit" size="md" disabled={loading}>
			{loading ? 'Creating...' : 'Create'}
		</Button>
	</form>
</div>
{/if}
