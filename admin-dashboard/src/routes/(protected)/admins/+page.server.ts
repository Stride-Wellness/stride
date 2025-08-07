import { AdminUsersService } from '$lib/services';
import { fail } from '@sveltejs/kit';
import type { Actions } from './$types';

export const load = async () => {
  const admins = await AdminUsersService.getAllAdmins(1000);
  return {
    admins: JSON.stringify(admins)
  };
};

export const actions: Actions = {
   create: async ({ request, locals }) => {
    const data = await request.formData();
    const email = data.get('email') as string;
    const name = data.get('name') as string;
    const privilege = parseInt(data.get('privilege') as string);
    const currentUserPrivilege = locals.user?.privilege ?? 999;

    // Only privilege 0 and 1 users can create admins
    if (currentUserPrivilege > 1) {
      return fail(403, {
        error: 'You do not have permission to create admin users'
      });
    }

    // Users with privilege 1 cannot create level 0 admins
    if (currentUserPrivilege === 1 && privilege === 0) {
      return fail(403, {
        error: 'You cannot create level 0 admin users'
      });
    }

    // Validation
    if (!email || !name || isNaN(privilege)) {
      return fail(400, {
        error: 'All fields are required'
      });
    }

    if (privilege < 0 || privilege > 3) {
      return fail(400, {
        error: 'Privilege level must be between 0 and 3'
      });
    }

    if (!email.includes('@')) {
      return fail(400, {
        error: 'Please enter a valid email address'
      });
    }

    try {
      await AdminUsersService.createAdmin({
        email,
        name,
        privilege
      });

      return {
        success: true
      };
    } catch (error) {
      console.error('Error creating admin:', error);
      return fail(500, {
        error: 'Failed to create admin user. Please try again.'
      });
    }
  },

  delete: async ({ request, locals }) => {
    const data = await request.formData();
    const id = data.get('id') as string;
    const currentUserPrivilege = locals.user?.privilege ?? 999;
    console.log('Current user privilege:', locals);
    
    // Only privilege 0 users can delete admins
    if (currentUserPrivilege !== 0) {
      return fail(403, {
        error: 'Only level 0 admins can delete admin users'
      });
    }

    if (!id || typeof id !== 'string') {
      return fail(400, {
        error: 'Admin ID is required'
      });
    }

    if (id === locals.user?.id) {
      return fail(400, {
        error: 'You cannot delete your own account'
      });
    }

    try {
      await AdminUsersService.deleteAdmin(id);
      return {
        success: true
      };
    } catch (error) {
      console.error('Error deleting admin:', error);
      return fail(500, {
        error: 'Failed to delete admin user. Please try again.'
      });
    }
  }
};
