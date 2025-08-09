<script lang="ts">
	import { page } from '$app/stores';
	import Card from '$lib/components/Card.svelte';
	import Button from '$lib/components/Button.svelte';

	const organizationId = $derived($page.params.id);
</script>

<div class="space-y-6 p-6">
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-semibold text-gray-900">Organization Details</h1>
			<p class="text-sm text-gray-600">Organization ID: {organizationId}</p>
		</div>
		<Button href="/organizations" as="a" variant="secondary" size="md">
			← Back to Organizations
		</Button>
	</div>

	<Card class="p-6">
		<h2 class="mb-4 text-lg font-medium text-gray-900">Organization Information</h2>
		<p class="text-gray-600">Details for organization {organizationId} will be displayed here.</p>
	</Card>
</div>
