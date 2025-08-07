<script lang="ts">
  const { children, class: className }: { children: any; class?: string } = $props();
</script>

<div class="p-4 border {className ?? ''}">
  {@render children?.()}
</div>
