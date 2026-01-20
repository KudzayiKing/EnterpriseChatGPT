"""
Suggested Actions Service
Detects user intent and suggests relevant actions based on the conversation
"""
from typing import List, Dict, Any
import re
import logging

logger = logging.getLogger(__name__)

class ActionSuggester:
    """Suggests contextual actions based on user queries and AI responses"""
    
    def __init__(self):
        # Service action mappings
        self.service_actions = {
            # Land Services
            "land_registration": [
                {
                    "id": "register_land",
                    "label": "Register Land Now",
                    "icon": "home",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "view_requirements",
                    "label": "View Requirements",
                    "icon": "file-text",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What are the requirements for land registration?"
                },
                {
                    "id": "check_processing_time",
                    "label": "Processing Time",
                    "icon": "clock",
                    "type": "secondary",
                    "action": "chat",
                    "message": "How long does land registration take?"
                }
            ],
            "title_transfer": [
                {
                    "id": "transfer_title",
                    "label": "Transfer Title",
                    "icon": "edit",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "view_transfer_requirements",
                    "label": "View Requirements",
                    "icon": "file-text",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What documents do I need for title transfer?"
                },
                {
                    "id": "compare_transfer_types",
                    "label": "Compare Transfer Types",
                    "icon": "refresh-cw",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What are the different types of title transfer?"
                }
            ],
            "land_subdivision": [
                {
                    "id": "subdivide_land",
                    "label": "Subdivide Land",
                    "icon": "edit",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "subdivision_cost",
                    "label": "Calculate Cost",
                    "icon": "dollar-sign",
                    "type": "secondary",
                    "action": "chat",
                    "message": "How much does land subdivision cost?"
                }
            ],
            
            # Immigration Services
            "visa_application": [
                {
                    "id": "apply_visa",
                    "label": "Apply for Visa",
                    "icon": "plane",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "visa_types",
                    "label": "Visa Types & Prices",
                    "icon": "credit-card",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What are the different visa types and their prices?"
                },
                {
                    "id": "visa_requirements",
                    "label": "Requirements",
                    "icon": "file-text",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What documents do I need for a visa application?"
                }
            ],
            "passport_application": [
                {
                    "id": "apply_passport",
                    "label": "Apply for Passport",
                    "icon": "file-text",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "passport_renewal",
                    "label": "Renew Passport",
                    "icon": "refresh-cw",
                    "type": "secondary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "passport_cost",
                    "label": "Check Prices",
                    "icon": "dollar-sign",
                    "type": "secondary",
                    "action": "chat",
                    "message": "How much does a Rwandan passport cost?"
                }
            ],
            "resident_id": [
                {
                    "id": "apply_resident_id",
                    "label": "Apply for Resident ID",
                    "icon": "user",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "resident_requirements",
                    "label": "Requirements",
                    "icon": "file-text",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What are the requirements for a Resident ID?"
                }
            ],
            "laissez_passer": [
                {
                    "id": "apply_laissez_passer",
                    "label": "Get Laissez-Passer",
                    "icon": "ticket",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "laissez_passer_info",
                    "label": "Learn More",
                    "icon": "info",
                    "type": "secondary",
                    "action": "chat",
                    "message": "Tell me more about Laissez-Passer"
                }
            ]
        }
        
        # Keywords for service detection
        self.service_keywords = {
            "land_registration": ["land registration", "register land", "register my land", "new land"],
            "title_transfer": ["title transfer", "transfer title", "transfer land", "sale", "donation"],
            "land_subdivision": ["subdivision", "subdivide", "split land", "divide land"],
            "visa_application": ["visa", "apply visa", "visa application", "enter rwanda"],
            "passport_application": ["passport", "rwandan passport", "passport renewal", "renew passport"],
            "resident_id": ["resident id", "foreigner id", "resident card"],
            "laissez_passer": ["laissez-passer", "laissez passer", "travel document"],
        }
        
        # General actions for when no specific service is detected
        self.general_actions = [
            {
                "id": "browse_services",
                "label": "Browse All Services",
                "icon": "search",
                "type": "secondary",
                "action": "external",
                "url": "https://irembo.gov.rw/home/citizen/all_services"
            },
            {
                "id": "contact_support",
                "label": "Contact Support",
                "icon": "message-circle",
                "type": "secondary",
                "action": "chat",
                "message": "How can I contact Irembo support?"
            }
        ]
    
    def suggest_actions(
        self,
        query: str,
        response: str,
        sources: List[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """
        Analyze query and response to suggest relevant actions
        
        Args:
            query: User's question
            response: AI's response
            sources: Retrieved document sources
            
        Returns:
            List of suggested actions
        """
        query_lower = query.lower()
        response_lower = response.lower()
        combined_text = f"{query_lower} {response_lower}"
        
        # Detect service from query and response
        detected_services = []
        
        for service, keywords in self.service_keywords.items():
            for keyword in keywords:
                if keyword in combined_text:
                    detected_services.append(service)
                    break
        
        # Return actions for the first detected service
        if detected_services:
            service = detected_services[0]
            actions = self.service_actions.get(service, [])
            logger.info(f"Detected service: {service}, suggesting {len(actions)} actions")
            return actions[:3]  # Limit to 3 actions
        
        # If discussing price/cost, add payment-related action
        if any(word in combined_text for word in ["price", "cost", "fee", "rwf", "$"]):
            return [
                {
                    "id": "view_all_prices",
                    "label": "View All Service Prices",
                    "icon": "dollar-sign",
                    "type": "secondary",
                    "action": "chat",
                    "message": "Show me prices for all services"
                },
                *self.general_actions[:1]
            ]
        
        # If discussing requirements/documents
        if any(word in combined_text for word in ["requirement", "document", "need", "necessary"]):
            return [
                {
                    "id": "prepare_documents",
                    "label": "Document Checklist",
                    "icon": "check-square",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What documents do I need to prepare?"
                },
                *self.general_actions[:1]
            ]
        
        # Default: show general actions
        return self.general_actions[:2]
