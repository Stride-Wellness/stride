<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import Card from '$lib/components/Card.svelte';
	import Button from '$lib/components/Button.svelte';
	import Message from '$lib/components/Message.svelte';
	import Input from '$lib/components/Input.svelte';
	import Table from '$lib/components/Table.svelte';
	import { OrganizationsService } from '$lib/services/organizations';
	import type { Organization } from '$lib/services/organizations';
	import { DivisionsService } from '$lib/services/divisions';
	import type { Division } from '$lib/services/divisions';
	import { UsersService } from '$lib/services/users';
	import type { User, UserType } from '$lib/services/users';
	import CreateDivisionForm from '$lib/components/compound/CreateDivisionForm.svelte';
	import Tabs from '$lib/components/Tabs.svelte';
	import TabPanel from '$lib/components/TabPanel.svelte';
	import CreateProviderUserForm from '$lib/components/compound/CreateProviderUserForm.svelte';

	const organizationId = $derived($page.params.id);

	// State
	let organization = $state<Organization | null>(null);
	let divisions = $state<Division[]>([]);
	let loading = $state(true);
	let saving = $state(false);
	let divisionsLoading = $state(false);
	let usersLoading = $state(false);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);
	let jsonText = $state('');

	// User state
	let providers = $state<User[]>([]);
	let clients = $state<User[]>([]);
	let providersLoading = $state(false);
	let clientsLoading = $state(false);

	// Client form state
	let newClientName = $state('');
	let newClientEmail = $state('');
	let newClientPhone = $state('');
	let newClientPassword = $state('');
	let newClientDateOfBirth = $state('');
	let newClientDivisionId = $state('');
	let creatingClient = $state(false);

	// Load organization data
	onMount(async () => {
		if (!organizationId) {
			error = 'No organization ID provided.';
			loading = false;
			return;
		}

		try {
			organization = await OrganizationsService.getById(organizationId);
			jsonText = JSON.stringify(organization, null, 2);

			// Load divisions for this organization
			await loadDivisions();

			// Load users for this organization
			await loadProviders();
			await loadClients();
		} catch (err) {
			console.error('Error loading organization:', err);
			error = 'Failed to load organization data. Please check the ID and try again.';
		} finally {
			loading = false;
		}
	});

	// Save changes
	async function saveChanges() {
		if (!organizationId) {
			error = 'No organization ID available.';
			return;
		}

		error = null;
		successMessage = null;
		saving = true;

		try {
			// Parse the JSON
			const updatedOrg = JSON.parse(jsonText);

			// Validate that it has an ID and matches the current organization ID
			if (!updatedOrg.id || updatedOrg.id !== organizationId) {
				error = 'Invalid JSON: ID field is missing or does not match the current organization ID.';
				return;
			}

			// Update the organization
			await OrganizationsService.update(organizationId, updatedOrg);

			// Update local state
			organization = updatedOrg;
			successMessage = 'Organization updated successfully!';
		} catch (err) {
			console.error('Error:', err);

			// Check if it's a JSON parse error
			if (err instanceof SyntaxError) {
				error = 'Invalid JSON format. Please check your syntax and try again.';
			} else {
				error = 'Failed to update organization. Please try again.';
			}
		} finally {
			saving = false;
		}
	}

	// Reset changes
	function resetChanges() {
		if (organization) {
			jsonText = JSON.stringify(organization, null, 2);
			error = null;
			successMessage = null;
		}
	}

	// Load divisions
	async function loadDivisions() {
		if (!organizationId) return;

		divisionsLoading = true;
		try {
			divisions = await DivisionsService.getByOrganizationId(organizationId);
		} catch (err) {
			console.error('Error loading divisions:', err);
			// Don't set error state here, it's not critical
		} finally {
			divisionsLoading = false;
		}
	}

	// Load providers
	async function loadProviders() {
		if (!organizationId) return;

		providersLoading = true;
		try {
			const allUsers = await UsersService.getByOrganizationId(organizationId);
			providers = allUsers.filter((user) => user.type === 'provider');
		} catch (err) {
			console.error('Error loading providers:', err);
		} finally {
			providersLoading = false;
		}
	}

	// Load clients
	async function loadClients() {
		if (!organizationId) return;

		clientsLoading = true;
		try {
			const allUsers = await UsersService.getByOrganizationId(organizationId);
			clients = allUsers.filter((user) => user.type === 'client');
		} catch (err) {
			console.error('Error loading clients:', err);
		} finally {
			clientsLoading = false;
		}
	}

	// Create new client
	async function createClient() {
		if (!organizationId || !newClientName.trim() || !newClientEmail.trim() || !newClientDivisionId)
			return;

		creatingClient = true;
		error = null;

		try {
			const clientData = {
				email: newClientEmail.trim(),
				name: newClientName.trim(),
				organizationId: organizationId,
				password: newClientPassword.trim(),
				divisionId: newClientDivisionId,
				profile: {
					phone: newClientPhone.trim() || undefined,
					dateOfBirth: newClientDateOfBirth || undefined
				}
			};

			await UsersService.createClient(clientData);

			// Reset form
			newClientName = '';
			newClientEmail = '';
			newClientPhone = '';
			newClientDateOfBirth = '';
			newClientDivisionId = '';

			// Reload clients
			await loadClients();

			successMessage = 'Client created successfully!';
		} catch (err) {
			console.error('Error creating client:', err);
			error = 'Failed to create client. Please try again.';
		} finally {
			creatingClient = false;
		}
	}

	// Get division name by ID
	function getDivisionName(divisionId: string): string {
		const division = divisions.find((d) => d.id === divisionId);
		return division ? division.name : 'Unknown Division';
	}

	// Get formatted provider data for table
	const providerTableData = $derived(
		providers.map((provider) => ({
			name: { name: provider.name, href: `/users/${provider.id}` },
			email: provider.email,
			role: provider.type === 'provider' ? provider.providerRole.join(', ') : '',
			division: getDivisionName(provider.divisionId),
			status: provider.status,
			created: new Date(provider.createdAt).toLocaleDateString()
		}))
	);

	// Get formatted client data for table
	const clientTableData = $derived(
		clients.map((client) => ({
			name: { name: client.name, href: `/users/${client.id}` },
			email: client.email,
			phone: client.type === 'client' ? client.profile.phone || '-' : '-',
			division: getDivisionName(client.divisionId),
			status: client.status,
			created: new Date(client.createdAt).toLocaleDateString()
		}))
	);

	// Get division options for dropdowns
	const divisionOptions = $derived(
		divisions.map((division) => ({
			value: division.id,
			label: division.name
		}))
	);
