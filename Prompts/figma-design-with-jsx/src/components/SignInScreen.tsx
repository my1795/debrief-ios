import React, { useState } from 'react';
import { Chrome, Loader2 } from 'lucide-react';
import { auth, User } from '../lib/firebase';

interface SignInScreenProps {
  onSignIn: (user: User) => void;
}

export default function SignInScreen({ onSignIn }: SignInScreenProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleGoogleSignIn = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const user = await auth.signInWithGoogle();
      onSignIn(user);
    } catch (err) {
      console.error('Sign in error:', err);
      setError('Failed to sign in. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900 p-4">
      {/* Logo/Brand */}
      <div className="mb-12 text-center">
        <div className="inline-block p-6 mb-4 bg-white/10 backdrop-blur-md border border-white/20 rounded-3xl">
          <div className="w-20 h-20 flex items-center justify-center text-5xl">
            🎙️
          </div>
        </div>
        <h1 className="text-4xl font-bold text-white mb-2">Debrief</h1>
        <p className="text-white/70">Voice memos that work for you</p>
      </div>

      {/* Sign In Card */}
      <div className="w-full max-w-md">
        <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl p-8">
          <h2 className="text-2xl font-semibold text-white mb-2 text-center">
            Welcome
          </h2>
          <p className="text-white/70 text-center mb-8">
            Sign in to start recording your debriefs
          </p>

          {/* Google Sign In Button */}
          <button
            onClick={handleGoogleSignIn}
            disabled={isLoading}
            className="w-full flex items-center justify-center gap-3 px-6 py-4 bg-white text-gray-900 rounded-xl hover:bg-gray-100 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-semibold"
          >
            {isLoading ? (
              <>
                <Loader2 className="w-5 h-5 animate-spin" />
                Signing in...
              </>
            ) : (
              <>
                <Chrome className="w-5 h-5" />
                Continue with Google
              </>
            )}
          </button>

          {error && (
            <div className="mt-4 p-3 bg-red-500/20 border border-red-400/30 rounded-lg">
              <p className="text-red-300 text-sm text-center">{error}</p>
            </div>
          )}

          {/* Privacy Notice */}
          <div className="mt-6 p-4 bg-teal-400/10 border border-teal-300/20 rounded-lg">
            <p className="text-teal-200 text-xs text-center">
              🔐 Your privacy matters. All recordings are encrypted and only accessible by you.
            </p>
          </div>
        </div>

        {/* Footer */}
        <div className="mt-8 text-center text-white/50 text-sm">
          <p>By signing in, you agree to our</p>
          <div className="flex items-center justify-center gap-2 mt-1">
            <button className="text-teal-300 hover:text-teal-200 transition-colors">
              Terms of Service
            </button>
            <span>•</span>
            <button className="text-teal-300 hover:text-teal-200 transition-colors">
              Privacy Policy
            </button>
          </div>
        </div>
      </div>

      {/* Version */}
      <div className="mt-12 text-white/40 text-sm">
        Debrief v1.0.0
      </div>
    </div>
  );
}
