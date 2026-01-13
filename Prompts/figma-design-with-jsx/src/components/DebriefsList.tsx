import React, { useState, useMemo } from 'react';
import { Search, SlidersHorizontal, Clock, Calendar } from 'lucide-react';
import { mockDebriefs } from '../data/mockData';
import { Debrief, DebriefStatus } from '../types';
import StatusBadge from './StatusBadge';

interface DebriefsListProps {
  onDebriefClick: (debriefId: string) => void;
}

type SortOption = 'recent' | 'oldest' | 'duration' | 'name' | 'status';

export default function DebriefsList({ onDebriefClick }: DebriefsListProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState<SortOption>('recent');
  const [showSortMenu, setShowSortMenu] = useState(false);

  const filteredAndSortedDebriefs = useMemo(() => {
    let filtered = mockDebriefs;

    // Filter by search query
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(
        (d) =>
          d.contactName.toLowerCase().includes(query) ||
          d.summary?.toLowerCase().includes(query) ||
          d.transcript?.toLowerCase().includes(query)
      );
    }

    // Sort
    const sorted = [...filtered];
    switch (sortBy) {
      case 'recent':
        sorted.sort((a, b) => new Date(b.occurredAt).getTime() - new Date(a.occurredAt).getTime());
        break;
      case 'oldest':
        sorted.sort((a, b) => new Date(a.occurredAt).getTime() - new Date(b.occurredAt).getTime());
        break;
      case 'duration':
        sorted.sort((a, b) => b.duration - a.duration);
        break;
      case 'name':
        sorted.sort((a, b) => a.contactName.localeCompare(b.contactName));
        break;
      case 'status':
        sorted.sort((a, b) => a.status.localeCompare(b.status));
        break;
    }

    return sorted;
  }, [searchQuery, sortBy]);

  // Calculate stats for status bar
  const stats = useMemo(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const todayDebriefs = mockDebriefs.filter(d => {
      const debriefDate = new Date(d.occurredAt);
      debriefDate.setHours(0, 0, 0, 0);
      return debriefDate.getTime() === today.getTime();
    });

    const totalMinutes = Math.floor(mockDebriefs.reduce((sum, d) => sum + d.duration, 0) / 60);
    const todayMinutes = Math.floor(todayDebriefs.reduce((sum, d) => sum + d.duration, 0) / 60);

    return {
      totalCalls: mockDebriefs.length,
      totalMinutes,
      todayCalls: todayDebriefs.length,
      todayMinutes
    };
  }, []);

  const formatDuration = (seconds: number): string => {
    const minutes = Math.floor(seconds / 60);
    return `${minutes} min`;
  };

  const formatDate = (dateString: string): string => {
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
      <div className="px-4 pt-6 pb-4">
        <div className="flex items-center justify-between mb-4">
          <h1 className="text-3xl font-bold tracking-tight text-white">Debriefs</h1>
          
          {/* Status Bar - Apple Style with Colors & Emojis */}
          <div className="flex items-center gap-2 text-xs">
            <div className="flex items-center gap-1 bg-white/10 backdrop-blur-md px-2.5 py-1.5 rounded-lg border border-white/20">
              <span>📝</span>
              <span className="font-semibold text-white">{stats.todayCalls}</span>
              <span className="text-white/60">/</span>
              <span>📞</span>
              <span className="font-semibold text-white">{stats.totalCalls}</span>
            </div>
            <div className="flex items-center gap-1 bg-white/10 backdrop-blur-md px-2.5 py-1.5 rounded-lg border border-white/20">
              <span>⏱️</span>
              <span className="font-semibold text-white">{stats.totalMinutes}</span>
              <span className="text-white/60">min</span>
            </div>
          </div>
        </div>
        
        {/* Search and Sort */}
        <div className="flex gap-2">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-teal-300 w-5 h-5" />
            <input
              type="text"
              placeholder="Search debriefs..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-white/10 backdrop-blur-md border border-white/20 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-400/50 placeholder-white/40 text-white"
            />
          </div>
          
          <div className="relative">
            <button
              onClick={() => setShowSortMenu(!showSortMenu)}
              className="px-4 py-3 bg-white/10 backdrop-blur-md border border-white/20 rounded-xl hover:bg-white/20 transition-colors"
            >
              <SlidersHorizontal className="w-5 h-5 text-teal-300" />
            </button>
            
            {showSortMenu && (
              <div className="absolute right-0 mt-2 w-48 bg-teal-950/95 backdrop-blur-md border border-white/20 rounded-xl shadow-xl z-10 overflow-hidden">
                <div className="py-1">
                  {[
                    { value: 'recent' as SortOption, label: 'Most Recent' },
                    { value: 'oldest' as SortOption, label: 'Oldest' },
                    { value: 'duration' as SortOption, label: 'Duration' },
                    { value: 'name' as SortOption, label: 'Contact Name' },
                    { value: 'status' as SortOption, label: 'Status' }
                  ].map((option) => (
                    <button
                      key={option.value}
                      onClick={() => {
                        setSortBy(option.value);
                        setShowSortMenu(false);
                      }}
                      className={`w-full text-left px-4 py-2 hover:bg-teal-800/50 transition-colors ${
                        sortBy === option.value ? 'text-teal-300 font-semibold bg-teal-800/50' : 'text-white/80'
                      }`}
                    >
                      {option.label}
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Debriefs List */}
      <div className="flex-1 overflow-y-auto px-4 py-4">
        <div className="space-y-3">
          {filteredAndSortedDebriefs.map((debrief) => (
            <button
              key={debrief.debriefId}
              onClick={() => onDebriefClick(debrief.debriefId)}
              className="w-full bg-white/95 backdrop-blur-md border border-white/50 rounded-2xl p-4 hover:bg-white hover:shadow-xl transition-all text-left"
            >
              {/* Contact Name and Status */}
              <div className="flex items-start justify-between mb-2">
                <h3 className="font-semibold text-gray-900">{debrief.contactName}</h3>
                <StatusBadge status={debrief.status} />
              </div>

              {/* Time and Duration */}
              <div className="flex items-center gap-4 text-sm text-gray-600 mb-2">
                <div className="flex items-center gap-1">
                  <Calendar className="w-4 h-4" />
                  <span>{formatDate(debrief.occurredAt)}</span>
                </div>
                <div className="flex items-center gap-1">
                  <Clock className="w-4 h-4" />
                  <span>{formatDuration(debrief.duration)}</span>
                </div>
              </div>

              {/* Summary Preview */}
              {debrief.summary && (
                <p className="text-sm text-gray-700 line-clamp-2">
                  {debrief.summary}
                </p>
              )}

              {/* Action Items Count */}
              {debrief.actionItems && debrief.actionItems.length > 0 && (
                <div className="mt-2 text-sm text-orange-700 font-medium">
                  ✓ {debrief.actionItems.length} action {debrief.actionItems.length === 1 ? 'item' : 'items'}
                </div>
              )}
            </button>
          ))}
        </div>

        {filteredAndSortedDebriefs.length === 0 && (
          <div className="text-center py-12">
            <p className="text-white/80 text-lg">No debriefs found</p>
          </div>
        )}
      </div>
    </div>
  );
}