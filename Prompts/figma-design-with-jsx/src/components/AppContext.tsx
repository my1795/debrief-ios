import { createContext, useContext, useState, ReactNode } from 'react';

export type DebriefStatus = 'DRAFT' | 'UPLOADED' | 'PROCESSING' | 'READY' | 'FAILED';

export interface ActionItem {
  id: string;
  text: string;
  completed: boolean;
}

export interface Debrief {
  id: string;
  contactId: string;
  contactName: string;
  occurredAt: string;
  duration: number; // in seconds
  status: DebriefStatus;
  summary?: string;
  transcript?: string;
  actionItems?: ActionItem[];
  audioUrl?: string;
}

export interface Contact {
  id: string;
  name: string;
  handle?: string;
  lastContactDate?: string;
  totalDebriefs: number;
  relationshipStatus?: string;
}

export interface QuotaInfo {
  tier: string;
  recordingsUsed: number;
  recordingsLimit: number;
  storageUsed: number;
  storageLimit: number;
}

interface AppContextType {
  debriefs: Debrief[];
  contacts: Contact[];
  quota: QuotaInfo;
  selectedDebriefId: string | null;
  selectedContactId: string | null;
  setSelectedDebriefId: (id: string | null) => void;
  setSelectedContactId: (id: string | null) => void;
  addDebrief: (debrief: Debrief) => void;
  updateDebrief: (id: string, updates: Partial<Debrief>) => void;
  deleteDebrief: (id: string) => void;
  addContact: (contact: Contact) => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

// Mock data
const mockContacts: Contact[] = [
  { id: 'c1', name: 'Ahmet', handle: 'TechCorp', lastContactDate: '2024-12-15', totalDebriefs: 3, relationshipStatus: 'Active prospect' },
  { id: 'c2', name: 'Mehmet', handle: 'ABC Ltd', lastContactDate: '2024-11-28', totalDebriefs: 2, relationshipStatus: 'Active prospect' },
  { id: 'c3', name: 'Ayşe', handle: 'XYZ Corp', lastContactDate: '2024-11-10', totalDebriefs: 1, relationshipStatus: 'Active prospect' },
  { id: 'c4', name: 'John Doe', handle: 'Enterprise Inc', lastContactDate: '2024-11-05', totalDebriefs: 4, relationshipStatus: 'Active client' },
];

const mockDebriefs: Debrief[] = [
  {
    id: 'd1',
    contactId: 'c1',
    contactName: 'Ahmet - TechCorp',
    occurredAt: '2024-12-15T14:30:00Z',
    duration: 900,
    status: 'READY',
    summary: 'Discussed enterprise plan with Ahmet. He\'s interested in the enterprise plan. Need to send pricing by Friday. Also schedule a demo for their team next Tuesday.',
    transcript: 'Full transcript here...',
    actionItems: [
      { id: 'a1', text: 'Send pricing proposal by Friday', completed: false },
      { id: 'a2', text: 'Schedule demo for next Tuesday', completed: false },
    ],
    audioUrl: 'https://example.com/audio1.mp3',
  },
  {
    id: 'd2',
    contactId: 'c2',
    contactName: 'Mehmet - ABC Ltd',
    occurredAt: '2024-11-28T10:15:00Z',
    duration: 600,
    status: 'READY',
    summary: 'Initial product demo. Follow-up on proposal, they asked about integration requirements.',
    transcript: 'Full transcript here...',
    actionItems: [
      { id: 'a3', text: 'Follow-up on proposal', completed: true },
    ],
    audioUrl: 'https://example.com/audio2.mp3',
  },
  {
    id: 'd3',
    contactId: 'c3',
    contactName: 'Ayşe - XYZ Corp',
    occurredAt: '2024-11-10T16:45:00Z',
    duration: 450,
    status: 'READY',
    summary: 'First introduction call. Discussed budget approval process.',
    transcript: 'Full transcript here...',
    actionItems: [],
    audioUrl: 'https://example.com/audio3.mp3',
  },
  {
    id: 'd4',
    contactId: 'c1',
    contactName: 'Ahmet - TechCorp',
    occurredAt: '2024-12-10T09:00:00Z',
    duration: 720,
    status: 'PROCESSING',
    summary: undefined,
    transcript: undefined,
  },
  {
    id: 'd5',
    contactId: 'c4',
    contactName: 'John Doe - Enterprise Inc',
    occurredAt: '2024-11-05T11:30:00Z',
    duration: 1200,
    status: 'FAILED',
    summary: undefined,
    transcript: undefined,
  },
];

export function AppProvider({ children }: { children: ReactNode }) {
  const [debriefs, setDebriefs] = useState<Debrief[]>(mockDebriefs);
  const [contacts, setContacts] = useState<Contact[]>(mockContacts);
  const [selectedDebriefId, setSelectedDebriefId] = useState<string | null>(null);
  const [selectedContactId, setSelectedContactId] = useState<string | null>(null);
  
  const quota: QuotaInfo = {
    tier: 'Pro',
    recordingsUsed: 23,
    recordingsLimit: 100,
    storageUsed: 2.4, // GB
    storageLimit: 10, // GB
  };

  const addDebrief = (debrief: Debrief) => {
    setDebriefs(prev => [debrief, ...prev]);
  };

  const updateDebrief = (id: string, updates: Partial<Debrief>) => {
    setDebriefs(prev =>
      prev.map(d => (d.id === id ? { ...d, ...updates } : d))
    );
  };

  const deleteDebrief = (id: string) => {
    setDebriefs(prev => prev.filter(d => d.id !== id));
  };

  const addContact = (contact: Contact) => {
    setContacts(prev => [contact, ...prev]);
  };

  return (
    <AppContext.Provider
      value={{
        debriefs,
        contacts,
        quota,
        selectedDebriefId,
        selectedContactId,
        setSelectedDebriefId,
        setSelectedContactId,
        addDebrief,
        updateDebrief,
        deleteDebrief,
        addContact,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within AppProvider');
  }
  return context;
}
