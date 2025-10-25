'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function Home() {
  const router = useRouter();

  useEffect(() => {
    // Always redirect to chat - no login required
    router.push('/chat');
  }, [router]);

  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-center">
        <h1 className="text-4xl font-bold mb-4">Enterprise RAG 2.0</h1>
        <p className="text-gray-600">Loading...</p>
      </div>
    </div>
  );
}
