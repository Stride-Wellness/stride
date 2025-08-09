<script lang="ts">
  import Link from './Link.svelte';
  
  const { data, class: className }: { data: Record<string, any>[]; class?: string } = $props();
  
  const headers = data.length > 0 ? Object.keys(data[0]) : [];
</script>

<div class="overflow-auto {className ?? ''}">
  <table class="border border-collapse w-full min-w-max">
    <thead>
      <tr>
        {#each headers as header}
          <th class="border p-2 text-left font-medium bg-background whitespace-nowrap">{header}</th>
        {/each}
      </tr>
    </thead>
    <tbody>
      {#each data as row}
        <tr>
          {#each headers as header}
            <td class="border p-2 whitespace-nowrap">
              {#if typeof row[header] === 'object' && row[header]?.href}
                <Link name={row[header].name} href={row[header].href} />
              {:else}
                {row[header]}
              {/if}
            </td>
          {/each}
        </tr>
      {/each}
    </tbody>
  </table>
</div>
