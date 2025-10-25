# Dark Mode Color Update

Replace these Tailwind classes throughout the app:

## Old → New Dark Mode Colors

### Backgrounds
- `bg-gray-900` → `bg-[#171717]` (main background)
- `bg-gray-950` → `bg-[#0d0d0d]` (sidebar, darker areas)
- `bg-gray-800` → `bg-[#232323]` (cards, hover states)
- `bg-gray-700` → `bg-[#2a2a2a]` (active states)

### Borders
- `border-gray-800` → `border-[#2a2a2a]`
- `border-gray-700` → `border-[#333333]`

### Text
- Keep `text-white`, `text-gray-100`, `text-gray-300`, `text-gray-400` as is

### Specific Updates Needed:
1. Main chat area background
2. Sidebar background
3. Message bubbles
4. Input containers
5. Modal backgrounds
6. Hover states
7. Border colors

This creates a true dark theme like DeepSeek instead of the bluish-gray theme.
