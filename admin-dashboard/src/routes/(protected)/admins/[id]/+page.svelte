<script lang="ts">
	import { page } from '$app/stores';
	import { enhance } from '$app/forms';
	import { onMount } from 'svelte';
	import Card from '$lib/components/Card.svelte';
	import Button from '$lib/components/Button.svelte';
	import Message from '$lib/components/Message.svelte';
	import Input from '$lib/components/Input.svelte';
	import type { AdminUser } from '$lib/types';

	let { data, form } = $props();

	const adminId = $derived($page.params.id);

	// State
	let admin = $state<AdminUser | null>(null);
	let loading = $state(false);
	let sendingEmail = $state(false);
	let sendingReset = $state(false);
	let error = $state<string | null>(null);
	let successMessage = $state<string | null>(null);
	
	// Form data
	let formData = $state({
		name: '',
		privilege: 0
	});

	// Load admin data from server
	onMount(() => {
		if (data.admin) {
			admin = JSON.parse(data.admin);
			if (admin) {
				formData = {
					name: admin.name || '',
					privilege: admin.privilege || 0
				};
			}
		}
	});

	// Handle form messages
	$effect(() => {
		if (form?.error) {
			error = form.error;
			successMessage = null;
		} else if (form?.success) {
			error = null;
			if (form.message) {
				successMessage = form.message;
			} else {
				successMessage = 'Admin updated successfully!';
			}
		}
	});

	function getPrivilegeName(level: number): string {
		switch (level) {
			case 0: return 'Super Admin';
			case 1: return 'Admin';
			case 2: return 'Manager';
			case 3: return 'Staff';
			default: return 'Unknown';
		}
	}
</script>

<div class="space-y-6 p-6">
	<div>
		<h1 class="text-2xl font-semibold text-gray-900">Admin Details</h1>
		<p class="text-sm text-gray-600">Admin ID: {adminId}</p>
	</div>

	{#if !admin}
		<Card class="p-6">
			<Message type="error" message="Admin not found." />
		</Card>
	{:else}
		<!-- Messages -->
		<Message type="error" message={error || undefined} />
		<Message type="success" message={successMessage || undefined} />

		<!-- Admin Information Card -->
		<Card class="p-6">
			<h2 class="text-lg font-medium text-gray-900 mb-4">Admin Information</h2>
			
			<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
				<!-- Left Column -->
				<div class="space-y-4">
					<div>
						<h5 class="block text-sm font-medium text-gray-700">Email</h5>
						<p class="mt-1 text-sm text-gray-900">{admin.email}</p>
					</div>
					
					<div>
						<h5 class="block text-sm font-medium text-gray-700">Current Privilege Level</h5>
						<p class="mt-1 text-sm text-gray-900">{admin.privilege} - {getPrivilegeName(admin.privilege)}</p>
					</div>

					<div>
						<h5 class="block text-sm font-medium text-gray-700">Email Verified</h5>
						<p class="mt-1 text-sm text-gray-900">{admin.emailVerified ? 'Verified' : 'Not Verified'}</p>
					</div>

					<div>
						<h5 class="block text-sm font-medium text-gray-700">Account Status</h5>
						<p class="mt-1 text-sm text-gray-900">{admin.disabled ? 'Disabled' : 'Active'}</p>
					</div>
				</div>

				<!-- Right Column -->
				<div class="space-y-4">
					<div>
						<h5 class="block text-sm font-medium text-gray-700">Created At</h5>
						<p class="mt-1 text-sm text-gray-900">
							{new Date(admin.createdAt).toLocaleString()}
						</p>
					</div>

					<div>
						<h5 class="block text-sm font-medium text-gray-700">Last Sign In</h5>
						<p class="mt-1 text-sm text-gray-900">
							{admin.lastSignIn ? new Date(admin.lastSignIn).toLocaleString() : 'Never'}
						</p>
					</div>

					<div>
						<h5 class="block text-sm font-medium text-gray-700">Last Updated</h5>
						<p class="mt-1 text-sm text-gray-900">
							{new Date(admin.updatedAt).toLocaleString()}
						</p>
					</div>
				</div>
			</div>
		</Card>

		<!-- Edit Admin Form -->
		<Card class="p-6">
			<h2 class="text-lg font-medium text-gray-900 mb-4">Edit Admin</h2>
			
			<form method="POST" action="?/update" use:enhance={() => {
				loading = true;
				error = null;
				successMessage = null;
				return async ({ update }) => {
					await update({ reset: false });
					loading = false;
					// Update the displayed admin data manually after successful update
					if (admin) {
						admin = {
							...admin,
							name: formData.name,
							privilege: formData.privilege,
							updatedAt: new Date()
						};
					}
				};
			}}>
				<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<Input
						label="Name"
						name="name"
						bind:value={formData.name}
						placeholder="Enter admin name"
						disabled={loading}
						required
					/>

					<Input
						as="select"
						label="Privilege Level"
						name="privilege"
						bind:value={formData.privilege}
						disabled={loading}
						options={[
							{ value: 0, label: '0 - Super Admin' },
							{ value: 1, label: '1 - Admin' },
							{ value: 2, label: '2 - Manager' },
							{ value: 3, label: '3 - Staff' }
						]}
					/>
				</div>

				<div class="mt-6">
					<Button type="submit" disabled={loading}>
						{loading ? 'Updating...' : 'Update Admin'}
					</Button>

          
				</div>
			</form>
		</Card>

		<!-- Admin Actions -->
		<div class="grid grid-cols-1 md:grid-cols-2 gap-6 mt-6">
					<form method="POST" action="?/sendEmailVerification" use:enhance={() => {
						sendingEmail = true;
						error = null;
						successMessage = null;
						return async ({ update }) => {
							sendingEmail = false;
							await update();
						};
					}}>
						<Button 
							type="submit" 
							variant="secondary" 
							size="md"
							disabled={sendingEmail || admin.emailVerified}
              class="w-full"
						>
							{sendingEmail ? 'Sending...' : 'Send Email Verification'}
						</Button>
					</form>

					<form method="POST" action="?/sendPasswordReset" use:enhance={() => {
						sendingReset = true;
						error = null;
						successMessage = null;
						return async ({ update }) => {
							sendingReset = false;
							await update();
						};
					}}>
						<Button 
							type="submit" 
							variant="secondary" 
							size="md"
							disabled={sendingReset}
              class="w-full"
						>
							{sendingReset ? 'Sending...' : 'Send Password Reset Link'}
						</Button>
					</form>
		</div>
	{/if}
</div>