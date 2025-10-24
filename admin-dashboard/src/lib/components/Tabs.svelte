<!-- Tab.svelte -->
<script lang="ts">
    import { setContext, type Snippet } from 'svelte';

    let {
        children,
        class: className = ''
    }: {
        children: Snippet;
        class?: string;
    } = $props();

    // Store tab information
    let tabs = $state<Array<{ label: string; disabled: boolean; id: string }>>([]);
    let activeTab = $state(0);

    // Context API - allows child TabPanel components to register themselves
    setContext('registerTab', (label: string, disabled: boolean, id: string) => {
        tabs.push({ label, disabled, id });
        return tabs.length - 1; // Return the tab index
    });

    setContext('activeTab', {
        get current() {
            return activeTab;
        }
    });
</script>

<div class="tab-container {className}">
    <!-- Tab Headers - dynamically built from registered TabPanels -->
    <div class="flex border-b border-gray-200">
        {#each tabs as tab, index}
            <button
                class="px-4 py-2 text-sm font-medium transition-colors
                    {activeTab === index
                        ? 'border-b-2 border-blue-500 text-blue-600'
                        : 'text-gray-600 hover:text-gray-900'}
                    {tab.disabled ? 'cursor-not-allowed opacity-50' : 'cursor-pointer'}"
                onclick={() => {
                    if (!tab.disabled && activeTab === index) activeTab = -1;
                    else (activeTab = index);    
                }}
                disabled={tab.disabled}
            >
                {tab.label}
            </button>
        {/each}
    </div>

        <!-- Tab Content - renders all TabPanels (they self-hide if not active) -->
        <div class="py-4">
            {@render children()}
        </div>
</div>