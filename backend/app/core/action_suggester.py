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
                    "label_rw": "Andikisha Ubutaka Ubu",
                    "icon": "home",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "view_requirements",
                    "label": "View Requirements",
                    "label_rw": "Reba Ibisabwa",
                    "icon": "file-text",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What are the requirements for land registration?",
                    "message_rw": "Ni izihe nyandiko nkeneye kugira ngo nandikishe ubutaka?"
                },
                {
                    "id": "check_processing_time",
                    "label": "Processing Time",
                    "label_rw": "Igihe Cyakora",
                    "icon": "clock",
                    "type": "secondary",
                    "action": "chat",
                    "message": "How long does land registration take?",
                    "message_rw": "Kwandikisha ubutaka bifata igihe kingana iki?"
                }
            ],
            "title_transfer": [
                {
                    "id": "transfer_title",
                    "label": "Transfer Title",
                    "label_rw": "Hindura Izina",
                    "icon": "edit",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "view_transfer_requirements",
                    "label": "View Requirements",
                    "label_rw": "Reba Ibisabwa",
                    "icon": "file-text",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What documents do I need for title transfer?",
                    "message_rw": "Ni izihe nyandiko nkeneye kugira ngo nime izina ku butaka?"
                },
                {
                    "id": "compare_transfer_types",
                    "label": "Compare Transfer Types",
                    "label_rw": "Gereranya Ubwoko bwo Kwimura",
                    "icon": "refresh-cw",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What are the different types of title transfer?",
                    "message_rw": "Ni ubuhe bwoko bwo kwimura izina ku butaka?"
                }
            ],
            "land_subdivision": [
                {
                    "id": "subdivide_land",
                    "label": "Subdivide Land",
                    "label_rw": "Gabanya Ubutaka",
                    "icon": "edit",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "subdivision_cost",
                    "label": "Calculate Cost",
                    "label_rw": "Reba Ikiguzi",
                    "icon": "dollar-sign",
                    "type": "secondary",
                    "action": "chat",
                    "message": "How much does land subdivision cost?",
                    "message_rw": "Ni amafaranga angahe yo kugabanya ubutaka?"
                }
            ],
            
            # Immigration Services
            "visa_application": [
                {
                    "id": "apply_visa",
                    "label": "Apply for Visa",
                    "label_rw": "Saba Viza",
                    "icon": "plane",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "visa_types",
                    "label": "Visa Types & Prices",
                    "label_rw": "Ubwoko bwa Viza n'Ibiciro",
                    "icon": "credit-card",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What are the different visa types and their prices?",
                    "message_rw": "Ni ubuhe bwoko bwa viza n'ibiciro byabyo?"
                },
                {
                    "id": "visa_requirements",
                    "label": "Requirements",
                    "label_rw": "Ibisabwa",
                    "icon": "file-text",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What documents do I need for a visa application?",
                    "message_rw": "Ni izihe nyandiko nkeneye kugira ngo nsabe viza?"
                }
            ],
            "passport_application": [
                {
                    "id": "apply_passport",
                    "label": "Apply for Passport",
                    "label_rw": "Saba Pasiporo",
                    "icon": "file-text",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "passport_renewal",
                    "label": "Renew Passport",
                    "label_rw": "Sana Pasiporo",
                    "icon": "refresh-cw",
                    "type": "secondary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "passport_cost",
                    "label": "Check Prices",
                    "label_rw": "Reba Ibiciro",
                    "icon": "dollar-sign",
                    "type": "secondary",
                    "action": "chat",
                    "message": "How much does a Rwandan passport cost?",
                    "message_rw": "Ni amafaranga angahe yo kubona pasiporo y'u Rwanda?"
                }
            ],
            "resident_id": [
                {
                    "id": "apply_resident_id",
                    "label": "Apply for Resident ID",
                    "label_rw": "Saba Indangamuntu",
                    "icon": "user",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "resident_requirements",
                    "label": "Requirements",
                    "label_rw": "Ibisabwa",
                    "icon": "file-text",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What are the requirements for a Resident ID?",
                    "message_rw": "Ni izihe nyandiko nkeneye kugira ngo nsabe indangamuntu y'umunyamahanga?"
                }
            ],
            "laissez_passer": [
                {
                    "id": "apply_laissez_passer",
                    "label": "Get Laissez-Passer",
                    "label_rw": "Saba Uruhushya rwo Kugenda",
                    "icon": "ticket",
                    "type": "primary",
                    "action": "external",
                    "url": "https://irembo.gov.rw/home/citizen/all_services"
                },
                {
                    "id": "laissez_passer_info",
                    "label": "Learn More",
                    "label_rw": "Menya Byinshi",
                    "icon": "info",
                    "type": "secondary",
                    "action": "chat",
                    "message": "Tell me more about Laissez-Passer",
                    "message_rw": "Mbwira byinshi kuri Laissez-Passer"
                }
            ]
        }
        
        # Keywords for service detection (English and Kinyarwanda)
        self.service_keywords = {
            "land_registration": [
                # English
                "land registration", "register land", "register my land", "new land",
                # Kinyarwanda - be specific to avoid false matches
                "kwandikisha ubutaka", "andikisha ubutaka", "nandikishe ubutaka", "ubutaka bushya"
            ],
            "title_transfer": [
                # English
                "title transfer", "transfer title", "transfer land", "sale", "donation",
                # Kinyarwanda
                "kwimura izina", "guhindura izina", "kugurisha ubutaka", "gutanga ubutaka", "nimure izina"
            ],
            "land_subdivision": [
                # English
                "subdivision", "subdivide", "split land", "divide land",
                # Kinyarwanda
                "kugabanya ubutaka", "gtandukanya ubutaka", "kugabura ubutaka", "ngabanye ubutaka"
            ],
            "visa_application": [
                # English
                "visa", "apply visa", "visa application", "enter rwanda",
                # Kinyarwanda - only match when asking about visa specifically
                "viza", "gusaba viza", "nsabe viza", "kubona viza", "kwinjira mu rwanda"
            ],
            "passport_application": [
                # English
                "passport", "rwandan passport", "passport renewal", "renew passport", "apply for passport",
                # Kinyarwanda - only match when asking about passport as main topic
                "gusaba pasiporo", "nsabe pasiporo", "kubona pasiporo", "kongerera pasiporo", "gusana pasiporo", "pasiporo y'u rwanda"
            ],
            "resident_id": [
                # English
                "resident id", "foreigner id", "resident card",
                # Kinyarwanda
                "indangamuntu y'umunyamahanga", "ikarita y'umunyamahanga", "nsabe indangamuntu"
            ],
            "laissez_passer": [
                # English
                "laissez-passer", "laissez passer", "travel document",
                # Kinyarwanda
                "icyangombwa cyo kugenda", "uruhushya rwo kugenda", "laissez-passer"
            ],
        }
        
        # General actions for when no specific service is detected
        self.general_actions = [
            {
                "id": "browse_services",
                "label": "Browse All Services",
                "label_rw": "Reba Serivisi Zose",
                "icon": "search",
                "type": "secondary",
                "action": "external",
                "url": "https://irembo.gov.rw/home/citizen/all_services"
            },
            {
                "id": "contact_support",
                "label": "Contact Support",
                "label_rw": "Hamagara Ubufasha",
                "icon": "message-circle",
                "type": "secondary",
                "action": "chat",
                "message": "How can I contact Irembo support?",
                "message_rw": "Ni gute nshobora guhamagara ubufasha bwa Irembo?"
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
        
        # Detect service from query FIRST (prioritize user intent)
        detected_services = []
        
        # Check query first
        for service, keywords in self.service_keywords.items():
            for keyword in keywords:
                if keyword in query_lower:
                    detected_services.append(service)
                    break
        
        # If no service detected in query, check response
        if not detected_services:
            for service, keywords in self.service_keywords.items():
                for keyword in keywords:
                    if keyword in response_lower:
                        detected_services.append(service)
                        break
        
        # Return actions for the first detected service
        if detected_services:
            service = detected_services[0]
            actions = self.service_actions.get(service, [])
            logger.info(f"Detected service: {service}, suggesting {len(actions)} actions")
            return actions[:3]  # Limit to 3 actions
        
        # Combine for fallback checks
        combined_text = f"{query_lower} {response_lower}"
        
        # If discussing price/cost, add payment-related action
        if any(word in combined_text for word in ["price", "cost", "fee", "rwf", "$", "amafaranga", "ikiguzi", "ibiciro"]):
            return [
                {
                    "id": "view_all_prices",
                    "label": "View All Service Prices",
                    "label_rw": "Reba Ibiciro bya Serivisi Zose",
                    "icon": "dollar-sign",
                    "type": "secondary",
                    "action": "chat",
                    "message": "Show me prices for all services",
                    "message_rw": "Ndeba ibiciro bya serivisi zose"
                },
                *self.general_actions[:1]
            ]
        
        # If discussing requirements/documents
        if any(word in combined_text for word in ["requirement", "document", "need", "necessary", "ibisabwa", "nyandiko", "nkeneye"]):
            return [
                {
                    "id": "prepare_documents",
                    "label": "Document Checklist",
                    "label_rw": "Urutonde rw'Inyandiko",
                    "icon": "check-square",
                    "type": "secondary",
                    "action": "chat",
                    "message": "What documents do I need to prepare?",
                    "message_rw": "Ni izihe nyandiko nkeneye gutegura?"
                },
                *self.general_actions[:1]
            ]
        
        # Default: show general actions
        return self.general_actions[:2]
