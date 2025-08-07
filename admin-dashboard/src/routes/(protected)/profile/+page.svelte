<script lang="ts">
	import { authStore } from '$lib/stores/auth';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { doc, getDoc } from 'firebase/firestore';
	import { db } from '$lib/firebase/config';
	import type { AdminUser } from '$lib/types'; // Your Firestore user type
	import Dictionary from '$lib/components/Dictionary.svelte';
	import Card from '$lib/components/Card.svelte';
	import Button from '$lib/components/Button.svelte';

	async function handleSignOut() {
		await authStore.signOut();
		goto('/login');
	}

	const permissions: Record<number, string> = {
		0: 'God - you can do anything',
		1: 'Admin - you can do most things',
		2: 'User - you can do some things',
		3: 'Guest - you can do very little'
	};
	onMount(async () => {
		const userDoc = await getDoc(doc(db, 'admins', $authStore.firebaseUser?.uid as string));
		const userData = userDoc.exists() ? ({ id: userDoc.id, ...userDoc.data() } as AdminUser) : null;

		console.log('User data:', userData);
	});
</script>

<div class="flex flex-col items-center gap-4 mt-10">
	{#if $authStore.loading}
		<div>Loading user data...</div>
	{:else if $authStore.user}

  <div class="flex flex-col items-center gap-4">
		<Card class="bg-background mx-auto w-max">
			<h class="text-lg font-semibold">Welcome, {$authStore.user.name}</h>
			<Dictionary
        class="mt-4"
				data={{
					'User Id': $authStore.user.id,
					Email: $authStore.firebaseUser?.email,
					'Permission Level': permissions[$authStore.user.privilege]
				}}
			/>
		</Card>
		<Button onclick={handleSignOut} style="primary" size="md" class="w-full">Sign Out</Button>
	</div>
	{:else if $authStore.firebaseUser}
		<div>
			<p>
				Found Firebase user: {$authStore.firebaseUser.email}, but no record of you exists in the
				database, please contact one of the admins.
			</p>
		</div>
	{:else}
		<div>User data not found</div>
	{/if}
</div>
