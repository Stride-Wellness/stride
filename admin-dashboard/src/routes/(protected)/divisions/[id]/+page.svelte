<script lang="ts">
	import { onMount } from 'svelte';
	import Card from '$lib/components/Card.svelte';
	import Button from '$lib/components/Button.svelte';
	import Message from '$lib/components/Message.svelte';
	import Input from '$lib/components/Input.svelte';
	import Table from '$lib/components/Table.svelte';
	import { DivisionsService } from '$lib/services/divisions';
	import type { Division } from '$lib/services/divisions';
	import { UsersService } from '$lib/services/users';
	import type {  User } from '$lib/services/users';
	import Link from '$lib/components/Link.svelte';
	import CreateClientUserForm from '$lib/components/compound/CreateClientUserForm.svelte';
	import CreateProviderUserForm from '$lib/components/compound/CreateProviderUserForm.svelte';
	import Tabs from '$lib/components/Tabs.svelte';
	import TabPanel from '$lib/components/TabPanel.svelte';
	import { page } from '$app/state';

	const divisionId = $derived(page.params.id);
	// State
	let division = $state<Division | null>(null);
	let loading = $state(true);
	let saving = $state(false);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);
	let jsonText = $state('');

	// User state
	let providers = $state<User[]>([]);
	let clients = $state<User[]>([]);
	let providersLoading = $state(false);
	let clientsLoading = $state(false);

	let organizationId = $derived(division?.organizationId || undefined);

	// Load division data
	onMount(async () => {
		if (!divisionId) {
			error = 'No division ID provided.';
			loading = false;
			return;
		}
		try {
			division = await DivisionsService.getById(divisionId);
			if (!division) {
				error = 'Division not found.';
				loading = false;
				return;
			}

			// Remove the id field from the JSON display
			const { id, ...divisionWithoutId } = division;
			jsonText = JSON.stringify(divisionWithoutId, null, 2);

			// Load users for this division
			await loadProviders();
			await loadClients();
		} catch (err: any) {
			console.error('Error loading division:', err);

			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have access to view this division.';
						break;
					case 'not-found':
						error = 'Division not found. Please check the ID and try again.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to load division data. Please try again.'}`;
				}
			} else if (err.message) {
				if (err.message.includes('Failed to get division')) {
					error = 'Failed to load division data. Please check the ID and try again.';
				} else {
					error = err.message;
				}
			} else {
				error = 'Failed to load division data. Please check the ID and try again.';
			}
		} finally {
			loading = false;
		}
	});

	// Save changes
	async function saveChanges() {
		if (!divisionId) {
			error = 'No division ID available.';
			return;
		}

		error = null;
		successMessage = null;
		saving = true;

		try {
			// Parse the JSON
			const updatedDivisionData = JSON.parse(jsonText);

			// Update the division (the service will handle adding the ID back)
			await DivisionsService.update(divisionId, updatedDivisionData);

			// Update local state with the ID included
			division = { id: divisionId, ...updatedDivisionData };
			successMessage = 'Division updated successfully!';
		} catch (err: any) {
			console.error('Error:', err);

			// Check if it's a JSON parse error
			if (err instanceof SyntaxError) {
				error = 'Invalid JSON format. Please check your syntax and try again.';
			} else if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error =
							'Permission denied. You may not have the required permissions to update this division.';
						break;
					case 'not-found':
						error = 'Division not found. It may have been deleted or the ID is incorrect.';
						break;
					case 'invalid-argument':
						error = 'Invalid data provided. Please check all fields are correctly formatted.';
						break;
					case 'failed-precondition':
						error =
							'Update failed validation. Please ensure manager ID is valid and belongs to the organization.';
						break;
					case 'unauthenticated':
						error = 'You are not authenticated. Please log in and try again.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to update division. Please try again.'}`;
				}
			} else if (err.message) {
				if (err.message.includes('Failed to update division')) {
					error = 'Failed to update division. Please check your data and try again.';
				} else {
					error = err.message;
				}
			} else {
				error = 'Failed to update division. Please try again.';
			}
		} finally {
			saving = false;
		}
	}

	// Reset changes
	function resetChanges() {
		if (division) {
			// Remove the id field when resetting
			const { id, ...divisionWithoutId } = division;
			jsonText = JSON.stringify(divisionWithoutId, null, 2);
			error = null;
			successMessage = null;
		}
	}

	// Load providers
	async function loadProviders() {
		if (!divisionId) return;

		providersLoading = true;
		try {
			const allUsers = await UsersService.getByDivisionId(divisionId);
			providers = allUsers.filter((user) => user.type === 'provider');
		} catch (err: any) {
			console.error('Error loading providers:', err);
			// Don't set the main error state for sub-operations, just log it
			if (err.code === 'permission-denied') {
				console.warn('Permission denied loading providers for division:', divisionId);
			}
		} finally {
			providersLoading = false;
		}
	}

	// Load clients
	async function loadClients() {
		if (!divisionId) return;

		clientsLoading = true;
		try {
			const allUsers = await UsersService.getByDivisionId(divisionId);
			clients = allUsers.filter((user) => user.type === 'client');
		} catch (err: any) {
			console.error('Error loading clients:', err);
			// Don't set the main error state for sub-operations, just log it
			if (err.code === 'permission-denied') {
				console.warn('Permission denied loading clients for division:', divisionId);
			}
		} finally {
			clientsLoading = false;
		}
	}

	// Get formatted provider data for table
	const providerTableData = $derived(
		providers.map((provider) => ({
			name: { name: provider.name, href: `/users/${provider.id}` },
			email: provider.email,
			role: UsersService.isProvider(provider) ? provider.providerRole.join(', ') : '',
			status: provider.status,
			created: new Date(provider.createdAt).toLocaleDateString()
		}))
	);

	// Get formatted client data for table
	const clientTableData = $derived(
		clients.map((client) => ({
			name: { name: client.name, href: `/users/${client.id}` },
			email: client.email,
			phone: UsersService.isClient(client) ? client.profile.phone || '-' : '-',
			dateOfBirth: UsersService.isClient(client) ? client.profile.dateOfBirth || '-' : '-',
			status: client.status,
			created: new Date(client.createdAt).toLocaleDateString()
		}))
	);
