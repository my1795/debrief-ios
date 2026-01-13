import React, { useState } from 'react';
import { ArrowLeft, Play, Pause, Trash2, Share2, Clock, Calendar, RefreshCw } from 'lucide-react';
import { mockDebriefs } from '../data/mockData';
import StatusBadge from './StatusBadge';

interface DebriefDetailProps {
  debriefId: string | null;
  onBack: () => void;
}

export default function DebriefDetail({ debriefId, onBack }: DebriefDetailProps) {
  const [isPlaying, setIsPlaying] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  const debrief = mockDebriefs.find((d) => d.debriefId === debriefId);

  if (!debrief) {
    return (
      <div className="flex flex-col items-center justify-center h-full p-4">
        <p className="text-gray-500">Debrief not found</p>
        <button onClick={onBack} className="mt-4 text-blue-600 hover:underline">
          Go back
        </button>
      </div>
    );
  }

  const formatDuration = (seconds: number): string => {
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${minutes}:${secs.toString().padStart(2, '0')}`;
  };

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit'
    });
  };

  const handleRetry = () => {
    alert('Retry processing initiated (mock action)');
  };

  const handleDelete = () => {
    alert('Debrief deleted (mock action)');
    setShowDeleteConfirm(false);
    onBack();
  };

  return (
    <div className="flex flex-col h-full bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900">
      {/* Header */}
      <div className="px-4 py-4">
        <div className="flex items-center gap-3 mb-3">
          <button
            onClick={onBack}
            className="p-2 hover:bg-white/10 rounded-lg transition-colors"
          >
            <ArrowLeft className="w-6 h-6 text-white" />
          </button>
          <h1 className="text-xl font-semibold flex-1 text-white">{debrief.contactName}</h1>
          <StatusBadge status={debrief.status} />
        </div>

        {/* Meta Info */}
        <div className="flex items-center gap-4 text-sm text-white/70 pl-14">
          <div className="flex items-center gap-1">
            <Calendar className="w-4 h-4" />
            <span>{formatDate(debrief.occurredAt)}</span>
          </div>
          <div className="flex items-center gap-1">
            <Clock className="w-4 h-4" />
            <span>{formatDuration(debrief.duration)}</span>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto">
        {/* Failed State */}
        {debrief.status === 'FAILED' && (
          <div className="mx-4 mt-4 p-4 bg-red-500/20 backdrop-blur-md border border-red-400/30 rounded-xl">
            <h3 className="font-semibold text-red-100 mb-2">Processing Failed</h3>
            <p className="text-sm text-red-200 mb-3">
              We encountered an error while processing this debrief. Please try again.
            </p>
            <button
              onClick={handleRetry}
              className="flex items-center gap-2 px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors"
            >
              <RefreshCw className="w-4 h-4" />
              Retry Processing
            </button>
          </div>
        )}

        {/* Processing State */}
        {debrief.status === 'PROCESSING' && (
          <div className="mx-4 mt-4 p-4 bg-yellow-500/20 backdrop-blur-md border border-yellow-400/30 rounded-xl">
            <h3 className="font-semibold text-yellow-100 mb-2">Processing Audio...</h3>
            <p className="text-sm text-yellow-200">
              Your debrief is being processed. This usually takes a few minutes.
            </p>
          </div>
        )}

        {/* Summary Section */}
        {debrief.summary && (
          <div className="mx-4 mt-4 p-4 bg-white/10 backdrop-blur-md border border-white/20 rounded-xl">
            <h2 className="font-semibold text-white mb-3">Summary</h2>
            <p className="text-white/90 leading-relaxed">{debrief.summary}</p>
          </div>
        )}

        {/* Action Items Section */}
        {debrief.actionItems && debrief.actionItems.length > 0 && (
          <div className="mx-4 mt-4 p-4 bg-white/10 backdrop-blur-md border border-white/20 rounded-xl">
            <h2 className="font-semibold text-white mb-3">Action Items</h2>
            <ul className="space-y-2">
              {debrief.actionItems.map((item, index) => (
                <li key={index} className="flex items-start gap-2">
                  <span className="text-teal-300 font-bold mt-0.5">•</span>
                  <span className="text-white/90 flex-1">{item}</span>
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* Transcript Section */}
        {debrief.transcript && (
          <div className="mx-4 mt-4 p-4 bg-white/10 backdrop-blur-md border border-white/20 rounded-xl">
            <h2 className="font-semibold text-white mb-3">Transcript</h2>
            <p className="text-white/90 leading-relaxed whitespace-pre-line">{debrief.transcript}</p>
          </div>
        )}

        {/* Audio Player */}
        {debrief.audioUrl && (
          <div className="mx-4 mt-4 mb-4 p-4 bg-white/10 backdrop-blur-md border border-white/20 rounded-xl">
            <h2 className="font-semibold text-white mb-3">Audio Recording</h2>
            <div className="flex items-center gap-3">
              <button
                onClick={() => setIsPlaying(!isPlaying)}
                className="p-3 bg-teal-500 text-white rounded-full hover:bg-teal-600 transition-colors"
              >
                {isPlaying ? <Pause className="w-5 h-5" /> : <Play className="w-5 h-5 ml-0.5" />}
              </button>
              <div className="flex-1">
                <div className="h-2 bg-white/20 rounded-full overflow-hidden">
                  <div className="h-full bg-teal-400 w-1/3"></div>
                </div>
                <div className="flex justify-between text-xs text-white/70 mt-1">
                  <span>1:23</span>
                  <span>{formatDuration(debrief.duration)}</span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Actions */}
        <div className="mx-4 mt-4 mb-6 flex gap-3">
          <button className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-teal-500 text-white rounded-xl hover:bg-teal-600 transition-colors">
            <Share2 className="w-5 h-5" />
            Export
          </button>
          <button
            onClick={() => setShowDeleteConfirm(true)}
            className="flex items-center justify-center gap-2 px-4 py-3 bg-red-500/20 text-red-200 border border-red-400/30 rounded-xl hover:bg-red-500/30 transition-colors"
          >
            <Trash2 className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Delete Confirmation Modal */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-teal-950/95 backdrop-blur-md border border-white/20 rounded-xl p-6 max-w-sm w-full">
            <h3 className="text-lg font-semibold text-white mb-2">Delete Debrief?</h3>
            <p className="text-white/70 mb-6">
              This action cannot be undone. The debrief and its audio will be permanently deleted.
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowDeleteConfirm(false)}
                className="flex-1 px-4 py-2 bg-white/10 text-white rounded-lg hover:bg-white/20 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleDelete}
                className="flex-1 px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}