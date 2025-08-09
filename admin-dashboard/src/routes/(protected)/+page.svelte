<script lang="ts">
  import Card from '$lib/components/Card.svelte';
  import Button from '$lib/components/Button.svelte';
  import { onMount } from 'svelte';
  import { OrganizationsService, AdminsService } from '$lib/services/organizations';
  import type { Organization } from '$lib/services/organizations';
  import type { AdminUser } from '$lib/types';
	import { goto } from '$app/navigation';

  // State for dashboard data
  let organizations = $state<Organization[]>([]);
  let admins = $state<AdminUser[]>([]);
  let loading = $state(true);
  let error = $state<string | null>(null);

  // Load dashboard data
  onMount(async () => {
    try {
      const [orgsData, adminsData] = await Promise.all([
        OrganizationsService.getAll(100),
        AdminsService.getAll(100) // Assuming you have this service
      ]);
      
      organizations = orgsData;
      admins = adminsData;
    } catch (err) {
      console.error('Error loading dashboard data:', err);
      error = 'Failed to load dashboard data.';
    } finally {
      loading = false;
    }
  });

  // Calculate metrics
  const metrics = $derived(() => {
    const totalOrgs = organizations.length;
    const activeOrgs = organizations.filter(org => org.status === 'active').length;
    const totalSeats = organizations.reduce((sum, org) => sum + org.totalSeats, 0);
    const usedSeats = organizations.reduce((sum, org) => sum + org.usedSeats, 0);
    const seatUtilization = totalSeats > 0 ? Math.round((usedSeats / totalSeats) * 100) : 0;
    
    const totalAdmins = admins.length;
    const activeAdmins = admins.filter(admin => !admin.disabled).length;
    const recentSignIns = admins.filter(admin => 
      admin.lastSignIn && new Date(admin.lastSignIn) > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    ).length;

    return {
      totalOrgs,
      activeOrgs,
      totalSeats,
      usedSeats,
      seatUtilization,
      totalAdmins,
      activeAdmins,
      recentSignIns
    };
  });

  // Recent activity (mock data for now)
  const recentActivity = [
    { action: 'New organization created', details: 'Sunset Retirement Homes', time: '2 hours ago' },
    { action: 'Admin user added', details: 'john.doe@example.com', time: '4 hours ago' },
    { action: 'Seat allocation updated', details: 'Pine Valley Care (+20 seats)', time: '1 day ago' },
    { action: 'Organization suspended', details: 'ABC Care Services', time: '2 days ago' }
  ];

  // System health indicators
  const systemHealth = {
    apiStatus: 'healthy',
    databaseStatus: 'healthy',
    storageStatus: 'healthy',
    lastBackup: '6 hours ago'
  };
</script>

{#if loading}
  <div class="p-6 flex items-center justify-center">
    <div class="text-lg">Loading dashboard...</div>
  </div>
{:else if error}
  <div class="p-6">
    <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
      {error}
    </div>
  </div>
{:else}
<div class="p-6 space-y-6">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1>Stride Admin Dashboard</h1>
    </div>
    <div class="text-sm text-gray-500">
      Last updated: {new Date().toLocaleString()}
    </div>
  </div>

  <!-- Key Metrics Grid -->
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
    <!-- Organizations -->
    <Card class="p-6">
      <div>
        <h4>Total Organizations</h4>
        <p class="text-3xl font-bold text-gray-900 mt-2">{metrics().totalOrgs}</p>
        <p class="text-sm text-gray-600 mt-1">{metrics().activeOrgs} active</p>
      </div>
    </Card>

    <!-- Platform Seats -->
    <Card class="p-6">
      <div>
        <h4>Platform Seats</h4>
        <p class="text-3xl font-bold text-gray-900 mt-2">{metrics().totalSeats}</p>
        <p class="text-sm text-gray-600 mt-1">{metrics().usedSeats} in use ({metrics().seatUtilization}%)</p>
      </div>
    </Card>

    <!-- Admin Users -->
    <Card class="p-6">
      <div>
        <h4>Admin Users</h4>
        <p class="text-3xl font-bold text-gray-900 mt-2">{metrics().totalAdmins}</p>
        <p class="text-sm text-gray-600 mt-1">{metrics().activeAdmins} active</p>
      </div>
    </Card>

    <!-- Recent Activity -->
    <Card class="p-6">
      <div>
        <h4>Recent Logins</h4>
        <p class="text-3xl font-bold text-gray-900 mt-2">{metrics().recentSignIns}</p>
        <p class="text-sm text-gray-600 mt-1">Past 7 days</p>
      </div>
    </Card>
  </div>

  <!-- Quick Actions & Recent Activity -->
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Quick Actions -->
    <Card class="p-6">
      <h2>Quick Actions</h2>
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <Button onclick={()=>goto('/organizations')} size="md" class="w-full justify-start">
          Add Organization
        </Button>

        <Button onclick={()=>goto('/admins')} size="md" variant="secondary" class="w-full justify-start">
          Add Admin User
        </Button>

        <Button onclick={()=>alert('Not Yet!')} size="md" variant="secondary" class="w-full justify-start">
          View Reports
        </Button>

        <Button onclick={()=>alert('Not Yet!')} size="md" variant="secondary" class="w-full justify-start">
          System Settings
        </Button>
      </div>
    </Card>

    <!-- Recent Activity -->
    <Card class="p-6">
      <h2>Recent Activity</h2>
      <div class="space-y-4">
        {#each recentActivity as activity}
          <div class="flex items-start space-x-3 p-3 bg-gray-50 rounded-lg">
            <div class="flex-shrink-0">
              <div class="w-2 h-2 bg-gray-400 rounded-full mt-2"></div>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900">{activity.action}</p>
              <p class="text-sm text-gray-600">{activity.details}</p>
              <p class="text-xs text-gray-400 mt-1">{activity.time}</p>
            </div>
          </div>
        {/each}
      </div>
    </Card>
  </div>

  <!-- System Status -->
  <Card class="p-6">
    <h2>System Health</h2>
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
      <div class="flex items-center space-x-3">
        <div class="w-3 h-3 bg-green-500 rounded-full"></div>
        <div>
          <p class="text-sm font-medium text-gray-900">API Status</p>
          <p class="text-xs text-gray-600 capitalize">{systemHealth.apiStatus}</p>
        </div>
      </div>
      
      <div class="flex items-center space-x-3">
        <div class="w-3 h-3 bg-green-500 rounded-full"></div>
        <div>
          <p class="text-sm font-medium text-gray-900">Database</p>
          <p class="text-xs text-gray-600 capitalize">{systemHealth.databaseStatus}</p>
        </div>
      </div>
      
      <div class="flex items-center space-x-3">
        <div class="w-3 h-3 bg-green-500 rounded-full"></div>
        <div>
          <p class="text-sm font-medium text-gray-900">Storage</p>
          <p class="text-xs text-gray-600 capitalize">{systemHealth.storageStatus}</p>
        </div>
      </div>
      
      <div class="flex items-center space-x-3">
        <div class="w-3 h-3 bg-gray-400 rounded-full"></div>
        <div>
          <p class="text-sm font-medium text-gray-900">Last Backup</p>
          <p class="text-xs text-gray-600">{systemHealth.lastBackup}</p>
        </div>
      </div>
    </div>
  </Card>
</div>
{/if}