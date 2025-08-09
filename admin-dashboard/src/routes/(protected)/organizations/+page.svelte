<script lang="ts">
	import type { Organization } from '$lib/services';
	import { OrganizationsService } from '$lib/services';
	import Table from '$lib/components/Table.svelte';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Message from '$lib/components/Message.svelte';
	import Card from '$lib/components/Card.svelte';
	import { enhance } from '$app/forms';
	import { onMount } from 'svelte';
  
  const { form }: { form: any } = $props();
  
  // State for organizations data
  let organizations = $state<Organization[]>([]);
  let loading = $state(true);
  let error = $state<string | null>(null);
  let successMessage = $state<string | null>(null);

  // Form state for creating organizations
  let name = $state('');
  let totalSeats = $state(10);
  let stripeUserId = $state('');

  // Form state for updating organization status
  let updateStatusId = $state('');
  let updateStatus = $state<'active' | 'suspended' | 'cancelled'>('active');

  // Form state for updating seats
  let updateSeatsId = $state('');
  let updateSeatsCount = $state(10);

  // Load organizations on mount
  onMount(async () => {
    try {
      organizations = await OrganizationsService.getAll(1000);
    } catch (err) {
      console.error('Error loading organizations:', err);
      error = 'Failed to load organizations. Please refresh the page.';
    } finally {
      loading = false;
    }
  });

  // Helper function to reload organizations
  async function reloadOrganizations() {
    try {
      organizations = await OrganizationsService.getAll(1000);
    } catch (err) {
      console.error('Error reloading organizations:', err);
      error = 'Failed to reload organizations.';
    }
  }

  // Handle create organization
  async function handleCreateOrganization(event: Event) {
    event.preventDefault();
    
    // Clear previous messages
    error = null;
    successMessage = null;

    // Validation
    if (!name || !stripeUserId || totalSeats < 1) {
      error = 'All fields are required and total seats must be at least 1';
      return;
    }

    if (name.length < 2) {
      error = 'Organization name must be at least 2 characters';
      return;
    }

    try {
      await OrganizationsService.create({
        name,
        totalSeats,
        stripeUserId
      });

      // Reset form
      name = '';
      totalSeats = 10;
      stripeUserId = '';
      
      successMessage = 'Organization created successfully!';
      await reloadOrganizations();
    } catch (err) {
      console.error('Error creating organization:', err);
      error = 'Failed to create organization. Please try again.';
    }
  }

  // Handle update status
  async function handleUpdateStatus(event: Event) {
    event.preventDefault();
    
    error = null;
    successMessage = null;

    if (!updateStatusId || !updateStatus) {
      error = 'Organization ID and status are required';
      return;
    }

    try {
      await OrganizationsService.update(updateStatusId, { status: updateStatus });
      
      updateStatusId = '';
      updateStatus = 'active';
      
      successMessage = 'Organization status updated successfully!';
      await reloadOrganizations();
    } catch (err) {
      console.error('Error updating organization status:', err);
      error = 'Failed to update organization status. Please try again.';
    }
  }

  // Handle update seats
  async function handleUpdateSeats(event: Event) {
    event.preventDefault();
    
    error = null;
    successMessage = null;

    if (!updateSeatsId || updateSeatsCount < 1) {
      error = 'Organization ID is required and seat count must be at least 1';
      return;
    }

    try {
      await OrganizationsService.update(updateSeatsId, { totalSeats: updateSeatsCount });
      
      updateSeatsId = '';
      updateSeatsCount = 10;
      
      successMessage = 'Organization seats updated successfully!';
      await reloadOrganizations();
    } catch (err) {
      console.error('Error updating organization seats:', err);
      error = 'Failed to update organization seats. Please try again.';
    }
  }

  // Remove the old effect that listened to form?.success
  // $effect(() => {
  //   if (form?.success) {
  //     // Reload data
  //     OrganizationsService.getAll(1000).then(data => {
  //       organizations = data;
  //     }).catch(err => {
  //       console.error('Error reloading organizations:', err);
  //     });
  //   }
  // });

  // Transform data for table display
  const tableData = $derived(organizations.map(org => ({
    id: org.id,
    name: org.name,
    status: org.status,
    'Total Seats': org.totalSeats,
    'Used Seats': org.usedSeats,
    'Utilization': `${Math.round((org.usedSeats / org.totalSeats) * 100)}%`,
    'Stripe ID': org.stripeUserId,
    'Created': org.createdAt ? new Date(org.createdAt).toLocaleDateString() : 'N/A',
    'Updated': org.updatedAt ? new Date(org.updatedAt).toLocaleDateString() : 'N/A'
  })));

  // Calculate summary stats
  const summaryStats = $derived(() => {
    const total = organizations.length;
    const active = organizations.filter(org => org.status === 'active').length;
    const suspended = organizations.filter(org => org.status === 'suspended').length;
    const cancelled = organizations.filter(org => org.status === 'cancelled').length;
    const totalSeats = organizations.reduce((sum, org) => sum + org.totalSeats, 0);
    const usedSeats = organizations.reduce((sum, org) => sum + org.usedSeats, 0);
    
    return { total, active, suspended, cancelled, totalSeats, usedSeats };
  });
</script>

