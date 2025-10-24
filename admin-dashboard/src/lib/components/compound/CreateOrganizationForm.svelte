<script lang="ts">
	import { OrganizationsService, type Organization } from '$lib/services/organizations';
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
		callback?: (newOrganization: Organization) => void;
	} = $props();

	let name = $state('');
	let totalSeats = $state(10);
	let stripeUserId = $state('');
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

			name = '';
			totalSeats = 10;
			stripeUserId = '';

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

<Card class="p-6">
	<h2 class="mb-4 text-lg font-medium text-gray-900">Add New Client Organization</h2>
	<form onsubmit={handleCreateOrganization} class="grid grid-cols-1 gap-4 md:grid-cols-3">
		<Input
			type="text"
			placeholder="Organization Name"
			size="md"
			variant="outline"
			name="name"
			bind:value={name}
			required
			disabled={loading}
		/>
		<Input
			type="text"
			placeholder="Stripe User ID"
			size="md"
			variant="outline"
			name="stripeUserId"
			bind:value={stripeUserId}
			required
			disabled={loading}
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
			disabled={loading}
		/>
		<Button type="submit" size="md" class="md:col-span-3" disabled={loading}>
			{loading ? 'Creating...' : 'Create Organization'}
		</Button>
	</form>
</Card>
