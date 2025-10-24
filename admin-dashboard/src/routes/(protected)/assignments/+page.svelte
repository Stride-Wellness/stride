<script lang="ts">
    import type { Assignment } from '$lib/services/assignments';
    import { AssignmentsService } from '$lib/services';
    import Table from '$lib/components/Table.svelte';
    import Button from '$lib/components/Button.svelte';
    import Message from '$lib/components/Message.svelte';
    import Card from '$lib/components/Card.svelte';
    import { onMount } from 'svelte';
    import Tabs from '$lib/components/Tabs.svelte';
    import TabPanel from '$lib/components/TabPanel.svelte';
    import CreateAssignmentForm from '$lib/components/compound/CreateAssignmentForm.svelte';
    import UpdateAssignmentForm from '$lib/components/compound/UpdateAssignmentForm.svelte';
    import DeleteAssignmentForm from '$lib/components/compound/DeleteAssignmentForm.svelte';

    // State for assignments data
    let assignments = $state<Assignment[]>([]);
    let loading = $state(true);
    let error = $state<string | null>(null);
    let successMessage = $state<string | null>(null);

    // Update/Delete form fields (for auto-fill from table selection)
    let updateAssignmentId = $state('');
    let deleteAssignmentId = $state('');

    let selectedAssignments: Record<string, any>[] = $state([]);

    async function loadAssignments() {
        try {
            loading = true;
            error = null;
            assignments = await AssignmentsService.getAll(1000);
        } catch (err: any) {
            console.error('Error loading assignments:', err);

            if (err.code) {
                switch (err.code) {
                    case 'permission-denied':
                        error = 'Permission denied. You may not have access to view care assignments.';
                        break;
                    case 'unauthenticated':
                        error = 'You are not authenticated. Please log in to view assignments.';
                        break;
                    default:
                        error = `Error loading assignments: ${err.message || 'Please refresh the page and try again.'}`;
                }
            } else if (err.message) {
                if (err.message.includes('Failed to get assignments')) {
                    error =
                        'Failed to load assignments. Please check your internet connection and refresh the page.';
                } else {
                    error = err.message;
                }
            } else {
                error = 'Failed to load assignments. Please refresh the page.';
            }
        } finally {
            loading = false;
        }
    }

    // Load assignments on mount
    onMount(async () => {
        await loadAssignments();
    });

    // Auto-fill forms when assignment is selected
    $effect(() => {
        if (selectedAssignments.length === 1) {
            const selectedId = selectedAssignments[0].id.name;
            updateAssignmentId = selectedId;
            deleteAssignmentId = selectedId;
        } else if (selectedAssignments.length > 1) {
            // For bulk delete
            deleteAssignmentId = selectedAssignments.map((a) => a.id.name).join(', ');
        }
    });

    // Transform data for table display
    const tableData = $derived(
        assignments.map((assignment) => ({
            id: { name: assignment.id, href: `/assignments/${assignment.id}` },
            'Client ID': assignment.clientId.substring(0, 8) + '...',
            'Worker ID': assignment.workerId.substring(0, 8) + '...',
            'Division ID': assignment.divisionId.substring(0, 8) + '...',
            'Assigned By': assignment.assignedBy.substring(0, 8) + '...',
            Status: assignment.status,
            'Can Modify Exercises': assignment.permissions.canModifyExercises ? 'Yes' : 'No',
            'Can View Medical': assignment.permissions.canViewMedicalInfo ? 'Yes' : 'No',
            'Can Schedule': assignment.permissions.canScheduleSessions ? 'Yes' : 'No',
            'Assigned At': assignment.assignedAt
                ? new Date(assignment.assignedAt).toLocaleDateString()
                : 'N/A',
            'Last Session': assignment.lastSessionAt
                ? new Date(assignment.lastSessionAt).toLocaleDateString()
                : 'Never',
            Created: assignment.createdAt ? new Date(assignment.createdAt).toLocaleDateString() : 'N/A',
            Updated: assignment.updatedAt ? new Date(assignment.updatedAt).toLocaleDateString() : 'N/A'
        }))
    );

    // Calculate summary stats
    const summaryStats = $derived(() => {
        const total = assignments.length;
        const active = assignments.filter((assignment) => assignment.status === 'active').length;
        const inactive = assignments.filter((assignment) => assignment.status === 'inactive').length;
        const completed = assignments.filter((assignment) => assignment.status === 'completed').length;

        return { total, active, inactive, completed };
    });
