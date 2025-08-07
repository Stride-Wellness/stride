import { dev } from '$app/environment';
import { adminAuth, adminDb } from '$lib/firebase/admin';
import type { AdminUser } from '$lib/types';

export interface CreateAdminData {
  email: string;
  name: string;
  privilege: number;
  password?: string;
  disabled?: boolean;
}

export interface UpdateAdminData {
  name?: string;
  privilege?: number;
  disabled?: boolean;
}

export class AdminUsersService {
  
  /**
   * Get all admin users from Firebase Auth with custom claims
   */
  static async getAllAdmins(limit: number): Promise<AdminUser[]> {
    try {
      const listUsersResult = await adminAuth.listUsers(limit);
      console.log(`Found ${listUsersResult.users.length} users in Firebase Auth`);
      const adminUsers: AdminUser[] = [];

      for (const authUser of listUsersResult.users) {
        // Only include users with admin claims
        if (authUser.customClaims?.isAdmin) {
          // Try to get additional data from Firestore
          const userDoc = await adminDb.collection('admins').doc(authUser.uid).get();
          const firestoreData = userDoc.exists ? userDoc.data() : {};

          adminUsers.push({
            id: authUser.uid,
            email: authUser.email!,
            name: firestoreData?.name,
            privilege: authUser.customClaims.privilege,
            emailVerified: authUser.emailVerified,
            lastSignIn: new Date(authUser.metadata.lastSignInTime),
            createdAt: new Date(authUser.metadata.creationTime),
            updatedAt: new Date(firestoreData?.updatedAt),
            disabled: authUser.disabled
          });
        }
      }

      return adminUsers;
    } catch (error) {
      console.error('Error getting all admins:', error);
      throw new Error('Failed to fetch admin users');
    }
  }

  /**
   * Get admin user by ID with both Auth and Firestore data
   */
  static async getAdminById(uid: string): Promise<AdminUser | null> {
    try {
      // Get from Firebase Auth
      const authUser = await adminAuth.getUser(uid);
      
      if (!authUser.customClaims?.isAdmin) {
        return null; // Not an admin
      }

      // Get from Firestore
      const userDoc = await adminDb.collection('admins').doc(uid).get();
      const firestoreData = userDoc.exists ? userDoc.data() : {};

      return {
            id: authUser.uid,
            email: authUser.email!,
            name: firestoreData?.name || authUser.email!,
            privilege: authUser.customClaims.privilege,
            emailVerified: authUser.emailVerified,
            lastSignIn: new Date(authUser.metadata.lastSignInTime),
            createdAt: new Date(authUser.metadata.creationTime),
            updatedAt: firestoreData?.updatedAt,
            disabled: authUser.disabled
          };
    } catch (error) {
      console.error('Error getting admin by ID:', error);
      return null;
    }
  }

  /**
   * Create a new admin user
   */
  static async createAdmin(data: CreateAdminData): Promise<AdminUser> {
    try {
      // Create user in Firebase Auth
      const userRecord = await adminAuth.createUser({
        email: data.email,
        password: data.password || this.generateRandomPassword(),
        disabled: data.disabled || false,
        emailVerified: false
      });

      // Set admin custom claims
      await adminAuth.setCustomUserClaims(userRecord.uid, {
        isAdmin: true,
        privilege: data.privilege,
        lastUpdated: Date.now()
      });

      // Create Firestore record
      const firestoreData = {
        name: data.name,
        privilege: data.privilege,
        createdAt: new Date(),
        updatedAt: new Date(),
        createdBy: 'system' // You can pass this as parameter
      };

      await adminDb.collection('admins').doc(userRecord.uid).set(firestoreData);

      return {
        id: userRecord.uid,
        email: data.email,
        disabled: data.disabled || false,
        emailVerified: false,
        lastSignIn: null,
        ...firestoreData
      };
    } catch (error) {
      console.error('Error creating admin:', error);
      throw new Error('Failed to create admin user');
    }
  }

  /**
   * Update admin user privileges and data
   */
  static async updateAdmin(uid: string, data: UpdateAdminData): Promise<AdminUser | null> {
    try {
      // Update Firebase Auth
      const authUpdates: Partial<{ disabled: boolean }> = {};
      if (data.disabled !== undefined) authUpdates.disabled = data.disabled;

      if (Object.keys(authUpdates).length > 0) {
        await adminAuth.updateUser(uid, authUpdates);
      }

      // Update custom claims if privilege level changed
      if (data.privilege !== undefined) {
        const user = await adminAuth.getUser(uid);
        await adminAuth.setCustomUserClaims(uid, {
          ...user.customClaims,
          privilege: data.privilege,
          lastUpdated: Date.now()
        });
      }

      // Update Firestore
      const firestoreUpdates = {
        name: data.name,
        privilege: data.privilege,
        updatedAt: new Date()
      };

      await adminDb.collection('admins').doc(uid).update(firestoreUpdates);

      // Return updated admin
      return await this.getAdminById(uid);
    } catch (error) {
      console.error('Error updating admin:', error);
      throw new Error('Failed to update admin user');
    }
  }

