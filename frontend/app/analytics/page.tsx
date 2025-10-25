'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useStore } from '@/lib/store';
import { analytics } from '@/lib/api';
import { ArrowLeft, MessageSquare, FileText, Clock, DollarSign } from 'lucide-react';

interface AnalyticsData {
  total_queries: number;
  total_documents: number;
  avg_response_time: number;
  total_tokens_used: number;
  total_cost: number;
}

export default function Analytics() {
  const router = useRouter();
  const { token } = useStore();
  const [data, setData] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const storedToken = localStorage.getItem('token');
    if (!storedToken) {
      // Show message that login is required for analytics
      return;
    }
    loadAnalytics();
  }, []);

  const loadAnalytics = async () => {
    setLoading(true);
    try {
      const response = await analytics.getOverview();
      setData(response.data);
    } catch (error) {
      console.error('Error loading analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="mb-6 flex items-center gap-4">
          <button
            onClick={() => router.push('/chat')}
            className="p-2 hover:bg-gray-200 rounded-lg text-gray-700"
          >
            <ArrowLeft size={24} />
          </button>
          <h1 className="text-3xl font-bold text-gray-900">Analytics</h1>
        </div>

        {!localStorage.getItem('token') ? (
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6">
            <h2 className="text-xl font-semibold mb-2">Login Required</h2>
            <p className="text-gray-700 mb-4">
              You need to login to view analytics.
            </p>
            <button
              onClick={() => router.push('/login')}
              className="px-6 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700"
            >
              Login / Sign Up
            </button>
          </div>
        ) : loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
          </div>
        ) : data ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-gray-500 text-sm font-medium">Total Queries</h3>
                <MessageSquare className="text-primary-600" size={24} />
              </div>
              <p className="text-3xl font-bold text-gray-900">{data.total_queries}</p>
            </div>

            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-gray-500 text-sm font-medium">Documents</h3>
                <FileText className="text-green-600" size={24} />
              </div>
              <p className="text-3xl font-bold text-gray-900">{data.total_documents}</p>
            </div>

            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-gray-500 text-sm font-medium">Avg Response Time</h3>
                <Clock className="text-yellow-600" size={24} />
              </div>
              <p className="text-3xl font-bold text-gray-900">{data.avg_response_time.toFixed(2)}s</p>
            </div>

            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-gray-500 text-sm font-medium">Total Cost</h3>
                <DollarSign className="text-purple-600" size={24} />
              </div>
              <p className="text-3xl font-bold text-gray-900">${data.total_cost.toFixed(2)}</p>
            </div>
          </div>
        ) : (
          <div className="text-center text-gray-500">No data available</div>
        )}

        <div className="mt-8 bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4 text-gray-900">Usage Statistics</h2>
          <p className="text-gray-600">Detailed usage charts coming soon...</p>
        </div>
      </div>
    </div>
  );
}
