export type DebriefStatus = 'DRAFT' | 'UPLOADED' | 'PROCESSING' | 'READY' | 'FAILED';

export interface Debrief {
  debriefId: string;
  contactId: string;
  contactName: string;
  occurredAt: string;
  duration: number; // in seconds
  status: DebriefStatus;
  summary?: string;
  transcript?: string;
  actionItems?: string[];
  audioUrl?: string;
  createdAt: string;
}

export interface Contact {
  contactId: string;
  name: string;
  handle?: string;
  lastContactedAt?: string;
  totalDebriefs: number;
  relationshipStatus?: string;
}

export interface TimelineEntry {
  debriefId: string;
  occurredAt: string;
  duration: number;
  summary: string;
  actionItemsCount: number;
  status: DebriefStatus;
}

export interface StatsQuota {
  tier: string;
  recordingsThisMonth: number;
  recordingsLimit: number;
  minutesThisMonth: number;
  minutesLimit: number;
  storageUsedMB: number;
  storageLimitMB: number;
}

export interface DashboardStats {
  thisWeek: {
    debriefs: number;
    minutes: number;
    actionItems: number;
  };
  thisMonth: {
    debriefs: number;
    minutes: number;
    actionItems: number;
  };
  recentActivity: Array<{
    date: string;
    count: number;
  }>;
}
