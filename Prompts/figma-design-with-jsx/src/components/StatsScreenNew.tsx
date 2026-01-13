import React, { useState } from 'react';
import { 
  TrendingUp, TrendingDown, Award, Clock, Mic, Users, 
  BarChart3, Calendar, Zap, Target, Sparkles, ChevronRight,
  Activity, FileText, CheckSquare, AlertCircle
} from 'lucide-react';
import { LineChart, Line, PieChart, Pie, Cell, ResponsiveContainer, XAxis, YAxis, Tooltip, AreaChart, Area } from 'recharts';

// Mock data based on backend structure
const mockOverview = {
  totalDebriefs: 156,
  totalMinutes: 892,
  totalActionItems: 234,
  totalContacts: 12,
  avgDebriefDuration: 5.7,
  completionRate: 87,
  mostActiveDay: 'Monday',
  longestStreak: 7
};

const mockTrends = {
  thisWeek: { debriefs: 12, minutes: 68, actionItems: 34 },
  lastWeek: { debriefs: 15, minutes: 72, actionItems: 28 },
  percentChange: {
    debriefs: -20,
    minutes: -5.6,
    actionItems: 21.4
  }
};

const mockTimelineData = [
  { date: 'Jan 1', debriefs: 3, minutes: 18 },
  { date: 'Jan 2', debriefs: 5, minutes: 24 },
  { date: 'Jan 3', debriefs: 2, minutes: 11 },
  { date: 'Jan 4', debriefs: 7, minutes: 38 },
  { date: 'Jan 5', debriefs: 4, minutes: 22 },
  { date: 'Jan 6', debriefs: 6, minutes: 31 },
  { date: 'Jan 7', debriefs: 3, minutes: 16 },
  { date: 'Jan 8', debriefs: 8, minutes: 42 },
  { date: 'Jan 9', debriefs: 5, minutes: 28 },
  { date: 'Jan 10', debriefs: 4, minutes: 19 }
];

const mockDistribution = [
  { name: 'John Doe', value: 35, color: '#14b8a6' },
  { name: 'Jane Smith', value: 25, color: '#0d9488' },
  { name: 'Bob Wilson', value: 20, color: '#0f766e' },
  { name: 'Alice Brown', value: 12, color: '#115e59' },
  { name: 'Others', value: 8, color: '#134e4a' }
];

const mockTopContacts = [
  { id: '1', name: 'John Doe', company: 'Acme Corp', debriefs: 24, minutes: 142, percentage: 35 },
  { id: '2', name: 'Jane Smith', company: 'Tech Inc', debriefs: 18, minutes: 98, percentage: 25 },
  { id: '3', name: 'Bob Wilson', company: 'StartupXYZ', debriefs: 15, minutes: 87, percentage: 20 }
];

const mockInsights = {
  patterns: [
    { icon: '🔥', title: 'Peak Performance', description: 'You record most debriefs on Monday mornings', color: 'red' },
    { icon: '⚡', title: 'Quick Briefs', description: 'Your average debrief is 5.7 minutes - perfect length!', color: 'yellow' },
    { icon: '📈', title: 'Growing Trend', description: '21% increase in action items this week', color: 'green' }
  ],
  achievements: [
    { icon: '🏆', title: '7-Day Streak', description: 'Longest recording streak' },
    { icon: '⭐', title: '100+ Debriefs', description: 'Century milestone reached' },
    { icon: '🎯', title: 'Top Performer', description: '87% completion rate' }
  ]
};

const mockHeatmap = [
  [0, 3, 2, 4, 1, 3, 2],
  [2, 1, 5, 3, 2, 4, 1],
  [1, 4, 2, 3, 5, 2, 3],
  [3, 2, 4, 1, 2, 5, 4],
  [2, 3, 1, 4, 3, 2, 1],
  [4, 1, 3, 2, 4, 3, 5],
  [1, 2, 4, 3, 1, 2, 3],
  [3, 4, 2, 5, 3, 4, 2],
  [2, 3, 1, 2, 4, 1, 3],
  [5, 2, 3, 1, 2, 3, 4],
  [1, 4, 2, 3, 5, 2, 1],
  [3, 1, 4, 2, 1, 4, 3]
];

const mockQuota = {
  tier: 'Pro',
  recordingsThisMonth: 42,
  recordingsLimit: 100,
  minutesThisMonth: 245,
  minutesLimit: 500,
  storageUsedMB: 1250,
  storageLimitMB: 5000
};

