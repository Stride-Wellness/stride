<script lang="ts">
    import { page } from '$app/stores';
    import { onMount } from 'svelte';
    import Card from '$lib/components/Card.svelte';
    import Button from '$lib/components/Button.svelte';
    import Message from '$lib/components/Message.svelte';
    import Input from '$lib/components/Input.svelte';
    import Table from '$lib/components/Table.svelte';
    import Link from '$lib/components/Link.svelte';
    import { UsersService } from '$lib/services/users';
    import type { User } from '$lib/services/users';
    import { AssignmentsService } from '$lib/services/assignments';
    import type { Assignment } from '$lib/services/assignments';
    import CreateAssignmentForm from '$lib/components/compound/CreateAssignmentForm.svelte';
    import UpdateAssignmentForm from '$lib/components/compound/UpdateAssignmentForm.svelte';
    import DeleteAssignmentForm from '$lib/components/compound/DeleteAssignmentForm.svelte';

    const userId = $derived($page.params.id);

    // State
    let user = $state<User | null>(null);
    let assignments = $state<Assignment[]>([]);
    let loading = $state(true);
    let saving = $state(false);
    let assignmentsLoading = $state(false);
    let error = $state<string | null>(null);
    let successMessage = $state<string | null>(null);
    let jsonText = $state('');
    
    let selectedAssignments: Record<string, any>[] = $state([]);

    // Load user data
    onMount(async () => {
        if (!userId) {
            error = 'No user ID provided.';
            loading = false;
            return;
        }

        try {
            user = await UsersService.getById(userId);
            if (!user) {
                error = 'User not found.';
                loading = false;
                return;
            }
            
            // Remove the id field from the JSON display
            const { id, ...userWithoutId } = user;
            jsonText = JSON.stringify(userWithoutId, null, 2);
            
            // Load assignments for this user
            await loadAssignments();
        } catch (err: any) {
            console.error('Error loading user:', err);
            
            if (err.code) {
                switch (err.code) {
                    case 'permission-denied':
                        error = 'Permission denied. You may not have access to view this user.';
                        break;
                    case 'not-found':
                        error = 'User not found. Please check the ID and try again.';
                        break;
                    case 'unauthenticated':
                        error = 'You are not authenticated. Please log in and try again.';
                        break;
                    default:
                        error = `Error: ${err.message || 'Failed to load user data. Please try again.'}`;
                }
            } else if (err.message) {
                error = err.message;
            } else {
                error = 'Failed to load user data. Please check the ID and try again.';
            }
        } finally {
            loading = false;
        }
    });

    // Save changes
    async function saveChanges() {
        if (!userId) {
            error = 'No user ID available.';
            return;
        }

        error = null;
        successMessage = null;
        saving = true;

         try {
        // Parse the JSON
        const updatedUserData = JSON.parse(jsonText);

        // Update the user based on type
        if (user?.type === 'provider') {
            await UsersService.updateProvider({
                userId: userId,
                name: updatedUserData.name,
                status: updatedUserData.status,
                providerRole: updatedUserData.providerRole,
                profile: updatedUserData.profile
            });
        } else {
            await UsersService.updateClient({
                userId: userId,
                name: updatedUserData.name,
                status: updatedUserData.status,
                profile: updatedUserData.profile
            });
        }

        // Update local state with the ID included
        user = { id: userId, ...updatedUserData };
        successMessage = 'User updated successfully!';
    } catch (err: any) {
        console.error('Error:', err);

        // Check if it's a JSON parse error
        if (err instanceof SyntaxError) {
            error = 'Invalid JSON format. Please check your syntax and try again.';
        } else if (err.code) {
            switch (err.code) {
                case 'permission-denied':
                    error = 'Permission denied. You may not have the required permissions to update this user.';
                    break;
                case 'not-found':
                    error = 'User not found. It may have been deleted or the ID is incorrect.';
                    break;
                case 'invalid-argument':
                    error = 'Invalid data provided. Please check all fields are correctly formatted.';
                    break;
                case 'unauthenticated':
                    error = 'You are not authenticated. Please log in and try again.';
                    break;
                default:
                    error = `Error: ${err.message || 'Failed to update user. Please try again.'}`;
            }
        } else if (err.message) {
            error = err.message;
        } else {
            error = 'Failed to update user. Please try again.';
        }
    } finally {
        saving = false;
    }
    }

    // Reset changes
    function resetChanges() {
        if (user) {
            // Remove the id field when resetting
            const { id, ...userWithoutId } = user;
            jsonText = JSON.stringify(userWithoutId, null, 2);
            error = null;
            successMessage = null;
        }
    }

    // Load assignments
    async function loadAssignments() {
        if (!userId || !user) return;
        
        assignmentsLoading = true;
        try {
            if (user.type === 'provider') {
                assignments = await AssignmentsService.getByProviderId(userId);
            } else if (user.type === 'client') {
                assignments = await AssignmentsService.getByClientId(userId);
            }
        } catch (err: any) {
            console.error('Error loading assignments:', err);
            // Don't set the main error state for sub-operations, just log it
            if (err.code === 'permission-denied') {
                console.warn('Permission denied loading assignments for user:', userId);
            }
        } finally {
            assignmentsLoading = false;
        }
    }

    // Get selected assignment IDs
    const selectedAssignmentIds = $derived(selectedAssignments.map((a) => a.id.name).join(', '));

    // Get formatted assignment data for table
    const assignmentTableData = $derived(assignments.map(assignment => ({
        id: { name: assignment.id, href: `/assignments/${assignment.id}` },
        provider: { name: assignment.providerId, href: `/users/${assignment.providerId}` },
        client: { name: assignment.clientId, href: `/users/${assignment.clientId}` },
        status: assignment.status,
        created: new Date(assignment.createdAt).toLocaleDateString()
    })));

    // Get user type label
    const userTypeLabel = $derived(() => {
        if (!user) return '';
        if (user.type === 'provider') {
            return `Provider (${UsersService.isProvider(user) ? user.providerRole.join(', ') : ''})`;
        }
        return 'Client';
    });
