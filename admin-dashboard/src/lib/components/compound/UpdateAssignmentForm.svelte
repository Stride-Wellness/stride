<script lang="ts">
    import { AssignmentsService } from '$lib/services';
    import Button from '$lib/components/Button.svelte';
    import Input from '$lib/components/Input.svelte';
    import Card from '$lib/components/Card.svelte';

    let {
        error = $bindable(),
        successMessage = $bindable(),
        prefilledAssignmentId,
        callback
    }: {
        error: string | null;
        successMessage: string | null;
        prefilledAssignmentId?: string;
        callback?: (updatedAssignmentId: string) => void;
    } = $props();

    // Update form fields
    let updateAssignmentId = $state(prefilledAssignmentId || '');
    let updateStatus = $state<'active' | 'inactive' | 'completed' | ''>('');
    let canModifyExercises = $state<boolean | null>(null);
    let canViewMedicalInfo = $state<boolean | null>(null);
    let canScheduleSessions = $state<boolean | null>(null);
    let updateLoading = $state(false);

    // Watch for prefilledAssignmentId changes
    $effect(() => {
        if (prefilledAssignmentId) {
            updateAssignmentId = prefilledAssignmentId;
        }
    });

    async function handleUpdate(event: Event) {
        event.preventDefault();
        updateLoading = true;
        error = '';
        successMessage = '';

        if (!updateAssignmentId) {
            error = 'Assignment ID is required';
            updateLoading = false;
            return;
        }

        // Check if at least one field is being updated
        if (
            !updateStatus &&
            canModifyExercises === null &&
            canViewMedicalInfo === null &&
            canScheduleSessions === null
        ) {
            error = 'No fields to update. Please change at least one field.';
            updateLoading = false;
            return;
        }

        try {
            // Build update object with only non-null values
            const updateData: any = {};

            if (updateStatus) {
                updateData.status = updateStatus;
            }

            // Only include permission updates if they're explicitly set
            if (
                canModifyExercises !== null ||
                canViewMedicalInfo !== null ||
                canScheduleSessions !== null
            ) {
                updateData.permissions = {};

                if (canModifyExercises !== null) {
                    updateData.permissions.canModifyExercises = canModifyExercises;
                }
                if (canViewMedicalInfo !== null) {
                    updateData.permissions.canViewMedicalInfo = canViewMedicalInfo;
                }
                if (canScheduleSessions !== null) {
                    updateData.permissions.canScheduleSessions = canScheduleSessions;
                }
            }

            await AssignmentsService.update(updateAssignmentId, updateData);

            successMessage = 'Assignment updated successfully!';

            // Reset form
            const updatedId = updateAssignmentId;
            updateAssignmentId = '';
            updateStatus = '';
            canModifyExercises = null;
            canViewMedicalInfo = null;
            canScheduleSessions = null;

            // Callback
            callback?.(updatedId);
        } catch (err: any) {
            console.error('Error updating assignment:', err);

            // Parse specific Firebase/Firestore errors
            if (err.code) {
                switch (err.code) {
                    case 'permission-denied':
                        error =
                            'Permission denied. You may not have the required permissions to update this assignment.';
                        break;
                    case 'not-found':
                        error =
                            'Assignment not found. It may have been deleted or the ID is incorrect. Please verify and try again.';
                        break;
                    case 'invalid-argument':
                        error = 'Invalid data provided. Please check all fields are correctly filled.';
                        break;
                    case 'failed-precondition':
                        error =
                            'Assignment update failed validation. Please check the assignment exists and try again.';
                        break;
                    case 'resource-exhausted':
                        error = 'Too many requests. Please wait a moment and try again.';
                        break;
                    case 'unauthenticated':
                        error = 'You are not authenticated. Please log in and try again.';
                        break;
                    default:
                        error = `Error: ${err.message || 'Failed to update assignment. Please try again.'}`;
                }
            } else if (err.message) {
                if (err.message.includes('Failed to update assignment')) {
                    error =
                        'Failed to update assignment. Please verify the assignment ID exists and try again.';
                } else {
                    error = err.message;
                }
            } else {
                error = 'An unexpected error occurred. Please try again.';
            }
        } finally {
            updateLoading = false;
        }
    }

    // Helper to toggle boolean state (null -> true -> false -> null)
    function togglePermission(current: boolean | null): boolean | null {
        if (current === null) return true;
        if (current === true) return false;
        return null;
    }
</script>

<!-- Update Assignment -->
<Card class="p-6">
    <h2 class="mb-4 text-lg font-medium text-gray-900">Update Assignment</h2>
    <form onsubmit={handleUpdate} class="space-y-4">
        <Input
            type="text"
            placeholder="Assignment ID"
            size="md"
            variant="outline"
            bind:value={updateAssignmentId}
            required
            disabled={updateLoading}
        />

        <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-700">
                Status (optional - leave empty for no change)
            </label>
            <select
                bind:value={updateStatus}
                class="w-full rounded-md border border-gray-300 px-3 py-2 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                disabled={updateLoading}
            >
                <option value="">-- No Change --</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
                <option value="completed">Completed</option>
            </select>
        </div>

        <!-- Permissions (optional) -->
        <div class="space-y-3">
            <h3 class="text-sm font-medium text-gray-900">
                Update Permissions (optional - leave unchecked for no change)
            </h3>
            <div class="space-y-2">
                <label class="flex items-center space-x-2">
                    <input
                        type="checkbox"
                        checked={canModifyExercises === true}
                        indeterminate={canModifyExercises === null}
                        onchange={() => (canModifyExercises = togglePermission(canModifyExercises))}
                        class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        disabled={updateLoading}
                    />
                    <span class="text-sm text-gray-700">
                        Can Modify Exercises
                        {canModifyExercises === null ? '(no change)' : canModifyExercises ? '(yes)' : '(no)'}
                    </span>
                </label>
                <label class="flex items-center space-x-2">
                    <input
                        type="checkbox"
                        checked={canViewMedicalInfo === true}
                        indeterminate={canViewMedicalInfo === null}
                        onchange={() => (canViewMedicalInfo = togglePermission(canViewMedicalInfo))}
                        class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        disabled={updateLoading}
                    />
                    <span class="text-sm text-gray-700">
                        Can View Medical Info
                        {canViewMedicalInfo === null ? '(no change)' : canViewMedicalInfo ? '(yes)' : '(no)'}
                    </span>
                </label>
                <label class="flex items-center space-x-2">
                    <input
                        type="checkbox"
                        checked={canScheduleSessions === true}
                        indeterminate={canScheduleSessions === null}
                        onchange={() => (canScheduleSessions = togglePermission(canScheduleSessions))}
                        class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        disabled={updateLoading}
                    />
                    <span class="text-sm text-gray-700">
                        Can Schedule Sessions
                        {canScheduleSessions === null ? '(no change)' : canScheduleSessions ? '(yes)' : '(no)'}
                    </span>
                </label>
            </div>
            <p class="text-xs text-gray-500">
                Click once to enable, twice to disable, three times to leave unchanged.
            </p>
        </div>

        <Button type="submit" size="md" class="w-full" disabled={updateLoading}>
            {updateLoading ? 'Updating...' : 'Update Assignment'}
        </Button>
    </form>
    <p class="mt-2 text-xs text-gray-500">
        Select an assignment from the table below to auto-fill the ID.
    </p>
</Card>