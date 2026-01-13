import React from 'react';
import { User, Shield, Database, CreditCard, HelpCircle, ChevronRight, ExternalLink, LogOut, Camera } from 'lucide-react';
import { mockQuota } from '../data/mockData';
import { auth } from '../lib/firebase';

interface SettingsScreenProps {
  onEnterScreenshotMode?: () => void;
}

export default function SettingsScreen({ onEnterScreenshotMode }: SettingsScreenProps = {}) {
  const quota = mockQuota;

  const handleSignOut = async () => {
    if (confirm('Are you sure you want to sign out?')) {
      try {
        await auth.signOut();
      } catch (error) {
        console.error('Sign out error:', error);
        alert('Failed to sign out. Please try again.');
      }
    }
  };

  const settingsSections = [
    {
      title: 'Account',
      icon: User,
      items: [
        { label: 'Profile', action: () => alert('Profile settings (mock)') },
        { label: 'Email & Notifications', action: () => alert('Notification settings (mock)') }
      ]
    },
    {
      title: 'Plan & Billing',
      icon: CreditCard,
      items: [
        { 
          label: 'Current Plan', 
          value: quota.tier,
          action: () => alert('Plan details (mock)') 
        },
        { label: 'Upgrade Plan', action: () => alert('Upgrade options (mock)') },
        { label: 'Billing History', action: () => alert('Billing history (mock)') }
      ]
    },
    {
      title: 'Privacy & Data',
      icon: Shield,
      items: [
        { 
          label: 'Privacy Policy', 
          action: () => alert('Privacy policy (mock)'),
          external: true 
        },
        { 
          label: 'Data Handling', 
          action: () => alert('Data handling info (mock)') 
        }
      ]
    },
    {
      title: 'Storage',
      icon: Database,
      items: [
        { 
          label: 'Audio Storage', 
          value: `${quota.storageUsedMB} MB used`,
          action: () => alert('Storage details (mock)') 
        },
        { label: 'Clear Cache', action: () => alert('Cache cleared (mock)') }
      ]
    },
    {
      title: 'Support',
      icon: HelpCircle,
      items: [
        { 
          label: 'Help Center', 
          action: () => alert('Help center (mock)'),
          external: true 
        },
        { label: 'Contact Support', action: () => alert('Contact support (mock)') },
        { label: 'Send Feedback', action: () => alert('Feedback form (mock)') }
      ]
    }
  ];

  return (
    <div className="flex flex-col h-full bg-gradient-to-br from-teal-900 via-teal-800 to-emerald-900 overflow-y-auto">
      {/* Header */}
      <div className="px-4 py-4">
        <h1 className="text-3xl font-bold tracking-tight text-white">Settings</h1>
      </div>

      <div className="px-4 py-4 space-y-4">
        {/* Important Notice */}
        <div className="bg-teal-400/20 backdrop-blur-md border border-teal-300/30 rounded-xl p-4">
          <h3 className="font-semibold text-teal-100 mb-1">Privacy First</h3>
          <p className="text-sm text-teal-200">
            This app is designed for recording personal debriefs and notes. It is not intended for 
            collecting personally identifiable information (PII) or securing sensitive data.
          </p>
        </div>

        {/* Settings Sections */}
        {settingsSections.map((section, sectionIndex) => (
          <div key={sectionIndex} className="bg-white/10 backdrop-blur-md border border-white/20 rounded-xl overflow-hidden">
            <div className="px-4 py-3 border-b border-white/20">
              <h2 className="font-semibold text-white flex items-center gap-2">
                <section.icon className="w-5 h-5 text-teal-300" />
                {section.title}
              </h2>
            </div>
            <div>
              {section.items.map((item, itemIndex) => (
                <button
                  key={itemIndex}
                  onClick={item.action}
                  className="w-full px-4 py-3 flex items-center justify-between hover:bg-white/10 transition-colors border-b border-white/10 last:border-b-0"
                >
                  <div className="flex-1 text-left">
                    <span className="text-white">{item.label}</span>
                    {item.value && (
                      <span className="ml-2 text-sm text-white/60">{item.value}</span>
                    )}
                  </div>
                  {item.external ? (
                    <ExternalLink className="w-5 h-5 text-white/60" />
                  ) : (
                    <ChevronRight className="w-5 h-5 text-white/60" />
                  )}
                </button>
              ))}
            </div>
          </div>
        ))}

        {/* Screenshot Mode Button - Developer Tool */}
        {onEnterScreenshotMode && (
          <button
            onClick={onEnterScreenshotMode}
            className="w-full bg-purple-500/20 backdrop-blur-md border border-purple-400/30 rounded-xl p-4 flex items-center justify-center gap-2 hover:bg-purple-500/30 transition-colors"
          >
            <Camera className="w-5 h-5 text-purple-300" />
            <span className="text-purple-300 font-semibold">📸 Screenshot Mode</span>
          </button>
        )}

        {/* Sign Out Button */}
        <button
          onClick={handleSignOut}
          className="w-full bg-red-500/20 backdrop-blur-md border border-red-400/30 rounded-xl p-4 flex items-center justify-center gap-2 hover:bg-red-500/30 transition-colors"
        >
          <LogOut className="w-5 h-5 text-red-300" />
          <span className="text-red-300 font-semibold">Sign Out</span>
        </button>

        {/* App Info */}
        <div className="text-center text-sm text-white/60 py-4 mb-6">
          <p>Debrief App v1.0.0</p>
          <p className="mt-1">© 2026 All rights reserved</p>
        </div>
      </div>
    </div>
  );
}