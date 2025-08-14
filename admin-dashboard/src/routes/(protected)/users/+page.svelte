<script lang="ts">
	import type { User, EmployeeUser, ClientUser, EmployeeRole, UserType, UserStatus } from '$lib/services/users';
	import { UsersService } from '$lib/services/users';
	import Table from '$lib/components/Table.svelte';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Message from '$lib/components/Message.svelte';
	import Card from '$lib/components/Card.svelte';
	import { onMount } from 'svelte';

	// State for users data
	let users = $state<User[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);

	// Filter state
	let filterType = $state<UserType | 'all'>('all');
	let filterStatus = $state<UserStatus | 'all'>('all');
	let searchTerm = $state('');

	// Form state for creating employee users
	let employeeName = $state('');
	let employeeEmail = $state('');
	let employeeOrganizationId = $state('');
	let employeeDivisionId = $state('');
	let employeeRoles = $state<EmployeeRole[]>([]);

	// Form state for creating client users
	let clientName = $state('');
	let clientEmail = $state('');
	let clientOrganizationId = $state('');
	let clientDivisionId = $state('');
	let clientPhone = $state('');
	let clientDateOfBirth = $state('');

	// Form state for updating user status
	let updateStatusId = $state('');
	let updateStatus = $state<UserStatus>('active');

	// Form state for deleting user
	let deleteUserId = $state('');

	// Available employee roles
	const availableRoles: EmployeeRole[] = ['psw', 'lw', 'admin', 'manager'];

	// Load users on mount
	onMount(async () => {
		try {
			users = await UsersService.getAll(1000);
		} catch (err) {
			console.error('Error loading users:', err);
			error = 'Failed to load users. Please refresh the page.';
		} finally {
			loading = false;
		}
	});

	// Handle create employee user
	async function handleCreateEmployee(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!employeeName || !employeeEmail || !employeeOrganizationId || !employeeDivisionId || employeeRoles.length === 0) {
			error = 'All fields are required and at least one role must be selected';
			return;
		}

		if (employeeName.length < 2) {
			error = 'Name must be at least 2 characters';
			return;
		}

		try {
			const newUser = await UsersService.createEmployee({
				name: employeeName,
				email: employeeEmail,
				organizationId: employeeOrganizationId,
				divisionId: employeeDivisionId,
				employeeRole: employeeRoles
			});

			// Reset form
			employeeName = '';
			employeeEmail = '';
			employeeOrganizationId = '';
			employeeDivisionId = '';
			employeeRoles = [];

			// Update local state - use spread to trigger reactivity
			users = [newUser, ...users];

			successMessage = 'Employee user created successfully!';
		} catch (err) {
			console.error('Error creating employee user:', err);
			error = 'Failed to create employee user. Please try again.';
		}
	}

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
			const profile = clientPhone || clientDateOfBirth ? {
				...(clientPhone && { phone: clientPhone }),
				...(clientDateOfBirth && { dateOfBirth: clientDateOfBirth })
			} : undefined;

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
			users = [newUser, ...users];

			successMessage = 'Client user created successfully!';
		} catch (err) {
			console.error('Error creating client user:', err);
			error = 'Failed to create client user. Please try again.';
		}
	}

	// Handle update status
	async function handleUpdateStatus(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!updateStatusId || !updateStatus) {
			error = 'User ID and status are required';
			return;
		}

		try {
			await UsersService.update(updateStatusId, { status: updateStatus });

			// Update local state - create new array to trigger reactivity
			users = users.map(user => 
				user.id === updateStatusId 
					? { ...user, status: updateStatus }
					: user
			);

			updateStatusId = '';
			updateStatus = 'active';

			successMessage = 'User status updated successfully!';
		} catch (err) {
			console.error('Error updating user status:', err);
			error = 'Failed to update user status. Please try again.';
		}
	}

	// Handle soft delete user
	async function handleSoftDeleteUser(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!deleteUserId) {
			error = 'User ID is required';
			return;
		}

		if (
			!confirm(
				'Are you sure you want to soft delete this user? This will hide them from the main view but preserve all data. You can restore them later if needed.'
			)
		) {
			return;
		}

		try {
			await UsersService.softDelete(deleteUserId);

			// Reload users to refresh the list (soft deleted won't show)
			users = await UsersService.getAll(1000);

			deleteUserId = '';

			successMessage = 'User soft deleted successfully! Data has been preserved and can be restored.';
		} catch (err: any) {
			console.error('Error soft deleting user:', err);
			
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to delete this user.';
						break;
					case 'not-found':
						error = 'User not found. They may have already been deleted or the ID is incorrect.';
						break;
					case 'failed-precondition':
						error = 'Cannot delete user. They may have active assignments or other dependencies.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to soft delete user. Please try again.'}`;
				}
			} else if (err.message) {
				error = err.message;
			} else {
				error = 'Failed to soft delete user. Please try again.';
			}
		}
	}

	// Handle delete user
	async function handleDeleteUser(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (!deleteUserId) {
			error = 'User ID is required';
			return;
		}

		if (
			!confirm(
				'Are you sure you want to delete this user? This action cannot be undone and will permanently remove all associated data.'
			)
		) {
			return;
		}

		try {
			await UsersService.hardDelete(deleteUserId);

			// Update local state - create new array to trigger reactivity
			users = users.filter((user) => user.id !== deleteUserId);

			deleteUserId = '';

			successMessage = 'User deleted successfully!';
		} catch (err) {
			console.error('Error deleting user:', err);
			error = 'Failed to delete user. Please try again.';
		}
	}

	// Handle role checkbox changes
	function handleRoleChange(role: EmployeeRole, checked: boolean) {
		if (checked) {
			employeeRoles = [...employeeRoles, role];
		} else {
			employeeRoles = employeeRoles.filter(r => r !== role);
		}
	}

	// Filter users based on current filters
	const filteredUsers = $derived(() => {
		let filtered = users;

		// Filter by type
		if (filterType !== 'all') {
			filtered = filtered.filter(user => user.type === filterType);
		}

		// Filter by status
		if (filterStatus !== 'all') {
			filtered = filtered.filter(user => user.status === filterStatus);
		}

		// Filter by search term
		if (searchTerm) {
			const term = searchTerm.toLowerCase();
			filtered = filtered.filter(user => 
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
			roles: UsersService.isEmployee(user) ? user.employeeRole.join(', ') : 'N/A',
			'Organization ID': user.organizationId,
			'Division ID': user.divisionId,
			'Last Login': user.lastLoginAt ? new Date(user.lastLoginAt).toLocaleDateString() : 'Never',
			Created: user.createdAt ? new Date(user.createdAt).toLocaleDateString() : 'N/A'
		}))
	);

	// Calculate summary stats
	const summaryStats = $derived(() => {
		const total = users.length;
		const employees = users.filter((user) => user.type === 'employee').length;
		const clients = users.filter((user) => user.type === 'client').length;
		const active = users.filter((user) => user.status === 'active').length;
		const inactive = users.filter((user) => user.status === 'inactive').length;
		const pending = users.filter((user) => user.status === 'pending').length;
		
		// Employee role breakdown
		const psws = users.filter((user) => UsersService.isEmployee(user) && UsersService.hasRole(user, 'psw')).length;
		const managers = users.filter((user) => UsersService.isEmployee(user) && UsersService.hasRole(user, 'manager')).length;
		const admins = users.filter((user) => UsersService.isEmployee(user) && UsersService.hasRole(user, 'admin')).length;
		const lws = users.filter((user) => UsersService.isEmployee(user) && UsersService.hasRole(user, 'lw')).length;

		return { total, employees, clients, active, inactive, pending, psws, managers, admins, lws };
	});
</script>

{#if loading}
	<div class="flex items-center justify-center p-6">
		<div class="text-lg">Loading users...</div>
	</div>
{:else}
	<div class="space-y-6 p-6">
		<div class="flex items-center justify-between">
			<h1 class="text-2xl font-semibold text-gray-900">Users</h1>
			<p class="text-sm text-gray-600">Manage employees and clients across all organizations</p>
		</div>

						<!-- Messages -->
		<Message type="error" message={error || undefined} />
		<Message type="success" message={successMessage || undefined} />

		<!-- Summary Cards -->
		<div class="grid grid-cols-2 gap-4 md:grid-cols-4 lg:grid-cols-6">
			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Total Users</h4>
					<p class="text-2xl font-bold text-gray-900">{summaryStats().total}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Employees</h4>
					<p class="text-2xl font-bold">{summaryStats().employees}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Clients</h4>
					<p class="text-2xl font-bold">{summaryStats().clients}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Active Users</h4>
					<p class="text-2xl font-bold">{summaryStats().active}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>PSWs</h4>
					<p class="text-2xl font-bold">{summaryStats().psws}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4>Managers</h4>
					<p class="text-2xl font-bold">{summaryStats().managers}</p>
				</div>
			</Card>
		</div>


		<!-- Filters -->
		<Card class="p-6">
			<h2>Filter Users</h2>
			<div class="grid grid-cols-1 gap-4 md:grid-cols-4">
				<Input
					type="text"
					placeholder="Search by name, email, or ID..."
					size="md"
					variant="outline"
					bind:value={searchTerm}
				/>
				<Input
					as="select"
					variant="outline"
					bind:value={filterType}
				>
					<option value="all">All Types</option>
					<option value="employee">Employees</option>
					<option value="client">Clients</option>
				</Input>
				<Input
					as="select"
					variant="outline"
					bind:value={filterStatus}
				>
					<option value="all">All Statuses</option>
					<option value="active">Active</option>
					<option value="inactive">Inactive</option>
					<option value="pending">Pending</option>
				</Input>
				<Button 
					size="md" 
					variant="secondary"
					onclick={() => {
						searchTerm = '';
						filterType = 'all';
						filterStatus = 'all';
					}}
				>
					Clear Filters
				</Button>
			</div>
		</Card>

		<!-- Create User Forms -->
		<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
			<!-- Create Employee Form -->
			<Card class="p-6">
				<h2>Add New Employee</h2>
				<form onsubmit={handleCreateEmployee} class="space-y-4">
					<Input
						type="text"
						placeholder="Employee Name"
						size="md"
						variant="outline"
						bind:value={employeeName}
						required
					/>
					<Input
						type="email"
						placeholder="Employee Email"
						size="md"
						variant="outline"
						bind:value={employeeEmail}
						required
					/>
					<Input
						type="text"
						placeholder="Organization ID"
						size="md"
						variant="outline"
						bind:value={employeeOrganizationId}
						required
					/>
					<Input
						type="text"
						placeholder="Division ID"
						size="md"
						variant="outline"
						bind:value={employeeDivisionId}
						required
					/>
					
					<!-- Role Checkboxes -->
					<div>
						<p class="block text-sm font-medium text-gray-700 mb-2">Employee Roles</p>
						<div class="space-y-2">
							{#each availableRoles as role}
								<label class="flex items-center">
									<input
										type="checkbox"
										class="mr-2 rounded border-gray-300"
										checked={employeeRoles.includes(role)}
										onchange={(e) => handleRoleChange(role, e.currentTarget.checked)}
									/>
									<span class="text-sm capitalize">{role}</span>
								</label>
							{/each}
						</div>
					</div>

					<Button type="submit" size="md" class="w-full">Create Employee</Button>
				</form>
			</Card>

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
						required
					/>
					<Input
						type="email"
						placeholder="Client Email"
						size="md"
						variant="outline"
						bind:value={clientEmail}
						required
					/>
					<Input
						type="text"
						placeholder="Organization ID"
						size="md"
						variant="outline"
						bind:value={clientOrganizationId}
						required
					/>
					<Input
						type="text"
						placeholder="Division ID"
						size="md"
						variant="outline"
						bind:value={clientDivisionId}
						required
					/>
					<Input
						type="tel"
						placeholder="Phone (optional)"
						size="md"
						variant="outline"
						bind:value={clientPhone}
					/>
					<Input
						type="date"
						placeholder="Date of Birth (optional)"
						size="md"
						variant="outline"
						bind:value={clientDateOfBirth}
					/>
					<Button type="submit" size="md" class="w-full">Create Client</Button>
				</form>
			</Card>
		</div>

		<!-- Management Actions -->
		<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
			<!-- Update Status -->
			<Card class="p-6">
				<h2 class="mb-4 text-lg font-medium text-gray-900">Update User Status</h2>
				<form onsubmit={handleUpdateStatus} class="space-y-4">
					<Input
						type="text"
						placeholder="User ID"
						size="md"
						variant="outline"
						bind:value={updateStatusId}
						required
					/>
					<Input
						as="select" 
						variant="outline"
						bind:value={updateStatus}
						required
					>
						<option value="active">Active</option>
						<option value="inactive">Inactive</option>
						<option value="pending">Pending</option>
					</Input>
					<Button type="submit" size="md" variant="secondary" class="w-full">Update Status</Button>
				</form>
			</Card>

			<!-- Delete User -->
			<Card class="border-red-200 bg-red-50 p-6 flex flex-col justify-between">
				<div>
					<h2 class="mb-4 text-lg font-medium text-red-900">Delete User</h2>
					<p class="my-2 text-xs text-red-700">
						Soft delete hides the user but preserves data. Hard delete permanently removes all data.
					</p>
				</div>
				<div class="space-y-4">
					<Input
						type="text"
						placeholder="User ID"
						size="md"
						variant="outline"
						name="deleteId"
						bind:value={deleteUserId}
						required
					/>
					<!-- Soft Delete Button -->
					<Button
						type="button"
						size="md"
						class="w-full border-yellow-600 bg-yellow-600 text-white hover:border-yellow-700 hover:bg-yellow-700"
						onclick={handleSoftDeleteUser}
					>
						Soft Delete User (Recoverable)
					</Button>
					<!-- Hard Delete Button -->
					<Button
						type="button"
						size="md"
						class="w-full border-red-600 bg-red-600 text-white hover:border-red-700 hover:bg-red-700"
						onclick={handleDeleteUser}
					>
						Hard Delete User (Permanent)
					</Button>
				</div>
			</Card>
		</div>

		<!-- Users Table -->
		<Card class="p-6">
			<div class="mb-4 flex items-center justify-between">
				<h2 class="text-lg font-medium text-gray-900">Users Overview</h2>
				<span class="text-sm text-gray-600">
					Showing {filteredUsers().length} of {users.length} users
				</span>
			</div>
			<Table data={tableData} class="max-h-96" />
		</Card>
	</div>
{/if}
