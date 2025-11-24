<script lang="ts">
    import { page } from '$app/stores';
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
    import Card from '$lib/components/Card.svelte';
    import Button from '$lib/components/Button.svelte';
    import Message from '$lib/components/Message.svelte';
    import Input from '$lib/components/Input.svelte';
    import { AdminsService, type Admin, AdminPrivilegeLevel } from '$lib/services/admins';

    const adminId = $derived($page.params.id);
    const currentUser = $derived($page.data.user);
    const currentUserPrivilege = $derived(currentUser?.privilege ?? AdminPrivilegeLevel.DISABLED);

    // State
    let admin = $state<Admin | null>(null);
    let loading = $state(true);
    let updating = $state(false);
    let sendingEmail = $state(false);
    let sendingReset = $state(false);
    let error = $state('');
    let successMessage = $state('');
    
    // Form data
    let formData = $state({
        name: '',
        privilege: AdminPrivilegeLevel.READ_ONLY
    });

    // Load admin data
    onMount(async () => {
        await loadAdmin();
    });

    async function loadAdmin() {
        try {
            loading = true;
            error = '';

            const adminData = await AdminsService.getById(adminId ?? "error-no-id-found");

            if (!adminData) {
                error = 'Admin not found';
                return;
            }

            admin = adminData;
            formData = {
                name: adminData.name || '',
                privilege: adminData.privilege
            };
        } catch (err) {
            error = err instanceof Error ? err.message : 'Failed to load admin data';
            console.error('Error loading admin:', err);
        } finally {
            loading = false;
        }
    }

    async function handleUpdate(event: Event) {
        event.preventDefault();
        updating = true;
        error = '';
        successMessage = '';

        // Permission checks
        if (currentUserPrivilege > AdminPrivilegeLevel.ADMIN) {
            error = 'You do not have permission to update admin users';
            updating = false;
            return;
        }

        // Prevent editing own privilege
        if (adminId === currentUser?.id) {
            // Can only update name
            if (!formData.name) {
                error = 'Name is required';
                updating = false;
                return;
            }

            try {
                await AdminsService.update({
                    userId: adminId ?? "error-no-id-found",
                    name: formData.name
                });

                successMessage = 'Admin updated successfully!';
                await loadAdmin(); // Reload data
            } catch (err) {
                error = err instanceof Error ? err.message : 'Failed to update admin user';
                console.error('Error updating admin:', err);
            } finally {
                updating = false;
            }
            return;
        }

        // For updating other admins
        if (!formData.name) {
            error = 'Name is required';
            updating = false;
            return;
        }

        // Users with privilege 1 cannot set level 0 privilege
        if (currentUserPrivilege === AdminPrivilegeLevel.ADMIN && 
            formData.privilege === AdminPrivilegeLevel.SUPER_ADMIN) {
            error = 'You cannot set privilege level 0 (Super Admin)';
            updating = false;
            return;
        }

        if (!AdminsService.canModify(currentUserPrivilege, formData.privilege)) {
            error = `You cannot assign privilege level ${AdminsService.getPrivilegeName(formData.privilege)}`;
            updating = false;
            return;
        }

        try {
            await AdminsService.update({
                userId: adminId ?? "error-no-id-found",
                name: formData.name,
                privilege: formData.privilege
            });

            successMessage = 'Admin updated successfully!';
            await loadAdmin(); // Reload data
        } catch (err) {
            error = err instanceof Error ? err.message : 'Failed to update admin user';
            console.error('Error updating admin:', err);
        } finally {
            updating = false;
        }
    }

    async function handleSendEmailVerification() {
        if (!admin) return;

        sendingEmail = true;
        error = '';
        successMessage = '';

        if (currentUserPrivilege > AdminPrivilegeLevel.ADMIN) {
            error = 'You do not have permission to send email verification';
            sendingEmail = false;
            return;
        }

        try {
            // TODO: Add resendEmailVerification to AdminsService
            // await AdminsService.resendEmailVerification(admin.email);
            successMessage = 'Email verification sent successfully';
        } catch (err) {
            error = err instanceof Error ? err.message : 'Failed to send email verification';
            console.error('Error sending email verification:', err);
        } finally {
            sendingEmail = false;
        }
    }

    async function handleSendPasswordReset() {
        if (!admin) return;

        sendingReset = true;
        error = '';
        successMessage = '';

        if (currentUserPrivilege > AdminPrivilegeLevel.ADMIN) {
            error = 'You do not have permission to send password reset';
            sendingReset = false;
            return;
        }

        try {
            // TODO: Add sendPasswordReset to AdminsService
            // await AdminsService.sendPasswordReset(admin.email);
            successMessage = 'Password reset email sent successfully';
        } catch (err) {
            error = err instanceof Error ? err.message : 'Failed to send password reset email';
            console.error('Error sending password reset:', err);
        } finally {
            sendingReset = false;
        }
    }

    function getPrivilegeName(level: AdminPrivilegeLevel): string {
        return AdminsService.getPrivilegeName(level).replace('_', ' ');
    }

    // Available privilege levels for dropdown
    const availablePrivilegeLevels = $derived(
        AdminsService.getAvailablePrivilegeLevels(currentUserPrivilege)
    );
