import type { Admin } from '$lib/services';
// See https://svelte.dev/docs/kit/types#app.d.ts
// for information about these interfaces
declare global {
	namespace App {
		interface Locals {
			user?: Admin;
		}
	}
	// interface Error {}
	// interface Locals {}
	// interface PageData {}
	// interface PageState {}
	// interface Platform {}
}

export {};
