'use client';

import { useEffect, useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useStore } from '@/lib/store';
import { chat, auth } from '@/lib/api';
import { MessageSquare, Upload, BarChart3, LogOut, Send, Plus, Menu, Sun, Moon, Copy, Download, Check, MoreVertical, X, Settings, User, Info } from 'lucide-react';
import ReactMarkdown from 'react-markdown';

export default function Chat() {
  const router = useRouter();
  const { user, setUser, token, setToken, currentConversation, setCurrentConversation, conversations, setConversations, logout } = useStore();
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [darkMode, setDarkMode] = useState(false);
  const [ragMode, setRagMode] = useState<'fast' | 'accurate'>('fast');
  const [streamingText, setStreamingText] = useState('');
  const [isStreaming, setIsStreaming] = useState(false);
  const [copiedMessageId, setCopiedMessageId] = useState<number | null>(null);
  const [showSettingsModal, setShowSettingsModal] = useState(false);
  const [settingsTab, setSettingsTab] = useState<'general' | 'profile' | 'about'>('general');
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const messagesContainerRef = useRef<HTMLDivElement>(null);
  const [longPressConvId, setLongPressConvId] = useState<number | null>(null);
  const longPressTimerRef = useRef<NodeJS.Timeout | null>(null);

  // Auto-scroll to bottom when messages change or streaming updates
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    const storedToken = localStorage.getItem('token');
    if (storedToken) {
      setToken(storedToken);
      loadUserAndConversations();
    }
    // No redirect - allow anonymous usage
  }, []);

  // Scroll to bottom when conversation changes or new messages arrive
  useEffect(() => {
    scrollToBottom();
  }, [currentConversation?.messages, streamingText, loading]);

  const loadUserAndConversations = async () => {
    try {
      const response = await auth.getMe();
      setUser(response.data);
      await loadConversations();
    } catch (error: any) {
      // Token expired or invalid
      if (error.response?.status === 401) {
        console.log('Session expired, clearing auth...');
        logout();
        // Don't redirect - allow anonymous usage
      }
    }
  };

  const loadConversations = async () => {
    try {
      const response = await chat.getConversations();
      setConversations(response.data);
    } catch (error: any) {
      if (error.response?.status === 401) {
        // Token expired, already handled in loadUserAndConversations
        return;
      }
      console.error('Error loading conversations:', error);
    }
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!message.trim() || loading) return;

    const userMessage = message;
    setMessage('');

    // Step 1: Immediately show user's message in the UI
    const tempUserMessage = {
      id: Date.now(),
      role: 'user' as const,
      content: userMessage,
      sources: [],
      created_at: new Date().toISOString()
    };

    if (!currentConversation) {
      // Create new conversation with user's message
      setCurrentConversation({
        id: 0,
        title: userMessage.slice(0, 50),
        messages: [tempUserMessage],
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      });
    } else {
      // Add user's message to existing conversation
      setCurrentConversation({
        ...currentConversation,
        messages: [...currentConversation.messages, tempUserMessage]
      });
    }

    // Step 2: Show loading (animated dots)
    setLoading(true);

    try {
      // Check if user is logged in
      if (!token && !localStorage.getItem('token')) {
        // Anonymous mode - show demo response
        await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate delay
        
        const demoResponse = {
          id: Date.now() + 1,
          role: 'assistant' as const,
          content: `I received your message: "${userMessage}"\n\nTo use the full AI-powered chat with document search, please login or create an account using the button in the sidebar.\n\nWith an account, you can:\n- Upload documents\n- Get AI-powered answers from your documents\n- Save conversation history\n- Access analytics`,
          sources: [],
          created_at: new Date().toISOString()
        };

        setLoading(false);
        
        // Step 3: Stream the response
        setIsStreaming(true);
        setStreamingText('');
        
        const fullText = demoResponse.content;
        let currentIndex = 0;

        const typingInterval = setInterval(() => {
          if (currentIndex < fullText.length) {
            setStreamingText(fullText.substring(0, currentIndex + 1));
            currentIndex++;
          } else {
            clearInterval(typingInterval);
            setIsStreaming(false);
            setStreamingText('');
            
            // Add assistant's message to conversation
            if (currentConversation) {
              setCurrentConversation({
                ...currentConversation,
                messages: [...currentConversation.messages, demoResponse]
              });
            }
          }
        }, 20);
        
        return;
      }

      // Step 3: Send message to backend
      const response = await chat.sendMessage(userMessage, currentConversation?.id, ragMode);

      // Step 4: Get the full conversation with the new response
      let convResponse;
      if (!currentConversation || currentConversation.id === 0) {
        convResponse = await chat.getConversation(response.data.conversation_id);
        loadConversations();
      } else {
        convResponse = await chat.getConversation(currentConversation.id);
      }

      setLoading(false);

      // Step 5: Find the assistant's response
      const assistantMessage = convResponse.data.messages[convResponse.data.messages.length - 1];

      if (assistantMessage && assistantMessage.role === 'assistant') {
        // Step 6: Stream the response with typing effect
        setIsStreaming(true);
        setStreamingText('');

        const fullText = assistantMessage.content;
        let currentIndex = 0;

        const typingInterval = setInterval(() => {
          if (currentIndex < fullText.length) {
            setStreamingText(fullText.substring(0, currentIndex + 1));
            currentIndex++;
          } else {
            clearInterval(typingInterval);
            setIsStreaming(false);
            setStreamingText('');
            setCurrentConversation(convResponse.data);
          }
        }, 20); // 20ms per character for smooth typing
      } else {
        setCurrentConversation(convResponse.data);
      }
    } catch (error) {
      console.error('Error sending message:', error);
      setLoading(false);
      alert('Error sending message. Please try logging in.');
    }
  };

  const handleNewChat = () => {
    setCurrentConversation(null);
  };

  const handleSelectConversation = async (id: number) => {
    try {
      const response = await chat.getConversation(id);
      setCurrentConversation(response.data);
    } catch (error) {
      console.error('Error loading conversation:', error);
    }
  };

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  const handleDeleteConversation = async (id: number) => {
    try {
      await chat.deleteConversation(id);
      setLongPressConvId(null);
      if (currentConversation?.id === id) {
        setCurrentConversation(null);
      }
      await loadConversations();
    } catch (error) {
      console.error('Error deleting conversation:', error);
      alert('Failed to delete conversation');
    }
  };

  const handleLongPressStart = (id: number) => {
    longPressTimerRef.current = setTimeout(() => {
      setLongPressConvId(id);
    }, 500); // 500ms long press
  };

  const handleLongPressEnd = () => {
    if (longPressTimerRef.current) {
      clearTimeout(longPressTimerRef.current);
      longPressTimerRef.current = null;
    }
  };

  const handleCopyMessage = async (content: string, messageId: number) => {
    try {
      await navigator.clipboard.writeText(content);
      setCopiedMessageId(messageId);
      setTimeout(() => setCopiedMessageId(null), 2000); // Reset after 2 seconds
    } catch (error) {
      console.error('Failed to copy:', error);
    }
  };

  const handleDownloadMessage = (content: string) => {
    const blob = new Blob([content], { type: 'text/markdown' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `chat-response-${new Date().toISOString().slice(0, 10)}.md`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const handleAvatarUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      // Validate file type
      if (!file.type.startsWith('image/')) {
        alert('Please upload an image file');
        return;
      }

      // Validate file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        alert('Image size should be less than 5MB');
        return;
      }

      // Create object URL and save to localStorage
      const url = URL.createObjectURL(file);
      setAvatarUrl(url);

      // Convert to base64 and store in localStorage
      const reader = new FileReader();
      reader.onloadend = () => {
        const base64String = reader.result as string;
        localStorage.setItem('userAvatar', base64String);
      };
      reader.readAsDataURL(file);
    }
  };

  // Load avatar from localStorage on mount
  useEffect(() => {
    const savedAvatar = localStorage.getItem('userAvatar');
    if (savedAvatar) {
      setAvatarUrl(savedAvatar);
    }
  }, []);

  const hasMessages = currentConversation && currentConversation.messages && currentConversation.messages.length > 0;

  return (
    <div className={`flex h-screen ${darkMode ? 'bg-[#171717]' : 'bg-white'}`}>
      {/* Sidebar */}
      <div className={`${sidebarOpen ? 'w-64' : 'w-0'} ${darkMode ? 'bg-[#171717] border-r border-[#2a2a2a]' : 'bg-gray-50 border-r border-gray-200'} transition-all duration-300 overflow-hidden flex flex-col h-screen`}>
        <div className="p-4 flex flex-col h-full">
          <div className="mb-6 text-center">
            <h1 className={`text-lg font-semibold ${darkMode ? 'text-white' : 'text-gray-900'}`}>EnterpriseChatGPT</h1>
          </div>

          <button
            onClick={handleNewChat}
            className={`w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-[24px] mb-4 ${darkMode
              ? 'bg-blue-600/20 hover:bg-blue-600/30 text-blue-400 border border-blue-600/30'
              : 'bg-blue-600/20 hover:bg-blue-600/30 text-blue-600 border border-blue-600/30'
              }`}
          >
            <Plus size={18} />
            <span>New Chat</span>
          </button>

          <div className="flex-1 overflow-y-auto space-y-1 mb-4">
            {conversations.map((conv) => (
              <div key={conv.id} className="relative group">
                <button
                  onClick={() => handleSelectConversation(conv.id)}
                  onMouseDown={() => handleLongPressStart(conv.id)}
                  onMouseUp={handleLongPressEnd}
                  onMouseLeave={handleLongPressEnd}
                  onTouchStart={() => handleLongPressStart(conv.id)}
                  onTouchEnd={handleLongPressEnd}
                  className={`w-full text-left px-3 py-2 rounded-lg text-sm truncate transition-colors ${currentConversation?.id === conv.id
                    ? darkMode ? 'bg-[#232323] text-white' : 'bg-gray-200 text-gray-900'
                    : darkMode ? 'text-gray-400 hover:bg-[#232323] hover:text-white' : 'text-gray-600 hover:bg-gray-200 hover:text-gray-900'
                    }`}
                >
                  {conv.title}
                </button>
                {longPressConvId === conv.id && (
                  <div className="absolute inset-0 flex items-center justify-center gap-2 bg-black/50 rounded-lg backdrop-blur-sm z-10 px-2">
                    <button
                      onClick={() => handleDeleteConversation(conv.id)}
                      className="px-3 py-1.5 bg-red-600 hover:bg-red-700 text-white rounded-md text-xs font-medium transition-colors"
                    >
                      Delete
                    </button>
                    <button
                      onClick={() => setLongPressConvId(null)}
                      className={`px-3 py-1.5 rounded-md text-xs font-medium transition-colors ${
                        darkMode ? 'bg-[#232323] hover:bg-[#2a2a2a] text-white' : 'bg-gray-200 hover:bg-gray-300 text-gray-900'
                      }`}
                    >
                      Cancel
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>

          <div className={`mt-auto border-t pt-4 space-y-1 flex-shrink-0 ${darkMode ? 'border-[#2a2a2a]' : 'border-gray-200'}`}>
            {user ? (
              <>
                <button
                  onClick={() => router.push('/documents')}
                  className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm ${darkMode ? 'text-gray-400 hover:bg-[#232323] hover:text-white' : 'text-gray-600 hover:bg-gray-200 hover:text-gray-900'
                    }`}
                >
                  <Upload size={18} />
                  <span>Upload Documents</span>
                </button>
                <button
                  onClick={() => router.push('/analytics')}
                  className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm ${darkMode ? 'text-gray-400 hover:bg-[#232323] hover:text-white' : 'text-gray-600 hover:bg-gray-200 hover:text-gray-900'
                    }`}
                >
                  <BarChart3 size={18} />
                  <span>Analytics</span>
                </button>
                {/* User Profile Section */}
                <div className={`border-t mt-2 pt-3 ${darkMode ? 'border-[#2a2a2a]' : 'border-gray-200'}`}>
                  <div className="flex items-center gap-3 px-3 py-2">
                    {/* Avatar with initial or uploaded image */}
                    <div className="flex-shrink-0">
                      {avatarUrl ? (
                        <img
                          src={avatarUrl}
                          alt="User avatar"
                          className="w-10 h-10 rounded-full object-cover"
                        />
                      ) : (
                        <div className="w-10 h-10 rounded-full bg-blue-600/20 flex items-center justify-center">
                          <span className="text-white font-semibold text-sm">
                            {(user.full_name || user.username || 'U').charAt(0).toUpperCase()}
                          </span>
                        </div>
                      )}
                    </div>

                    {/* Name */}
                    <div className="flex-1 min-w-0">
                      <p className={`text-sm font-medium truncate ${darkMode ? 'text-white' : 'text-gray-900'}`}>
                        {user.full_name || user.username}
                      </p>
                      <p className={`text-xs truncate ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                        {user.email}
                      </p>
                    </div>

                    {/* 3-dot menu */}
                    <button
                      onClick={() => setShowSettingsModal(true)}
                      className={`p-1.5 rounded-lg transition-colors ${darkMode ? 'hover:bg-[#232323] text-gray-400' : 'hover:bg-gray-200 text-gray-600'
                        }`}
                      title="Settings"
                    >
                      <MoreVertical size={18} />
                    </button>
                  </div>

                  {/* Logout button */}
                  <button
                    onClick={handleLogout}
                    className={`w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm mt-1 ${darkMode ? 'text-red-400 hover:bg-[#232323]' : 'text-red-600 hover:bg-red-50'
                      }`}
                  >
                    <LogOut size={18} />
                    <span>Logout</span>
                  </button>
                </div>
              </>
            ) : (
              <button
                onClick={() => router.push('/login')}
                className="w-full flex items-center justify-center gap-2 px-3 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm"
              >
                Login / Sign Up
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Main Chat Area */}
      <div className="flex-1 flex flex-col relative overflow-hidden">
        {/* Messages Area - Full height with padding for header/input */}
        <div ref={messagesContainerRef} className={`absolute inset-0 overflow-y-auto ${darkMode ? 'bg-[#171717]' : 'bg-white'}`} style={{ paddingTop: '73px', paddingBottom: '100px' }}>
          {!hasMessages ? (
            // Centered welcome screen
            <div className="h-full flex flex-col items-center justify-center px-4">
              <div className="text-center mb-8">
                <div className={`text-4xl font-bold mb-4 ${darkMode ? 'text-white' : 'text-gray-900'}`}>
                  How can I help you?
                </div>
                <p className={`text-lg ${darkMode ? 'text-gray-400' : 'text-gray-600'}`}>
                  Ask me anything about your documents
                </p>
              </div>
            </div>
          ) : (
            // Messages list
            <div className="max-w-4xl mx-auto px-4 py-6 space-y-6">
              {currentConversation.messages.map((msg) => (
                <div key={msg.id} className="space-y-2">
                  {msg.role === 'user' ? (
                    <div className="flex justify-end">
                      <div className={`max-w-[80%] rounded-2xl px-4 py-3 ${darkMode ? 'bg-blue-600/20 text-blue-100' : 'bg-blue-600/20 text-blue-900'
                        }`}>
                        <p className="text-sm leading-relaxed">{msg.content}</p>
                      </div>
                    </div>
                  ) : (
                    <div className="flex justify-start">
                      <div className={`max-w-[80%] rounded-2xl px-4 py-3 ${darkMode ? 'bg-[#232323] text-gray-100' : 'bg-gray-100 text-gray-900'
                        }`}>
                        <ReactMarkdown className={`prose prose-sm max-w-none ${darkMode ? 'prose-invert' : ''
                          }`}>
                          {msg.content}
                        </ReactMarkdown>

                        {msg.sources && msg.sources.length > 0 && (
                          <div className={`mt-3 pt-3 border-t ${darkMode ? 'border-[#333333]' : 'border-gray-200'}`}>
                            <p className="text-xs font-semibold mb-2">Sources:</p>
                            {msg.sources.map((source, idx) => (
                              <div key={idx} className={`text-xs mb-1 ${darkMode ? 'text-gray-400' : 'text-gray-600'}`}>
                                {source.content}
                              </div>
                            ))}
                          </div>
                        )}

                        {/* Copy and Download buttons */}
                        <div className={`flex items-center gap-2 mt-3 pt-3 border-t ${darkMode ? 'border-[#333333]' : 'border-gray-200'}`}>
                          <button
                            onClick={() => handleCopyMessage(msg.content, msg.id)}
                            className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs transition-colors ${darkMode
                              ? 'hover:bg-[#2a2a2a] text-gray-400 hover:text-gray-300'
                              : 'hover:bg-gray-200 text-gray-600 hover:text-gray-700'
                              }`}
                            title="Copy to clipboard"
                          >
                            {copiedMessageId === msg.id ? (
                              <>
                                <Check size={14} className="text-green-500" />
                                <span className="text-green-500">Copied!</span>
                              </>
                            ) : (
                              <>
                                <Copy size={14} />
                                <span>Copy</span>
                              </>
                            )}
                          </button>
                          <button
                            onClick={() => handleDownloadMessage(msg.content)}
                            className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs transition-colors ${darkMode
                              ? 'hover:bg-[#2a2a2a] text-gray-400 hover:text-gray-300'
                              : 'hover:bg-gray-200 text-gray-600 hover:text-gray-700'
                              }`}
                            title="Download as markdown"
                          >
                            <Download size={14} />
                            <span>Download</span>
                          </button>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              ))}

              {loading && (
                <div className="flex justify-start">
                  <div className={`rounded-2xl px-4 py-3 ${darkMode ? 'bg-[#232323]' : 'bg-gray-100'
                    }`}>
                    <div className="flex items-center gap-1">
                      <div className="flex gap-1">
                        <span className="animate-bounce inline-block w-2 h-2 bg-blue-600 rounded-full" style={{ animationDelay: '0ms' }}></span>
                        <span className="animate-bounce inline-block w-2 h-2 bg-blue-600 rounded-full" style={{ animationDelay: '150ms' }}></span>
                        <span className="animate-bounce inline-block w-2 h-2 bg-blue-600 rounded-full" style={{ animationDelay: '300ms' }}></span>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {isStreaming && streamingText && (
                <div className="flex justify-start">
                  <div className={`max-w-[80%] rounded-2xl px-4 py-3 ${darkMode ? 'bg-[#232323] text-gray-100' : 'bg-gray-100 text-gray-900'
                    }`}>
                    <ReactMarkdown className={`prose prose-sm max-w-none ${darkMode ? 'prose-invert' : ''
                      }`}>
                      {streamingText}
                    </ReactMarkdown>
                    <span className="inline-block w-1 h-4 bg-blue-600 animate-pulse ml-1"></span>
                  </div>
                </div>
              )}

              {/* Scroll anchor */}
              <div ref={messagesEndRef} />
            </div>
          )}
        </div>

        {/* Header - Glassmorphic - Absolute at top */}
        <div className={`absolute top-0 left-0 right-0 z-10 px-6 py-4 flex items-center justify-between backdrop-blur-xl ${darkMode
          ? 'bg-[#171717]/30 border-b border-[#2a2a2a]/30'
          : 'bg-white/30 border-b border-gray-200/30'
          }`}
          style={{ backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)' }}
        >
          <div className="flex items-center gap-3">
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className={`p-2 rounded-lg ${darkMode ? 'hover:bg-[#232323]/50' : 'hover:bg-gray-100/50'}`}
            >
              <Menu size={20} className={darkMode ? 'text-gray-400' : 'text-gray-600'} />
            </button>
            <h2 className={`text-lg font-medium ${darkMode ? 'text-white' : 'text-gray-900'}`}>
              {currentConversation?.title || 'New Conversation'}
            </h2>
          </div>

          {/* Mode Selector */}
          <div className="flex items-center gap-2">
            <span className={`text-xs ${darkMode ? 'text-gray-400' : 'text-gray-600'}`}>Mode:</span>
            <button
              onClick={() => setRagMode('fast')}
              className={`px-3 py-1.5 text-xs rounded-lg transition-all ${ragMode === 'fast'
                ? darkMode
                  ? 'bg-blue-600/20 text-blue-400 border border-blue-600/30'
                  : 'bg-blue-600/20 text-blue-600 border border-blue-600/30'
                : darkMode
                  ? 'bg-[#232323]/50 text-gray-400 hover:bg-[#2a2a2a]/50 border border-transparent'
                  : 'bg-gray-200/50 text-gray-600 hover:bg-gray-300/50 border border-transparent'
                }`}
            >
              Fast (5-15s)
            </button>
            <button
              onClick={() => setRagMode('accurate')}
              className={`px-3 py-1.5 text-xs rounded-lg transition-all ${ragMode === 'accurate'
                ? darkMode
                  ? 'bg-blue-600/20 text-blue-400 border border-blue-600/30'
                  : 'bg-blue-600/20 text-blue-600 border border-blue-600/30'
                : darkMode
                  ? 'bg-[#232323]/50 text-gray-400 hover:bg-[#2a2a2a]/50 border border-transparent'
                  : 'bg-gray-200/50 text-gray-600 hover:bg-gray-300/50 border border-transparent'
                }`}
            >
              Accurate (60-90s)
            </button>
          </div>
        </div>

        {/* Input Area - Glassmorphic - Absolute at bottom */}
        <div className={`absolute bottom-0 left-0 right-0 z-10 backdrop-blur-xl ${darkMode ? 'bg-[#171717]/30 border-t border-[#2a2a2a]/30' : 'bg-white/30 border-t border-gray-200/30'
          }`}
          style={{ backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)' }}
        >
          <div className="max-w-3xl mx-auto px-4 py-4">
            <form onSubmit={handleSendMessage}>
              <div className={`flex items-center gap-2 rounded-2xl border backdrop-blur-lg ${darkMode
                ? 'bg-[#232323]/50 border-[#333333]/50 shadow-lg'
                : 'bg-white/50 border-gray-300/50 shadow-lg'
                }`}
                style={{ backdropFilter: 'blur(8px)' }}
              >
                <input
                  type="text"
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  placeholder="Ask EnterpriseChatGPT..."
                  className={`flex-1 px-5 py-3.5 bg-transparent rounded-2xl focus:outline-none text-sm ${darkMode ? 'text-white placeholder-gray-500' : 'text-gray-900 placeholder-gray-400'
                    }`}
                  disabled={loading}
                />
                <button
                  type="submit"
                  disabled={loading || !message.trim()}
                  className={`mr-2 p-2.5 rounded-xl transition-colors ${message.trim() && !loading
                    ? darkMode
                      ? 'bg-blue-600/20 hover:bg-blue-600/30 text-blue-400'
                      : 'bg-blue-600/20 hover:bg-blue-600/30 text-blue-600'
                    : darkMode ? 'bg-[#2a2a2a]/50 text-gray-500' : 'bg-gray-200/50 text-gray-400'
                    } disabled:cursor-not-allowed`}
                >
                  <Send size={18} />
                </button>
              </div>
            </form>
            {!hasMessages && (
              <p className={`text-center text-xs mt-3 ${darkMode ? 'text-gray-500' : 'text-gray-500'}`}>
                EnterpriseChatGPT can make mistakes. Check important info.
              </p>
            )}
          </div>
        </div>
      </div>

      {/* Settings Modal */}
      {showSettingsModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm" onClick={() => setShowSettingsModal(false)}>
          <div className={`w-full max-w-2xl mx-4 rounded-2xl shadow-2xl ${darkMode ? 'bg-[#171717]' : 'bg-white'}`} onClick={(e) => e.stopPropagation()}>
            {/* Modal Header */}
            <div className={`flex items-center justify-between px-6 py-4 border-b ${darkMode ? 'border-[#2a2a2a]' : 'border-gray-200'}`}>
              <h2 className={`text-xl font-semibold ${darkMode ? 'text-white' : 'text-gray-900'}`}>Settings</h2>
              <button
                onClick={() => setShowSettingsModal(false)}
                className={`p-2 rounded-lg transition-colors ${darkMode ? 'hover:bg-[#232323] text-gray-400' : 'hover:bg-gray-200 text-gray-600'}`}
              >
                <X size={20} />
              </button>
            </div>

            {/* Modal Content */}
            <div className="flex h-[500px]">
              {/* Sidebar */}
              <div className={`w-48 border-r ${darkMode ? 'border-[#2a2a2a] bg-[#171717]' : 'border-gray-200 bg-gray-50'}`}>
                <button
                  onClick={() => setSettingsTab('general')}
                  className={`w-full flex items-center gap-3 px-4 py-3 text-sm transition-colors ${settingsTab === 'general'
                    ? darkMode ? 'bg-[#232323] text-white' : 'bg-gray-200 text-gray-900'
                    : darkMode ? 'text-gray-400 hover:bg-[#232323] hover:text-white' : 'text-gray-600 hover:bg-gray-200'
                    }`}
                >
                  <Settings size={18} />
                  <span>General</span>
                </button>
                <button
                  onClick={() => setSettingsTab('profile')}
                  className={`w-full flex items-center gap-3 px-4 py-3 text-sm transition-colors ${settingsTab === 'profile'
                    ? darkMode ? 'bg-[#232323] text-white' : 'bg-gray-200 text-gray-900'
                    : darkMode ? 'text-gray-400 hover:bg-[#232323] hover:text-white' : 'text-gray-600 hover:bg-gray-200'
                    }`}
                >
                  <User size={18} />
                  <span>Profile</span>
                </button>
                <button
                  onClick={() => setSettingsTab('about')}
                  className={`w-full flex items-center gap-3 px-4 py-3 text-sm transition-colors ${settingsTab === 'about'
                    ? darkMode ? 'bg-[#232323] text-white' : 'bg-gray-200 text-gray-900'
                    : darkMode ? 'text-gray-400 hover:bg-[#232323] hover:text-white' : 'text-gray-600 hover:bg-gray-200'
                    }`}
                >
                  <Info size={18} />
                  <span>About</span>
                </button>
              </div>

              {/* Content Area */}
              <div className="flex-1 p-6 overflow-y-auto">
                {settingsTab === 'general' && (
                  <div>
                    <h3 className={`text-lg font-semibold mb-4 ${darkMode ? 'text-white' : 'text-gray-900'}`}>General Settings</h3>

                    {/* Theme Selection */}
                    <div className="mb-6">
                      <label className={`block text-sm font-medium mb-3 ${darkMode ? 'text-gray-300' : 'text-gray-700'}`}>
                        Theme
                      </label>
                      <div className="grid grid-cols-2 gap-3">
                        <button
                          onClick={() => setDarkMode(false)}
                          className={`flex items-center justify-center gap-2 px-4 py-3 rounded-lg border-2 transition-all ${!darkMode
                            ? 'border-blue-600 bg-blue-600/10'
                            : darkMode ? 'border-[#333333] hover:border-gray-600' : 'border-gray-300 hover:border-gray-400'
                            }`}
                        >
                          <Sun size={18} className={!darkMode ? 'text-blue-600' : darkMode ? 'text-gray-400' : 'text-gray-600'} />
                          <span className={!darkMode ? 'text-blue-600 font-medium' : darkMode ? 'text-gray-400' : 'text-gray-600'}>Light</span>
                        </button>
                        <button
                          onClick={() => setDarkMode(true)}
                          className={`flex items-center justify-center gap-2 px-4 py-3 rounded-lg border-2 transition-all ${darkMode
                            ? 'border-blue-600 bg-blue-600/10'
                            : 'border-gray-300 hover:border-gray-400'
                            }`}
                        >
                          <Moon size={18} className={darkMode ? 'text-blue-600' : 'text-gray-600'} />
                          <span className={darkMode ? 'text-blue-600 font-medium' : 'text-gray-600'}>Dark</span>
                        </button>
                      </div>
                    </div>
                  </div>
                )}

                {settingsTab === 'profile' && (
                  <div>
                    <h3 className={`text-lg font-semibold mb-4 ${darkMode ? 'text-white' : 'text-gray-900'}`}>Profile Settings</h3>

                    {/* Avatar Upload */}
                    <div className="mb-6">
                      <label className={`block text-sm font-medium mb-3 ${darkMode ? 'text-gray-300' : 'text-gray-700'}`}>
                        Avatar
                      </label>
                      <div className="flex items-center gap-4">
                        {avatarUrl ? (
                          <img
                            src={avatarUrl}
                            alt="User avatar"
                            className="w-20 h-20 rounded-full object-cover"
                          />
                        ) : (
                          <div className="w-20 h-20 rounded-full bg-blue-600/20 flex items-center justify-center">
                            <span className="text-white font-semibold text-2xl">
                              {(user?.full_name || user?.username || 'U').charAt(0).toUpperCase()}
                            </span>
                          </div>
                        )}
                        <div className="flex flex-col gap-2">
                          <input
                            ref={fileInputRef}
                            type="file"
                            accept="image/*"
                            onChange={handleAvatarUpload}
                            className="hidden"
                          />
                          <button
                            onClick={() => fileInputRef.current?.click()}
                            className={`px-4 py-2 rounded-lg text-sm ${darkMode ? 'bg-[#232323] hover:bg-[#2a2a2a] text-white' : 'bg-gray-200 hover:bg-gray-300 text-gray-900'}`}
                          >
                            Upload Image
                          </button>
                          {avatarUrl && (
                            <button
                              onClick={() => {
                                setAvatarUrl(null);
                                localStorage.removeItem('userAvatar');
                              }}
                              className={`px-4 py-2 rounded-lg text-sm ${darkMode ? 'bg-red-900/20 hover:bg-red-900/30 text-red-400' : 'bg-red-50 hover:bg-red-100 text-red-600'}`}
                            >
                              Remove
                            </button>
                          )}
                        </div>
                      </div>
                      <p className={`text-xs mt-2 ${darkMode ? 'text-gray-500' : 'text-gray-500'}`}>
                        Recommended: Square image, at least 200x200px
                      </p>
                    </div>

                    {/* Display Name */}
                    <div className="mb-6">
                      <label className={`block text-sm font-medium mb-2 ${darkMode ? 'text-gray-300' : 'text-gray-700'}`}>
                        Display Name
                      </label>
                      <input
                        type="text"
                        defaultValue={user?.full_name || user?.username}
                        className={`w-full px-4 py-2 rounded-lg border ${darkMode
                          ? 'bg-[#232323] border-[#333333] text-white placeholder-gray-500'
                          : 'bg-white border-gray-300 text-gray-900 placeholder-gray-400'
                          } focus:outline-none focus:ring-2 focus:ring-blue-600`}
                        placeholder="Enter your display name"
                      />
                    </div>

                    {/* Phone Number */}
                    <div className="mb-6">
                      <label className={`block text-sm font-medium mb-2 ${darkMode ? 'text-gray-300' : 'text-gray-700'}`}>
                        Phone Number
                      </label>
                      <input
                        type="tel"
                        className={`w-full px-4 py-2 rounded-lg border ${darkMode
                          ? 'bg-[#232323] border-[#333333] text-white placeholder-gray-500'
                          : 'bg-white border-gray-300 text-gray-900 placeholder-gray-400'
                          } focus:outline-none focus:ring-2 focus:ring-blue-600`}
                        placeholder="+1 (555) 000-0000"
                      />
                    </div>

                    <button className="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium">
                      Save Changes
                    </button>
                  </div>
                )}

                {settingsTab === 'about' && (
                  <div>
                    <h3 className={`text-lg font-semibold mb-4 ${darkMode ? 'text-white' : 'text-gray-900'}`}>About EnterpriseChatGPT</h3>

                    <div className={`space-y-4 ${darkMode ? 'text-gray-300' : 'text-gray-700'}`}>
                      <p className="leading-relaxed">
                        <strong className={darkMode ? 'text-white' : 'text-gray-900'}>EnterpriseChatGPT</strong> is an advanced AI-powered chat application built with enterprise-grade Retrieval-Augmented Generation (RAG 2.0) technology, powered entirely by local open-source models.
                      </p>

                      <p className="leading-relaxed">
                        Our platform enables organizations to leverage the power of large language models while maintaining complete control over their data, ensuring 100% privacy compliance, and eliminating ongoing API costs.
                      </p>

                      <div className="mt-6">
                        <h4 className={`font-semibold mb-2 ${darkMode ? 'text-white' : 'text-gray-900'}`}>Key Features:</h4>
                        <ul className="list-disc list-inside space-y-2 ml-2">
                          <li>100% Local AI Models - Powered by Llama 3.1 via Ollama</li>
                          <li>Zero External API Calls - Complete data sovereignty</li>
                          <li>Advanced RAG 2.0 Pipeline with multi-stage retrieval</li>
                          <li>Local Embeddings - sentence-transformers/all-MiniLM-L6-v2</li>
                          <li>Support for multiple document formats (PDF, DOCX, XLSX, TXT, etc.)</li>
                          <li>Real-time chat with source citations and document references</li>
                          <li>Fast Mode (5-15s) and Accurate Mode (60-90s) for optimal performance</li>
                          <li>Enterprise-ready with multi-tenancy and role-based access</li>
                          <li>GDPR, HIPAA, and SOC2 compliant architecture</li>
                        </ul>
                      </div>

                      <div className="mt-6">
                        <h4 className={`font-semibold mb-2 ${darkMode ? 'text-white' : 'text-gray-900'}`}>Technology Stack:</h4>
                        <ul className="list-disc list-inside space-y-2 ml-2">
                          <li><strong>LLM:</strong> Llama 3.1 8B (via Ollama)</li>
                          <li><strong>Embeddings:</strong> sentence-transformers/all-MiniLM-L6-v2</li>
                          <li><strong>Vector Store:</strong> ChromaDB</li>
                          <li><strong>Backend:</strong> FastAPI + Python</li>
                          <li><strong>Frontend:</strong> Next.js 14 + React + TypeScript</li>
                          <li><strong>Database:</strong> PostgreSQL</li>
                        </ul>
                      </div>

                      <div className={`mt-6 pt-6 border-t ${darkMode ? 'border-[#2a2a2a]' : 'border-gray-200'}`}>
                        <p className="text-sm">
                          <strong>Version:</strong> 2.0.0<br />
                          <strong>LLM Model:</strong> Llama 3.1 8B (Local via Ollama)<br />
                          <strong>Embedding Model:</strong> all-MiniLM-L6-v2 (Local)<br />
                          <strong>Deployment:</strong> 100% On-Premise<br />
                          <strong>License:</strong> Enterprise
                        </p>
                      </div>

                      <div className={`mt-6 p-4 rounded-lg ${darkMode ? 'bg-blue-600/10 border border-blue-600/20' : 'bg-blue-50 border border-blue-200'}`}>
                        <p className="text-sm leading-relaxed">
                          <strong className={darkMode ? 'text-blue-400' : 'text-blue-700'}>Privacy First:</strong> All AI processing happens locally on your infrastructure. No data is ever sent to external APIs like OpenAI, Anthropic, or any third-party services. Your documents and conversations remain completely private and secure.
                        </p>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
