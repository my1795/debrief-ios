import React from 'react';
import { DebriefStatus } from '../types';
import { Clock, Upload, Loader2, CheckCircle2, XCircle } from 'lucide-react';

interface StatusBadgeProps {
  status: DebriefStatus;
  showIcon?: boolean;
}

export default function StatusBadge({ status, showIcon = true }: StatusBadgeProps) {
  const getStatusConfig = (status: DebriefStatus) => {
    switch (status) {
      case 'DRAFT':
        return {
          label: 'Draft',
          color: 'bg-gray-100 text-gray-700 border-gray-300',
          icon: Clock
        };
      case 'UPLOADED':
        return {
          label: 'Uploaded',
          color: 'bg-blue-100 text-blue-700 border-blue-300',
          icon: Upload
        };
      case 'PROCESSING':
        return {
          label: 'Processing',
          color: 'bg-yellow-100 text-yellow-700 border-yellow-300',
          icon: Loader2
        };
      case 'READY':
        return {
          label: 'Ready',
          color: 'bg-green-100 text-green-700 border-green-300',
          icon: CheckCircle2
        };
      case 'FAILED':
        return {
          label: 'Failed',
          color: 'bg-red-100 text-red-700 border-red-300',
          icon: XCircle
        };
      default:
        return {
          label: status,
          color: 'bg-gray-100 text-gray-700 border-gray-300',
          icon: Clock
        };
    }
  };

  const config = getStatusConfig(status);
  const Icon = config.icon;

  return (
    <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium border ${config.color}`}>
      {showIcon && <Icon className={`w-3.5 h-3.5 ${status === 'PROCESSING' ? 'animate-spin' : ''}`} />}
      {config.label}
    </span>
  );
}