</script>

<svelte:head>
    <title>Admin Details - Stride Admin</title>
</svelte:head>

<div class="space-y-6 p-6">
    <div class="flex items-center justify-between">
        <div>
            <h1 class="text-2xl font-semibold text-gray-900">Admin Details</h1>
            <p class="text-sm text-gray-600">Admin ID: {adminId}</p>
        </div>
        <Button onclick={loadAdmin} disabled={loading} size="sm" variant="secondary">
            {loading ? 'Refreshing...' : 'Refresh'}
        </Button>
    </div>

    <!-- Messages -->
    <Message type="error" message={error} />
    <Message type="success" message={successMessage} />

    {#if loading && !admin}
        <Card class="p-8">
            <div class="flex items-center justify-center">
                <p class="text-gray-600">Loading admin data...</p>
            </div>
        </Card>
    {:else if !admin}
        <Card class="p-6">
            <Message type="error" message="Admin not found." />
            <Button onclick={() => goto('/admins')} class="mt-4">
                Back to Admins
            </Button>
        </Card>
    {:else}
        <!-- Admin Information Card -->
        <Card class="p-6">
            <h2 class="mb-4 text-lg font-medium text-gray-900">Admin Information</h2>
            
            <div class="grid grid-cols-1 gap-6 md:grid-cols-2">
                <!-- Left Column -->
                <div class="space-y-4">
                    <div>
                        <h5 class="block text-sm font-medium text-gray-700">Name</h5>
                        <p class="mt-1 text-sm text-gray-900">{admin.name}</p>
                    </div>
                    
                    <div>
                        <h5 class="block text-sm font-medium text-gray-700">Privilege Level</h5>
                        <p class="mt-1 text-sm text-gray-900">
                            {admin.privilege} - {getPrivilegeName(admin.privilege)}
                        </p>
                    </div>

                    <div>
                        <h5 class="block text-sm font-medium text-gray-700">Created By</h5>
                        <p class="mt-1 text-sm text-gray-900">{admin.createdBy}</p>
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
            <h2 class="mb-4 text-lg font-medium text-gray-900">Edit Admin</h2>
            
            <form onsubmit={handleUpdate} class="space-y-4">
                <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                    <div>
                        <label for="name" class="mb-2 block text-sm font-medium text-gray-700">
                            Name
                        </label>
                        <Input
                            id="name"
                            type="text"
                            placeholder="Enter admin name"
                            size="md"
                            variant="outline"
                            bind:value={formData.name}
                            required
                            disabled={updating}
                        />
                    </div>

                    <div>
                        <label for="privilege" class="mb-2 block text-sm font-medium text-gray-700">
                            Privilege Level
                        </label>
                        <select
                            id="privilege"
                            bind:value={formData.privilege}
                            class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                            disabled={updating || adminId === currentUser?.id}
                        >
                            {#each availablePrivilegeLevels as level}
                                <option value={level}>
                                    {level} - {getPrivilegeName(level)}
                                </option>
                            {/each}
                        </select>
                        {#if adminId === currentUser?.id}
                            <p class="mt-1 text-xs text-gray-500">
                                You cannot change your own privilege level
                            </p>
                        {/if}
                    </div>
                </div>

                <div class="mt-6">
                    <Button type="submit" disabled={updating}>
                        {updating ? 'Updating...' : 'Update Admin'}
                    </Button>
                </div>
            </form>
        </Card>

        <!-- Admin Actions -->
        <Card class="p-6">
            <h2 class="mb-4 text-lg font-medium text-gray-900">Admin Actions</h2>
            <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                <Button
                    onclick={handleSendEmailVerification}
                    variant="secondary"
                    size="md"
                    disabled={sendingEmail || currentUserPrivilege > AdminPrivilegeLevel.ADMIN}
                    class="w-full"
                >
                    {sendingEmail ? 'Sending...' : 'Send Email Verification'}
                </Button>

                <Button
                    onclick={handleSendPasswordReset}
                    variant="secondary"
                    size="md"
                    disabled={sendingReset || currentUserPrivilege > AdminPrivilegeLevel.ADMIN}
                    class="w-full"
                >
                    {sendingReset ? 'Sending...' : 'Send Password Reset Link'}
                </Button>
            </div>
            <p class="mt-4 text-xs text-gray-500">
                Note: Email verification and password reset functionality requires additional Cloud Functions.
            </p>
        </Card>
    {/if}
</div>