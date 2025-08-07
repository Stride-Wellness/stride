<script lang="ts">
  const { data, class: className }: { data: Record<string, any>, class?: string } = $props();
</script>

<div class={className}>
  {#each Object.entries(data) as [key, value]}
    <div>
      <strong>{key}:</strong> {value}
    </div>
  {/each}
</div>