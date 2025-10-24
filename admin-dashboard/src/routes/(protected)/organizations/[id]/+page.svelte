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
	
	// Division form state
	let newDivisionName = $state('');
	let newDivisionManagerId = $state('');
	let newDivisionType = $state<'retirement_home' | 'homecare_provider'>('retirement_home');
	let creatingDivision = $state(false);

	// User state
	let providers = $state<User[]>([]);
	let clients = $state<User[]>([]);
	let providersLoading = $state(false);
	let clientsLoading = $state(false);
	
	// Provider form state
	let newProviderName = $state('');
	let newProviderEmail = $state('');
	let newProviderRole = $state<string>('psw');
	let newProviderDivisionId = $state('');
	let creatingProvider = $state(false);
	
	// Client form state
	let newClientName = $state('');
	let newClientEmail = $state('');
	let newClientPhone = $state('');
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


	// Delete division
	async function deleteDivision(divisionId: string) {
		if (!confirm('Are you sure you want to delete this division? This action cannot be undone.')) {
			return;
		}
		
		try {
			await DivisionsService.hardDelete(divisionId);
			await loadDivisions();
			successMessage = 'Division deleted successfully!';
		} catch (err) {
			console.error('Error deleting division:', err);
			error = 'Failed to delete division. Please try again.';
		}
	}

	// Load providers
	async function loadProviders() {
		if (!organizationId) return;
		
		providersLoading = true;
		try {
			const allUsers = await UsersService.getByOrganizationId(organizationId);
			providers = allUsers.filter(user => user.type === 'provider');
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
			clients = allUsers.filter(user => user.type === 'client');
		} catch (err) {
			console.error('Error loading clients:', err);
		} finally {
			clientsLoading = false;
		}
	}

	// Create new provider
	async function createProvider() {
		if (!organizationId || !newProviderName.trim() || !newProviderEmail.trim() || !newProviderDivisionId) return;
		
		creatingProvider = true;
		error = null;
		
		try {
			const providerData = {
				email: newProviderEmail.trim(),
				name: newProviderName.trim(),
				organizationId: organizationId,
				divisionId: newProviderDivisionId,
				providerRole: [newProviderRole as any]
			};
			
			await UsersService.createProvider(providerData);
			
			// Reset form
			newProviderName = '';
			newProviderEmail = '';
			newProviderRole = 'psw';
			newProviderDivisionId = '';
			
			// Reload providers
			await loadProviders();
			
			successMessage = 'Provider created successfully!';
		} catch (err) {
			console.error('Error creating provider:', err);
			error = 'Failed to create provider. Please try again.';
		} finally {
			creatingProvider = false;
		}
	}

	// Create new client
	async function createClient() {
		if (!organizationId || !newClientName.trim() || !newClientEmail.trim() || !newClientDivisionId) return;
		
		creatingClient = true;
		error = null;
		
		try {
			const clientData = {
				email: newClientEmail.trim(),
				name: newClientName.trim(),
				organizationId: organizationId,
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

	// Delete provider
	async function deleteProvider(userId: string) {
		if (!confirm('Are you sure you want to delete this provider? This action cannot be undone.')) {
			return;
		}
		
		try {
			await UsersService.hardDelete(userId);
			await loadProviders();
			successMessage = 'Provider deleted successfully!';
		} catch (err) {
			console.error('Error deleting provider:', err);
			error = 'Failed to delete provider. Please try again.';
		}
	}

	// Delete client
	async function deleteClient(userId: string) {
		if (!confirm('Are you sure you want to delete this client? This action cannot be undone.')) {
			return;
		}
		
		try {
			await UsersService.hardDelete(userId);
			await loadClients();
			successMessage = 'Client deleted successfully!';
		} catch (err) {
			console.error('Error deleting client:', err);
			error = 'Failed to delete client. Please try again.';
		}
	}

	// Get division name by ID
	function getDivisionName(divisionId: string): string {
		const division = divisions.find(d => d.id === divisionId);
		return division ? division.name : 'Unknown Division';
	}

	// Get formatted provider data for table
	const providerTableData = $derived(providers.map(provider => ({
		name: { name: provider.name, href: `/users/${provider.id}` },
		email: provider.email,
		role: provider.type === 'provider' ? provider.providerRole.join(', ') : '',
		division: getDivisionName(provider.divisionId),
		status: provider.status,
		created: new Date(provider.createdAt).toLocaleDateString()
	})));

	// Get formatted client data for table
	const clientTableData = $derived(clients.map(client => ({
		name: { name: client.name, href: `/users/${client.id}` },
		email: client.email,
		phone: client.type === 'client' ? client.profile.phone || '-' : '-',
		division: getDivisionName(client.divisionId),
		status: client.status,
		created: new Date(client.createdAt).toLocaleDateString()
	})));

	// Get division options for dropdowns
	const divisionOptions = $derived(divisions.map(division => ({
		value: division.id,
		label: division.name
	})));
</script>

<div class="space-y-6 p-6">
	<div class="">
			<h1 class="text-2xl font-semibold text-gray-900">Organization Details</h1>
			<p class="text-sm text-gray-600">Organization ID: {organizationId}</p>
	</div>

	{#if loading}
		<Card class="p-6">
			<div class="flex items-center justify-center">
				<div class="text-lg">Loading organization data...</div>
			</div>
		</Card>
	{:else if !organization}
		<Card class="p-6">
			<Message type="error" message="Organization not found." />
		</Card>
	{:else}
				<!-- Messages -->
		<Message type="error" message={error || undefined} />
		<Message type="success" message={successMessage || undefined} />

		<!-- Organization JSON Editor -->
		<Card class="p-6">
			<div class="flex items-center justify-between mb-4">
				<h2 class="text-lg font-medium text-gray-900">Organization Data (JSON)</h2>
				<div class="space-x-2">
					<Button 
						variant="secondary" 
						size="sm" 
						onclick={resetChanges}
						disabled={saving}
					>
						Reset
					</Button>
					<Button 
						size="sm" 
						onclick={saveChanges}
						disabled={saving}
					>
						{saving ? 'Saving...' : 'Save Changes'}
					</Button>
				</div>
			</div>
			
			<Input
				as="textarea"
				bind:value={jsonText}
				class="w-full h-96 font-mono text-sm"
				variant="outline"
				placeholder="Organization JSON data will appear here..."
				disabled={saving}
			/>
			
			<p class="mt-2 text-xs text-gray-500">
				Edit the JSON above and click "Save Changes" to update the organization. 
				Make sure to maintain valid JSON format.
			</p>
		</Card>


    <!-- Divisions Section -->
		<Card class="p-6">
			<div class="flex items-center justify-between mb-4">
				<h2 class="text-lg font-medium text-gray-900">Divisions</h2>
				<div class="text-sm text-gray-600">
					{divisions.length} division{divisions.length !== 1 ? 's' : ''}
				</div>
			</div>

			<div class="mb-4">
				<CreateDivisionForm variant="complementary" bind:error bind:successMessage constantOrganizationId={organizationId} callback={async (_) => await loadDivisions()} />
			</div>

			<!-- Divisions Table -->
			{#if divisionsLoading}
				<div class="text-center py-8">
					<div class="text-gray-500">Loading divisions...</div>
				</div>
			{:else if divisions.length === 0}
				<div class="text-center py-8">
					<div class="text-gray-500">No divisions found. Create one above to get started.</div>
				</div>
			{:else}
				<Table
					data={divisions.map(division => ({
						name: { name: division.name, href: `/divisions/${division.id}` },
						'Manager ID': division.managerId,
						'Type': division.divisionType === 'retirement_home' ? 'Retirement Home' : 'Homecare Provider',
						created: new Date(division.createdAt).toLocaleDateString()
					}))}
				/>
			
			{/if}
		</Card>

		<!-- Providers Section -->
		<Card class="p-6">
			<div class="flex items-center justify-between mb-4">
				<h2 class="text-lg font-medium text-gray-900">Providers</h2>
				<div class="text-sm text-gray-600">
					{providers.length} provider{providers.length !== 1 ? 's' : ''}
				</div>
			</div>
			
			<!-- Create Provider Form -->
			<div class="grid grid-cols-1 md:grid-cols-5 gap-4 mb-6 py-4">
				<Input
					label="Provider Name"
					bind:value={newProviderName}
					placeholder="Enter provider name"
					disabled={creatingProvider}
				/>
				<Input
					label="Email"
					bind:value={newProviderEmail}
					placeholder="Enter email address"
					disabled={creatingProvider}
				/>
				<Input
					as="select"
					label="Provider Role"
					bind:value={newProviderRole}
					disabled={creatingProvider}
					options={[
						{ value: 'psw', label: 'PSW' },
						{ value: 'lw', label: 'LW' },
						{ value: 'admin', label: 'Admin' },
						{ value: 'manager', label: 'Manager' }
					]}
				/>
				<Input
					as="select"
					label="Division"
					bind:value={newProviderDivisionId}
					disabled={creatingProvider}
					options={divisionOptions}
					placeholder="Select division"
				/>
				<div class="flex items-end">
					<Button 
						onclick={createProvider}
						disabled={creatingProvider || !newProviderName.trim() || !newProviderEmail.trim() || !newProviderDivisionId}
						class="w-full"
					>
						{creatingProvider ? 'Creating...' : 'Create Provider'}
					</Button>
				</div>
			</div>
			
			<!-- Providers Table -->
			{#if providersLoading}
				<div class="text-center py-8">
					<div class="text-gray-500">Loading providers...</div>
				</div>
			{:else if providers.length === 0}
				<div class="text-center py-8">
					<div class="text-gray-500">No providers found. Create one above to get started.</div>
				</div>
			{:else}
				<Table data={providerTableData} />
			{/if}
		</Card>

		<!-- Clients Section -->
		<Card class="p-6">
			<div class="flex items-center justify-between mb-4">
				<h2 class="text-lg font-medium text-gray-900">Clients</h2>
				<div class="text-sm text-gray-600">
					{clients.length} client{clients.length !== 1 ? 's' : ''}
				</div>
			</div>
			
			<!-- Create Client Form -->
			<div class="grid grid-cols-1 md:grid-cols-6 gap-4 mb-6 py-4">
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
						disabled={creatingClient || !newClientName.trim() || !newClientEmail.trim() || !newClientDivisionId}
						class="w-full"
					>
						{creatingClient ? 'Creating...' : 'Create Client'}
					</Button>
				</div>
			</div>
			
			<!-- Clients Table -->
			{#if clientsLoading}
				<div class="text-center py-8">
					<div class="text-gray-500">Loading clients...</div>
				</div>
			{:else if clients.length === 0}
				<div class="text-center py-8">
					<div class="text-gray-500">No clients found. Create one above to get started.</div>
				</div>
			{:else}
				<Table data={clientTableData} />
			{/if}
		</Card>
	{/if}
</div>
