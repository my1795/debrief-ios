import React, { useState, useEffect } from 'react';
import { Home, BarChart3, Mic, Users, Settings, LogOut, Camera } from 'lucide-react';
import DebriefsList from './components/DebriefsList';
import DebriefDetail from './components/DebriefDetail';
import RecordScreen from './components/RecordScreen';
import ContactsList from './components/ContactsList';
import ContactDetail from './components/ContactDetail';
import StatsScreenNew from './components/StatsScreenNew';
import SettingsScreen from './components/SettingsScreen';
import SignInScreen from './components/SignInScreen';
import ScreenshotMode from './components/ScreenshotMode';
import { auth, User } from './lib/firebase';

type Screen = 'debriefs' | 'stats' | 'record' | 'contacts' | 'settings' | 'debrief-detail' | 'contact-detail';

export default function App() {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [isAuthLoading, setIsAuthLoading] = useState(true);
  const [currentScreen, setCurrentScreen] = useState<Screen>('debriefs');
  const [selectedDebriefId, setSelectedDebriefId] = useState<string | null>(null);
  const [selectedContactId, setSelectedContactId] = useState<string | null>(null);
  const [isScreenshotMode, setIsScreenshotMode] = useState(false);

  // Listen to auth state changes
  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged((user) => {
      setCurrentUser(user);
      setIsAuthLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleSignOut = async () => {
    try {
      await auth.signOut();
      setCurrentScreen('debriefs');
    } catch (error) {
      console.error('Sign out error:', error);
    }
  };

  const navigateToDebriefDetail = (debriefId: string) => {
    setSelectedDebriefId(debriefId);
    setCurrentScreen('debrief-detail');
  };

  const navigateToContactDetail = (contactId: string) => {
    setSelectedContactId(contactId);
    setCurrentScreen('contact-detail');
  };

  const navigateBack = () => {
    if (currentScreen === 'debrief-detail') {
      setCurrentScreen('debriefs');
    } else if (currentScreen === 'contact-detail') {
      setCurrentScreen('contacts');
    }
  };

  const renderScreen = () => {
    switch (currentScreen) {
      case 'debriefs':
        return <DebriefsList onDebriefClick={navigateToDebriefDetail} />;
      case 'debrief-detail':
        return <DebriefDetail debriefId={selectedDebriefId} onBack={navigateBack} />;
      case 'stats':
        return <StatsScreenNew />;
      case 'record':
        return <RecordScreen onComplete={() => setCurrentScreen('debriefs')} />;
      case 'contacts':
        return <ContactsList onContactClick={navigateToContactDetail} />;
      case 'contact-detail':
        return <ContactDetail contactId={selectedContactId} onBack={navigateBack} />;
      case 'settings':
        return <SettingsScreen onEnterScreenshotMode={() => setIsScreenshotMode(true)} />;
      default:
        return <DebriefsList onDebriefClick={navigateToDebriefDetail} />;
    }
  };

  const isDetailScreen = currentScreen === 'debrief-detail' || currentScreen === 'contact-detail';

  // Show loading while checking auth
  if (isAuthLoading) {
    return (
      <div className="flex items-center justify-center h-screen bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-teal-300 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-white/70">Loading...</p>
        </div>
      </div>
    );
  }

  // Show sign in screen if not authenticated
  if (!currentUser) {
    return <SignInScreen onSignIn={setCurrentUser} />;
  }

  // Screenshot Mode
  if (isScreenshotMode) {
    return (
      <div className="relative">
        <ScreenshotMode />
        <button
          onClick={() => setIsScreenshotMode(false)}
          className="fixed top-4 left-4 z-50 px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg transition-colors text-sm font-semibold"
        >
          Exit Screenshot Mode
        </button>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-screen bg-gray-50 max-w-md mx-auto">
      {/* Sign Out Button - Top Right (visible on all screens except detail screens) */}
      {!isDetailScreen && (
        <div className="absolute top-4 right-4 z-10 max-w-md mx-auto">
          <button
            onClick={handleSignOut}
            className="flex items-center gap-2 px-3 py-2 bg-white/10 backdrop-blur-md border border-white/20 text-white rounded-lg hover:bg-white/20 transition-colors text-sm"
          >
            <LogOut className="w-4 h-4" />
            Sign Out
          </button>
        </div>
      )}

      {/* Main Content */}
      <div className="flex-1 overflow-y-auto pb-20">
        {renderScreen()}
      </div>

      {/* Bottom Navigation */}
      {!isDetailScreen && (
        <nav className="fixed bottom-0 left-0 right-0 max-w-md mx-auto bg-white border-t border-gray-200 px-4 py-2 safe-area-bottom">
          <div className="flex items-center justify-around">
            <button
              onClick={() => setCurrentScreen('debriefs')}
              className={`flex flex-col items-center gap-1 px-3 py-2 rounded-lg transition-colors ${
                currentScreen === 'debriefs' ? 'text-blue-600' : 'text-gray-600'
              }`}
            >
              <Home className="w-6 h-6" />
              <span className="text-xs">Debriefs</span>
            </button>

            <button
              onClick={() => setCurrentScreen('stats')}
              className={`flex flex-col items-center gap-1 px-3 py-2 rounded-lg transition-colors ${
                currentScreen === 'stats' ? 'text-blue-600' : 'text-gray-600'
              }`}
            >
              <BarChart3 className="w-6 h-6" />
              <span className="text-xs">Stats</span>
            </button>

            <button
              onClick={() => setCurrentScreen('record')}
              className="flex flex-col items-center gap-1 px-3 py-2 rounded-lg transition-colors relative -top-4"
            >
              <div className="bg-red-500 text-white p-4 rounded-full shadow-lg">
                <Mic className="w-7 h-7" />
              </div>
            </button>

            <button
              onClick={() => setCurrentScreen('contacts')}
              className={`flex flex-col items-center gap-1 px-3 py-2 rounded-lg transition-colors ${
                currentScreen === 'contacts' ? 'text-blue-600' : 'text-gray-600'
              }`}
            >
              <Users className="w-6 h-6" />
              <span className="text-xs">Contacts</span>
            </button>

            <button
              onClick={() => setCurrentScreen('settings')}
              className={`flex flex-col items-center gap-1 px-3 py-2 rounded-lg transition-colors ${
                currentScreen === 'settings' ? 'text-blue-600' : 'text-gray-600'
              }`}
            >
              <Settings className="w-6 h-6" />
              <span className="text-xs">Settings</span>
            </button>
          </div>
        </nav>
      )}
    </div>
  );
}