<script lang="ts">
    import { AssignmentsService } from '$lib/services';
    import Button from '$lib/components/Button.svelte';
    import Input from '$lib/components/Input.svelte';
    import Card from '$lib/components/Card.svelte';

    let {
        error = $bindable(),
        successMessage = $bindable(),
        constantClientId,
        constantWorkerId,
        constantDivisionId,
        constantAssignedBy,
        callback
    }: {
        error: string | null;
        successMessage: string | null;
        constantClientId?: string;
        constantWorkerId?: string;
        constantDivisionId?: string;
        constantAssignedBy?: string;
        callback?: (newAssignmentId: string) => void;
    } = $props();

    // Form state for creating assignments
    let clientId = $state(constantClientId || '');
    let workerId = $state(constantWorkerId || '');
    let divisionId = $state(constantDivisionId || '');
    let assignedBy = $state(constantAssignedBy || '');
    let canModifyExercises = $state(false);
    let canViewMedicalInfo = $state(false);
    let canScheduleSessions = $state(false);
    let createLoading = $state(false);

    // Watch for constant prop changes
    $effect(() => {
        if (constantClientId) clientId = constantClientId;
        if (constantWorkerId) workerId = constantWorkerId;
        if (constantDivisionId) divisionId = constantDivisionId;
        if (constantAssignedBy) assignedBy = constantAssignedBy;
    });

    // Handle create assignment
    async function handleCreateAssignment(event: Event) {
        event.preventDefault();
        createLoading = true;
        error = '';
        successMessage = '';

        // Validation
        if (!clientId || !workerId || !divisionId || !assignedBy) {
            error = 'All fields are required';
            createLoading = false;
            return;
        }

        try {
            const newAssignment = await AssignmentsService.create({
                clientId,
                workerId,
                divisionId,
                assignedBy,
                permissions: {
                    canModifyExercises,
                    canViewMedicalInfo,
                    canScheduleSessions
                }
            });

            successMessage = 'Assignment created successfully!';

            // Reset form
            const assignmentId = newAssignment.id;
            clientId = '';
            workerId = '';
            divisionId = '';
            assignedBy = '';
            canModifyExercises = false;
            canViewMedicalInfo = false;
            canScheduleSessions = false;

            // Callback
            callback?.(assignmentId);
        } catch (err: any) {
            console.error('Error creating assignment:', err);

            // Parse specific Firebase/Firestore errors
            if (err.code) {
                switch (err.code) {
                    case 'permission-denied':
                        error =
                            'Permission denied. You may not have the required permissions or the organization/users may not exist.';
                        break;
                    case 'not-found':
                        error =
                            'Organization, client, worker, or division not found. Please verify the IDs are correct.';
                        break;
                    case 'already-exists':
                        error = 'This assignment already exists.';
                        break;
                    case 'invalid-argument':
                        error = 'Invalid data provided. Please check all fields are correctly filled.';
                        break;
                    case 'failed-precondition':
                        error =
                            'Assignment creation failed validation. All users must exist, belong to the organization and division.';
                        break;
                    case 'resource-exhausted':
                        error = 'Too many requests. Please wait a moment and try again.';
                        break;
                    case 'unauthenticated':
                        error = 'You are not authenticated. Please log in and try again.';
                        break;
                    default:
                        error = `Error: ${err.message || 'Failed to create assignment. Please try again.'}`;
                }
            } else if (err.message) {
                if (err.message.includes('Failed to create assignment')) {
                    error =
                        'Failed to create assignment. Please verify all user and organization IDs exist and try again.';
                } else {
                    error = err.message;
                }
            } else {
                error = 'An unexpected error occurred. Please try again.';
            }
        } finally {
            createLoading = false;
        }
    }
</script>

<!-- Create Assignment Form -->
<Card class="p-6">
    <h2 class="mb-4 text-lg font-medium text-gray-900">Create New Assignment</h2>
    <form onsubmit={handleCreateAssignment} class="space-y-4">
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
            <Input
                type="text"
                placeholder="Client ID"
                size="md"
                variant="outline"
                bind:value={clientId}
                required
                disabled={createLoading}
            />
            <Input
                type="text"
                placeholder="Worker ID"
                size="md"
                variant="outline"
                bind:value={workerId}
                required
                disabled={createLoading}
            />
            <Input
                type="text"
                placeholder="Division ID"
                size="md"
                variant="outline"
                bind:value={divisionId}
                required
                disabled={createLoading}
            />
            <Input
                type="text"
                placeholder="Assigned By (User ID)"
                size="md"
                variant="outline"
                bind:value={assignedBy}
                required
                disabled={createLoading}
            />
        </div>

        <!-- Permissions -->
        <div class="space-y-3">
            <h3 class="text-sm font-medium text-gray-900">Assignment Permissions</h3>
            <div class="flex flex-wrap gap-4">
                <label class="flex items-center space-x-2">
                    <input
                        type="checkbox"
                        bind:checked={canModifyExercises}
                        class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        disabled={createLoading}
                    />
                    <span class="text-sm text-gray-700">Can Modify Exercises</span>
                </label>
                <label class="flex items-center space-x-2">
                    <input
                        type="checkbox"
                        bind:checked={canViewMedicalInfo}
                        class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        disabled={createLoading}
                    />
                    <span class="text-sm text-gray-700">Can View Medical Info</span>
                </label>
                <label class="flex items-center space-x-2">
                    <input
                        type="checkbox"
                        bind:checked={canScheduleSessions}
                        class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                        disabled={createLoading}
                    />
                    <span class="text-sm text-gray-700">Can Schedule Sessions</span>
                </label>
            </div>
        </div>

        <Button type="submit" size="md" class="w-full" disabled={createLoading}>
            {createLoading ? 'Creating...' : 'Create Assignment'}
        </Button>
    </form>
</Card>