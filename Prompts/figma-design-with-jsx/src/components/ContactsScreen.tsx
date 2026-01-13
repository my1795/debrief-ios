interface ContactsScreenProps {
  onContactClick: () => void;
}

export default function ContactsScreen({ onContactClick }: ContactsScreenProps) {
  return (
    <div className="p-4">
      <h1 className="text-2xl mb-4">Contacts</h1>
      <p className="text-gray-500">Contacts list coming soon...</p>
    </div>
  );
}
