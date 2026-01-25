import { useState } from 'react';
import { useStore } from '@/lib/store';
import { languages, Language } from '@/lib/translations';
import { Globe } from 'lucide-react';

interface LanguagePickerProps {
  darkMode?: boolean;
}

export default function LanguagePicker({ darkMode = false }: LanguagePickerProps) {
  const { language, setLanguage } = useStore();
  const [isOpen, setIsOpen] = useState(false);

  const currentLanguage = languages.find(lang => lang.code === language) || languages[0];

  const handleLanguageChange = (newLang: Language) => {
    setLanguage(newLang);
    setIsOpen(false);
  };

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={`flex items-center gap-2 px-3 py-2 rounded-lg transition-colors ${
          darkMode
            ? 'hover:bg-[#2a2a2a] text-gray-300'
            : 'hover:bg-gray-100 text-gray-700'
        }`}
        title="Change language"
      >
        <Globe size={18} />
        <span className="text-xl">{currentLanguage.flag}</span>
        <span className="text-sm font-medium hidden sm:inline">{currentLanguage.code.toUpperCase()}</span>
      </button>

      {isOpen && (
        <>
          {/* Backdrop */}
          <div
            className="fixed inset-0 z-40"
            onClick={() => setIsOpen(false)}
          />
          
          {/* Dropdown */}
          <div
            className={`absolute right-0 bottom-full mb-2 w-48 rounded-lg shadow-lg border z-50 ${
              darkMode
                ? 'bg-[#232323] border-[#333333]'
                : 'bg-white border-gray-200'
            }`}
          >
            {languages.map((lang) => (
              <button
                key={lang.code}
                onClick={() => handleLanguageChange(lang.code)}
                className={`w-full flex items-center gap-3 px-4 py-3 text-left transition-colors ${
                  language === lang.code
                    ? darkMode
                      ? 'bg-blue-600/20 text-blue-400'
                      : 'bg-blue-50 text-blue-600'
                    : darkMode
                    ? 'hover:bg-[#2a2a2a] text-gray-300'
                    : 'hover:bg-gray-50 text-gray-700'
                } ${lang === languages[0] ? 'rounded-t-lg' : ''} ${
                  lang === languages[languages.length - 1] ? 'rounded-b-lg' : ''
                }`}
              >
                <span className="text-2xl">{lang.flag}</span>
                <div className="flex-1">
                  <div className="font-medium">{lang.name}</div>
                  <div className={`text-xs ${darkMode ? 'text-gray-500' : 'text-gray-400'}`}>
                    {lang.code.toUpperCase()}
                  </div>
                </div>
                {language === lang.code && (
                  <svg
                    className="w-5 h-5"
                    fill="currentColor"
                    viewBox="0 0 20 20"
                  >
                    <path
                      fillRule="evenodd"
                      d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                      clipRule="evenodd"
                    />
                  </svg>
                )}
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
