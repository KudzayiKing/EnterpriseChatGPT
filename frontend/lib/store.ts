import { create } from 'zustand';
import { Language } from './translations';

interface User {
  id: number;
  email: string;
  username: string;
  full_name?: string;
}

interface Message {
  id: number;
  role: string;
  content: string;
  sources?: any[];
  suggested_actions?: any[];
  created_at: string;
}

interface Conversation {
  id: number;
  title: string;
  messages: Message[];
  created_at: string;
  updated_at: string;
}

interface AppState {
  user: User | null;
  token: string | null;
  currentConversation: Conversation | null;
  conversations: Conversation[];
  language: Language;
  setUser: (user: User | null) => void;
  setToken: (token: string | null) => void;
  setCurrentConversation: (conversation: Conversation | null) => void;
  setConversations: (conversations: Conversation[]) => void;
  setLanguage: (language: Language) => void;
  logout: () => void;
}

export const useStore = create<AppState>((set) => ({
  user: null,
  token: null,
  currentConversation: null,
  conversations: [],
  language: (typeof window !== 'undefined' ? localStorage.getItem('language') as Language : null) || 'rw',
  setUser: (user) => set({ user }),
  setToken: (token) => {
    if (token) {
      localStorage.setItem('token', token);
    } else {
      localStorage.removeItem('token');
    }
    set({ token });
  },
  setCurrentConversation: (conversation) => set({ currentConversation: conversation }),
  setConversations: (conversations) => set({ conversations }),
  setLanguage: (language) => {
    if (typeof window !== 'undefined') {
      localStorage.setItem('language', language);
    }
    set({ language });
  },
  logout: () => {
    localStorage.removeItem('token');
    set({ user: null, token: null, currentConversation: null, conversations: [] });
  },
}));
