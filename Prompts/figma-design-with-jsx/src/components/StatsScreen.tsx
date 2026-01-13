import React from 'react';
import { TrendingUp, Clock, CheckSquare, Zap, Database, Award, Calendar } from 'lucide-react';
import { mockDashboardStats, mockQuota } from '../data/mockData';

export default function StatsScreen() {
  const stats = mockDashboardStats;
  const quota = mockQuota;

  const quotaPercentages = {
    recordings: (quota.recordingsThisMonth / quota.recordingsLimit) * 100,
    minutes: (quota.minutesThisMonth / quota.minutesLimit) * 100,
    storage: (quota.storageUsedMB / quota.storageLimitMB) * 100
  };

  return (
    <div className="flex flex-col h-full bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900 overflow-y-auto">
      {/* Header */}
      <div className="px-4 py-4">
        <h1 className="text-3xl font-bold tracking-tight text-white">Stats</h1>
      </div>

      <div className="px-4 py-4 space-y-4">
        {/* Current Plan */}
        <div className="bg-gradient-to-br from-teal-500 to-emerald-500 text-white rounded-xl p-6 shadow-lg">
          <div className="flex items-center gap-2 mb-2">
            <Award className="w-6 h-6" />
            <h2 className="text-lg font-semibold">Current Plan</h2>
          </div>
          <p className="text-3xl font-bold mb-1">{quota.tier}</p>
          <p className="text-teal-100 text-sm">All features unlocked</p>
        </div>

        {/* This Week Stats */}
        <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4">
          <h2 className="font-semibold text-white mb-3 flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-teal-300" />
            This Week
          </h2>
          <div className="grid grid-cols-3 gap-4">
            <div>
              <div className="text-2xl font-bold text-white">{stats.thisWeek.debriefs}</div>
              <div className="text-xs text-white/70 mt-1">Debriefs</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-white">{stats.thisWeek.minutes}</div>
              <div className="text-xs text-white/70 mt-1">Minutes</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-white">{stats.thisWeek.actionItems}</div>
              <div className="text-xs text-white/70 mt-1">Actions</div>
            </div>
          </div>
        </div>

        {/* This Month Stats */}
        <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4">
          <h2 className="font-semibold text-white mb-3 flex items-center gap-2">
            <Calendar className="w-5 h-5 text-teal-300" />
            This Month
          </h2>
          <div className="grid grid-cols-3 gap-4">
            <div>
              <div className="text-2xl font-bold text-white">{stats.thisMonth.debriefs}</div>
              <div className="text-xs text-white/70 mt-1">Debriefs</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-white">{stats.thisMonth.minutes}</div>
              <div className="text-xs text-white/70 mt-1">Minutes</div>
            </div>
            <div>
              <div className="text-2xl font-bold text-white">{stats.thisMonth.actionItems}</div>
              <div className="text-xs text-white/70 mt-1">Actions</div>
            </div>
          </div>
        </div>

        {/* Quota Usage */}
        <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4">
          <h2 className="font-semibold text-white mb-4 flex items-center gap-2">
            <Zap className="w-5 h-5 text-teal-300" />
            Quota Usage
          </h2>

          {/* Recordings */}
          <div className="mb-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-white/80">Recordings</span>
              <span className="text-sm font-semibold text-white">
                {quota.recordingsThisMonth} / {quota.recordingsLimit}
              </span>
            </div>
            <div className="h-2 bg-white/20 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all ${
                  quotaPercentages.recordings > 80 ? 'bg-red-400' : 'bg-teal-400'
                }`}
                style={{ width: `${quotaPercentages.recordings}%` }}
              ></div>
            </div>
          </div>

          {/* Minutes */}
          <div className="mb-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-white/80">Minutes</span>
              <span className="text-sm font-semibold text-white">
                {quota.minutesThisMonth} / {quota.minutesLimit}
              </span>
            </div>
            <div className="h-2 bg-white/20 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all ${
                  quotaPercentages.minutes > 80 ? 'bg-red-400' : 'bg-teal-400'
                }`}
                style={{ width: `${quotaPercentages.minutes}%` }}
              ></div>
            </div>
          </div>

          {/* Storage */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-white/80">Storage</span>
              <span className="text-sm font-semibold text-white">
                {quota.storageUsedMB} MB / {quota.storageLimitMB} MB
              </span>
            </div>
            <div className="h-2 bg-white/20 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all ${
                  quotaPercentages.storage > 80 ? 'bg-red-400' : 'bg-teal-400'
                }`}
                style={{ width: `${quotaPercentages.storage}%` }}
              ></div>
            </div>
          </div>
        </div>

        {/* Recent Activity Chart */}
        <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4 mb-6">
          <h2 className="font-semibold text-white mb-4">Recent Activity</h2>
          <div className="flex items-end justify-between gap-2 h-32">
            {stats.recentActivity.map((day, index) => {
              const maxCount = Math.max(...stats.recentActivity.map(d => d.count));
              const height = maxCount > 0 ? (day.count / maxCount) * 100 : 0;
              
              return (
                <div key={index} className="flex-1 flex flex-col items-center gap-2">
                  <div
                    className="w-full bg-teal-400 rounded-t transition-all hover:bg-teal-300"
                    style={{ height: `${height}%`, minHeight: day.count > 0 ? '8px' : '0' }}
                  ></div>
                  <span className="text-xs text-white/70">
                    {new Date(day.date).toLocaleDateString('en-US', { weekday: 'short' })[0]}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}