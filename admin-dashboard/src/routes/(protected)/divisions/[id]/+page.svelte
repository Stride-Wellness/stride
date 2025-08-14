<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import Card from '$lib/components/Card.svelte';
	import Button from '$lib/components/Button.svelte';
	import Message from '$lib/components/Message.svelte';
	import Input from '$lib/components/Input.svelte';
	import Table from '$lib/components/Table.svelte';
	import { DivisionsService } from '$lib/services/divisions';
	import type { Division } from '$lib/services/divisions';
	import { UsersService } from '$lib/services/users';
	import type { ClientUser, EmployeeUser, User, UserType } from '$lib/services/users';
	import Link from '$lib/components/Link.svelte';

	const divisionId = $derived($page.params.id);

	// State
	let division = $state<Division | null>(null);
	let loading = $state(true);
	let saving = $state(false);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);
	let jsonText = $state('');

	// User state
	let employees = $state<User[]>([]);
	let clients = $state<User[]>([]);
	let employeesLoading = $state(false);
	let clientsLoading = $state(false);
	
	// Employee form state
	let newEmployeeName = $state('');
	let newEmployeeEmail = $state('');
	let newEmployeeRole = $state<string>('psw');
	let creatingEmployee = $state(false);
	
	// Client form state
	let newClientName = $state('');
	let newClientEmail = $state('');
	let newClientPhone = $state('');
	let newClientDateOfBirth = $state('');
	let creatingClient = $state(false);
	
	// Delete states
	let deletingEmployees = $state(new Set<string>());
	let deletingClients = $state(new Set<string>());

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
			await loadEmployees();
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
						error = 'Permission denied. You may not have the required permissions to update this division.';
						break;
					case 'not-found':
						error = 'Division not found. It may have been deleted or the ID is incorrect.';
						break;
					case 'invalid-argument':
						error = 'Invalid data provided. Please check all fields are correctly formatted.';
						break;
					case 'failed-precondition':
						error = 'Update failed validation. Please ensure manager ID is valid and belongs to the organization.';
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

	// Load employees
	async function loadEmployees() {
		if (!divisionId) return;
		
		employeesLoading = true;
		try {
			const allUsers = await UsersService.getByDivisionId(divisionId);
			employees = allUsers.filter(user => user.type === 'employee');
		} catch (err: any) {
			console.error('Error loading employees:', err);
			// Don't set the main error state for sub-operations, just log it
			if (err.code === 'permission-denied') {
				console.warn('Permission denied loading employees for division:', divisionId);
			}
		} finally {
			employeesLoading = false;
		}
	}

	// Load clients
	async function loadClients() {
		if (!divisionId) return;
		
		clientsLoading = true;
		try {
			const allUsers = await UsersService.getByDivisionId(divisionId);
			clients = allUsers.filter(user => user.type === 'client');
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

	// Create new employee
	async function createEmployee() {
		if (!divisionId || !division || !newEmployeeName.trim() || !newEmployeeEmail.trim()) {
			error = 'Employee name and email are required.';
			return;
		}
		
		creatingEmployee = true;
		error = null;
		
		try {
			const employeeData = {
				email: newEmployeeEmail.trim(),
				name: newEmployeeName.trim(),
				organizationId: division.organizationId,
				divisionId: divisionId,
				employeeRole: [newEmployeeRole as any]
			};
			
			await UsersService.createEmployee(employeeData);
			
			// Reset form
			newEmployeeName = '';
			newEmployeeEmail = '';
			newEmployeeRole = 'psw';
			
			// Reload employees
			await loadEmployees();
			
			successMessage = 'Employee created successfully!';
		} catch (err: any) {
			console.error('Error creating employee:', err);
			
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to create employees.';
						break;
					case 'already-exists':
						error = 'An employee with this email already exists.';
						break;
					case 'invalid-argument':
						error = 'Invalid employee data. Please check the email format and other fields.';
						break;
					case 'failed-precondition':
						error = 'Employee creation failed. Please ensure the division and organization are valid.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to create employee. Please try again.'}`;
				}
			} else if (err.message) {
				if (err.message.includes('Failed to create employee')) {
					error = 'Failed to create employee. Please check the data and try again.';
				} else {
					error = err.message;
				}
			} else {
				error = 'Failed to create employee. Please try again.';
			}
		} finally {
			creatingEmployee = false;
		}
	}

	// Create new client
	async function createClient() {
		if (!divisionId || !division || !newClientName.trim()) {
			error = 'Client name is required.';
			return;
		}
		
		creatingClient = true;
		error = null;
		
		try {
			const clientData = {
				email: newClientEmail.trim() || `${newClientName.trim().replace(/\s+/g, '').toLowerCase()}@temp.local`,
				name: newClientName.trim(),
				organizationId: division.organizationId,
				divisionId: divisionId,
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
			
			// Reload clients
			await loadClients();
			
			successMessage = 'Client created successfully!';
		} catch (err: any) {
			console.error('Error creating client:', err);
			
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to create clients.';
						break;
					case 'invalid-argument':
						error = 'Invalid client data. Please check the name and other fields.';
						break;
					case 'failed-precondition':
						error = 'Client creation failed. Please ensure the division and organization are valid.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to create client. Please try again.'}`;
				}
			} else if (err.message) {
				if (err.message.includes('Failed to create client')) {
					error = 'Failed to create client. Please check the data and try again.';
				} else {
					error = err.message;
				}
			} else {
				error = 'Failed to create client. Please try again.';
			}
		} finally {
			creatingClient = false;
		}
	}	

	// Delete employee
	async function deleteEmployee(employeeId: string) {
		if (!confirm('Are you sure you want to delete this employee?')) return;
		
		error = null;
		deletingEmployees.add(employeeId);
		deletingEmployees = deletingEmployees;
		
		try {
			await UsersService.hardDelete(employeeId);
			await loadEmployees();
			successMessage = 'Employee deleted successfully!';
		} catch (err: any) {
			console.error('Error deleting employee:', err);
			
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to delete employees.';
						break;
					case 'not-found':
						error = 'Employee not found. They may have already been deleted.';
						break;
					case 'failed-precondition':
						error = 'Cannot delete employee. They may have active assignments or other dependencies.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to delete employee. Please try again.'}`;
				}
			} else if (err.message) {
				error = err.message;
			} else {
				error = 'Failed to delete employee. Please try again.';
			}
		} finally {
			deletingEmployees.delete(employeeId);
			deletingEmployees = deletingEmployees;
		}
	}

	// Delete client
	async function deleteClient(clientId: string) {
		if (!confirm('Are you sure you want to delete this client?')) return;
		
		error = null;
		deletingClients.add(clientId);
		deletingClients = deletingClients;
		
		try {
			await UsersService.hardDelete(clientId);
			await loadClients();
			successMessage = 'Client deleted successfully!';
		} catch (err: any) {
			console.error('Error deleting client:', err);
			
			if (err.code) {
				switch (err.code) {
					case 'permission-denied':
						error = 'Permission denied. You may not have the required permissions to delete clients.';
						break;
					case 'not-found':
						error = 'Client not found. They may have already been deleted.';
						break;
					case 'failed-precondition':
						error = 'Cannot delete client. They may have active assignments or other dependencies.';
						break;
					default:
						error = `Error: ${err.message || 'Failed to delete client. Please try again.'}`;
				}
			} else if (err.message) {
				error = err.message;
			} else {
				error = 'Failed to delete client. Please try again.';
			}
		} finally {
			deletingClients.delete(clientId);
			deletingClients = deletingClients;
		}
	}
	// Get formatted employee data for table
	const employeeTableData = $derived(employees.map(employee => ({
		name: { name: employee.name, href: `/users/${employee.id}` },
		email: employee.email,
		role: UsersService.isEmployee(employee) ? employee.employeeRole.join(', ') : '',
		status: employee.status,
		created: new Date(employee.createdAt).toLocaleDateString()
	})));

	// Get formatted client data for table
	const clientTableData = $derived(clients.map(client => ({
		name: { name: client.name, href: `/users/${client.id}` },
		email: client.email,
		phone: UsersService.isClient(client) ? client.profile.phone || '-' : '-',
		dateOfBirth: UsersService.isClient(client) ? client.profile.dateOfBirth || '-' : '-',
		status: client.status,
		created: new Date(client.createdAt).toLocaleDateString()
	})));
</script>

<div class="space-y-6 p-6">
	<div>
		<h1 class="text-2xl font-semibold text-gray-900">Division Details</h1>
		<p class="text-sm text-gray-600">Division ID: {divisionId}</p>
    <p class="text-sm text-gray-600">Organization ID: <Link href={`/organizations/${division?.organizationId}`} name={division?.organizationId || "error getting org"}></Link></p>
	</div>

	{#if loading}
		<Card class="p-6">
			<div class="flex items-center justify-center">
				<div class="text-lg">Loading division data...</div>
			</div>
		</Card>
	{:else if !division}
		<Card class="p-6">
			<Message type="error" message="Division not found." />
		</Card>
	{:else}
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

		<!-- Messages -->
		<Message type="error" message={error || undefined} />
		<Message type="success" message={successMessage || undefined} />

		<!-- Employees Section -->
		<Card class="p-6">
			<div class="flex items-center justify-between mb-4">
				<h2 class="text-lg font-medium text-gray-900">Employees</h2>
				<div class="text-sm text-gray-600">
					{employees.length} employee{employees.length !== 1 ? 's' : ''}
				</div>
			</div>
			
			<!-- Create Employee Form -->
			<div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6 py-4">
				<Input
					label="Employee Name"
					bind:value={newEmployeeName}
					placeholder="Enter employee name"
					disabled={creatingEmployee}
				/>
				<Input
					label="Email"
					bind:value={newEmployeeEmail}
					placeholder="Enter email address"
					disabled={creatingEmployee}
				/>
				<Input
					as="select"
					label="Employee Role"
					bind:value={newEmployeeRole}
					disabled={creatingEmployee}
					options={[
						{ value: 'psw', label: 'PSW' },
						{ value: 'lw', label: 'LW' },
						{ value: 'admin', label: 'Admin' },
						{ value: 'manager', label: 'Manager' }
					]}
				/>
				<div class="flex items-end">
					<Button 
						onclick={createEmployee}
						disabled={creatingEmployee || !newEmployeeName.trim() || !newEmployeeEmail.trim()}
						class="w-full"
					>
						{creatingEmployee ? 'Creating...' : 'Create Employee'}
					</Button>
				</div>
			</div>
			
			<!-- Employees Table -->
			{#if employeesLoading}
				<div class="text-center py-8">
					<div class="text-gray-500">Loading employees...</div>
				</div>
			{:else if employees.length === 0}
				<div class="text-center py-8">
					<div class="text-gray-500">No employees found. Create one above to get started.</div>
				</div>
			{:else}
				<Table data={employeeTableData} />
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
			<div class="grid grid-cols-1 md:grid-cols-5 gap-4 mb-6 py-4">
				<Input
					label="Client Name"
					bind:value={newClientName}
					placeholder="Enter client name"
					disabled={creatingClient}
				/>
				<Input
					label="Email (Optional)"
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
				<div class="flex items-end">
					<Button 
						onclick={createClient}
						disabled={creatingClient || !newClientName.trim()}
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
