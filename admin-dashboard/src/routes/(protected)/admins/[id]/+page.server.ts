import { AdminUsersService } from '$lib/services/privileged';
import { fail } from '@sveltejs/kit';
import type { Actions } from './$types';

export const load = async ({ params }) => {
	const adminId = params.id;
	
	if (!adminId) {
		throw new Error('Admin ID is required');
	}

	try {
		const admin = await AdminUsersService.getAdminById(adminId);
		
		if (!admin) {
			throw new Error('Admin not found');
		}

		return {
			admin: JSON.stringify(admin)
		};
	} catch (error) {
		console.error('Error loading admin:', error);
		throw new Error('Failed to load admin data');
	}
};

export const actions: Actions = {
	update: async ({ request, params, locals }) => {
		const adminId = params.id;
		const data = await request.formData();
		const currentUserPrivilege = locals.user?.privilege ?? 999;

		// Only privilege 0 and 1 users can update admins
		if (currentUserPrivilege > 1) {
			return fail(403, {
				error: 'You do not have permission to update admin users'
			});
		}

		if (!adminId) {
			return fail(400, {
				error: 'Admin ID is required'
			});
		}

		// Prevent users from editing their own privilege level
		if (adminId === locals.user?.id) {
			// Allow updating own name but not privilege
			const name = data.get('name') as string;
			
			if (!name) {
				return fail(400, {
					error: 'Name is required'
				});
			}

			try {
				await AdminUsersService.updateAdmin(adminId, { name });
				return { success: true };
			} catch (error) {
				console.error('Error updating admin:', error);
				return fail(500, {
					error: 'Failed to update admin user. Please try again.'
				});
			}
		}

		// For updating other admins
		const name = data.get('name') as string;
		const privilege = parseInt(data.get('privilege') as string);

		// Users with privilege 1 cannot set level 0 privilege
		if (currentUserPrivilege === 1 && privilege === 0) {
			return fail(403, {
				error: 'You cannot set privilege level 0'
			});
		}

		// Validation
		if (!name) {
			return fail(400, {
				error: 'Name is required'
			});
		}

		if (isNaN(privilege) || privilege < 0 || privilege > 3) {
			return fail(400, {
				error: 'Privilege level must be between 0 and 3'
			});
		}

		try {
			await AdminUsersService.updateAdmin(adminId, {
				name,
				privilege
			});

			return { success: true };
		} catch (error) {
			console.error('Error updating admin:', error);
			return fail(500, {
				error: 'Failed to update admin user. Please try again.'
			});
		}
	},

	sendEmailVerification: async ({ params, locals }) => {
		const adminId = params.id;
		const currentUserPrivilege = locals.user?.privilege ?? 999;

		// Only privilege 0 and 1 users can send email verification
		if (currentUserPrivilege > 1) {
			return fail(403, {
				error: 'You do not have permission to send email verification'
			});
		}

		if (!adminId) {
			return fail(400, {
				error: 'Admin ID is required'
			});
		}

		try {
			const admin = await AdminUsersService.getAdminById(adminId);
			if (!admin) {
				return fail(404, {
					error: 'Admin not found'
				});
			}

			await AdminUsersService.resendEmailVerification(admin.email);
			return { success: true, message: 'Email verification sent successfully' };
		} catch (error) {
			console.error('Error sending email verification:', error);
			return fail(500, {
				error: 'Failed to send email verification. Please try again.'
			});
		}
	},

	sendPasswordReset: async ({ params, locals }) => {
		const adminId = params.id;
		const currentUserPrivilege = locals.user?.privilege ?? 999;

		// Only privilege 0 and 1 users can send password reset
		if (currentUserPrivilege > 1) {
			return fail(403, {
				error: 'You do not have permission to send password reset'
			});
		}

		if (!adminId) {
			return fail(400, {
				error: 'Admin ID is required'
			});
		}

		try {
			const admin = await AdminUsersService.getAdminById(adminId);
			if (!admin) {
				return fail(404, {
					error: 'Admin not found'
				});
			}

			await AdminUsersService.sendPasswordReset(admin.email);
			return { success: true, message: 'Password reset email sent successfully' };
		} catch (error) {
			console.error('Error sending password reset:', error);
			return fail(500, {
				error: 'Failed to send password reset email. Please try again.'
			});
		}
	}
};