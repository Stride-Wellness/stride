<script lang="ts">
    import { AdminPrivilegeLevel, AdminsService, type Admin } from '$lib/services/admins';
    import { page } from '$app/stores';
    import Button from '$lib/components/Button.svelte';
    import Input from '$lib/components/Input.svelte';
    import Card from '$lib/components/Card.svelte';

    let {
        error = $bindable(),
        successMessage = $bindable(),
        prefilledUserId,
        callback
    }: {
        error: string | null;
        successMessage: string | null;
        prefilledUserId?: string;
        callback?: (deletedAdminId: string) => void;
    } = $props();

    const currentUser = $derived($page.data.user as Admin | undefined);
    const currentUserPrivilege = $derived(currentUser?.privilege ?? AdminPrivilegeLevel.DISABLED);

    // Delete form fields
    let deleteUserId = $state(prefilledUserId || '');
    let deleteLoading = $state(false);

    // Watch for prefilledUserId changes
    $effect(() => {
        if (prefilledUserId) {
            deleteUserId = prefilledUserId;
        }
    });

    async function handleDelete(event: Event) {
        event.preventDefault();
        deleteLoading = true;
        error = '';
        successMessage = '';

        if (!deleteUserId) {
            error = 'Admin ID is required';
            deleteLoading = false;
            return;
        }

        if (deleteUserId === currentUser?.id) {
            error = 'You cannot delete your own account';
            deleteLoading = false;
            return;
        }

        try {
            // Get target admin to check permissions
            const targetAdmin = await AdminsService.getById(deleteUserId);
            if (!targetAdmin) {
                error = 'Admin user not found';
                deleteLoading = false;
                return;
            }

            if (!AdminsService.canModify(currentUserPrivilege, targetAdmin.privilege)) {
                error = 'You do not have permission to delete this admin user';
                deleteLoading = false;
                return;
            }

            if (
                !confirm(
                    `Are you sure you want to delete admin user "${targetAdmin.name}"? This action cannot be undone.`
                )
            ) {
                deleteLoading = false;
                return;
            }

            await AdminsService.delete({ userId: deleteUserId });

            successMessage = 'Administrator deleted successfully!';

            // Reset form
            const deletedId = deleteUserId;
            deleteUserId = '';

            // Callback
            callback?.(deletedId);
        } catch (err) {
            error = err instanceof Error ? err.message : 'Failed to delete admin user';
            console.error('Error deleting admin:', err);
        } finally {
            deleteLoading = false;
        }
    }
</script>

<!-- Delete Admin -->
<Card class="border-red-200 bg-red-50 p-6">
    <h2 class="mb-4 text-lg font-medium text-red-900">Delete Administrator</h2>
    <form onsubmit={handleDelete} class="space-y-4">
        <Input
            type="text"
            placeholder="Admin User ID"
            size="md"
            variant="outline"
            bind:value={deleteUserId}
            required
            disabled={deleteLoading}
        />
        <Button
            type="submit"
            size="md"
            class="w-full border-red-600 bg-red-600 text-white hover:border-red-700 hover:bg-red-700"
            disabled={deleteLoading}
        >
            {deleteLoading ? 'Deleting...' : 'Delete Administrator'}
        </Button>
    </form>
    <p class="mt-2 text-xs text-red-700">
        This will permanently remove admin access and delete the account from Firebase Auth.
    </p>
</Card>l