  /**
   * Remove admin privileges (but keep user account)
   */
  static async removeAdminPrivileges(uid: string): Promise<void> {
    try {
      // Remove admin custom claims
      await adminAuth.setCustomUserClaims(uid, {
        isAdmin: false,
        privilege: 4, // Default to lowest privilege
        lastUpdated: Date.now()
      });

      // Update Firestore record
      await adminDb.collection('admins').doc(uid).update({
        privilege: 4,
        updatedAt: new Date()
      });

    } catch (error) {
      console.error('Error removing admin privileges:', error);
      throw new Error('Failed to remove admin privileges');
    }
  }

  /**
   * Completely delete admin user
   */
  static async deleteAdmin(uid: string): Promise<void> {
    try {
      // Delete from Firebase Auth
      await adminAuth.deleteUser(uid);

      // Delete from Firestore
      await adminDb.collection('admins').doc(uid).delete();

    } catch (error) {
      console.error('Error deleting admin:', error);
      throw new Error('Failed to delete admin user');
    }
  }

  /**
   * Grant admin privileges to existing user
   */
  static async grantAdminPrivileges(uid: string, privilege: number): Promise<AdminUser | null> {
    try {
      // Set admin custom claims
      await adminAuth.setCustomUserClaims(uid, {
        isAdmin: true,
        privilege,
        lastUpdated: Date.now()
      });

      // Create or update Firestore record
      const adminData = {
        privilege,
        updatedAt: new Date()
      };

      await adminDb.collection('admins').doc(uid).set(adminData, { merge: true });

      return await this.getAdminById(uid);
    } catch (error) {
      console.error('Error granting admin privileges:', error);
      throw new Error('Failed to grant admin privileges');
    }
  }

  // /**
  //  * Sync Firebase Auth users to Firestore (maintenance function)
  //  */
  // static async syncAuthToFirestore(): Promise<void> {
  //   try {
  //     const listUsersResult = await adminAuth.listUsers();
      
  //     for (const authUser of listUsersResult.users) {
  //       if (authUser.customClaims?.isAdmin) {
  //         const userDoc = await adminDb.collection('admins').doc(authUser.uid).get();
          
  //         if (!userDoc.exists) {
  //           // Create missing Firestore record
  //           await adminDb.collection('admins').doc(authUser.uid).set({
  //             name: authUser.displayName || authUser.email,
  //             privilege: authUser.customClaims.privilege,
  //             createdAt: new Date(authUser.metadata.creationTime),
  //             updatedAt: new Date()
  //           });
  //         }
  //       }
  //     }
  //   } catch (error) {
  //     console.error('Error syncing auth to firestore:', error);
  //     throw new Error('Failed to sync data');
  //   }
  // }

  /**
   * Check if user has specific permission level or higher
   */
  static async hasPermission(uid: string, requiredLevel: number): Promise<boolean> {
    try {
      const user = await adminAuth.getUser(uid);
      const userLevel = user.customClaims?.permissionLevel || 999;
      return user.customClaims?.isAdmin && userLevel <= requiredLevel;
    } catch {
      return false;
    }
  }

  /**
   * Generate random password for new users
   */
  private static generateRandomPassword(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
    let password = '';
    for (let i = 0; i < 12; i++) {
      password += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    if (!dev) return password;
    else return 'password'; // Use a fixed password in dev mode for testing
  }

  /**
   * Get admin statistics
   */
  static async getAdminStats(): Promise<{
    totalAdmins: number;
    activeAdmins: number;
    disabledAdmins: number;
    byPrivilegeLevel: Record<number, number>;
  }> {
    try {
      const admins = await this.getAllAdmins(1000);
      
      const stats = {
        totalAdmins: admins.length,
        activeAdmins: admins.filter(admin => !admin.disabled).length,
        disabledAdmins: admins.filter(admin => admin.disabled).length,
        byPrivilegeLevel: {} as Record<number, number>
      };

      // Count by privilege level
      admins.forEach(admin => {
        const level = admin.privilege;
        stats.byPrivilegeLevel[level] = (stats.byPrivilegeLevel[level] || 0) + 1;
      });

      return stats;
    } catch {
      console.error('Error getting admin stats:');
      throw new Error('Failed to get admin statistics');
    }
  }
}