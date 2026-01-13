import React, { useState, useMemo } from 'react';
import { Search, User } from 'lucide-react';
import { mockContacts } from '../data/mockData';

interface ContactsListProps {
  onContactClick: (contactId: string) => void;
}

export default function ContactsList({ onContactClick }: ContactsListProps) {
  const [searchQuery, setSearchQuery] = useState('');

  const filteredContacts = useMemo(() => {
    if (!searchQuery) return mockContacts;

    const query = searchQuery.toLowerCase();
    return mockContacts.filter(
      (contact) =>
        contact.name.toLowerCase().includes(query) ||
        contact.handle?.toLowerCase().includes(query)
    );
  }, [searchQuery]);

  const formatDate = (dateString: string | undefined): string => {
    if (!dateString) return 'No recent contact';
    
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      return 'Today';
    } else if (diffDays === 1) {
      return 'Yesterday';
    } else if (diffDays < 7) {
      return `${diffDays} days ago`;
    } else {
      return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    }
  };

  return (
    <div className="flex flex-col h-full bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900">
      {/* Header */}
      <div className="px-4 py-4">
        <h1 className="text-3xl font-bold tracking-tight text-white mb-4">Contacts</h1>
        
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

      {/* Contacts List */}
      <div className="flex-1 overflow-y-auto px-4 py-4">
        <div className="space-y-3">
          {filteredContacts.map((contact) => (
            <button
              key={contact.contactId}
              onClick={() => onContactClick(contact.contactId)}
              className="w-full bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4 hover:bg-white/20 transition-all text-left"
            >
              <div className="flex items-start gap-3">
                {/* Avatar */}
                <div className="w-12 h-12 rounded-full bg-teal-400/30 flex items-center justify-center flex-shrink-0">
                  <User className="w-6 h-6 text-teal-300" />
                </div>

                {/* Contact Info */}
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-white truncate">{contact.name}</h3>
                  {contact.handle && (
                    <p className="text-sm text-white/70 truncate">{contact.handle}</p>
                  )}
                  <div className="flex items-center gap-3 mt-2">
                    <span className="text-xs text-white/60">
                      {contact.totalDebriefs} {contact.totalDebriefs === 1 ? 'debrief' : 'debriefs'}
                    </span>
                    <span className="text-xs text-white/40">•</span>
                    <span className="text-xs text-white/60">
                      {formatDate(contact.lastContactedAt)}
                    </span>
                  </div>
                </div>

                {/* Status indicator */}
                {contact.relationshipStatus && (
                  <div className="flex-shrink-0">
                    <span className="text-xs text-white/60">{contact.relationshipStatus}</span>
                  </div>
                )}
              </div>
            </button>
          ))}
        </div>

        {filteredContacts.length === 0 && (
          <div className="text-center py-12">
            <p className="text-white/70">No contacts found</p>
          </div>
        )}
      </div>
    </div>
  );
}