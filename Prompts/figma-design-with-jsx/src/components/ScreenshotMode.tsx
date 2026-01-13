import React, { useState, useEffect } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import SignInScreen from './SignInScreen';
import DebriefsList from './DebriefsList';
import DebriefDetail from './DebriefDetail';
import RecordScreen from './RecordScreen';
import ContactsList from './ContactsList';
import ContactDetail from './ContactDetail';
import StatsScreen from './StatsScreen';
import SettingsScreen from './SettingsScreen';

interface ScreenshotScenario {
  id: string;
  title: string;
  description: string;
  component: React.ReactNode;
}

export default function ScreenshotMode() {
  const [currentIndex, setCurrentIndex] = useState(0);

  const scenarios: ScreenshotScenario[] = [
    {
      id: 'sign-in',
      title: '1. Sign In Screen',
      description: 'Initial sign in screen with Google authentication',
      component: <SignInScreen onSignIn={() => {}} />
    },
    {
      id: 'debriefs-list',
      title: '2. Debriefs List (With Data)',
      description: 'Main list view with debriefs',
      component: <DebriefsList onDebriefClick={() => {}} />
    },
    {
      id: 'debriefs-empty',
      title: '3. Debriefs List (Empty State)',
      description: 'Empty state when no debriefs exist',
      component: (
        <div className="flex flex-col h-screen bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900">
          <div className="px-4 py-4">
            <h1 className="text-3xl font-bold tracking-tight text-white">Debriefs</h1>
          </div>
          <div className="flex-1 flex flex-col items-center justify-center px-4">
            <div className="text-center">
              <div className="w-20 h-20 mx-auto mb-4 flex items-center justify-center text-6xl">
                🎙️
              </div>
              <h2 className="text-xl font-semibold text-white mb-2">No debriefs yet</h2>
              <p className="text-white/70 mb-6">Tap the mic button to record your first debrief</p>
            </div>
          </div>
        </div>
      )
    },
    {
      id: 'debrief-detail-ready',
      title: '4. Debrief Detail (READY)',
      description: 'Debrief detail with all content ready',
      component: <DebriefDetail debriefId="1" onBack={() => {}} />
    },
    {
      id: 'debrief-detail-failed',
      title: '5. Debrief Detail (FAILED)',
      description: 'Debrief detail with failed status and retry option',
      component: <DebriefDetail debriefId="6" onBack={() => {}} />
    },
    {
      id: 'debrief-detail-processing',
      title: '6. Debrief Detail (PROCESSING)',
      description: 'Debrief detail while processing',
      component: <DebriefDetail debriefId="2" onBack={() => {}} />
    },
    {
      id: 'record-recording',
      title: '7. Record Screen - Recording',
      description: 'Active recording with timer',
      component: (
        <div className="flex flex-col items-center justify-center h-screen bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900 px-4">
          <div className="flex-1 flex flex-col items-center justify-center">
            <div className="w-32 h-32 bg-red-500 rounded-full flex items-center justify-center mb-8 animate-pulse">
              <div className="text-6xl">🎙️</div>
            </div>
            <p className="text-white/70 mb-4">Recording...</p>
            <div className="text-6xl font-mono text-white">05:23</div>
          </div>
          <div className="w-full max-w-md pb-8">
            <button className="w-full flex items-center justify-center gap-2 px-6 py-4 bg-white/10 backdrop-blur-md border border-white/20 text-white rounded-xl hover:bg-white/20 transition-colors">
              <span className="w-6 h-6 flex items-center justify-center">⏹️</span>
              Stop Recording
            </button>
          </div>
        </div>
      )
    },
    {
      id: 'record-select-contact',
      title: '8. Record Screen - Select Contact',
      description: 'Contact selection after recording',
      component: (
        <div className="flex flex-col h-screen bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900">
          <div className="px-4 py-4">
            <h1 className="text-2xl font-semibold mb-2 text-white">Recording Saved!</h1>
            <div className="flex items-center gap-2 mb-4">
              <span className="text-white/70 text-sm">Duration:</span>
              <span className="text-teal-300 font-semibold text-sm">5:23</span>
            </div>
            <p className="text-white/70 mb-4">Select a contact for this debrief</p>
            <div className="relative mb-4">
              <input
                type="text"
                placeholder="Search contacts..."
                className="w-full pl-10 pr-4 py-2.5 bg-white/10 backdrop-blur-md border border-white/20 rounded-lg text-white placeholder-white/40"
              />
            </div>
          </div>
          <div className="flex-1 overflow-y-auto px-4 space-y-2">
            <button className="w-full bg-teal-400/30 backdrop-blur-md border border-teal-300/50 rounded-xl p-4 text-left">
              <div className="flex items-center justify-between">
                <div>
                  <div className="font-semibold text-white">John Doe</div>
                  <div className="text-sm text-white/70">@johndoe</div>
                </div>
                <div className="text-teal-300">✓</div>
              </div>
            </button>
            <button className="w-full bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4 text-left hover:bg-white/20 transition-colors">
              <div className="font-semibold text-white">Jane Smith</div>
              <div className="text-sm text-white/70">Acme Corp</div>
            </button>
          </div>
          <div className="p-4">
            <button className="w-full flex items-center justify-center gap-2 px-6 py-4 bg-teal-500 text-white rounded-xl">
              ✓ Save Debrief
            </button>
          </div>
        </div>
      )
    },
    {
      id: 'record-processing',
      title: '9. Record Screen - Processing',
      description: 'Processing state after save',
      component: (
        <div className="flex flex-col items-center justify-center h-screen bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900 px-4">
          <div className="bg-teal-500/30 backdrop-blur-md border border-teal-400/50 rounded-2xl p-12 text-center">
            <div className="w-16 h-16 border-4 border-teal-300 border-t-transparent rounded-full animate-spin mx-auto mb-6"></div>
            <h2 className="text-2xl font-semibold text-white mb-2">Processing...</h2>
            <p className="text-white/70">Uploading and processing your debrief</p>
          </div>
        </div>
      )
    },
    {
      id: 'record-complete',
      title: '10. Record Screen - Complete',
      description: 'Success state',
      component: (
        <div className="flex flex-col items-center justify-center h-screen bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900 px-4">
          <div className="bg-green-500/30 backdrop-blur-md border border-green-400/50 rounded-2xl p-12 text-center">
            <div className="text-8xl text-green-300 mb-6">✓</div>
            <h2 className="text-2xl font-semibold text-white mb-2">Complete!</h2>
            <p className="text-white/70">Your debrief has been saved</p>
          </div>
        </div>
      )
    },
    {
      id: 'contacts-list',
      title: '11. Contacts List',
      description: 'List of all contacts',
      component: <ContactsList onContactClick={() => {}} />
    },
    {
      id: 'contact-detail',
      title: '12. Contact Detail',
      description: 'Contact detail with debrief history',
      component: <ContactDetail contactId="1" onBack={() => {}} />
    },
    {
      id: 'stats',
      title: '13. Stats Screen',
      description: 'Statistics and quota usage',
      component: <StatsScreen />
    },
    {
      id: 'settings',
      title: '14. Settings Screen',
      description: 'App settings and preferences',
      component: <SettingsScreen />
    }
  ];

  const handlePrevious = () => {
    setCurrentIndex((prev) => (prev > 0 ? prev - 1 : scenarios.length - 1));
  };

  const handleNext = () => {
    setCurrentIndex((prev) => (prev < scenarios.length - 1 ? prev + 1 : 0));
  };

  // Keyboard navigation
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft') {
        handlePrevious();
      } else if (e.key === 'ArrowRight') {
        handleNext();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  const currentScenario = scenarios[currentIndex];

  return (
    <div className="relative h-screen bg-black overflow-hidden">
      {/* Info Bar - Top */}
      <div className="absolute top-0 left-0 right-0 z-50 bg-black/90 backdrop-blur-sm border-b border-white/10 px-6 py-4">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <div>
            <h2 className="text-white font-semibold text-lg">{currentScenario.title}</h2>
            <p className="text-white/60 text-sm">{currentScenario.description}</p>
          </div>
          <div className="text-white/60 text-sm">
            {currentIndex + 1} / {scenarios.length}
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="h-full flex items-center justify-center pt-20 pb-20">
        <div className="max-w-md w-full h-full shadow-2xl">
          {currentScenario.component}
        </div>
      </div>

      {/* Navigation - Bottom */}
      <div className="absolute bottom-0 left-0 right-0 z-50 bg-black/90 backdrop-blur-sm border-t border-white/10 px-6 py-4">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <button
            onClick={handlePrevious}
            className="flex items-center gap-2 px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg transition-colors"
          >
            <ChevronLeft className="w-5 h-5" />
            Previous
          </button>

          {/* Progress Dots */}
          <div className="flex items-center gap-2">
            {scenarios.map((_, index) => (
              <button
                key={index}
                onClick={() => setCurrentIndex(index)}
                className={`w-2 h-2 rounded-full transition-all ${
                  index === currentIndex
                    ? 'bg-teal-400 w-8'
                    : 'bg-white/30 hover:bg-white/50'
                }`}
              />
            ))}
          </div>

          <button
            onClick={handleNext}
            className="flex items-center gap-2 px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg transition-colors"
          >
            Next
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Instructions */}
      <div className="absolute top-24 right-6 bg-black/80 backdrop-blur-sm border border-white/20 rounded-lg px-4 py-3 text-white/70 text-sm max-w-xs">
        <p className="font-semibold mb-2">📸 Screenshot Mode</p>
        <p className="mb-1">• Use ← → arrow keys to navigate</p>
        <p className="mb-1">• Click dots to jump to a screen</p>
        <p>• Take screenshots of each scenario</p>
      </div>
    </div>
  );
}
