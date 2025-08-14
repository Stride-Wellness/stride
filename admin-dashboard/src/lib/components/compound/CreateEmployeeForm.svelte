<script lang="ts">
	import type {
		User,
		EmployeeUser,
		ClientUser,
		EmployeeRole,
		UserType,
		UserStatus
	} from '$lib/services/users';
	import { UsersService } from '$lib/services/users';
	import Table from '$lib/components/Table.svelte';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Message from '$lib/components/Message.svelte';
	import Card from '$lib/components/Card.svelte';
	import { onMount } from 'svelte';

	let {
		variant = 'independent',
		error = $bindable(),
		successMessage = $bindable(),
		constantEmail,
		constantName,
		constantOrganizationId,
		constantDivisionId,
		constantRoles,
		callback
	}: {
		variant?: 'independent' | 'complementary';
		users?: User[];
		error: string | null;
		successMessage: string | null;
		constantEmail?: string;
		constantName?: string;
    constantOrganizationId?: string;
    constantDivisionId?: string;
    constantRoles?: EmployeeRole[];
		callback?: (newUser: User) => void;
	} = $props();

	// Form state for creating employee users
	let employeeName = $state(constantName);
	let employeeEmail = $state(constantEmail);
	let employeeOrganizationId = $state(constantOrganizationId);
	let employeeDivisionId = $state(constantDivisionId);
	let employeeRoles = $state(constantRoles || []);

	// Available employee roles
	const availableRoles: EmployeeRole[] = ['psw', 'lw', 'admin', 'manager'];

	// Handle create employee user
	async function handleCreateEmployee(event: Event) {
		event.preventDefault();

		error = null;
		successMessage = null;

		if (
			!employeeName ||
			!employeeEmail ||
			!employeeOrganizationId ||
			!employeeDivisionId ||
			employeeRoles.length === 0
		) {
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
			callback?.(newUser);
			successMessage = 'Employee user created successfully!';
		} catch (err) {
			console.error('Error creating employee user:', err);
			error = 'Failed to create employee user. Please try again.';
		}
	}

	// Handle role checkbox changes
	function handleRoleChange(role: EmployeeRole, checked: boolean) {
		if (checked) {
			employeeRoles = [...employeeRoles, role];
		} else {
			employeeRoles = employeeRoles.filter((r) => r !== role);
		}
	}
</script>

{#if variant === 'independent'}
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
				disabled={constantName}
        required
		  />

		<Input
			type="email"
			placeholder="Employee Email"
			size="md"
			variant="outline"
			bind:value={employeeEmail}
			disabled={constantEmail}
			required
		/>
		<Input
			type="text"
			placeholder="Organization ID"
			size="md"
			variant="outline"
			bind:value={employeeOrganizationId}
			disabled={constantOrganizationId}
			required
		/>
		<Input
			type="text"
			placeholder="Division ID"
			size="md"
			variant="outline"
			bind:value={employeeDivisionId}
			disabled={constantDivisionId}
			required
		/>

		<!-- Role Checkboxes -->
		<div>
			<p class="mb-2 block text-sm font-medium text-gray-700">Employee Roles</p>
			<div class="space-y-2">
				{#each availableRoles as role}
					<label class="flex items-center">
						<input
							type="checkbox"
							class="mr-2 rounded border-gray-300"
							checked={employeeRoles && employeeRoles.includes(role)}
							onchange={(e) => handleRoleChange(role, e.currentTarget.checked)}
							disabled={Boolean(constantRoles)}
						/>
						<span class="text-sm capitalize">{role}</span>
					</label>
				{/each}
			</div>
		</div>

		<Button type="submit" size="md" class="w-full">Create Employee</Button>
	</form>
</Card>
{:else if variant === 'complementary'}
<!-- Complementary Employee Form (for table top) -->
<div class="">
	<form onsubmit={handleCreateEmployee} class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-4 items-end">
		<Input
			type="text"
			placeholder="Employee Name"
			size="md"
			variant="outline"
			bind:value={employeeName}
			disabled={constantName}
			required
		/>
		
		<Input
			type="email"
			placeholder="Employee Email"
			size="md"
			variant="outline"
			bind:value={employeeEmail}
			disabled={constantEmail}
			required
		/>
		
		<Input
			type="text"
			placeholder="Organization ID"
			size="md"
			variant="outline"
			bind:value={employeeOrganizationId}
			disabled={constantOrganizationId}
			required
		/>
		
		<Input
			type="text"
			placeholder="Division ID"
			size="md"
			variant="outline"
			bind:value={employeeDivisionId}
			disabled={constantDivisionId}
			required
		/>
		
		<!-- Compact Role Selection -->
		<div class="lg:col-span-1">
			<div class="flex flex-wrap gap-2">
				{#each availableRoles as role}
					<label class="flex items-center text-xs">
						<input
							type="checkbox"
							class="mr-1 h-3 w-3 rounded border-gray-300"
							checked={employeeRoles && employeeRoles.includes(role)}
							onchange={(e) => handleRoleChange(role, e.currentTarget.checked)}
							disabled={Boolean(constantRoles)}
						/>
						<span class="capitalize">{role}</span>
					</label>
				{/each}
			</div>
		</div>
		
		<Button type="submit" size="md" class="lg:col-span-1">Add Employee</Button>
	</form>
</div>
{/if}