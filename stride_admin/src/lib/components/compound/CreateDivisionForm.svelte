<script lang="ts">
	import type { Division } from '$lib/services';
	import { DivisionsService } from '$lib/services';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Card from '$lib/components/Card.svelte';
	import { enhance } from '$app/forms';

	let {
		variant = 'independent',
		error = $bindable(),
		successMessage = $bindable(),
		constantName,
		constantOrganizationId,
		constantManagerId,
		constantDivisionType,
		callback
	}: {
		variant?: 'independent' | 'complementary';
		error: string | null;
		successMessage: string | null;
		constantName?: string;
		constantOrganizationId?: string;
		constantManagerId?: string;
		constantDivisionType?: 'retirement_home' | 'homecare_provider';
		callback?: (newDivision: Division) => void;
	} = $props();

	// Form state for creating divisions
	let name = $derived(constantName);
	let organizationId = $derived(constantOrganizationId || '');
	let managerId = $derived(constantManagerId || '');
	let divisionType = $state<'retirement_home' | 'homecare_provider'>(constantDivisionType || 'retirement_home');

	// Handle create division
	async function handleCreateDivision(event: Event) {
		event.preventDefault();

		// Clear previous messages
		error = null;
		successMessage = null;

		// Validation
		if (!name || !organizationId) {
			error = 'Name and Organization ID are required';
			return;
		}

		if (name.length < 2) {
			error = 'Division name must be at least 2 characters';
			return;
		}

		try {
			const newDivision = await DivisionsService.create({
				name,
				organizationId,
				managerId: managerId || null, // Allow empty manager ID
				divisionType
			});

			// Reset form
			name = constantName || '';
			organizationId = constantOrganizationId || '';
			managerId = constantManagerId || '';
			divisionType = constantDivisionType || 'retirement_home';

			// Update local state - use spread to trigger reactivity
			callback?.(newDivision);
			successMessage = 'Division created successfully!';
		} catch (err: any) {
			console.error('Error creating division:', err);
			
			// Parse specific Firebase/Firestore errors
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions or the organization/manager may not exist.';
						break;
					case 'not-found':
						error = 'Organization or manager not found. Please verify the IDs are correct.';
						break;
					case 'already-exists':
						error = 'A division with this name already exists in the organization.';
						break;
					case 'invalid-argument':
						error = 'Invalid data provided. Please check all fields are correctly filled.';
						break;
					case 'failed-precondition':
						error = 'Division creation failed validation. The manager must exist, belong to the organization, and have manager role.';
						break;
					case 'resource-exhausted':
						error = 'Too many requests. Please wait a moment and try again.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to create division. Please try again.'}`;
				}
			} else if (err.message) {
				// Handle generic errors from the service
				if (err.message.includes('Failed to create division')) {
					error = 'Failed to create division. Please verify the organization and manager IDs exist and try again.';
				} else {
					error = err.message;
				}
			} else {
				error = 'An unexpected error occurred. Please try again.';
			}
		}
	}
</script>

{#if variant === 'independent'}
<!-- Create Division Form -->
<Card class="p-6">
	<h2>Add New Division</h2>
	<p class="mb-4 text-sm text-gray-600">
		You can create a division without a manager and assign one later, or specify a manager ID if you already have one.
	</p>
	<form onsubmit={handleCreateDivision} class="space-y-4">
		<Input
			type="text"
			placeholder="Division Name"
			size="md"
			variant="outline"
			bind:value={name}
			disabled={constantName}
			required
		/>

		<Input
			type="text"
			placeholder="Organization ID"
			size="md"
			variant="outline"
			bind:value={organizationId}
			disabled={constantOrganizationId}
			required
		/>

		<Input
			type="text"
			placeholder="Manager ID (optional - can be assigned later)"
			size="md"
			variant="outline"
			bind:value={managerId}
			disabled={constantManagerId}
		/>

		<Input
			as="select"
			variant="outline"
			bind:value={divisionType}
			disabled={constantDivisionType}
			required
		>
			<option value="retirement_home">Retirement Home</option>
			<option value="homecare_provider">Homecare Provider</option>
		</Input>

		<Button type="submit" size="md" class="w-full">Create Division</Button>
	</form>
</Card>
{:else if variant === 'complementary'}
<!-- Complementary Division Form (for table top) -->
<div class="">
	<form onsubmit={handleCreateDivision} class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 items-end">
		<Input
			type="text"
			placeholder="Division Name"
			size="md"
			variant="outline"
			bind:value={name}
			disabled={constantName}
			required
		/>
		
		<Input
			type="text"
			placeholder="Organization ID"
			size="md"
			variant="outline"
			bind:value={organizationId}
			disabled={constantOrganizationId}
			required
		/>
		
		<Input
			type="text"
			placeholder="Manager ID"
			size="md"
			variant="outline"
			bind:value={managerId}
			disabled={constantManagerId}
		/>
		
		<Input
			as="select"
			variant="outline"
			bind:value={divisionType}
			disabled={constantDivisionType}
			required
		>
			<option value="retirement_home">Retirement Home</option>
			<option value="homecare_provider">Homecare Provider</option>
		</Input>
		
		<Button type="submit" size="md" class="lg:col-span-1">Add Division</Button>
	</form>
</div>
{/if}