</script>

<div class="space-y-6 p-6">
	<div>
		<h1 class="text-2xl font-semibold text-gray-900">Division Details</h1>
		<p class="text-sm text-gray-600">Division ID: {divisionId}</p>
		<p class="text-sm text-gray-600">
			Organization ID: <Link
				href={`/organizations/${division?.organizationId}`}
				name={division?.organizationId || 'error getting org'}
			></Link>
		</p>
	</div>
	<!-- Messages -->
	<Message type="error" message={error || undefined} />
	<Message type="success" message={successMessage || undefined} />

	<Tabs>
		<TabPanel label="Providers">
			<!-- Providers Section -->
			<Card class="p-6">
				<div class="mb-4 flex items-center justify-between">
					<h2 class="text-lg font-medium text-gray-900">Providers</h2>
					<div class="text-sm text-gray-600">
						{providers.length} provider{providers.length !== 1 ? 's' : ''}
					</div>
				</div>

				<!-- Create Provider Form -->
				<div class="mb-4">
					<CreateProviderUserForm
						variant="complementary"
						bind:error
						bind:successMessage
						callback={() => loadProviders()}
						constantDivisionId={divisionId}
						divisionIdOptions={[
							{ label: division?.name || '', value: divisionId || '' }
						]}
						constantOrganizationId={organizationId}
					/>
				</div>

				<!-- Providers Table -->
				{#if providersLoading}
					<div class="py-8 text-center">
						<div class="text-gray-500">Loading providers...</div>
					</div>
				{:else if providers.length === 0}
					<div class="py-8 text-center">
						<div class="text-gray-500">No providers found. Create one above to get started.</div>
					</div>
				{:else}
					<Table data={providerTableData} />
				{/if}
			</Card>
		</TabPanel>
		<TabPanel label="Clients">
			<!-- Clients Section -->
			<Card class="p-6">
				<div class="mb-4 flex items-center justify-between">
					<h2 class="text-lg font-medium text-gray-900">Clients</h2>
					<div class="text-sm text-gray-600">
						{clients.length} client{clients.length !== 1 ? 's' : ''}
					</div>
				</div>

				<div>
					<CreateClientUserForm
						bind:error
						bind:successMessage
						variant="complementary"
						callback={() => loadClients()}
						constantDivisionId={divisionId}
						constantOrganizationId={division?.organizationId}
					/>
				</div>

				<!-- Clients Table -->
				{#if clientsLoading}
					<div class="py-8 text-center">
						<div class="text-gray-500">Loading clients...</div>
					</div>
				{:else if clients.length === 0}
					<div class="py-8 text-center">
						<div class="text-gray-500">No clients found. Create one above to get started.</div>
					</div>
				{:else}
					<Table data={clientTableData} />
				{/if}
			</Card>
		</TabPanel>
	</Tabs>

	<Card class="p-6">
		<div class="mb-4 flex items-center justify-between">
			<h2 class="text-lg font-medium text-gray-900">Division Data (JSON)</h2>
			<div class="space-x-2">
				<Button variant="secondary" size="sm" onclick={resetChanges} disabled={saving}>
					Reset
				</Button>
				<Button size="sm" onclick={saveChanges} disabled={saving}>
					{saving ? 'Saving...' : 'Save Changes'}
				</Button>
			</div>
		</div>

		<Input
			as="textarea"
			bind:value={jsonText}
			class="h-96 w-full font-mono text-sm"
			variant="outline"
			placeholder="Division JSON data will appear here..."
			disabled={saving}
		/>

		<p class="mt-2 text-xs text-gray-500">
			Edit the JSON above and click "Save Changes" to update the division. Make sure to maintain
			valid JSON format.
		</p>
	</Card>
</div>
