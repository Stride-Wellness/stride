<script lang="ts">
  let { name, href, class: className }: { name: string; href: string; class?: string } = $props();
</script>

<a href={href} class={`px-2 py-1 hover:underline ${className ?? ''}`}>{name}</a>