</script>

<div class="space-y-6 p-6">
    <div>
        <h1 class="text-2xl font-semibold text-gray-900">User Details</h1>
        <p class="text-sm text-gray-600">User ID: {userId}</p>
        {#if user}
            <p class="text-sm text-gray-600">
                Organization ID: <Link href={`/organizations/${user.organizationId}`} name={user.organizationId} />
            </p>
            <p class="text-sm text-gray-600">
                Division ID: <Link href={`/divisions/${user.divisionId}`} name={user.divisionId} />
            </p>
        {/if}
    </div>

    {#if !user}
        <Card class="p-6">
            <Message type="error" message="User not found." />
        </Card>
    {:else}
        <!-- Messages -->
        <Message type="error" message={error || undefined} />
        <Message type="success" message={successMessage || undefined} />

        <!-- User Summary -->
        <div class="grid grid-cols-2 gap-4 md:grid-cols-4">
            <Card class="flex items-center justify-between p-4">
                <div>
                    <h4>Name</h4>
                    <p class="text-lg font-bold text-gray-900">{user.name}</p>
                </div>
            </Card>

            <Card class="flex items-center justify-between p-4">
                <div>
                    <h4>Email</h4>
                    <p class="text-lg font-bold">{user.email}</p>
                </div>
            </Card>

            <Card class="flex items-center justify-between p-4">
                <div>
                    <h4>Type</h4>
                    <p class="text-lg font-bold">{userTypeLabel()}</p>
                </div>
            </Card>

            <Card class="flex items-center justify-between p-4">
                <div>
                    <h4>Status</h4>
                    <p class="text-lg font-bold">{user.status}</p>
                </div>
            </Card>
        </div>

        <!-- User JSON Editor -->
        <Card class="p-6">
            <div class="mb-4 flex items-center justify-between">
                <h2 class="text-lg font-medium text-gray-900">User Data (JSON)</h2>
                <div class="space-x-2">
                    <Button variant="secondary" size="sm" onclick={resetChanges} disabled={saving}>
                        Reset
                    </Button>
                    <Button size="sm" onclick={saveChanges} disabled={saving}>
                        {saving ? 'Saving...' : 'Save Changes'}
                    </Button>
                </div>
            </div>

            <Input
                as="textarea"
                bind:value={jsonText}
                class="h-96 w-full font-mono text-sm"
                variant="outline"
                placeholder="User JSON data will appear here..."
                disabled={saving}
            />

            <p class="mt-2 text-xs text-gray-500">
                Edit the JSON above and click "Save Changes" to update the user. Make sure to maintain
                valid JSON format.
            </p>
        </Card>

        <!-- Assignments Section -->
        <Card class="p-6">
            <div class="flex items-center justify-between mb-4">
                <h2 class="text-lg font-medium text-gray-900">Assignments</h2>
                <div class="text-sm text-gray-600">
                    {assignments.length} assignment{assignments.length !== 1 ? 's' : ''}
                </div>
            </div>

            {#if user.type === 'provider'}
                <div class="mb-4">
                    <CreateAssignmentForm 
                        variant="complementary"
                        bind:error 
                        bind:successMessage 
                        constantProviderId={userId}
                        callback={loadAssignments} 
                    />
                </div>
            {:else}
                <div class="mb-4">
                    <CreateAssignmentForm 
                        variant="complementary"
                        bind:error 
                        bind:successMessage 
                        constantClientId={userId}
                        callback={loadAssignments} 
                    />
                </div>
            {/if}

            <!-- Assignments Table -->
            {#if assignmentsLoading}
                <div class="text-center py-8">
                    <div class="text-gray-500">Loading assignments...</div>
                </div>
            {:else if assignments.length === 0}
                <div class="text-center py-8">
                    <div class="text-gray-500">No assignments found. Create one above to get started.</div>
                </div>
            {:else}
                {#key assignments.length}
                    <Table data={assignmentTableData} bind:selected={selectedAssignments} class="max-h-96" />
                {/key}
            {/if}
        </Card>

        <!-- Assignment Management -->
        {#if selectedAssignments.length > 0}
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <Card class="p-6">
                    <h3 class="text-lg font-medium text-gray-900 mb-4">Update Assignment</h3>
                    <UpdateAssignmentForm
                        bind:error
                        bind:successMessage
                        constantAssignmentId={selectedAssignmentIds}
                        callback={loadAssignments}
                    />
                </Card>

                <Card class="p-6">
                    <h3 class="text-lg font-medium text-gray-900 mb-4">Delete Assignment</h3>
                    <DeleteAssignmentForm
                        bind:error
                        bind:successMessage
                        constantAssignmentId={selectedAssignmentIds}
                        callback={loadAssignments}
                    />
                </Card>
            </div>
        {/if}
    {/if}
</div>