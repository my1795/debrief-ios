interface DebriefDetailScreenProps {
  onBack: () => void;
}

export default function DebriefDetailScreen({ onBack }: DebriefDetailScreenProps) {
  return (
    <div className="p-4">
      <button onClick={onBack} className="mb-4 text-blue-600">← Back</button>
      <h1 className="text-2xl mb-4">Debrief Detail</h1>
      <p className="text-gray-500">Detail view coming soon...</p>
    </div>
  );
}
