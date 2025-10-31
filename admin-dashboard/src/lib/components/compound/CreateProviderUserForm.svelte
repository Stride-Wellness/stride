<script lang="ts">
	import { UsersService, type ProviderRole } from '$lib/services/users';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Card from '$lib/components/Card.svelte';

	let {
		variant = 'independent',
		error = $bindable(),
		successMessage = $bindable(),
		divisionIdOptions,
		constantEmail,
		constantPassword,
		constantName,
		constantOrganizationId,
		constantDivisionId,
		constantRoles,
		callback
	}: {
		variant?: 'independent' | 'complementary';
		error: string | null;
		divisionIdOptions?: { label: string; value: string }[];
		successMessage: string | null;
		constantEmail?: string;
		constantPassword?: string;
		constantName?: string;
		constantOrganizationId?: string;
		constantDivisionId?: string;
		constantRoles?: ProviderRole[];
		callback?: () => void;
	} = $props();

	// divisionIdOptions = divisionIdOptions?.map((option => ({
	// 	...option,
	// 	selected: option.value === constantDivisionId
	// })) );



	const availableRoles: ProviderRole[] = ['psw', 'lw', 'admin', 'manager'];

	let createProviderEmail = $derived(constantEmail || '');
	let createProviderPassword = $derived(constantPassword || '');
	let createProviderName = $derived(constantName || '');
	let createProviderOrgId = $derived(constantOrganizationId || '');
	let createProviderDivId = $derived(constantDivisionId || '');
	let createProviderRoles = $derived<ProviderRole[]>(constantRoles || []);
	let createProviderLoading = $state(false);

	// $effect(() => {
	// 	if (constantOrganizationId !== undefined) {
	// 		createProviderOrgId = constantOrganizationId;
	// 	}
	// });


	function toggleRole(role: ProviderRole) {
		if (createProviderRoles.includes(role)) {
			createProviderRoles = createProviderRoles.filter((r) => r !== role);
		} else {
			createProviderRoles = [...createProviderRoles, role];
		}
	}

	async function handleCreateProvider(event: Event) {
		event.preventDefault();
		createProviderLoading = true;
		error = null;
		successMessage = null;

		if (
			!createProviderEmail ||
			!createProviderPassword ||
			!createProviderName ||
			!createProviderOrgId ||
			!createProviderDivId
		) {
			error = 'All fields are required';
			createProviderLoading = false;
			return;
		}

		if (!createProviderEmail.includes('@')) {
			error = 'Please enter a valid email address';
			createProviderLoading = false;
			return;
		}

		if (createProviderPassword.length < 6) {
			error = 'Password must be at least 6 characters';
			createProviderLoading = false;
			return;
		}

		// In complementary mode, use default role if none selected
		const rolesToUse =
			variant === 'complementary' && createProviderRoles.length === 0
				? ['psw' as ProviderRole]
				: createProviderRoles;

		if (rolesToUse.length === 0) {
			error = 'At least one provider role is required';
			createProviderLoading = false;
			return;
		}

		try {
			await UsersService.createProvider({
				email: createProviderEmail,
				password: createProviderPassword,
				name: createProviderName,
				organizationId: createProviderOrgId,
				divisionId: createProviderDivId,
				providerRole: rolesToUse
			});

			successMessage = 'Provider user created successfully!';

			createProviderEmail = constantEmail || '';
			createProviderPassword = constantPassword || '';
			createProviderName = constantName || '';
			createProviderOrgId = constantOrganizationId || '';
			createProviderDivId = constantDivisionId || '';
			createProviderRoles = constantRoles || [];

			callback?.();
		} catch (err) {
			error = err instanceof Error ? err.message : 'Failed to create provider user';
			console.error('Error creating provider:', err);
		} finally {
			createProviderLoading = false;
		}
	}
	$inspect(constantOrganizationId).with(console.log);
		console.log(constantOrganizationId, "here org");
</script>

