<script lang="ts">
    import { AssignmentsService } from '$lib/services';
    import Button from '$lib/components/Button.svelte';
    import Input from '$lib/components/Input.svelte';
    import Card from '$lib/components/Card.svelte';

    let {
        error = $bindable(),
        successMessage = $bindable(),
        prefilledIds,
        constantAssignmentId,
        callback
    }: {
        error: string | null;
        successMessage: string | null;
        constantAssignmentId?: string;
        prefilledIds?: string[];
        callback?: (deletedAssignmentId: string) => void;
    } = $props();;
    // Delete form fields
    let deleteAssignmentId = $derived(constantAssignmentId || prefilledIds?.join(', ') || '');
    let deleteLoading = $state(false);

    // Watch for prefilledAssignmentId changes
    $effect(() => {
        if (constantAssignmentId) {
            deleteAssignmentId = constantAssignmentId;
        }
    });

    async function handleDelete(event: Event) {
        event.preventDefault();
        deleteLoading = true;
        error = '';
        successMessage = '';

        if (!deleteAssignmentId) {
            error = 'Assignment ID is required';
            deleteLoading = false;
            return;
        }

        if (
            !confirm(
                'Are you sure you want to delete this assignment? This action cannot be undone and will permanently remove the care assignment.'
            )
        ) {
            deleteLoading = false;
            return;
        }

        try {
            // Support comma-separated IDs for bulk deletion
            const assignmentsToDelete = deleteAssignmentId.split(',').map((id) => id.trim());
            
            for (const id of assignmentsToDelete) {
                await AssignmentsService.delete(id);
            }

            successMessage = `${assignmentsToDelete.length} assignment${assignmentsToDelete.length > 1 ? 's' : ''} deleted successfully!`;

            // Reset form
            const deletedIds = deleteAssignmentId;
            deleteAssignmentId = constantAssignmentId || '';

            // Callback
            callback?.(deletedIds);
        } catch (err: any) {
            console.error('Error deleting assignment:', err);

            // Parse specific Firebase/Firestore errors
            if (err.code) {
                switch (err.code) {
                    case 'permission-denied':
                        error =
                            'Permission denied. You may not have the required permissions to delete this care assignment.';
                        break;
                    case 'not-found':
                        error =
                            'Assignment not found. It may have already been deleted or the ID is incorrect. Please verify and try again.';
                        break;
                    case 'failed-precondition':
                        error =
                            'Cannot delete assignment. The assignment may have active sessions or dependencies.';
                        break;
                    case 'unauthenticated':
                        error = 'You are not authenticated. Please log in and try again.';
                        break;
                    default:
                        error = `Error: ${err.message || 'Failed to delete assignment. Please try again.'}`;
                }
            } else if (err.message) {
                if (err.message.includes('Failed to delete assignment')) {
                    error = 'Failed to delete assignment. Please check the assignment ID and try again.';
                } else {
                    error = err.message;
                }
            } else {
                error = 'An unexpected error occurred while deleting the assignment.';
            }
        } finally {
            deleteLoading = false;
        }
    }
</script>

<!-- Delete Assignment -->
<Card class="border-red-200 bg-red-50 p-6">
    <h2 class="mb-4 text-lg font-medium text-red-900">Delete Care Assignment</h2>
    <form onsubmit={handleDelete} class="space-y-4">
        <Input
            type="text"
            placeholder="Assignment ID (or comma-separated IDs for bulk delete)"
            size="md"
            variant="outline"
            bind:value={deleteAssignmentId}
            required
            disabled={deleteLoading}
        />
        <Button
            type="submit"
            size="md"
            class="w-full border-red-600 bg-red-600 text-white hover:border-red-700 hover:bg-red-700"
            disabled={deleteLoading}
        >
            {deleteLoading ? 'Deleting...' : 'Delete Assignment (Permanent)'}
        </Button>
    </form>
    <p class="mt-2 text-xs text-red-700">
        This will permanently delete the care assignment between provider and resident. This action cannot
        be undone.
    </p>
</Card>