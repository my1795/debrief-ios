interface ContactDetailScreenProps {
  onBack: () => void;
}

export default function ContactDetailScreen({ onBack }: ContactDetailScreenProps) {
  return (
    <div className="p-4">
      <button onClick={onBack} className="mb-4 text-blue-600">← Back</button>
      <h1 className="text-2xl mb-4">Contact Detail</h1>
      <p className="text-gray-500">Contact timeline coming soon...</p>
    </div>
  );
}
