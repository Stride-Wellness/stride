<script lang="ts">
  import Link from './Link.svelte';

  const { 
    data = $bindable([]), 
    selected = $bindable([]), 
    class: className 
  }: { 
    data: Record<string, any>[]; 
    selected?: Record<string, any>[]; 
    class?: string 
  } = $props();

  const headers = data.length > 0 ? Object.keys(data[0]) : [];
  let selectAllCheckbox: HTMLInputElement;

  function toggleSelection(row: Record<string, any>) {
    const index = selected.findIndex(item => JSON.stringify(item) === JSON.stringify(row));
    if (index > -1) {
      selected.splice(index, 1);
    } else {
      selected.push(row);
    }
  }

  function toggleAll() {
    if (selected.length === data.length) {
      selected.length = 0;
    } else {
      selected.length = 0;
      selected.push(...data);
    }
  }

  function isSelected(row: Record<string, any>): boolean {
    return selected.some(item => JSON.stringify(item) === JSON.stringify(row));
  }

  const allSelected = $derived(selected.length === data.length && data.length > 0);
  const someSelected = $derived(selected.length > 0 && selected.length < data.length);

  $effect(() => {
    if (selectAllCheckbox) {
      selectAllCheckbox.indeterminate = someSelected;
    }
  });
</script>

<div class="overflow-auto {className ?? ''}">
  <table class="border border-collapse w-full min-w-max">
    <thead>
      <tr>
        <th class="border p-2 text-left font-medium bg-background whitespace-nowrap">
          <input
            bind:this={selectAllCheckbox}
            type="checkbox"
            checked={allSelected}
            onchange={toggleAll}
            class="w-4 h-4 cursor-pointer"
            aria-label="Select all rows"
          />
        </th>
        {#each headers as header}
          <th class="border p-2 text-left font-medium bg-background whitespace-nowrap">{header}</th>
        {/each}
      </tr>
    </thead>
    <tbody>
      {#each data as row}
        <tr class:bg-muted={isSelected(row)}>
          <td class="border p-2 whitespace-nowrap">
            <input
              type="checkbox"
              checked={isSelected(row)}
              onchange={() => toggleSelection(row)}
              class="w-4 h-4 cursor-pointer"
              aria-label="Select row"
            />
          </td>
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