# Suggested Actions Feature - Demo Guide

## Overview
The Suggested Actions feature transforms your chatbot from an information tool into an action-oriented assistant that guides citizens through government services.

## What It Does

After the AI responds to a user's question, **contextual action buttons** appear below the response, allowing users to:
- Start a service application immediately
- Ask follow-up questions with one click
- Navigate to relevant Irembo pages
- Get more detailed information

## Visual Example

```
User: "What is the price for land registration?"

AI Response: "Land registration costs 5,000 RWF. This service allows 
citizens to register their land for the first time..."

[Action Bubbles Appear Below]
┌─────────────────────────┐  ┌──────────────────┐  ┌─────────────────┐
│ 🏠 Register Land Now    │  │ 📋 View Require  │  │ ⏱️ Processing   │
│     (Primary - Blue)    │  │     ments        │  │     Time        │
└─────────────────────────┘  └──────────────────┘  └─────────────────┘
```

## Supported Services

### 🏠 Land Services

#### 1. Land Registration
**Triggers:** "land registration", "register land", "register my land"
**Actions:**
- 🏠 **Register Land Now** (Primary) → Opens Irembo service page
- 📋 **View Requirements** → Asks "What are the requirements for land registration?"
- ⏱️ **Processing Time** → Asks "How long does land registration take?"

#### 2. Title Transfer
**Triggers:** "title transfer", "transfer title", "transfer land"
**Actions:**
- 📝 **Transfer Title** (Primary) → Opens Irembo service page
- 📋 **View Requirements** → Shows required documents
- 🔄 **Compare Transfer Types** → Explains different transfer types

#### 3. Land Subdivision
**Triggers:** "subdivision", "subdivide", "split land"
**Actions:**
- ✂️ **Subdivide Land** (Primary) → Opens Irembo service page
- 💰 **Calculate Cost** → Shows subdivision pricing

### ✈️ Immigration Services

#### 1. Visa Application
**Triggers:** "visa", "apply visa", "visa application"
**Actions:**
- ✈️ **Apply for Visa** (Primary) → Opens Irembo visa application
- 💳 **Visa Types & Prices** → Shows all visa types and costs
- 📋 **Requirements** → Lists required documents

#### 2. Passport Application
**Triggers:** "passport", "rwandan passport", "passport renewal"
**Actions:**
- 📘 **Apply for Passport** (Primary) → Opens passport application
- 🔄 **Renew Passport** → Opens renewal service
- 💰 **Check Prices** → Shows passport costs (5 year vs 10 year)

#### 3. Resident ID (Foreigner ID)
**Triggers:** "resident id", "foreigner id", "resident card"
**Actions:**
- 🆔 **Apply for Resident ID** (Primary) → Opens application
- 📋 **Requirements** → Shows what documents are needed

#### 4. Laissez-Passer
**Triggers:** "laissez-passer", "travel document"
**Actions:**
- 🎫 **Get Laissez-Passer** (Primary) → Opens application
- ℹ️ **Learn More** → Provides detailed information

## Smart Context Detection

The system also detects general intents:

### Price/Cost Queries
If the conversation mentions prices, fees, or costs:
- 💰 **View All Service Prices**
- 🔍 **Browse All Services**

### Requirements/Documents Queries
If discussing requirements or documents:
- ✅ **Document Checklist**
- 🔍 **Browse All Services**

## User Experience Flow

### Example 1: Land Registration Journey

```
Step 1: User asks about price
  → AI responds with price
  → Actions: [Register Land Now] [View Requirements] [Processing Time]

Step 2: User clicks "View Requirements"
  → AI shows requirements list
  → Actions: [Register Land Now] [I Have Documents] [Get Help]

Step 3: User clicks "Register Land Now"
  → Opens Irembo portal in new tab
  → User completes registration
```

### Example 2: Visa Application Journey

```
Step 1: User asks "How do I get a visa?"
  → AI explains visa process
  → Actions: [Apply for Visa] [Visa Types & Prices] [Requirements]

Step 2: User clicks "Visa Types & Prices"
  → AI shows all visa types ($50-$100)
  → Actions: [Apply for Visa] [Requirements] [Contact Support]

Step 3: User clicks "Apply for Visa"
  → Opens Irembo visa portal
```

## Technical Details

### Action Types

**Primary Actions (Blue)**
- Most important action
- Typically "Apply Now" or "Register Now"
- Opens external Irembo service page
- Visually prominent with blue background

**Secondary Actions (Gray/White)**
- Supporting actions
- Can trigger follow-up questions (chat action)
- Can open external links
- Less prominent styling

### Action Properties

Each action has:
- **id**: Unique identifier
- **label**: Button text (e.g., "Register Land Now")
- **icon**: Emoji icon (e.g., 🏠)
- **type**: "primary" or "secondary"
- **action**: "external" (opens URL) or "chat" (sends message)
- **url/message**: Destination URL or chat message

## Testing Instructions

### 1. Restart Backend
```bash
pkill -f uvicorn
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > ../backend.log 2>&1 &
cd ..
```

### 2. Open Chat Interface
Navigate to: http://localhost:3001/chat

### 3. Test Queries

**Land Services:**
- "What is the price for land registration?"
- "How do I transfer my land title?"
- "Tell me about land subdivision"
- "What are the requirements for land registration?"

**Immigration Services:**
- "How do I apply for a visa?"
- "What is the cost of a Rwandan passport?"
- "Tell me about Resident ID"
- "How do I get a Laissez-Passer?"

### 4. Observe Action Bubbles
- Look for action buttons below AI responses
- Primary action should be blue and prominent
- Secondary actions should be gray/white
- Click actions to test functionality

## Benefits for Citizens

✅ **Faster Service Access** - One click from information to action
✅ **Guided Experience** - No need to search for services
✅ **Reduced Confusion** - Clear next steps provided
✅ **Mobile-Friendly** - Large, tappable buttons
✅ **Contextual Help** - Actions match user's current need

## Benefits for Government

✅ **Higher Conversion Rates** - More citizens complete applications
✅ **Reduced Support Calls** - Self-service guidance
✅ **Better Analytics** - Track which actions users take
✅ **Improved UX** - Modern, intuitive interface
✅ **Scalable** - Easy to add new services

## Future Enhancements

### Phase 2 (Recommended)
- **Personalized Actions** - Show "Continue Your Application" if user has one in progress
- **Multi-Step Flows** - Guide through entire application process
- **Status Tracking** - "Check Application Status" action
- **Smart Suggestions** - AI-powered action recommendations

### Phase 3 (Advanced)
- **In-App Applications** - Complete applications without leaving chat
- **Document Upload** - Upload required documents directly
- **Payment Integration** - Pay fees within the chat
- **Appointment Booking** - Schedule in-person visits

## Customization

To add new services, edit: `backend/app/core/action_suggester.py`

Example:
```python
"new_service": [
    {
        "id": "apply_service",
        "label": "Apply Now",
        "icon": "🎯",
        "type": "primary",
        "action": "external",
        "url": "https://irembo.gov.rw/service"
    }
]
```

## Support

For questions or issues:
- Check backend logs: `tail -f backend.log`
- Check frontend console: Browser DevTools (F12)
- Test action detection: Look for "Detected service" in backend logs

---

**Ready to Demo!** 🚀

Show your client how citizens can go from asking a question to starting their application in just 2 clicks!
