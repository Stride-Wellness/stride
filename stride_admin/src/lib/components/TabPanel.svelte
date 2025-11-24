<!-- TabPanel.svelte -->
<script lang="ts">
    import { getContext, onMount, type Snippet } from 'svelte';

    let {
        label,
        disabled = false,
        children
    }: {
        label: string;
        disabled?: boolean;
        children: Snippet;
    } = $props();

    // Get context from parent Tab component
    const registerTab = getContext<(label: string, disabled: boolean, id: string) => number>('registerTab');
    const activeTab = getContext<{ current: number }>('activeTab');

    // Generate unique ID for this tab
    const tabId = crypto.randomUUID();
    let tabIndex = $state(-1);

    // Register this tab with parent when component mounts
    onMount(() => {
        tabIndex = registerTab(label, disabled, tabId);
    });

    // Only show content if this is the active tab
    const isActive = $derived(activeTab.current === tabIndex);
</script>

{#if isActive}
    {@render children()}
{/if}