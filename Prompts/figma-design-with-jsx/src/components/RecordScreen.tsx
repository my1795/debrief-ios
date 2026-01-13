import React, { useState, useEffect } from 'react';
import { Mic, Square, Search, Check } from 'lucide-react';
import { mockContacts } from '../data/mockData';
import { Contact } from '../types';

interface RecordScreenProps {
  onComplete: () => void;
}

type RecordingState = 'recording' | 'select-contact' | 'processing' | 'complete';

export default function RecordScreen({ onComplete }: RecordScreenProps) {
  const [recordingState, setRecordingState] = useState<RecordingState>('recording');
  const [selectedContact, setSelectedContact] = useState<Contact | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [recordingTime, setRecordingTime] = useState(0);
  const [showNewContactForm, setShowNewContactForm] = useState(false);
  const [newContactName, setNewContactName] = useState('');
  const [newContactHandle, setNewContactHandle] = useState('');

  // Auto-start recording timer
  useEffect(() => {
    if (recordingState === 'recording') {
      const interval = setInterval(() => {
        setRecordingTime((prev) => prev + 1);
      }, 1000);
      
      (window as any).recordingInterval = interval;
      
      return () => clearInterval(interval);
    }
  }, [recordingState]);

  const filteredContacts = mockContacts.filter((contact) =>
    contact.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    contact.handle?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleContactSelect = (contact: Contact) => {
    setSelectedContact(contact);
  };

  const handleStartRecording = () => {
    setRecordingState('recording');
    // Simulate recording timer
    const interval = setInterval(() => {
      setRecordingTime((prev) => prev + 1);
    }, 1000);

    // Store interval ID for cleanup
    (window as any).recordingInterval = interval;
  };

  const handleStopRecording = () => {
    clearInterval((window as any).recordingInterval);
    setRecordingState('select-contact');
  };

  const handleSaveWithContact = () => {
    if (selectedContact) {
      setRecordingState('processing');

      // Simulate processing
      setTimeout(() => {
        setRecordingState('complete');
        setTimeout(() => {
          onComplete();
        }, 2000);
      }, 2000);
    }
  };

  const handleCreateContact = () => {
    if (newContactName.trim()) {
      const newContact: Contact = {
        contactId: `contact-${Date.now()}`,
        name: newContactName,
        handle: newContactHandle || undefined,
        totalDebriefs: 0
      };
      setSelectedContact(newContact);
      setShowNewContactForm(false);
      setNewContactName('');
      setNewContactHandle('');
    }
  };

  const formatRecordingTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  // Select Contact View
  if (recordingState === 'select-contact') {
    return (
      <div className="flex flex-col h-full bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900">
        <div className="px-4 py-4">
          <h1 className="text-2xl font-semibold mb-2 text-white">Recording Saved!</h1>
          <div className="flex items-center gap-2 mb-4">
            <span className="text-white/70 text-sm">Duration:</span>
            <span className="text-teal-300 font-semibold text-sm">{formatRecordingTime(recordingTime)}</span>
          </div>
          <p className="text-white/70 mb-4">Select a contact for this debrief</p>
          
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-teal-300 w-5 h-5" />
            <input
              type="text"
              placeholder="Search contacts..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 bg-white/10 backdrop-blur-md border border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-400/50 placeholder-white/40 text-white"
            />
          </div>
        </div>

        <div className="flex-1 overflow-y-auto px-4 py-4">
          <div className="space-y-2">
            {filteredContacts.map((contact) => (
              <button
                key={contact.contactId}
                onClick={() => handleContactSelect(contact)}
                className={`w-full text-left p-4 rounded-lg transition-all backdrop-blur-md ${
                  selectedContact?.contactId === contact.contactId
                    ? 'bg-teal-400/30 border border-teal-300/50'
                    : 'bg-white/10 border border-white/20 hover:bg-white/20'
                }`}
              >
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="font-semibold text-white">{contact.name}</h3>
                    {contact.handle && (
                      <p className="text-sm text-white/70">{contact.handle}</p>
                    )}
                  </div>
                  {selectedContact?.contactId === contact.contactId && (
                    <Check className="w-5 h-5 text-teal-300" />
                  )}
                </div>
              </button>
            ))}
          </div>

          {!showNewContactForm ? (
            <button
              onClick={() => setShowNewContactForm(true)}
              className="w-full mt-4 p-4 border-2 border-dashed border-white/30 rounded-lg text-white/80 hover:border-teal-300 hover:text-teal-300 transition-all backdrop-blur-md"
            >
              + Create New Contact
            </button>
          ) : (
            <div className="mt-4 p-4 bg-white/10 backdrop-blur-md border border-white/20 rounded-lg">
              <h3 className="font-semibold text-white mb-3">New Contact</h3>
              <input
                type="text"
                placeholder="Name *"
                value={newContactName}
                onChange={(e) => setNewContactName(e.target.value)}
                className="w-full px-4 py-2 mb-2 bg-white/10 border border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-400/50 placeholder-white/40 text-white"
              />
              <input
                type="text"
                placeholder="Company (optional)"
                value={newContactHandle}
                onChange={(e) => setNewContactHandle(e.target.value)}
                className="w-full px-4 py-2 mb-3 bg-white/10 border border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-400/50 placeholder-white/40 text-white"
              />
              <div className="flex gap-2">
                <button
                  onClick={() => setShowNewContactForm(false)}
                  className="flex-1 px-4 py-2 bg-white/10 text-white rounded-lg hover:bg-white/20 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleCreateContact}
                  disabled={!newContactName.trim()}
                  className="flex-1 px-4 py-2 bg-teal-500 text-white rounded-lg hover:bg-teal-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Create
                </button>
              </div>
            </div>
          )}
        </div>

        {selectedContact && (
          <div className="p-4">
            <button
              onClick={handleSaveWithContact}
              className="w-full flex items-center justify-center gap-2 px-6 py-4 bg-teal-500 text-white rounded-xl hover:bg-teal-600 transition-colors"
            >
              <Check className="w-6 h-6" />
              Save Debrief
            </button>
          </div>
        )}
      </div>
    );
  }

  // Recording View
  if (recordingState === 'recording') {
    return (
      <div className="flex flex-col items-center justify-center h-full bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900 p-4">
        <div className="text-center">
          <div className="mb-8">
            <div className="inline-block p-8 bg-red-500 rounded-full animate-pulse">
              <Mic className="w-16 h-16 text-white" />
            </div>
          </div>

          <h2 className="text-2xl font-semibold text-white mb-2">Recording...</h2>
          <p className="text-white/70 mb-4">{selectedContact?.name}</p>
          
          <div className="text-4xl font-bold text-white mb-12">
            {formatRecordingTime(recordingTime)}
          </div>

          <button
            onClick={handleStopRecording}
            className="flex items-center justify-center gap-2 px-8 py-4 bg-white/10 backdrop-blur-md border border-white/20 text-white rounded-xl hover:bg-white/20 transition-colors"
          >
            <Square className="w-6 h-6" />
            Stop Recording
          </button>
        </div>
      </div>
    );
  }

  // Processing View
  if (recordingState === 'processing') {
    return (
      <div className="flex flex-col items-center justify-center h-full bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900 p-4">
        <div className="text-center">
          <div className="mb-8">
            <div className="inline-block p-8 bg-teal-500/30 backdrop-blur-md border border-teal-400/50 rounded-full">
              <div className="w-16 h-16 border-4 border-teal-300 border-t-transparent rounded-full animate-spin"></div>
            </div>
          </div>

          <h2 className="text-2xl font-semibold text-white mb-2">Processing...</h2>
          <p className="text-white/70">Uploading and processing your debrief</p>
        </div>
      </div>
    );
  }

  // Complete View
  return (
    <div className="flex flex-col items-center justify-center h-full bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900 p-4">
      <div className="text-center">
        <div className="mb-8">
          <div className="inline-block p-8 bg-green-500/30 backdrop-blur-md border border-green-400/50 rounded-full">
            <Check className="w-16 h-16 text-green-300" />
          </div>
        </div>

        <h2 className="text-2xl font-semibold text-white mb-2">Complete!</h2>
        <p className="text-white/70">Your debrief has been saved</p>
      </div>
    </div>
  );
}