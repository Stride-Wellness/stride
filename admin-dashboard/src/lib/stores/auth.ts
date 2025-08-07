import { writable } from 'svelte/store';
import { onAuthStateChanged, type User as FirebaseUser } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '$lib/firebase/config';
import { browser } from '$app/environment';
import type { AdminUser } from '$lib/types'; // Your Firestore user type

interface AuthState {
  firebaseUser: FirebaseUser | null;
  user: AdminUser | null; // Full Firestore user data
  loading: boolean;
}

function createAuthStore() {
  const { subscribe, set, update } = writable<AuthState>({
    firebaseUser: null,
    user: null,
    loading: true
  });

  // Only run on client side
  if (browser) {
    onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        try {
          // Fetch full user data from Firestore
          const userDoc = await getDoc(doc(db, 'admins', firebaseUser.uid));
          const userData = userDoc.exists() 
            ? { id: userDoc.id, ...userDoc.data() } as AdminUser
            : null;
          
          set({ 
            firebaseUser, 
            user: userData, 
            loading: false 
          });
        } catch (error) {
          console.error('Error fetching user data:', error);
          set({ 
            firebaseUser, 
            user: null, 
            loading: false 
          });
        }
      } else {
        set({ 
          firebaseUser: null, 
          user: null, 
          loading: false 
        });
      }
    });
  }

  return {
    subscribe,
    signOut: async () => {
      await auth.signOut();
    },
    // Helper to refresh user data
    refreshUser: async () => {
      update(state => ({ ...state, loading: true }));
      const currentUser = auth.currentUser;
      if (currentUser) {
        const userDoc = await getDoc(doc(db, 'users', currentUser.uid));
        const userData = userDoc.exists() 
          ? { id: userDoc.id, ...userDoc.data() } as AdminUser
          : null;
        
        update(state => ({ 
          ...state, 
          user: userData, 
          loading: false 
        }));
      }
    }
  };
}

export const authStore = createAuthStore();