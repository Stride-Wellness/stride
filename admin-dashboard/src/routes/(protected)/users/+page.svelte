<script lang="ts">
	import type { User, UserStatus } from '$lib/services/users';
	import { UsersService } from '$lib/services/users';
	import Table from '$lib/components/Table.svelte';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Message from '$lib/components/Message.svelte';
	import Card from '$lib/components/Card.svelte';
	import Tabs from '$lib/components/Tabs.svelte';
	import TabPanel from '$lib/components/TabPanel.svelte';
	import CreateProviderUserForm from '$lib/components/compound/CreateProviderUserForm.svelte';
	import CreateClientUserForm from '$lib/components/compound/CreateClientUserForm.svelte';
	import UpdateUserForm from '$lib/components/compound/UpdateUserForm.svelte';
	import DeleteUserForm from '$lib/components/compound/DeleteUserForm.svelte';
	import { onMount } from 'svelte';

	// State
	let users = $state<User[]>([]);
	let loading = $state(true);
	let error = $state('');
	let successMessage = $state('');

	// Filter state
	let filterType = $state<'provider' | 'client' | 'all'>('all');
	let filterStatus = $state<UserStatus | 'all'>('all');
	let searchTerm = $state('');

	let selectedUsers: Record<string, any>[] = $state([]);

	// Load users on mount
	onMount(async () => {
		await loadUsers();
	});

	async function loadUsers() {
		try {
			loading = true;
			error = '';
			users = await UsersService.getAll(1000, false);
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to load users';
			console.error('Error loading users:', err);
		} finally {
			loading = false;
		}
	}

	// Filter users based on current filters
	const filteredUsers = $derived(() => {
		let filtered = users;

		// Filter by type
		if (filterType !== 'all') {
			filtered = filtered.filter((user) => user.type === filterType);
		}

		// Filter by status
		if (filterStatus !== 'all') {
			filtered = filtered.filter((user) => user.status === filterStatus);
		}

		// Filter by search term
		if (searchTerm) {
			const term = searchTerm.toLowerCase();
			filtered = filtered.filter(
				(user) =>
					user.name.toLowerCase().includes(term) ||
					user.email.toLowerCase().includes(term) ||
					user.id.toLowerCase().includes(term)
			);
		}

		return filtered;
	});

	// Transform data for table display
	const tableData = $derived(
		filteredUsers().map((user) => ({
			id: { name: user.id, href: `/users/${user.id}` },
			name: user.name,
			email: user.email,
			type: user.type,
			status: user.status,
			roles: UsersService.isProvider(user) ? user.providerRole.join(', ') : 'N/A',
			'Org ID': user.organizationId.substring(0, 8) + '...',
			'Div ID': user.divisionId.substring(0, 8) + '...',
			Created: new Date(user.createdAt).toLocaleDateString()
		}))
	);

	// Calculate summary stats from all users
	const summaryStats = $derived(() => {
		const total = users.length;
		const providers = users.filter((user) => user.type === 'provider').length;
		const clients = users.filter((user) => user.type === 'client').length;
		const active = users.filter((user) => user.status === 'active').length;
		const inactive = users.filter((user) => user.status === 'inactive').length;
		const pending = users.filter((user) => user.status === 'pending').length;

		// Provider role breakdown
		const psws = users.filter(
			(user) => UsersService.isProvider(user) && UsersService.hasRole(user, 'psw')
		).length;
		const managers = users.filter(
			(user) => UsersService.isProvider(user) && UsersService.hasRole(user, 'manager')
		).length;
		const admins = users.filter(
			(user) => UsersService.isProvider(user) && UsersService.hasRole(user, 'admin')
		).length;
		const lws = users.filter(
			(user) => UsersService.isProvider(user) && UsersService.hasRole(user, 'lw')
		).length;

		return { total, providers, clients, active, inactive, pending, psws, managers, admins, lws };
	});

	// Get selected user IDs and types for prefilling forms
	const selectedUserIds = $derived(selectedUsers.map((user) => user.id.name));
</script>

<svelte:head>
	<title>Users - Stride Admin</title>
	<meta name="description" content="Manage facility providers and elderly care residents" />
