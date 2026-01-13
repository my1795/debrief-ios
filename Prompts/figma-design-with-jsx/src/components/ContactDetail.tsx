import React from 'react';
import { ArrowLeft, User, Calendar, Clock, MessageSquare } from 'lucide-react';
import { mockContacts, getContactTimeline } from '../data/mockData';
import StatusBadge from './StatusBadge';

interface ContactDetailProps {
  contactId: string | null;
  onBack: () => void;
}

export default function ContactDetail({ contactId, onBack }: ContactDetailProps) {
  const contact = mockContacts.find((c) => c.contactId === contactId);
  const timeline = contactId ? getContactTimeline(contactId) : [];

  if (!contact) {
    return (
      <div className="flex flex-col items-center justify-center h-full p-4">
        <p className="text-gray-500">Contact not found</p>
        <button onClick={onBack} className="mt-4 text-blue-600 hover:underline">
          Go back
        </button>
      </div>
    );
  }

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  const formatDuration = (seconds: number): string => {
    const minutes = Math.floor(seconds / 60);
    return `${minutes} min`;
  };

  const totalInteractionTime = timeline.reduce((sum, entry) => sum + entry.duration, 0);
  const totalActionItems = timeline.reduce((sum, entry) => sum + entry.actionItemsCount, 0);

  return (
    <div className="flex flex-col h-full bg-gray-50">
      {/* Header */}
      <div className="bg-white px-4 py-4 border-b border-gray-200">
        <div className="flex items-center gap-3 mb-4">
          <button
            onClick={onBack}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6 text-gray-700" />
          </button>
        </div>

        {/* Contact Info */}
        <div className="flex items-start gap-4 pl-2">
          <div className="w-16 h-16 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
            <User className="w-8 h-8 text-blue-600" />
          </div>
          <div className="flex-1">
            <h1 className="text-2xl font-semibold text-gray-900">{contact.name}</h1>
            {contact.handle && (
              <p className="text-gray-600">{contact.handle}</p>
            )}
            {contact.relationshipStatus && (
              <p className="text-sm text-gray-500 mt-1">{contact.relationshipStatus}</p>
            )}
          </div>
        </div>
      </div>

      {/* Summary Stats */}
      <div className="bg-white mx-4 mt-4 p-4 border border-gray-200 rounded-lg">
        <h2 className="font-semibold text-gray-900 mb-3">Relationship Summary</h2>
        <div className="grid grid-cols-3 gap-4">
          <div className="text-center">
            <div className="text-2xl font-bold text-blue-600">{timeline.length}</div>
            <div className="text-xs text-gray-600 mt-1">Interactions</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-blue-600">
              {Math.floor(totalInteractionTime / 60)}
            </div>
            <div className="text-xs text-gray-600 mt-1">Total Minutes</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-blue-600">{totalActionItems}</div>
            <div className="text-xs text-gray-600 mt-1">Action Items</div>
          </div>
        </div>
      </div>

      {/* Timeline */}
      <div className="flex-1 overflow-y-auto px-4 py-4">
        <h2 className="font-semibold text-gray-900 mb-3">Interaction History</h2>
        
        <div className="space-y-3">
          {timeline.map((entry, index) => (
            <div
              key={entry.debriefId}
              className="bg-white border border-gray-200 rounded-lg p-4"
            >
              {/* Date and Status */}
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Calendar className="w-4 h-4" />
                  <span>{formatDate(entry.occurredAt)}</span>
                </div>
                <StatusBadge status={entry.status} showIcon={false} />
              </div>

              {/* Duration */}
              <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
                <Clock className="w-4 h-4" />
                <span>{formatDuration(entry.duration)}</span>
              </div>

              {/* Summary */}
              {entry.summary && entry.status === 'READY' && (
                <div className="mt-2">
                  <p className="text-sm text-gray-700 line-clamp-2">{entry.summary}</p>
                </div>
              )}

              {/* Action Items Count */}
              {entry.actionItemsCount > 0 && (
                <div className="mt-2 text-sm text-blue-600">
                  ✓ {entry.actionItemsCount} action {entry.actionItemsCount === 1 ? 'item' : 'items'}
                </div>
              )}
            </div>
          ))}
        </div>

        {timeline.length === 0 && (
          <div className="text-center py-12">
            <MessageSquare className="w-12 h-12 text-gray-400 mx-auto mb-3" />
            <p className="text-gray-500">No interactions yet</p>
          </div>
        )}
      </div>
    </div>
  );
}
