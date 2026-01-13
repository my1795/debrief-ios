// Firebase configuration and authentication
// Replace these with your actual Firebase config values

export const firebaseConfig = {
  apiKey: "YOUR_API_KEY_HERE",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456"
};

// Mock Firebase auth for demo purposes
// Replace this with actual Firebase SDK when deploying

export interface User {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
}

class MockFirebaseAuth {
  private currentUser: User | null = null;
  private listeners: ((user: User | null) => void)[] = [];

  // Simulate Google Sign In
  async signInWithGoogle(): Promise<User> {
    // In production, use:
    // import { getAuth, signInWithPopup, GoogleAuthProvider } from 'firebase/auth';
    // const auth = getAuth();
    // const provider = new GoogleAuthProvider();
    // const result = await signInWithPopup(auth, provider);
    // return result.user;

    return new Promise((resolve) => {
      setTimeout(() => {
        const mockUser: User = {
          uid: 'user-' + Date.now(),
          email: 'demo@debrief.app',
          displayName: 'Demo User',
          photoURL: 'https://api.dicebear.com/7.x/avataaars/svg?seed=demo'
        };
        this.currentUser = mockUser;
        this.notifyListeners();
        resolve(mockUser);
      }, 1000);
    });
  }

  // Sign out
  async signOut(): Promise<void> {
    // In production, use:
    // import { getAuth, signOut } from 'firebase/auth';
    // const auth = getAuth();
    // await signOut(auth);

    return new Promise((resolve) => {
      setTimeout(() => {
        this.currentUser = null;
        this.notifyListeners();
        resolve();
      }, 500);
    });
  }

  // Get current user
  getCurrentUser(): User | null {
    return this.currentUser;
  }

  // Listen to auth state changes
  onAuthStateChanged(callback: (user: User | null) => void): () => void {
    this.listeners.push(callback);
    // Immediately call with current user
    callback(this.currentUser);
    
    // Return unsubscribe function
    return () => {
      this.listeners = this.listeners.filter(l => l !== callback);
    };
  }

  private notifyListeners() {
    this.listeners.forEach(listener => listener(this.currentUser));
  }
}

// Export singleton instance
export const auth = new MockFirebaseAuth();

// Helper to check if user is authenticated
export const isAuthenticated = (): boolean => {
  return auth.getCurrentUser() !== null;
};