{#if variant === 'independent'}
	<Card class="p-6">
		<h2 class="mb-4 text-lg font-medium text-gray-900">Create Provider User</h2>
		<form onsubmit={handleCreateProvider} class="space-y-4">
			<Input
				type="email"
				placeholder="Email"
				size="md"
				variant="outline"
				bind:value={createProviderEmail}
				required
				disabled={createProviderLoading || !!constantEmail}
			/>
			<Input
				type="password"
				placeholder="Password (min 6 characters)"
				size="md"
				variant="outline"
				bind:value={createProviderPassword}
				required
				disabled={createProviderLoading || !!constantPassword}
			/>
			<Input
				type="text"
				placeholder="Full Name"
				size="md"
				variant="outline"
				bind:value={createProviderName}
				required
				disabled={createProviderLoading || !!constantName}
			/>
			<Input
				type="text"
				placeholder="Organization ID"
				size="md"
				variant="outline"
				bind:value={createProviderOrgId}
				required
				disabled={createProviderLoading || !!constantOrganizationId}
			/>
			<Input
				type="text"
				placeholder="Division ID"
				size="md"
				variant="outline"
				bind:value={createProviderDivId}
				required
				disabled={createProviderLoading || !!constantDivisionId}
			/>

			<div class="space-y-2">
				<label class="block text-sm font-medium text-gray-700"
					>Provider Roles (select at least one)</label
				>
				<div class="space-y-2">
					{#each availableRoles as role}
						<label class="flex items-center">
							<input
								type="checkbox"
								checked={createProviderRoles.includes(role)}
								onchange={() => toggleRole(role)}
								class="mr-2 rounded"
								disabled={createProviderLoading || !!constantRoles}
							/>
							<span class="text-sm capitalize">{role}</span>
						</label>
					{/each}
				</div>
			</div>

			<Button type="submit" size="md" class="w-full" disabled={createProviderLoading}>
				{createProviderLoading ? 'Creating...' : 'Create Provider'}
			</Button>
		</form>
	</Card>
{:else if variant === 'complementary'}
	<div class="">
		<form onsubmit={handleCreateProvider} class="space-y-4">
			<div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
				<Input
					type="email"
					placeholder="Email"
					size="md"
					variant="outline"
					bind:value={createProviderEmail}
					required
					disabled={createProviderLoading || !!constantEmail}
				/>
				<Input
					type="password"
					placeholder="Password"
					size="md"
					variant="outline"
					bind:value={createProviderPassword}
					required
					disabled={createProviderLoading || !!constantPassword}
				/>
				<Input
					type="text"
					placeholder="Full Name"
					size="md"
					variant="outline"
					bind:value={createProviderName}
					required
					disabled={createProviderLoading || !!constantName}
				/>
				<Input
					type="text"
					placeholder="Organization ID"
					size="md"
					variant="outline"
					bind:value={createProviderOrgId}
					required
					disabled={createProviderLoading || !!constantOrganizationId}
				/>
				<Input
					type="text"
					placeholder="Division ID"
					size="md"
					variant="outline"
					as="select"
					bind:value={createProviderDivId}
					required
					disabled={createProviderLoading || !!constantDivisionId}
					options={divisionIdOptions}
				/>

				<div class="flex space-x-2 space-y-2 items-center">
				<p class="text-sm font-medium text-gray-700">Provider Roles:</p>
				<div class="flex space-x-3 space-y-2">
					{#each availableRoles as role}
						<div class="items-center">
							<input
								type="checkbox"
								checked={createProviderRoles.includes(role)}
								onchange={() => toggleRole(role)}
								class="mr-1 rounded"
								disabled={createProviderLoading || !!constantRoles}
							/>
							<span class="text-sm capitalize">{role}</span>
						</div>
					{/each}
				</div>
			</div>
			</div>

			

			<Button type="submit" size="md" class="w-full" disabled={createProviderLoading}>
				{createProviderLoading ? 'Creating...' : 'Create'}
			</Button>
		</form>
		<p class="mt-2 text-xs text-gray-500">
			If no roles selected, default role 'psw' will be assigned. Edit roles after creation if
			needed.
		</p>
	</div>
{/if}
