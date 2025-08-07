<script lang="ts">
  let { 
    type = 'info',
    message,
    class: className = '',
    show = true,
    ...restProps
  }: { 
    type?: 'success' | 'error' | 'warning' | 'info';
    message?: string;
    class?: string;
    show?: boolean;
    [key: string]: any;
  } = $props();

  const baseClasses = 'mt-4 p-4 border';
  
  const typeClasses = {
    success: 'bg-green-100 border-green-400 text-green-700',
    error: 'bg-red-100 border-red-400 text-red-700',
    warning: 'bg-yellow-100 border-yellow-400 text-yellow-700',
    info: 'bg-blue-100 border-blue-400 text-blue-700'
  };

  const classes = `${baseClasses} ${typeClasses[type]} ${className}`;
</script>

{#if show && message}
  <div class={classes} {...restProps}>
    {message}
  </div>
{/if}
