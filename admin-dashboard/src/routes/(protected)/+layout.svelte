<script lang="ts">
    import Link from '$lib/components/Link.svelte';
    import { authStore } from '$lib/stores/auth';
    import { goto } from '$app/navigation';
	import Button from '$lib/components/Button.svelte';

    let { children } = $props();

    // Reactive statement to handle redirects
    $effect(() => {
        if (!$authStore.loading && !$authStore.firebaseUser) {
            goto('/login');
        }
    });

    let pages = [
        { name: 'Organizations', href: '/organizations' },
        { name: 'Users', href: '/users' },
        { name: 'Admins', href: '/admins' }
    ];

    async function handleSignOut() {
        await authStore.signOut();
        goto('/login');
    }
</script>

{#if $authStore.loading}
    <div>Loading...</div>
{:else if $authStore.user}
    <header class="bg-background flex h-15 items-center justify-between border px-2">
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
        <div class="flex items-center gap-2">
            <Link href="/profile" name="Profile" />
            <Button onclick={handleSignOut} variant="subtle" size="sm">Sign Out</Button>
        </div>
    </header>
    <main class="">
        {@render children?.()}
    </main>
{:else}
    <div>Redirecting...</div>
{/if}