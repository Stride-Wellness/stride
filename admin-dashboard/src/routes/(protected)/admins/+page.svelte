<script lang="ts">
	import type { AdminUser } from '$lib/types';
	import type { PageProps } from './$types';
	import Table from '$lib/components/Table.svelte';
	import Button from '$lib/components/Button.svelte';
	import Input from '$lib/components/Input.svelte';
	import Message from '$lib/components/Message.svelte';
	import { enhance } from '$app/forms';
  
  const { data, form }: PageProps = $props();
  
  // Make admins reactive to data changes
  const admins = $derived(JSON.parse(data.admins) as AdminUser[]);

  let email = $state('');
  let name = $state('');
  let privilege = $state(0);
  let id = $state('');

  // Reset form after successful submission
  $effect(() => {
    if (form?.success) {
      email = '';
      name = '';
      privilege = 0;
      id = '';
    }
  });

  // Transform data for table display - make this reactive too
  const tableData = $derived(admins.map(admin => ({
    id: admin.id,
    name: admin.name,
    email: admin.email,
    privilege: admin.privilege,
    disabled: admin.disabled ? 'Yes' : 'No',
    emailVerified: admin.emailVerified ? 'Yes' : 'No',
    createdAt: admin.createdAt ? new Date(admin.createdAt).toLocaleDateString() : 'N/A',
    lastSignIn: admin.lastSignIn ? new Date(admin.lastSignIn).toLocaleDateString() : 'Never',
    updatedAt: admin.updatedAt ? new Date(admin.updatedAt).toLocaleDateString() : 'N/A'
  })));
</script>

<div class="p-4 mt-8">
  <form method="post" action="?/create" class="space-y-4" use:enhance>
    <Input 
      type="email" 
      placeholder="Admin Email" 
      size="md" 
      variant="outline" 
      name="email"
      bind:value={email}
      required
    />
    <Input 
      type="text" 
      placeholder="Admin Name" 
      size="md" 
      variant="outline" 
      name="name"
      bind:value={name}
      required
    />
    <Input 
      type="number" 
      placeholder="Privilege Level (0-3)" 
      size="md" 
      variant="outline" 
      name="privilege"
      bind:value={privilege}
      min="0"
      max="3"
      required
    />
    <Button type="submit" size="md">Add Admin</Button>
  </form>
  <form method="post" action="?/delete" class="space-y-4" use:enhance>
    <Input 
      type="text" 
      placeholder="Admin Id" 
      size="md" 
      variant="outline" 
      name="id"
      bind:value={id}
      required
    />
    <Button type="submit" variant="danger" size="md">Delete Admin</Button>
  </form>
  
  <Message type="error" message={form?.error} />
  <Message type="success" message={form?.success ? "Operation completed successfully!" : undefined} />
  
  <Table data={tableData} class="mt-4" />
</div>