<script lang="ts">
  const { 
    class: className = '', 
    variant = 'primary',
    size = 'md',
    children,
    ...restProps
  }: { 
    class?: string; 
    variant?: 'primary' | 'secondary' | 'outline' | 'danger' | 'subtle';
    size?: 'sm' | 'md' | 'lg';
    children?: any 
    [key: string]: any;
  } = $props();

  const baseClasses = 'px-4 py-2 border transition-colors font-medium';
  
  const variantClasses = {
    primary: 'bg-primary hover:bg-primary-hover text-white border-primary',
    secondary: 'bg-secondary hover:bg-secondary-hover text-text border-border',
    outline: 'bg-transparent hover:bg-muted text-text border-border',
    danger: 'bg-danger hover:bg-red-600 text-white border-danger',
    subtle: 'bg-transparent hover:font-semibold font-medium !border-none !p-0 !m-0 text-text'
  };
  
  const sizeClasses = {
    sm: 'px-3 py-1 text-sm',
    md: 'px-4 py-2',
    lg: 'px-6 py-3 text-lg'
  };

  const classes = `${baseClasses} ${sizeClasses[size]} ${variantClasses[variant]} ${className}`;
</script>

<button class={classes} {...restProps}>
  {@render children?.()}
</button>
