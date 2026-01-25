'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useStore } from '@/lib/store';
import { documents } from '@/lib/api';
import { Upload, FileText, Trash2, ArrowLeft, CheckCircle, XCircle, Clock } from 'lucide-react';
import { useDropzone } from 'react-dropzone';

interface Document {
  id: number;
  filename: string;
  file_type: string;
  file_size: number;
  status: string;
  chunk_count: number;
  created_at: string;
}

export default function Documents() {
  const router = useRouter();
  const { token } = useStore();
  const [docs, setDocs] = useState<Document[]>([]);
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    const storedToken = localStorage.getItem('token');
    if (!storedToken) {
      // Show message that login is required for documents
      return;
    }
    loadDocuments();
  }, []);

  const loadDocuments = async () => {
    setLoading(true);
    try {
      const response = await documents.getAll();
      setDocs(response.data);
    } catch (error) {
      console.error('Error loading documents:', error);
    } finally {
      setLoading(false);
    }
  };

  const onDrop = async (acceptedFiles: File[]) => {
    for (const file of acceptedFiles) {
      setUploading(true);
      try {
        await documents.upload(file);
        await loadDocuments();
      } catch (error: any) {
        alert(error.response?.data?.detail || 'Error uploading file');
      } finally {
        setUploading(false);
      }
    }
  };

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'application/pdf': ['.pdf'],
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx'],
      'application/vnd.openxmlformats-officedocument.presentationml.presentation': ['.pptx'],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['.xlsx'],
      'text/html': ['.html'],
      'text/plain': ['.txt'],
    },
  });

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this document?')) return;
    
    try {
      await documents.delete(id);
      await loadDocuments();
    } catch (error) {
      console.error('Error deleting document:', error);
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="text-green-500" size={20} />;
      case 'failed':
        return <XCircle className="text-red-500" size={20} />;
      default:
        return <Clock className="text-yellow-500" size={20} />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
        <div className="mb-4 sm:mb-6 flex items-center justify-between">
          <div className="flex items-center gap-2 sm:gap-4">
            <button
              onClick={() => router.push('/chat')}
              className="p-2 hover:bg-gray-200 rounded-lg text-gray-700"
            >
              <ArrowLeft size={20} className="sm:w-6 sm:h-6" />
            </button>
            <h1 className="text-xl sm:text-2xl lg:text-3xl font-bold text-gray-900">Documents</h1>
          </div>
        </div>

        {/* Login Required Message */}
        {!localStorage.getItem('token') && (
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 sm:p-6 mb-6 sm:mb-8">
            <h2 className="text-lg sm:text-xl font-semibold mb-2">Login Required</h2>
            <p className="text-sm sm:text-base text-gray-700 mb-4">
              You need to login to upload and manage documents.
            </p>
            <button
              onClick={() => router.push('/login')}
              className="w-full sm:w-auto px-6 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700"
            >
              Login / Sign Up
            </button>
          </div>
        )}

        {/* Upload Area */}
        {localStorage.getItem('token') && (
          <div
            {...getRootProps()}
            className={`border-2 border-dashed rounded-lg p-6 sm:p-8 lg:p-12 text-center mb-6 sm:mb-8 cursor-pointer transition-colors ${
              isDragActive ? 'border-primary-500 bg-primary-50' : 'border-gray-300 hover:border-primary-400'
            }`}
          >
            <input {...getInputProps()} />
            <Upload className="mx-auto mb-3 sm:mb-4 text-gray-400" size={36} />
            <p className="text-base sm:text-lg mb-2 text-gray-700">
              {isDragActive ? 'Drop files here' : 'Drag & drop files here, or click to select'}
            </p>
            <p className="text-xs sm:text-sm text-gray-600">
              Supported: PDF, DOCX, PPTX, XLSX, HTML, TXT (Max 50MB)
            </p>
            {uploading && (
              <div className="mt-4">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600 mx-auto"></div>
                <p className="mt-2 text-sm text-gray-600">Uploading and processing...</p>
              </div>
            )}
          </div>
        )}

        {/* Documents List */}
        {localStorage.getItem('token') && (
          <div className="bg-white rounded-lg shadow overflow-hidden">
          <div className="px-4 sm:px-6 py-3 sm:py-4 border-b">
            <h2 className="text-lg sm:text-xl font-semibold">Your Documents</h2>
          </div>
          
          {loading ? (
            <div className="p-8 sm:p-12 text-center">
              <div className="animate-spin rounded-full h-10 w-10 sm:h-12 sm:w-12 border-b-2 border-primary-600 mx-auto"></div>
            </div>
          ) : docs.length === 0 ? (
            <div className="p-8 sm:p-12 text-center text-gray-500">
              <FileText className="mx-auto mb-4 text-gray-300" size={40} />
              <p className="text-sm sm:text-base">No documents uploaded yet</p>
            </div>
          ) : (
            <div className="divide-y">
              {docs.map((doc) => (
                <div key={doc.id} className="px-4 sm:px-6 py-3 sm:py-4 flex flex-col sm:flex-row sm:items-center sm:justify-between hover:bg-gray-50 gap-3 sm:gap-4">
                  <div className="flex items-start sm:items-center gap-3 sm:gap-4 flex-1 min-w-0">
                    <FileText className="text-gray-400 flex-shrink-0 mt-1 sm:mt-0" size={20} />
                    <div className="flex-1 min-w-0">
                      <h3 className="font-medium text-gray-900 text-sm sm:text-base truncate">{doc.filename}</h3>
                      <p className="text-xs sm:text-sm text-gray-500 mt-1">
                        {formatFileSize(doc.file_size)} • {doc.chunk_count} chunks
                      </p>
                      <p className="text-xs text-gray-400 mt-0.5 sm:hidden">
                        {new Date(doc.created_at).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center justify-between sm:justify-end gap-3 sm:gap-4 ml-8 sm:ml-0">
                    <div className="flex items-center gap-2">
                      {getStatusIcon(doc.status)}
                      <span className="text-xs sm:text-sm capitalize text-gray-700">{doc.status}</span>
                    </div>
                    <button
                      onClick={() => handleDelete(doc.id)}
                      className="p-2 text-red-600 hover:bg-red-50 rounded-lg flex-shrink-0"
                      aria-label="Delete document"
                    >
                      <Trash2 size={18} />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
          </div>
        )}
      </div>
    </div>
  );
}
