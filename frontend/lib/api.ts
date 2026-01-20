import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add token to requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle 401 errors globally
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Token expired or invalid - clear auth state
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      
      // Only redirect if not already on login page
      if (typeof window !== 'undefined' && !window.location.pathname.includes('/login')) {
        window.location.href = '/login?expired=true';
      }
    }
    return Promise.reject(error);
  }
);

// Auth
export const auth = {
  register: (data: any) => api.post('/api/v1/auth/register', data),
  login: (username: string, password: string) => 
    api.post('/api/v1/auth/login', new URLSearchParams({ username, password }), {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    }),
  getMe: () => api.get('/api/v1/auth/me'),
};

// Chat
export const chat = {
  sendMessage: (content: string, conversationId?: number, ragMode?: 'fast' | 'accurate') =>
    api.post('/api/v1/chat/message', { content, conversation_id: conversationId, rag_mode: ragMode }),
  getConversations: () => api.get('/api/v1/chat/conversations'),
  getConversation: (id: number) => api.get(`/api/v1/chat/conversations/${id}`),
  deleteConversation: (id: number) => api.delete(`/api/v1/chat/conversations/${id}`),
};

// Documents
export const documents = {
  upload: (file: File) => {
    const formData = new FormData();
    formData.append('file', file);
    return api.post('/api/v1/documents/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    });
  },
  getAll: () => api.get('/api/v1/documents/'),
  getOne: (id: number) => api.get(`/api/v1/documents/${id}`),
  delete: (id: number) => api.delete(`/api/v1/documents/${id}`),
};

// Analytics
export const analytics = {
  getOverview: () => api.get('/api/v1/analytics/overview'),
  getUsage: (days: number = 7) => api.get(`/api/v1/analytics/usage?days=${days}`),
};

export default api;