</svelte:head>

<div class="space-y-6 p-6">
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-semibold text-gray-900">Users</h1>
			<p class="text-sm text-gray-600">Manage facility providers and elderly care residents across all organizations</p>
		</div>
		<Button onclick={loadUsers} disabled={loading} size="sm">
			{loading ? 'Refreshing...' : 'Refresh'}
		</Button>
	</div>

	<!-- Messages -->
	<Message type="error" message={error} />
	<Message type="success" message={successMessage} />


		<!-- Summary Cards -->
		<div class="grid grid-cols-2 gap-4 md:grid-cols-4 lg:grid-cols-6">
			<Card class="flex items-center justify-between p-4">
				<div>
					<h4 class="text-sm text-gray-600">Total Users</h4>
					<p class="text-2xl font-bold text-gray-900">{summaryStats().total}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4 class="text-sm text-gray-600">Providers</h4>
					<p class="text-2xl font-bold text-blue-600">{summaryStats().providers}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4 class="text-sm text-gray-600">Residents</h4>
					<p class="text-2xl font-bold text-green-600">{summaryStats().clients}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4 class="text-sm text-gray-600">Active</h4>
					<p class="text-2xl font-bold text-emerald-600">{summaryStats().active}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4 class="text-sm text-gray-600">PSWs</h4>
					<p class="text-2xl font-bold text-purple-600">{summaryStats().psws}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4 class="text-sm text-gray-600">Managers</h4>
					<p class="text-2xl font-bold text-orange-600">{summaryStats().managers}</p>
				</div>
			</Card>
		</div>

		<!-- Create User Forms in Tabs -->
		<Tabs>
			<TabPanel label="Create Provider">
				<CreateProviderUserForm
					bind:error
					bind:successMessage
					callback={loadUsers}
				/>
			</TabPanel>
			<TabPanel label="Create Resident">
				<CreateClientUserForm
					bind:error
					bind:successMessage
					callback={loadUsers}
				/>
			</TabPanel>
			<TabPanel label="Update User">
				<UpdateUserForm
					bind:error
					bind:successMessage
					callback={loadUsers}
				/>
			</TabPanel>
			<TabPanel label="Delete User">
				<DeleteUserForm
					bind:error
					bind:successMessage
					prefilledIds={selectedUserIds}
					callback={loadUsers}
				/>
			</TabPanel>
		</Tabs>

		<!-- Filters -->
		<Card class="p-6">
			<h2 class="mb-4 text-lg font-medium text-gray-900">Filter Users</h2>
			<div class="grid grid-cols-1 gap-4 md:grid-cols-3">
				<div>
					<label class="mb-2 block text-sm font-medium text-gray-700">Type</label>
					<select
						bind:value={filterType}
						class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
					>
						<option value="all">All Types</option>
						<option value="provider">Providers</option>
						<option value="client">Residents</option>
					</select>
				</div>
				<div>
					<label class="mb-2 block text-sm font-medium text-gray-700">Status</label>
					<select
						bind:value={filterStatus}
						class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
					>
						<option value="all">All Statuses</option>
						<option value="active">Active</option>
						<option value="inactive">Inactive</option>
						<option value="pending">Pending</option>
						<option value="deleted">Deleted</option>
					</select>
				</div>
				<div>
					<label class="mb-2 block text-sm font-medium text-gray-700">Search</label>
					<Input
						type="text"
						placeholder="Search by name, email, or ID..."
						size="md"
						variant="outline"
						bind:value={searchTerm}
					/>
				</div>
			</div>
		</Card>

		<!-- Users Table -->
		<Card class="p-6">
			<div class="mb-4 flex items-center justify-between">
				<h2 class="text-lg font-medium text-gray-900">Users Overview</h2>
				<span class="text-sm text-gray-600">
					Showing {filteredUsers().length} of {users.length} users
				</span>
			</div>
            {#key tableData.length}
                
			<Table data={tableData} bind:selected={selectedUsers} class="max-h-96" />
            {/key}
			<p class="mt-2 text-xs text-gray-500">
				Select users to auto-fill the update/delete forms above.
			</p>
		</Card>
</div>