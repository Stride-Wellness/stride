<script lang="ts">
	import Link from '$lib/components/Link.svelte';
	import { onMount } from 'svelte';
	import { auth } from '$lib/firebase/config';
	import { onAuthStateChanged } from 'firebase/auth';
	import { goto } from '$app/navigation';

	let loading = $state(true);
	let user: any = $state(null);

	onMount(() => {
		const unsubscribe = onAuthStateChanged(auth, (authUser) => {
			user = authUser;
			loading = false;

			if (!authUser) {
				goto('/login');
			}
		});

		return unsubscribe;
	});

	let { children } = $props();

	let pages = [
		{ name: 'Organizations', href: '/organizations' },
		{ name: 'Users', href: '/users' },
		{ name: 'Settings', href: '/settings' }
	];
</script>

{#if loading}
	<div>Loading...</div>
{:else if user}
	<header class="bg-background flex h-10 items-center justify-between border px-2">
		<div class="flex items-center gap-4">
			<h1 class="px-2">
				<a href="/">Admin Dashboard</a>
			</h1>
			<nav>
				{#each pages as { name, href }}
					<Link {href} {name} />
				{/each}
			</nav>
		</div>
		<div>
			<Link href="/profile" name="Profile" />
		</div>
	</header>
	<main class="bg-background">
		{@render children?.()}
	</main>
{:else}
	<div>Redirecting...</div>
{/if}
