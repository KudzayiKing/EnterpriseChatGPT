export type Language = 'rw' | 'en' | 'fr';

export const languages = [
  { code: 'rw' as Language, name: 'Kinyarwanda', flag: '🇷🇼', voiceCode: 'rw-RW' },
  { code: 'en' as Language, name: 'English', flag: '🇬🇧', voiceCode: 'en-US' },
  { code: 'fr' as Language, name: 'Français', flag: '🇫🇷', voiceCode: 'fr-FR' },
];

export const translations = {
  rw: {
    // Chat Interface
    placeholder: 'Baza IremboChat...',
    newChat: 'Ikiganiro gishya',
    documents: 'Inyandiko',
    analytics: 'Imibare',
    settings: 'Igenamiterere',
    logout: 'Sohoka',
    
    // Messages
    loading: 'Tegereza...',
    typing: 'Yandika...',
    error: 'Ikosa ryabaye',
    noMessages: 'Ntakintu cyanditswe',
    
    // Actions
    copy: 'Koporora',
    copied: 'Byakoporoye',
    download: 'Kuramo',
    
    // Settings
    general: 'Rusange',
    profile: 'Umwirondoro',
    about: 'Ibyerekeye',
    darkMode: 'Uburyo bwijimye',
    language: 'Ururimi',
    
    // Documents
    uploadDocuments: 'Ohereza inyandiko',
    dragDrop: 'Kurura no gusohora inyandiko hano',
    supported: 'Zemewe',
    
    // Voice
    startVoice: 'Tangira ijwi',
    stopVoice: 'Hagarika ijwi',
    listening: 'Tumva...',
  },
  en: {
    // Chat Interface
    placeholder: 'Ask IremboChat...',
    newChat: 'New Chat',
    documents: 'Documents',
    analytics: 'Analytics',
    settings: 'Settings',
    logout: 'Logout',
    
    // Messages
    loading: 'Loading...',
    typing: 'Typing...',
    error: 'An error occurred',
    noMessages: 'No messages yet',
    
    // Actions
    copy: 'Copy',
    copied: 'Copied',
    download: 'Download',
    
    // Settings
    general: 'General',
    profile: 'Profile',
    about: 'About',
    darkMode: 'Dark Mode',
    language: 'Language',
    
    // Documents
    uploadDocuments: 'Upload Documents',
    dragDrop: 'Drag & drop files here',
    supported: 'Supported',
    
    // Voice
    startVoice: 'Start voice input',
    stopVoice: 'Stop listening',
    listening: 'Listening...',
  },
  fr: {
    // Chat Interface
    placeholder: 'Demandez à IremboChat...',
    newChat: 'Nouvelle conversation',
    documents: 'Documents',
    analytics: 'Analytique',
    settings: 'Paramètres',
    logout: 'Déconnexion',
    
    // Messages
    loading: 'Chargement...',
    typing: 'Écriture...',
    error: 'Une erreur est survenue',
    noMessages: 'Aucun message',
    
    // Actions
    copy: 'Copier',
    copied: 'Copié',
    download: 'Télécharger',
    
    // Settings
    general: 'Général',
    profile: 'Profil',
    about: 'À propos',
    darkMode: 'Mode sombre',
    language: 'Langue',
    
    // Documents
    uploadDocuments: 'Télécharger des documents',
    dragDrop: 'Glissez-déposez les fichiers ici',
    supported: 'Pris en charge',
    
    // Voice
    startVoice: 'Démarrer la saisie vocale',
    stopVoice: 'Arrêter l\'écoute',
    listening: 'Écoute...',
  },
};

export const getTranslation = (lang: Language, key: keyof typeof translations.en): string => {
  return translations[lang][key] || translations.en[key];
};
