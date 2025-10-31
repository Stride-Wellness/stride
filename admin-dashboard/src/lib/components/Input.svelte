<script lang="ts">
  let { 
    value = $bindable(undefined),
    as = 'input',
    size = 'md',
    variant = 'default',
    class: className = '',
    options = [], // Add options prop
    children,
    ...restProps
  }: { 
    as?: 'input' | 'select' | 'textarea';
    size?: 'sm' | 'md' | 'lg';
    variant?: 'default' | 'outline';
    class?: string;
    options?: Array<{ value: string|number|boolean; label: string, selected?: boolean }>; // Add options type
    children?: any;
    [key: string]: any;
  } = $props();
  const baseClasses = 'w-full border transition-colors font-medium focus:outline-none focus:ring-2 focus:ring-primary rounded-none';
  
  const variantClasses = {
    default: 'bg-background text-text border-border focus:border-primary',
    outline: 'bg-transparent text-text border-border focus:border-primary'
  };
  
  const sizeClasses = {
    sm: 'px-3 py-1 text-sm',
    md: 'px-4 py-2',
    lg: 'px-6 py-3 text-lg'
  };

  const classes = `${baseClasses} ${sizeClasses[size]} ${variantClasses[variant]} ${className}`;
</script>


{#if as === 'select'}
  <select
    bind:value={value}
    
    class={classes}
    {...restProps}
  >
    {#each options as option}
      <option selected={option.selected} value={option.value}>{option.label}</option>
    {/each}
    {@render children?.()}
  </select>
{:else if as === 'textarea'}
  <textarea
    bind:value={value}
    class={classes}
    {...restProps}
  ></textarea>
{:else}
  <input
    bind:value={value}
    class={classes}
    {...restProps}
  />
{/if}