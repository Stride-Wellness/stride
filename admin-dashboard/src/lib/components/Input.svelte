<script lang="ts">
  let { 
    value = $bindable(undefined),
    as = 'input',
    size = 'md',
    variant = 'default',
    class: className = '',
    children,
    ...restProps
  }: { 
    as?: 'input' | 'select';
    size?: 'sm' | 'md' | 'lg';
    variant?: 'default' | 'outline';
    class?: string;
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
    {@render children?.()}
  </select>
{:else}
  <input
    bind:value={value}
    class={classes}
    {...restProps}
  />
{/if}
