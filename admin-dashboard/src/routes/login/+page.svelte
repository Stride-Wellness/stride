<script lang="ts">
  import { signInWithEmailAndPassword } from 'firebase/auth';
  import { auth } from '$lib/firebase/config';
  import { goto } from '$app/navigation';
  import Button from '$lib/components/Button.svelte';
  import Input from '$lib/components/Input.svelte';
  import Card from '$lib/components/Card.svelte';
  import Message from '$lib/components/Message.svelte';
  
  let email = $state('');
  let password = $state('');
  let loading = $state(false);
  let error = $state('');

  async function handleSubmit(event: Event) {
    event.preventDefault();
    loading = true;
    error = '';
    
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const idToken = await userCredential.user.getIdToken();
      
      // Set secure session
      const response = await fetch('/v1/auth/session', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken })
      });
      
      if (response.ok) {
        goto('/');
      } else {
        error = 'Login failed. Please check your credentials and try again.';
      }
    } catch (err: any) {
      console.error('Login error:', err);
      if (err.code === 'auth/user-not-found') {
        error = 'No admin account found with this email address.';
      } else if (err.code === 'auth/wrong-password') {
        error = 'Incorrect password. Please try again.';
      } else if (err.code === 'auth/invalid-email') {
        error = 'Please enter a valid email address.';
      } else if (err.code === 'auth/too-many-requests') {
        error = 'Too many failed attempts. Please try again later.';
      } else {
        error = 'Login failed. Please check your credentials and try again.';
      }
    } finally {
      loading = false;
    }
  }
</script>

<svelte:head>
  <title>Stride Admin - Login</title>
  <meta name="description" content="Stride Admin Dashboard Login" />
</svelte:head>

<div class="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
  <!-- Header with branding -->
  <div class="sm:mx-auto sm:w-full sm:max-w-md">
    <div class="text-center">
      <h1 class="text-3xl font-bold text-gray-900 mb-2">Stride Admin</h1>
      <p class="text-sm text-gray-600">Administrator Dashboard</p>
    </div>
  </div>

  <!-- Login form -->
  <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
    <Card class="py-8 px-6 shadow-lg">
      <div class="mb-6">
        <h2 class="text-center text-xl font-medium text-gray-900">Sign in to your account</h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          Access the admin dashboard to manage organizations, users, and platform settings
        </p>
      </div>

      <form onsubmit={handleSubmit} class="space-y-6">
        <div>
          <label for="email" class="block text-sm font-medium text-gray-700 mb-1">
            Email address
          </label>
          <Input
            id="email"
            type="email"
            placeholder="admin@example.com"
            size="md"
            variant="outline"
            bind:value={email}
            required
            disabled={loading}
            class="w-full"
          />
        </div>

        <div>
          <label for="password" class="block text-sm font-medium text-gray-700 mb-1">
            Password
          </label>
          <Input
            id="password"
            type="password"
            placeholder="Enter your password"
            size="md"
            variant="outline"
            bind:value={password}
            required
            disabled={loading}
            class="w-full"
          />
        </div>

        <div>
          <Button
            type="submit"
            size="md"
            disabled={loading}
            class="w-full flex justify-center py-2 px-4"
          >
            {loading ? 'Signing in...' : 'Sign in'}
          </Button>
        </div>
      </form>

      <!-- Error message -->
      {#if error}
        <div class="mt-4">
          <Message type="error" message={error} />
        </div>
      {/if}

      <!-- Help text -->
      <div class="mt-6 text-center">
        <p class="text-xs text-gray-500">
          This is an administrative portal. Only authorized administrators can access this system.
        </p>
      </div>
    </Card>
  </div>

  <!-- Link to main app -->
  <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
    <Card class="p-4 bg-blue-50 border-blue-200">
      <div class="text-center">
        <h3 class="text-sm font-medium text-blue-900 mb-2">Looking for the Stride app?</h3>
        <p class="text-xs text-blue-700 mb-3">
          If you're a client or care worker, you'll want to use the main Stride application instead.
        </p>
        <a 
          href="https://stridewellness.ca" 
          class="inline-flex items-center text-sm font-medium text-blue-600 hover:text-blue-500 transition-colors"
        >
          Go to Stride App
          <svg class="ml-1 w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
          </svg>
        </a>
      </div>
    </Card>
  </div>

  <!-- Footer -->
  <div class="mt-8 text-center">
    <p class="text-xs text-gray-400">
      © 2025 Stride. All rights reserved.
    </p>
  </div>
</div>