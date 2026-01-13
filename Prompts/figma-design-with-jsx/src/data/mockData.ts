import { Debrief, Contact, StatsQuota, DashboardStats, TimelineEntry } from '../types';

export const mockDebriefs: Debrief[] = [
  {
    debriefId: 'uuid-1',
    contactId: 'contact-1',
    contactName: 'Ahmet - TechCorp',
    occurredAt: '2026-01-13T14:30:00Z',
    duration: 900, // 15 minutes
    status: 'READY',
    summary: 'Discussed enterprise plan with Ahmet. He\'s interested in the enterprise plan. Need to send pricing by Friday. Also schedule a demo for their team next Tuesday.',
    transcript: 'Full transcript: I just had a great conversation with Ahmet from TechCorp. We talked about their enterprise licensing needs...',
    actionItems: [
      'Send pricing proposal by Friday',
      'Schedule demo for their team next Tuesday',
      'Follow up on integration requirements'
    ],
    audioUrl: 'https://example.com/audio/1.mp3',
    createdAt: '2026-01-13T14:45:00Z'
  },
  {
    debriefId: 'uuid-2',
    contactId: 'contact-2',
    contactName: 'Mehmet - ABC Ltd',
    occurredAt: '2026-01-12T10:15:00Z',
    duration: 600, // 10 minutes
    status: 'READY',
    summary: 'Follow-up on proposal, they asked about budget concerns and timeline flexibility.',
    transcript: 'Mehmet called about the proposal we sent last week...',
    actionItems: [
      'Prepare security review materials'
    ],
    audioUrl: 'https://example.com/audio/2.mp3',
    createdAt: '2026-01-12T10:25:00Z'
  },
  {
    debriefId: 'uuid-3',
    contactId: 'contact-3',
    contactName: 'Ayşe - XYZ Corp',
    occurredAt: '2026-01-11T16:45:00Z',
    duration: 480, // 8 minutes
    status: 'PROCESSING',
    summary: undefined,
    transcript: undefined,
    actionItems: undefined,
    audioUrl: 'https://example.com/audio/3.mp3',
    createdAt: '2026-01-11T16:53:00Z'
  },
  {
    debriefId: 'uuid-4',
    contactId: 'contact-4',
    contactName: 'Sarah - Innovation Inc',
    occurredAt: '2026-01-10T09:00:00Z',
    duration: 1200, // 20 minutes
    status: 'READY',
    summary: 'Initial introduction call. Sarah is interested in our platform for her team of 50 people.',
    transcript: 'Great first conversation with Sarah from Innovation Inc...',
    actionItems: [
      'Send trial access credentials',
      'Set up onboarding call for next week'
    ],
    audioUrl: 'https://example.com/audio/4.mp3',
    createdAt: '2026-01-10T09:20:00Z'
  },
  {
    debriefId: 'uuid-5',
    contactId: 'contact-5',
    contactName: 'John - StartupCo',
    occurredAt: '2026-01-09T13:15:00Z',
    duration: 300, // 5 minutes
    status: 'FAILED',
    summary: undefined,
    transcript: undefined,
    actionItems: undefined,
    audioUrl: undefined,
    createdAt: '2026-01-09T13:20:00Z'
  },
  {
    debriefId: 'uuid-6',
    contactId: 'contact-1',
    contactName: 'Ahmet - TechCorp',
    occurredAt: '2025-12-15T11:30:00Z',
    duration: 720, // 12 minutes
    status: 'READY',
    summary: 'Discussed budget concerns and timeline for Q1 rollout.',
    transcript: 'Follow-up conversation about their Q1 plans...',
    actionItems: [
      'Send technical docs to Ayşe',
      'Prepare security review materials'
    ],
    audioUrl: 'https://example.com/audio/6.mp3',
    createdAt: '2025-12-15T11:42:00Z'
  },
  {
    debriefId: 'uuid-7',
    contactId: 'contact-2',
    contactName: 'Mehmet - ABC Ltd',
    occurredAt: '2025-11-28T15:20:00Z',
    duration: 540, // 9 minutes
    status: 'READY',
    summary: 'Initial product demo. Mehmet asked great questions about API integration.',
    transcript: 'First demo with Mehmet went really well...',
    actionItems: [
      'Follow-up with pricing details'
    ],
    audioUrl: 'https://example.com/audio/7.mp3',
    createdAt: '2025-11-28T15:29:00Z'
  },
  {
    debriefId: 'uuid-8',
    contactId: 'contact-1',
    contactName: 'Ahmet - TechCorp',
    occurredAt: '2025-11-10T14:00:00Z',
    duration: 420, // 7 minutes
    status: 'READY',
    summary: 'First introduction call. Ahmet expressed strong interest in enterprise features.',
    transcript: 'Initial conversation with Ahmet from TechCorp...',
    actionItems: [],
    audioUrl: 'https://example.com/audio/8.mp3',
    createdAt: '2025-11-10T14:07:00Z'
  }
];

export const mockContacts: Contact[] = [
  {
    contactId: 'contact-1',
    name: 'Ahmet',
    handle: 'TechCorp',
    lastContactedAt: '2026-01-13T14:30:00Z',
    totalDebriefs: 3,
    relationshipStatus: 'Active prospect'
  },
  {
    contactId: 'contact-2',
    name: 'Mehmet',
    handle: 'ABC Ltd',
    lastContactedAt: '2026-01-12T10:15:00Z',
    totalDebriefs: 2,
    relationshipStatus: 'Active prospect'
  },
  {
    contactId: 'contact-3',
    name: 'Ayşe',
    handle: 'XYZ Corp',
    lastContactedAt: '2026-01-11T16:45:00Z',
    totalDebriefs: 1,
    relationshipStatus: 'New contact'
  },
  {
    contactId: 'contact-4',
    name: 'Sarah',
    handle: 'Innovation Inc',
    lastContactedAt: '2026-01-10T09:00:00Z',
    totalDebriefs: 1,
    relationshipStatus: 'New contact'
  },
  {
    contactId: 'contact-5',
    name: 'John',
    handle: 'StartupCo',
    lastContactedAt: '2026-01-09T13:15:00Z',
    totalDebriefs: 1,
    relationshipStatus: 'New contact'
  }
];

export const mockQuota: StatsQuota = {
  tier: 'Professional',
  recordingsThisMonth: 12,
  recordingsLimit: 50,
  minutesThisMonth: 142,
  minutesLimit: 300,
  storageUsedMB: 234,
  storageLimitMB: 5000
};

export const mockDashboardStats: DashboardStats = {
  thisWeek: {
    debriefs: 5,
    minutes: 58,
    actionItems: 12
  },
  thisMonth: {
    debriefs: 12,
    minutes: 142,
    actionItems: 28
  },
  recentActivity: [
    { date: '2026-01-13', count: 1 },
    { date: '2026-01-12', count: 1 },
    { date: '2026-01-11', count: 1 },
    { date: '2026-01-10', count: 1 },
    { date: '2026-01-09', count: 1 },
    { date: '2026-01-08', count: 0 },
    { date: '2026-01-07', count: 0 }
  ]
};

export const getContactTimeline = (contactId: string): TimelineEntry[] => {
  const debriefs = mockDebriefs.filter(d => d.contactId === contactId);
  return debriefs.map(d => ({
    debriefId: d.debriefId,
    occurredAt: d.occurredAt,
    duration: d.duration,
    summary: d.summary || 'Processing...',
    actionItemsCount: d.actionItems?.length || 0,
    status: d.status
  }));
};