{#if loading}
  <div class="p-6 flex items-center justify-center">
    <div class="text-lg">Loading organizations...</div>
  </div>
{:else if error}
  <div class="p-6">
    <Message type="error" message={error} />
  </div>
{:else}
<div class="p-6 space-y-6">
  <div class="flex items-center justify-between">
    <h1 class="text-2xl font-semibold text-gray-900">Organizations Management</h1>
  </div>

  <!-- Summary Cards -->
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
    <Card class="p-4">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm font-medium text-gray-600">Total Organizations</p>
          <p class="text-2xl font-bold text-gray-900">{summaryStats().total}</p>
        </div>
      </div>
    </Card>
    
    <Card class="p-4">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm font-medium text-gray-600">Active</p>
          <p class="text-2xl font-bold text-green-600">{summaryStats().active}</p>
        </div>
      </div>
    </Card>
    
    <Card class="p-4">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm font-medium text-gray-600">Total Seats</p>
          <p class="text-2xl font-bold text-blue-600">{summaryStats().totalSeats}</p>
        </div>
      </div>
    </Card>
    
    <Card class="p-4">
      <div class="flex items-center justify-between">
        <div>
          <p class="text-sm font-medium text-gray-600">Seats Utilized</p>
          <p class="text-2xl font-bold text-purple-600">{summaryStats().usedSeats}</p>
        </div>
      </div>
    </Card>
  </div>

  <!-- Create Organization Form -->
    <!-- Create Organization Form -->
  <Card class="p-6">
    <h2 class="text-lg font-medium text-gray-900 mb-4">Create New Organization</h2>
    <form onsubmit={handleCreateOrganization} class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <Input 
        type="text" 
        placeholder="Organization Name" 
        size="md" 
        variant="outline" 
        name="name"
        bind:value={name}
        required
      />
      <Input 
        type="number" 
        placeholder="Total Seats" 
        size="md" 
        variant="outline" 
        name="totalSeats"
        bind:value={totalSeats}
        min="1"
        required
      />
      <Input 
        type="text" 
        placeholder="Stripe User ID" 
        size="md" 
        variant="outline" 
        name="stripeUserId"
        bind:value={stripeUserId}
        required
      />
      <Button type="submit" size="md" class="md:col-span-3">Create Organization</Button>
    </form>
  </Card>

  <!-- Management Actions -->
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Update Status -->
    <Card class="p-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Update Organization Status</h2>
      <form onsubmit={handleUpdateStatus} class="space-y-4">
        <Input 
          type="text" 
          placeholder="Organization ID" 
          size="md" 
          variant="outline" 
          name="id"
          bind:value={updateStatusId}
          required
        />
        <select 
          name="status" 
          bind:value={updateStatus}
          class="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          required
        >
          <option value="active">Active</option>
          <option value="suspended">Suspended</option>
          <option value="cancelled">Cancelled</option>
        </select>
        <Button type="submit" size="md" variant="secondary" class="w-full">Update Status</Button>
      </form>
    </Card>

    <!-- Update Seats -->
    <Card class="p-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Update Organization Seats</h2>
      <form onsubmit={handleUpdateSeats} class="space-y-4">
        <Input 
          type="text" 
          placeholder="Organization ID" 
          size="md" 
          variant="outline" 
          name="id"
          bind:value={updateSeatsId}
          required
        />
        <Input 
          type="number" 
          placeholder="New Total Seats" 
          size="md" 
          variant="outline" 
          name="totalSeats"
          bind:value={updateSeatsCount}
          min="1"
          required
        />
        <Button type="submit" size="md" variant="secondary" class="w-full">Update Seats</Button>
      </form>
    </Card>
  </div>

  <!-- Messages -->
  <Message type="error" message={error || undefined} />
  <Message type="success" message={successMessage || undefined} />

  <!-- Management Actions -->
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Update Status -->
    <Card class="p-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Update Organization Status</h2>
      <form method="post" action="?/updateStatus" class="space-y-4" use:enhance>
        <Input 
          type="text" 
          placeholder="Organization ID" 
          size="md" 
          variant="outline" 
          name="id"
          bind:value={updateStatusId}
          required
        />
        <Input 
          as="select"
          name="status" 
          bind:value={updateStatus}
          size="md"
          variant="outline"
          required
        >
          <option value="active">Active</option>
          <option value="suspended">Suspended</option>
          <option value="cancelled">Cancelled</option>
        </Input>
        <Button type="submit" size="md" variant="secondary" class="w-full">Update Status</Button>
      </form>
    </Card>

    <!-- Update Seats -->
    <Card class="p-6">
      <h2 class="text-lg font-medium text-gray-900 mb-4">Update Organization Seats</h2>
      <form method="post" action="?/updateSeats" class="space-y-4" use:enhance>
        <Input 
          type="text" 
          placeholder="Organization ID" 
          size="md" 
          variant="outline" 
          name="id"
          bind:value={updateSeatsId}
          required
        />
        <Input 
          type="number" 
          placeholder="New Total Seats" 
          size="md" 
          variant="outline" 
          name="totalSeats"
          bind:value={updateSeatsCount}
          min="1"
          required
        />
        <Button type="submit" size="md" variant="secondary" class="w-full">Update Seats</Button>
      </form>
    </Card>
  </div>

  <!-- Messages -->
  <Message type="error" message={form?.error} />
  <Message type="success" message={form?.success ? "Operation completed successfully!" : undefined} />
  
  <!-- Organizations Table -->
  <Card class="p-6">
    <h2 class="text-lg font-medium text-gray-900 mb-4">All Organizations</h2>
    <Table data={tableData} class="max-h-96" />
  </Card>
</div>
{/if}