</script>

<svelte:head>
    <title>Care Assignments - Stride Admin</title>
    <meta
        name="description"
        content="Manage care worker and resident assignments for elderly wellness facilities"
    />
</svelte:head>

{#if loading && assignments.length === 0}
    <div class="flex items-center justify-center p-6">
        <Card class="p-8">
            <p class="text-gray-600">Loading care assignments...</p>
        </Card>
    </div>
{:else}
    <div class="space-y-6 p-6">
        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-2xl font-semibold text-gray-900">Care Assignments</h1>
                <p class="text-sm text-gray-600">
                    Manage care worker and resident assignments across all facilities
                </p>
            </div>
            <Button onclick={loadAssignments} disabled={loading} size="sm" variant="secondary">
                {loading ? 'Refreshing...' : 'Refresh'}
            </Button>
        </div>

        <!-- Messages -->
        <Message type="error" message={error || undefined} />
        <Message type="success" message={successMessage || undefined} />

        <!-- Summary Cards -->
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
            <Card class="flex items-center justify-between p-4">
                <div>
                    <h4 class="text-sm text-gray-600">Total Assignments</h4>
                    <p class="text-2xl font-bold text-gray-900">{summaryStats().total}</p>
                </div>
            </Card>

            <Card class="flex items-center justify-between p-4">
                <div>
                    <h4 class="text-sm text-gray-600">Active</h4>
                    <p class="text-2xl font-bold text-green-600">{summaryStats().active}</p>
                </div>
            </Card>

            <Card class="flex items-center justify-between p-4">
                <div>
                    <h4 class="text-sm text-gray-600">Inactive</h4>
                    <p class="text-2xl font-bold text-gray-600">{summaryStats().inactive}</p>
                </div>
            </Card>

            <Card class="flex items-center justify-between p-4">
                <div>
                    <h4 class="text-sm text-gray-600">Completed</h4>
                    <p class="text-2xl font-bold text-blue-600">{summaryStats().completed}</p>
                </div>
            </Card>
        </div>

        <Tabs>
            <TabPanel label="Create Assignment">
                <CreateAssignmentForm
                    bind:error
                    bind:successMessage
                    callback={(newAssignmentId) => {
                        loadAssignments();
                        console.log('New care assignment created with ID:', newAssignmentId);
                    }}
                />
            </TabPanel>

            <TabPanel label="Update Assignment">
                <UpdateAssignmentForm
                    bind:error
                    bind:successMessage
                    prefilledAssignmentId={updateAssignmentId}
                    callback={(updatedAssignmentId) => {
                        loadAssignments();
                        console.log('Care assignment updated with ID:', updatedAssignmentId);
                    }}
                />
            </TabPanel>

            <TabPanel label="Delete Assignment">
                <DeleteAssignmentForm
                    bind:error
                    bind:successMessage
                    prefilledAssignmentId={deleteAssignmentId}
                    callback={(deletedAssignmentId) => {
                        loadAssignments();
                        console.log('Care assignment(s) deleted:', deletedAssignmentId);
                    }}
                />
            </TabPanel>
        </Tabs>

        <!-- Assignments Table -->
        <Card class="p-6">
            <div class="mb-4 flex items-center justify-between">
                <h2 class="text-lg font-medium text-gray-900">Care Assignments Overview</h2>
                <span class="text-sm text-gray-600">{assignments.length} total</span>
            </div>
            <Table data={tableData} bind:selected={selectedAssignments} class="max-h-96" />
            <p class="mt-2 text-xs text-gray-500">
                Select assignment(s) to auto-fill the update/delete forms above.
            </p>
        </Card>
    </div>
{/if}