type Tab = 'overview' | 'charts' | 'insights';

interface StatsScreenNewProps {
  onEnterScreenshotMode?: () => void;
}

export default function StatsScreenNew({ onEnterScreenshotMode }: StatsScreenNewProps = {}) {
  const [activeTab, setActiveTab] = useState<Tab>('overview');

  const quotaPercentages = {
    recordings: (mockQuota.recordingsThisMonth / mockQuota.recordingsLimit) * 100,
    minutes: (mockQuota.minutesThisMonth / mockQuota.minutesLimit) * 100,
    storage: (mockQuota.storageUsedMB / mockQuota.storageLimitMB) * 100
  };

  const getTrendIcon = (change: number) => {
    if (change > 0) return <TrendingUp className="w-4 h-4 text-green-400" />;
    if (change < 0) return <TrendingDown className="w-4 h-4 text-red-400" />;
    return null;
  };

  const getTrendColor = (change: number) => {
    if (change > 0) return 'text-green-400';
    if (change < 0) return 'text-red-400';
    return 'text-white/60';
  };

  return (
    <div className="flex flex-col h-full bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900">
      {/* Header */}
      <div className="px-4 py-4 pb-0">
        <h1 className="text-3xl font-bold tracking-tight text-white mb-4">Stats</h1>
        
        {/* Tabs */}
        <div className="flex gap-2 mb-4">
          <button
            onClick={() => setActiveTab('overview')}
            className={`flex-1 px-4 py-2 rounded-lg transition-all ${
              activeTab === 'overview'
                ? 'bg-white/20 text-white'
                : 'bg-white/5 text-white/60 hover:bg-white/10'
            }`}
          >
            <div className="flex items-center justify-center gap-2">
              <Activity className="w-4 h-4" />
              <span className="text-sm font-medium">Overview</span>
            </div>
          </button>
          <button
            onClick={() => setActiveTab('charts')}
            className={`flex-1 px-4 py-2 rounded-lg transition-all ${
              activeTab === 'charts'
                ? 'bg-white/20 text-white'
                : 'bg-white/5 text-white/60 hover:bg-white/10'
            }`}
          >
            <div className="flex items-center justify-center gap-2">
              <BarChart3 className="w-4 h-4" />
              <span className="text-sm font-medium">Charts</span>
            </div>
          </button>
          <button
            onClick={() => setActiveTab('insights')}
            className={`flex-1 px-4 py-2 rounded-lg transition-all ${
              activeTab === 'insights'
                ? 'bg-white/20 text-white'
                : 'bg-white/5 text-white/60 hover:bg-white/10'
            }`}
          >
            <div className="flex items-center justify-center gap-2">
              <Sparkles className="w-4 h-4" />
              <span className="text-sm font-medium">Insights</span>
            </div>
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-4 pb-24">
        {/* OVERVIEW TAB */}
        {activeTab === 'overview' && (
          <div className="space-y-4">
            {/* Current Plan */}
            <div className="bg-gradient-to-br from-teal-500 to-emerald-500 text-white rounded-xl p-6 shadow-lg">
              <div className="flex items-center gap-2 mb-2">
                <Award className="w-6 h-6" />
                <h2 className="text-lg font-semibold">Current Plan</h2>
              </div>
              <p className="text-3xl font-bold mb-1">{mockQuota.tier}</p>
              <p className="text-teal-100 text-sm">All features unlocked</p>
            </div>

            {/* Key Metrics */}
            <div className="grid grid-cols-2 gap-3">
              <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4 hover:bg-white/15 transition-all hover:scale-105">
                <div className="flex items-center gap-2 mb-2">
                  <Mic className="w-5 h-5 text-teal-300" />
                  <span className="text-xs text-white/70">Total Debriefs</span>
                </div>
                <div className="text-3xl font-bold text-white">{mockOverview.totalDebriefs}</div>
                <div className="flex items-center gap-1 mt-1">
                  {getTrendIcon(mockTrends.percentChange.debriefs)}
                  <span className={`text-xs ${getTrendColor(mockTrends.percentChange.debriefs)}`}>
                    {Math.abs(mockTrends.percentChange.debriefs)}%
                  </span>
                </div>
              </div>

              <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4 hover:bg-white/15 transition-all hover:scale-105">
                <div className="flex items-center gap-2 mb-2">
                  <Clock className="w-5 h-5 text-teal-300" />
                  <span className="text-xs text-white/70">Total Minutes</span>
                </div>
                <div className="text-3xl font-bold text-white">{mockOverview.totalMinutes}</div>
                <div className="flex items-center gap-1 mt-1">
                  {getTrendIcon(mockTrends.percentChange.minutes)}
                  <span className={`text-xs ${getTrendColor(mockTrends.percentChange.minutes)}`}>
                    {Math.abs(mockTrends.percentChange.minutes)}%
                  </span>
                </div>
              </div>

              <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4 hover:bg-white/15 transition-all hover:scale-105">
                <div className="flex items-center gap-2 mb-2">
                  <CheckSquare className="w-5 h-5 text-teal-300" />
                  <span className="text-xs text-white/70">Action Items</span>
                </div>
                <div className="text-3xl font-bold text-white">{mockOverview.totalActionItems}</div>
                <div className="flex items-center gap-1 mt-1">
                  {getTrendIcon(mockTrends.percentChange.actionItems)}
                  <span className={`text-xs ${getTrendColor(mockTrends.percentChange.actionItems)}`}>
                    {Math.abs(mockTrends.percentChange.actionItems)}%
                  </span>
                </div>
              </div>

              <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4 hover:bg-white/15 transition-all hover:scale-105">
                <div className="flex items-center gap-2 mb-2">
                  <Users className="w-5 h-5 text-teal-300" />
                  <span className="text-xs text-white/70">Contacts</span>
                </div>
                <div className="text-3xl font-bold text-white">{mockOverview.totalContacts}</div>
                <div className="text-xs text-white/60 mt-1">Active contacts</div>
              </div>
            </div>

            {/* Quick Stats */}
            <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4">
              <h3 className="font-semibold text-white mb-3">Quick Stats</h3>
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 bg-teal-500/30 rounded-lg flex items-center justify-center">
                      <Clock className="w-4 h-4 text-teal-300" />
                    </div>
                    <span className="text-sm text-white/80">Avg Duration</span>
                  </div>
                  <span className="text-sm font-semibold text-white">{mockOverview.avgDebriefDuration} min</span>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 bg-green-500/30 rounded-lg flex items-center justify-center">
                      <Target className="w-4 h-4 text-green-300" />
                    </div>
                    <span className="text-sm text-white/80">Completion Rate</span>
                  </div>
                  <span className="text-sm font-semibold text-white">{mockOverview.completionRate}%</span>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 bg-orange-500/30 rounded-lg flex items-center justify-center">
                      <Calendar className="w-4 h-4 text-orange-300" />
                    </div>
                    <span className="text-sm text-white/80">Most Active Day</span>
                  </div>
                  <span className="text-sm font-semibold text-white">{mockOverview.mostActiveDay}</span>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 bg-red-500/30 rounded-lg flex items-center justify-center">
                      <Zap className="w-4 h-4 text-red-300" />
                    </div>
                    <span className="text-sm text-white/80">Longest Streak</span>
                  </div>
                  <span className="text-sm font-semibold text-white">{mockOverview.longestStreak} days</span>
                </div>
              </div>
            </div>

            {/* Quota Usage */}
            <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4">
              <h3 className="font-semibold text-white mb-4 flex items-center gap-2">
                <Zap className="w-5 h-5 text-teal-300" />
                Quota Usage
              </h3>

              <div className="space-y-4">
                {/* Recordings */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm text-white/80">Recordings</span>
                    <span className="text-sm font-semibold text-white">
                      {mockQuota.recordingsThisMonth} / {mockQuota.recordingsLimit}
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
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm text-white/80">Minutes</span>
                    <span className="text-sm font-semibold text-white">
                      {mockQuota.minutesThisMonth} / {mockQuota.minutesLimit}
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
                      {mockQuota.storageUsedMB} MB / {mockQuota.storageLimitMB} MB
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
            </div>

            {/* Top Contacts */}
            <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4">
              <div className="flex items-center justify-between mb-3">
                <h3 className="font-semibold text-white flex items-center gap-2">
                  <Users className="w-5 h-5 text-teal-300" />
                  Top Contacts
                </h3>
                <button className="text-xs text-teal-300 hover:text-teal-200">View All</button>
              </div>
              <div className="space-y-2">
                {mockTopContacts.map((contact, index) => (
                  <div key={contact.id} className="flex items-center gap-3 p-3 bg-white/5 rounded-lg hover:bg-white/10 transition-colors">
                    <div className="flex-shrink-0 w-8 h-8 bg-teal-500/30 rounded-full flex items-center justify-center">
                      <span className="text-sm font-bold text-teal-300">#{index + 1}</span>
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="font-medium text-white text-sm truncate">{contact.name}</div>
                      <div className="text-xs text-white/60 truncate">{contact.company}</div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-semibold text-white">{contact.debriefs}</div>
                      <div className="text-xs text-white/60">{contact.minutes}m</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* CHARTS TAB */}
        {activeTab === 'charts' && (
          <div className="space-y-4">
            {/* Timeline Chart */}
            <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4">
              <h3 className="font-semibold text-white mb-4">Activity Timeline</h3>
              <ResponsiveContainer width="100%" height={200}>
                <AreaChart data={mockTimelineData}>
                  <defs>
                    <linearGradient id="colorDebriefs" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#14b8a6" stopOpacity={0.8}/>
                      <stop offset="95%" stopColor="#14b8a6" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <XAxis 
                    dataKey="date" 
                    stroke="#ffffff40"
                    style={{ fontSize: '10px' }}
                    tick={{ fill: '#ffffff80' }}
                  />
                  <YAxis 
                    stroke="#ffffff40"
                    style={{ fontSize: '10px' }}
                    tick={{ fill: '#ffffff80' }}
                  />
                  <Tooltip 
                    contentStyle={{ 
                      backgroundColor: 'rgba(255, 255, 255, 0.1)', 
                      border: '1px solid rgba(255, 255, 255, 0.2)',
                      borderRadius: '8px',
                      backdropFilter: 'blur(10px)'
                    }}
                    labelStyle={{ color: '#fff' }}
                    itemStyle={{ color: '#14b8a6' }}
                  />
                  <Area 
                    type="monotone" 
                    dataKey="debriefs" 
                    stroke="#14b8a6" 
                    strokeWidth={2}
                    fillOpacity={1} 
                    fill="url(#colorDebriefs)" 
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>

            {/* Distribution Pie Chart */}
            <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4">
              <h3 className="font-semibold text-white mb-4">Distribution by Contact</h3>
              <div className="flex items-center justify-center">
                <ResponsiveContainer width="100%" height={200}>
                  <PieChart>
                    <Pie
                      data={mockDistribution}
                      cx="50%"
                      cy="50%"
                      innerRadius={50}
                      outerRadius={80}
                      paddingAngle={5}
                      dataKey="value"
                    >
                      {mockDistribution.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip 
                      contentStyle={{ 
                        backgroundColor: 'rgba(255, 255, 255, 0.1)', 
                        border: '1px solid rgba(255, 255, 255, 0.2)',
                        borderRadius: '8px',
                        backdropFilter: 'blur(10px)'
                      }}
                      labelStyle={{ color: '#fff' }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <div className="mt-4 space-y-2">
                {mockDistribution.map((item, index) => (
                  <div key={index} className="flex items-center justify-between text-sm">
                    <div className="flex items-center gap-2">
                      <div 
                        className="w-3 h-3 rounded-full" 
                        style={{ backgroundColor: item.color }}
                      ></div>
                      <span className="text-white/80">{item.name}</span>
                    </div>
                    <span className="text-white font-semibold">{item.value}%</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Activity Heatmap */}
            <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4">
              <h3 className="font-semibold text-white mb-4">Activity Heatmap</h3>
              <div className="overflow-x-auto">
                <div className="inline-flex flex-col gap-1">
                  <div className="flex gap-1 mb-1 ml-6">
                    {['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day, i) => (
                      <div key={i} className="w-4 h-4 text-[8px] text-white/60 flex items-center justify-center">
                        {day}
                      </div>
                    ))}
                  </div>
                  {mockHeatmap.map((week, weekIndex) => (
                    <div key={weekIndex} className="flex gap-1">
                      <div className="w-6 text-[8px] text-white/60 flex items-center justify-end pr-1">
                        W{weekIndex + 1}
                      </div>
                      {week.map((value, dayIndex) => {
                        const intensity = value === 0 ? 0 : value / 5;
                        const bgColor = value === 0 
                          ? 'rgba(255, 255, 255, 0.1)' 
                          : `rgba(20, 184, 166, ${0.2 + intensity * 0.8})`;
                        
                        return (
                          <div
                            key={dayIndex}
                            className="w-4 h-4 rounded-sm transition-all hover:scale-110"
                            style={{ backgroundColor: bgColor }}
                            title={`${value} debriefs`}
                          ></div>
                        );
                      })}
                    </div>
                  ))}
                </div>
              </div>
              <div className="flex items-center justify-end gap-2 mt-3">
                <span className="text-xs text-white/60">Less</span>
                <div className="flex gap-1">
                  {[0, 1, 2, 3, 4, 5].map((level) => (
                    <div
                      key={level}
                      className="w-3 h-3 rounded-sm"
                      style={{ 
                        backgroundColor: level === 0 
                          ? 'rgba(255, 255, 255, 0.1)' 
                          : `rgba(20, 184, 166, ${0.2 + (level / 5) * 0.8})`
                      }}
                    ></div>
                  ))}
                </div>
                <span className="text-xs text-white/60">More</span>
              </div>
            </div>
          </div>
        )}

        {/* INSIGHTS TAB */}
        {activeTab === 'insights' && (
          <div className="space-y-4">
            {/* Patterns */}
            <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4">
              <h3 className="font-semibold text-white mb-4 flex items-center gap-2">
                <Sparkles className="w-5 h-5 text-teal-300" />
                Patterns & Trends
              </h3>
              <div className="space-y-3">
                {mockInsights.patterns.map((pattern, index) => (
                  <div 
                    key={index}
                    className="p-3 bg-white/5 rounded-lg border-l-4"
                    style={{ borderLeftColor: 
                      pattern.color === 'red' ? '#f87171' :
                      pattern.color === 'yellow' ? '#fbbf24' :
                      '#34d399'
                    }}
                  >
                    <div className="flex items-start gap-3">
                      <div className="text-2xl">{pattern.icon}</div>
                      <div className="flex-1">
                        <div className="font-medium text-white text-sm">{pattern.title}</div>
                        <div className="text-xs text-white/70 mt-1">{pattern.description}</div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Achievements */}
            <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4">
              <h3 className="font-semibold text-white mb-4 flex items-center gap-2">
                <Award className="w-5 h-5 text-teal-300" />
                Achievements
              </h3>
              <div className="grid grid-cols-1 gap-3">
                {mockInsights.achievements.map((achievement, index) => (
                  <div 
                    key={index}
                    className="p-4 bg-gradient-to-r from-yellow-500/20 to-orange-500/20 rounded-lg border border-yellow-400/30"
                  >
                    <div className="flex items-center gap-3">
                      <div className="text-3xl">{achievement.icon}</div>
                      <div className="flex-1">
                        <div className="font-semibold text-white">{achievement.title}</div>
                        <div className="text-sm text-white/70 mt-0.5">{achievement.description}</div>
                      </div>
                      <ChevronRight className="w-5 h-5 text-white/40" />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Recommendations */}
            <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl p-4">
              <h3 className="font-semibold text-white mb-4 flex items-center gap-2">
                <Target className="w-5 h-5 text-teal-300" />
                Recommendations
              </h3>
              <div className="space-y-3">
                <div className="p-3 bg-blue-500/10 border border-blue-400/30 rounded-lg">
                  <div className="flex items-start gap-2">
                    <AlertCircle className="w-5 h-5 text-blue-400 mt-0.5" />
                    <div>
                      <div className="text-sm font-medium text-white">Record more in the afternoon</div>
                      <div className="text-xs text-white/70 mt-1">
                        Your debriefs are 30% longer in the afternoon - more productive time!
                      </div>
                    </div>
                  </div>
                </div>

                <div className="p-3 bg-purple-500/10 border border-purple-400/30 rounded-lg">
                  <div className="flex items-start gap-2">
                    <AlertCircle className="w-5 h-5 text-purple-400 mt-0.5" />
                    <div>
                      <div className="text-sm font-medium text-white">Follow up with Bob Wilson</div>
                      <div className="text-xs text-white/70 mt-1">
                        No debriefs recorded for 7 days - might need a check-in
                      </div>
                    </div>
                  </div>
                </div>

                <div className="p-3 bg-green-500/10 border border-green-400/30 rounded-lg">
                  <div className="flex items-start gap-2">
                    <AlertCircle className="w-5 h-5 text-green-400 mt-0.5" />
                    <div>
                      <div className="text-sm font-medium text-white">Keep up the momentum!</div>
                      <div className="text-xs text-white/70 mt-1">
                        You're on track to beat last month's record
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}