</script>

<div class="space-y-6 p-6">
	<div class="">
		<h1 class="text-2xl font-semibold text-gray-900">Organization Details</h1>
		<p class="text-sm text-gray-600">Organization ID: {organizationId}</p>
	</div>

		<!-- Messages -->
		<Message type="error" message={error || undefined} />
		<Message type="success" message={successMessage || undefined} />
		<Tabs>
			<TabPanel label="Divisions">
				<!-- Divisions Section -->
				<Card class="p-6">
					<div class="mb-4 flex items-center justify-between">
						<h2 class="text-lg font-medium text-gray-900">Divisions</h2>
						<div class="text-sm text-gray-600">
							{divisions.length} division{divisions.length !== 1 ? 's' : ''}
						</div>
					</div>

					<div class="mb-4">
						<CreateDivisionForm
							variant="complementary"
							bind:error
							bind:successMessage
							constantOrganizationId={organizationId}
							callback={async (_) => await loadDivisions()}
						/>
					</div>

					<!-- Divisions Table -->
					{#if divisionsLoading}
						<div class="py-8 text-center">
							<div class="text-gray-500">Loading divisions...</div>
						</div>
					{:else if divisions.length === 0}
						<div class="py-8 text-center">
							<div class="text-gray-500">No divisions found. Create one above to get started.</div>
						</div>
					{:else}
						<Table
							data={divisions.map((division) => ({
								name: { name: division.name, href: `/divisions/${division.id}` },
								'Manager ID': division.managerId,
								Type:
									division.divisionType === 'retirement_home'
										? 'Retirement Home'
										: 'Homecare Provider',
								created: new Date(division.createdAt).toLocaleDateString()
							}))}
						/>
					{/if}
				</Card>
			</TabPanel>
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
							<!-- Create Provider Form -->
					
					{#key divisionOptions.length}
					<CreateProviderUserForm
						bind:error
						bind:successMessage
						variant="complementary"
						constantOrganizationId={organizationId}
						divisionIdOptions={divisionOptions}
						callback={async () => await loadProviders()}
					/>
					{/key}
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

					<!-- Create Client Form -->
					<div class="mb-6 grid grid-cols-1 gap-4 py-4 md:grid-cols-6">
						<Input
							label="Client Name"
							bind:value={newClientName}
							placeholder="Enter client name"
							disabled={creatingClient}
						/>
						<Input
							label="Email"
							bind:value={newClientEmail}
							placeholder="Enter email address"
							disabled={creatingClient}
						/>
						<Input
							label="Phone (Optional)"
							bind:value={newClientPhone}
							placeholder="Enter phone number"
							disabled={creatingClient}
						/>
						<Input
							label="Date of Birth (Optional)"
							type="date"
							bind:value={newClientDateOfBirth}
							disabled={creatingClient}
						/>
						<Input
							as="select"
							label="Division"
							bind:value={newClientDivisionId}
							disabled={creatingClient}
							options={divisionOptions}
							placeholder="Select division"
						/>
						<div class="flex items-end">
							<Button
								onclick={createClient}
								disabled={creatingClient ||
									!newClientName.trim() ||
									!newClientEmail.trim() ||
									!newClientDivisionId}
								class="w-full"
							>
								{creatingClient ? 'Creating...' : 'Create Client'}
							</Button>
						</div>
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
		<!-- Organization JSON Editor -->
		<Card class="p-6">
			<div class="mb-4 flex items-center justify-between">
				<h2 class="text-lg font-medium text-gray-900">Organization Data (JSON)</h2>
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
				placeholder="Organization JSON data will appear here..."
				disabled={saving}
			/>

			<p class="mt-2 text-xs text-gray-500">
				Edit the JSON above and click "Save Changes" to update the organization. Make sure to
				maintain valid JSON format.
			</p>
		</Card>

</div>
