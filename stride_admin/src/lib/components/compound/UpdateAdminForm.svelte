<script lang="ts">
    import { AdminPrivilegeLevel, AdminsService, type Admin } from '$lib/services/admins';
    import { page } from '$app/stores';
    import Button from '$lib/components/Button.svelte';
    import Input from '$lib/components/Input.svelte';
    import Card from '$lib/components/Card.svelte';
    import { getPrivilegeName } from '$lib/utils';

    let {
        variant = 'independent',
        error = $bindable(),
        successMessage = $bindable(),
        constantUserId: constantUserId,
        callback
    }: {
        variant?: 'independent' | 'complementary';
        error: string | null;
        successMessage: string | null;
        constantUserId?: string;
        callback?: (updatedAdminId: string) => void;
    } = $props();

    const currentUser = $derived($page.data.user as Admin | undefined);
    const currentUserPrivilege = $derived(currentUser?.privilege ?? AdminPrivilegeLevel.DISABLED);

    // Update form fields
    let updateUserId = $derived(constantUserId || '');
    let updateName = $state('');
    let updatePrivilege = $state<AdminPrivilegeLevel | ''>('');
    let updateLoading = $state(false);

    // Watch for prefilledUserId changes
    $effect(() => {
        if (constantUserId) {
            updateUserId = constantUserId;
        }
    });

    // Get available privilege levels for current user
    const availablePrivilegeLevels = $derived(
        AdminsService.getAvailablePrivilegeLevels(currentUserPrivilege)
    );

    async function handleUpdate(event: Event) {
        event.preventDefault();
        updateLoading = true;
        error = '';
        successMessage = '';

        if (!updateUserId) {
            error = 'Admin ID is required';
            updateLoading = false;
            return;
        }

        if (!updateName && !updatePrivilege) {
            error = 'No fields to update';
            updateLoading = false;
            return;
        }

        try {
            // Get target admin to check permissions
            const targetAdmin = await AdminsService.getById(updateUserId);
            if (!targetAdmin) {
                error = 'Admin user not found';
                updateLoading = false;
                return;
            }

            if (!AdminsService.canModify(currentUserPrivilege, targetAdmin.privilege)) {
                error = 'You do not have permission to modify this admin user';
                updateLoading = false;
                return;
            }

            const privilege = updatePrivilege !== '' ? updatePrivilege : undefined;
            if (privilege !== undefined && !AdminsService.canModify(currentUserPrivilege, privilege)) {
                error = `You cannot assign privilege level ${getPrivilegeName(privilege)}`;
                updateLoading = false;
                return;
            }

            await AdminsService.update({
                userId: updateUserId,
                name: updateName || undefined,
                privilege
            });

            successMessage = 'Administrator updated successfully!';

            // Reset form
            const updatedId = updateUserId;
            updateUserId = constantUserId ||'';
            updateName = '';
            updatePrivilege = '';

            // Callback
            callback?.(updatedId);
        } catch (err) {
            error = err instanceof Error ? err.message : 'Failed to update admin user';
            console.error('Error updating admin:', err);
        } finally {
            updateLoading = false;
        }
    }
</script>

{#if variant === 'independent'}
<!-- Update Admin -->
<Card class="p-6">
    <h2 class="mb-4 text-lg font-medium text-gray-900">Update Administrator</h2>
    <form onsubmit={handleUpdate} class="space-y-4">
        <Input
            type="text"
            placeholder="Admin User ID"
            size="md"
            variant="outline"
            bind:value={updateUserId}
            required
            disabled={updateLoading}
        />
        <Input
            type="text"
            placeholder="New Name (optional)"
            size="md"
            variant="outline"
            bind:value={updateName}
            disabled={updateLoading}
        />
        <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-700">
                New Privilege Level (optional)
            </label>
            <select
                bind:value={updatePrivilege}
                class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                disabled={updateLoading}
            >
                <option value="">-- No Change --</option>
                {#each availablePrivilegeLevels as level}
                    <option value={level}>{getPrivilegeName(level)}</option>
                {/each}
            </select>
        </div>
        <Button type="submit" size="md" class="w-full" disabled={updateLoading}>
            {updateLoading ? 'Updating...' : 'Update Administrator'}
        </Button>
    </form>
    <p class="mt-2 text-xs text-gray-500">
        Select an admin from the table below to auto-fill the ID.
    </p>
</Card>
{:else if variant === 'complementary'}
<div class="">
    <form onsubmit={handleUpdate} class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 items-end">
        <Input
            type="text"
            placeholder="Admin User ID"
            size="md"
            variant="outline"
            bind:value={updateUserId}
            required
            disabled={updateLoading}
        />
        <Input
            type="text"
            placeholder="New Name"
            size="md"
            variant="outline"
            bind:value={updateName}
            disabled={updateLoading}
        />
        <select
            bind:value={updatePrivilege}
            class="rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            disabled={updateLoading}
        >
            <option value="">-- Privilege --</option>
            {#each availablePrivilegeLevels as level}
                <option value={level}>{getPrivilegeName(level)}</option>
            {/each}
        </select>
        <Button type="submit" size="md" disabled={updateLoading}>
            {updateLoading ? 'Updating...' : 'Update'}
        </Button>
    </form>
</div>
{/if}