<script lang="ts">
	import { AdminPrivilegeLevel, AdminsService, type Admin } from '$lib/services/admins';
	import { page } from '$app/stores';
	import Table from '$lib/components/Table.svelte';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Message from '$lib/components/Message.svelte';
	import Card from '$lib/components/Card.svelte';
	import { onMount } from 'svelte';
	import Tabs from '$lib/components/Tabs.svelte';
	import TabPanel from '$lib/components/TabPanel.svelte';
	import CreateAdminForm from '$lib/components/compound/CreateAdminForm.svelte';
	import UpdateAdminForm from '$lib/components/compound/UpdateAdminForm.svelte';
	import DeleteAdminForm from '$lib/components/compound/DeleteAdminForm.svelte';

	// State
	let admins = $state<Admin[]>([]);
	let loading = $state(true);
	let error = $state('');
	let successMessage = $state('');

	// Current user from page data
	const currentUser = $derived($page.data.user as Admin | undefined);
	const currentUserPrivilege = $derived(currentUser?.privilege ?? AdminPrivilegeLevel.DISABLED);

	// Create form fields
	let createEmail = $state('');
	let createPassword = $state('');
	let createName = $state('');
	let createPrivilege = $state(AdminPrivilegeLevel.READ_ONLY);
	let createLoading = $state(false);

	// Update form fields
	let updateUserId = $state('');
	let updateName = $state('');
	let updatePrivilege = $state<AdminPrivilegeLevel | ''>('');
	let updateLoading = $state(false);

	// Delete form fields
	let deleteUserId = $state('');
	let deleteLoading = $state(false);

	let selectedAdmins: Record<string, any>[] = $state([]);

	// Load admins on mount
	onMount(async () => {
		await loadAdmins();
	});

	async function loadAdmins() {
		try {
			loading = true;
			error = '';
			admins = await AdminsService.getAll(1000);
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to load admin users';
			console.error('Error loading admins:', err);
		} finally {
			loading = false;
		}
	}

	// Auto-fill delete/update forms when admin is selected
	$effect(() => {
		if (selectedAdmins.length === 1) {
			const selectedId = selectedAdmins[0].id.name;
			deleteUserId = selectedId;
			updateUserId = selectedId;
		}
	});

	// Transform data for table display
	const tableData = $derived(
		admins.map((admin) => ({
			id: { name: admin.id, href: `/admins/${admin.id}` },
			name: admin.name,
			privilege: getPrivilegeName(admin.privilege),
			createdAt: new Date(admin.createdAt).toLocaleDateString(),
			updatedAt: new Date(admin.updatedAt).toLocaleDateString(),
			lastSignIn: admin.lastSignIn ? new Date(admin.lastSignIn).toLocaleDateString() : 'Never'
		}))
	);

	// Helper function to get privilege name
	function getPrivilegeName(privilege: AdminPrivilegeLevel): string {
		return AdminsService.getPrivilegeName(privilege).replace('_', ' ');
	}

	// Calculate summary stats
	const summaryStats = $derived(() => {
		const total = admins.length;
		const superAdmins = admins.filter(
			(admin) => admin.privilege === AdminPrivilegeLevel.SUPER_ADMIN
		).length;
		const adminsCount = admins.filter(
			(admin) => admin.privilege === AdminPrivilegeLevel.ADMIN
		).length;
		const moderators = admins.filter(
			(admin) => admin.privilege === AdminPrivilegeLevel.MODERATOR
		).length;
		const readOnly = admins.filter(
			(admin) => admin.privilege === AdminPrivilegeLevel.READ_ONLY
		).length;

		return { total, superAdmins, adminsCount, moderators, readOnly };
	});

	// Get available privilege levels for current user

</script>

<svelte:head>
	<title>Admin Users - Stride Admin</title>
	<meta name="description" content="Manage administrator accounts and permissions" />
</svelte:head>

<div class="space-y-6 p-6">
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-semibold text-gray-900">Admin Users</h1>
			<p class="text-sm text-gray-600">Manage administrator accounts and permissions</p>
		</div>
		<Button onclick={loadAdmins} disabled={loading} size="sm" variant="secondary">
			{loading ? 'Refreshing...' : 'Refresh'}
		</Button>
	</div>

	<!-- Messages -->
	<Message type="error" message={error} />
	<Message type="success" message={successMessage} />

		<!-- Summary Cards -->
		<div class="grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-5">
			<Card class="flex items-center justify-between p-4">
				<div>
					<h4 class="text-sm text-gray-600">Total Admins</h4>
					<p class="text-2xl font-bold text-gray-900">{summaryStats().total}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4 class="text-sm text-gray-600">Super Admins</h4>
					<p class="text-2xl font-bold text-purple-600">{summaryStats().superAdmins}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4 class="text-sm text-gray-600">Admins</h4>
					<p class="text-2xl font-bold text-blue-600">{summaryStats().adminsCount}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4 class="text-sm text-gray-600">Moderators</h4>
					<p class="text-2xl font-bold text-green-600">{summaryStats().moderators}</p>
				</div>
			</Card>

			<Card class="flex items-center justify-between p-4">
				<div>
					<h4 class="text-sm text-gray-600">Read-only</h4>
					<p class="text-2xl font-bold text-gray-600">{summaryStats().readOnly}</p>
				</div>
			</Card>
		</div>

		<Tabs>
			<TabPanel label="Create Admin">
				<CreateAdminForm
					bind:error
					bind:successMessage
					callback={(newAdminId) => {
						loadAdmins();
						// Handle the new admin ID (e.g., reload the admin list)
						console.log('New admin created with ID:', newAdminId);
					}}
				/>
			</TabPanel>
			<TabPanel label="Update Admin">
				<UpdateAdminForm
					bind:error
					bind:successMessage
					constantUserId={updateUserId}
					callback={(updatedAdminId) => {
						loadAdmins();
						console.log('Admin updated with ID:', updatedAdminId);
					}}
				/>
			</TabPanel>
			<TabPanel label="Delete Admin">
				<DeleteAdminForm
					bind:error
					bind:successMessage
					constantUserId={deleteUserId}
					callback={(deletedAdminId) => {
						loadAdmins();
						console.log('Admin deleted with ID:', deletedAdminId);
					}}
				/>
			</TabPanel>
		</Tabs>

		<!-- Admins Table -->
		<Card class="p-6">
			<div class="mb-4 flex items-center justify-between">
				<h2 class="text-lg font-medium text-gray-900">Administrator Accounts Overview</h2>
				<span class="text-sm text-gray-600">{admins.length} total</span>
			</div>
            {#key admins.length}
			<Table data={tableData} bind:selected={selectedAdmins} class="max-h-96" />
            {/key}
			<p class="mt-2 text-xs text-gray-500">
				Select an admin to auto-fill the update/delete forms above.
			</p>
		</Card>
</div>
