<script lang="ts">
	import type { AdminUser } from '$lib/types';
	import type { PageProps } from './$types';
	import Table from '$lib/components/Table.svelte';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Message from '$lib/components/Message.svelte';
	import Card from '$lib/components/Card.svelte';
	import { enhance } from '$app/forms';

	const { data, form }: PageProps = $props();

	// Make admins reactive to data changes
	const admins = $derived(JSON.parse(data.admins) as AdminUser[]);

	let email = $state('');
	let name = $state('');
	let privilege = $state(0);
	let id = $state('');

	// Reset form after successful submission
	$effect(() => {
		if (form?.success) {
			email = '';
			name = '';
			privilege = 0;
			id = '';
		}
	});

	// Transform data for table display - make this reactive too
	const tableData = $derived(
		admins.map((admin) => ({
			id: admin.id,
			name: admin.name,
			email: admin.email,
			privilege: admin.privilege,
			disabled: admin.disabled ? 'Yes' : 'No',
			emailVerified: admin.emailVerified ? 'Yes' : 'No',
			createdAt: admin.createdAt ? new Date(admin.createdAt).toLocaleDateString() : 'N/A',
			lastSignIn: admin.lastSignIn ? new Date(admin.lastSignIn).toLocaleDateString() : 'Never',
			updatedAt: admin.updatedAt ? new Date(admin.updatedAt).toLocaleDateString() : 'N/A'
		}))
	);

	// Calculate summary stats
	const summaryStats = $derived(() => {
		const total = admins.length;
		const active = admins.filter((admin) => !admin.disabled).length;
		const verified = admins.filter((admin) => admin.emailVerified).length;
		const highPrivilege = admins.filter((admin) => admin.privilege <= 1).length;

		return { total, active, verified, highPrivilege };
	});
</script>

<div class="space-y-6 p-6">
	<div class="flex items-center justify-between">
		<h1 class="text-2xl font-semibold text-gray-900">Admin Users</h1>
		<p class="text-sm text-gray-600">Manage administrator accounts and permissions</p>
	</div>

	<!-- Summary Cards -->
	<div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
		<Card class="flex items-center justify-between p-4">
			<div>
				<h4>Total Admins</h4>
				<p class="text-2xl font-bold">{summaryStats().total}</p>
			</div>
		</Card>

		<Card class="flex items-center justify-between p-4">
			<div>
				<h4>Active Admins</h4>
				<p class="text-2xl font-bold">{summaryStats().active}</p>
			</div>
		</Card>

		<Card class="flex items-center justify-between p-4">
			<div>
				<h4>Email Verified</h4>
				<p class="text-2xl font-bold ">{summaryStats().verified}</p>
			</div>
		</Card>

		<Card class="flex items-center justify-between p-4">
			<div>
				<h4>High Privilege</h4>
				<p class="text-2xl font-bold">{summaryStats().highPrivilege}</p>
			</div>
		</Card>
	</div>

	<!-- Admin Management Actions -->
	<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
		<!-- Add New Admin -->
		<Card class="p-6">
			<h2>Add New Administrator</h2>
			<form method="post" action="?/create" class="space-y-4" use:enhance>
				<Input
					type="email"
					placeholder="Administrator Email"
					size="md"
					variant="outline"
					name="email"
					bind:value={email}
					required
				/>
				<Input
					type="text"
					placeholder="Full Name"
					size="md"
					variant="outline"
					name="name"
					bind:value={name}
					required
				/>
				<div class="space-y-2">
					<label class="block text-sm font-medium text-gray-700">Privilege Level</label>
					<Input
						type="number"
						placeholder="0-3 (0=Super Admin, 3=Limited)"
						size="md"
						variant="outline"
						name="privilege"
						bind:value={privilege}
						min="0"
						max="3"
						required
					/>
					<p class="text-xs text-gray-500">
						0: Super Admin • 1: Advanced Admin • 2: Basic Admin • 3: Read-only
					</p>
				</div>
				<Button type="submit" size="md" class="w-full">Create Administrator</Button>
			</form>
		</Card>

		<!-- Delete Admin -->
		<Card class="border-red-200 bg-red-50 p-6">
			<h2 class="text-red-900">Remove Administrator</h2>
			<form method="post" action="?/delete" class="space-y-4" use:enhance>
				<Input
					type="text"
					placeholder="Administrator ID"
					size="md"
					variant="outline"
					name="id"
					bind:value={id}
					required
				/>
				<Button
					type="submit"
					size="md"
					class="w-full border-red-600 bg-red-600 text-white hover:border-red-700 hover:bg-red-700"
				>
					Remove Administrator
				</Button>
			</form>
			<p class="mt-2 text-xs text-red-700">
				This will permanently remove admin access. The user will no longer be able to sign in.
			</p>
		</Card>
	</div>

	<!-- Messages -->
	<Message type="error" message={form?.error} />
	<Message
		type="success"
		message={form?.success ? 'Operation completed successfully!' : undefined}
	/>

	<!-- Admins Table -->
	<Card class="p-6">
		<h2>Administrator Accounts Overview</h2>
		<Table data={tableData} class="max-h-96" />
	</Card>
</div>
