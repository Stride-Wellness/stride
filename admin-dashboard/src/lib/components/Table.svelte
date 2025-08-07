<script lang="ts">
  const { data, class: className }: { data: Record<string, any>[]; class?: string } = $props();
  
  const headers = data.length > 0 ? Object.keys(data[0]) : [];
</script>

<table class="border border-collapse w-full {className ?? ''}">
  <thead>
    <tr>
      {#each headers as header}
        <th class="border p-2 text-left font-medium bg-background">{header}</th>
      {/each}
    </tr>
  </thead>
  <tbody>
    {#each data as row}
      <tr>
        {#each headers as header}
          <td class="border p-2">{row[header]}</td>
        {/each}
      </tr>
    {/each}
  </tbody>
</table>
