"""
AI Service for enhancing Feng Shui suggestions with personalized context
Designed with fallback mechanism - works without AI if unavailable
"""
import os
import json
import logging
import asyncio
from typing import List, Dict, Optional
from app.models import AnalyzeRoomRequest, Suggestion

logger = logging.getLogger(__name__)

# Try to import Gemini - fallback if not installed
try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    logger.warning("google-generativeai not installed. AI enhancement will be disabled.")


"""
    Enhances rule-based Feng Shui suggestions with AI-generated personalized content.
    
    Features:
    - Optional AI enhancement (works without API key)
    - Fallback to rule-based suggestions if AI unavailable
    - Graceful error handling
    - Configurable via environment variables
"""
class AISuggestionEnhancer:
    
    def __init__(self, api_key: Optional[str] = None):
        ## api_key: Optional API key for AI service. If None, enhancement is disabled.
        self.api_key = api_key or os.getenv("AI_API_KEY")
        self.enabled = self.api_key is not None and GEMINI_AVAILABLE
        self.model_name = os.getenv("AI_MODEL", "gemini-2.5-flash")
        self.timeout = int(os.getenv("AI_TIMEOUT", "5"))
        self.gemini_model = None
        
        if not GEMINI_AVAILABLE:
            logger.warning("google-generativeai package not installed. Install with: pip install google-generativeai")
            self.enabled = False
        elif not self.api_key:
            logger.info("AI enhancement disabled, no API key provided. Using rule-based suggestions.")
        else:
            # Configure Gemini
            try:
                genai.configure(api_key=self.api_key)
                self.gemini_model = genai.GenerativeModel(self.model_name)
                logger.info(f"Gemini AI enabled with model: {self.model_name}")
            except Exception as e:
                logger.warning(f"Failed to configure Gemini: {e}. AI enhancement disabled.")
                self.enabled = False
    

    """
        Enhance rule-based suggestions with AI-generated personalized content.
        
        If AI is unavailable or fails, returns original rule-based suggestions.
        
        Args:
            rule_suggestions: List of rule-based suggestions to enhance
            context: Context dictionary with room metadata, violations, scores, etc.
        
        Returns:
            Enhanced suggestions (or original if AI unavailable/failed)
    """
    async def enhance_suggestions(
        self,
        rule_suggestions: List[Suggestion],
        context: Dict
    ) -> List[Suggestion]:

        # If AI not enabled, return original suggestions
        if not self.enabled:
            return rule_suggestions
        
        try:
            logger.debug(f"AI enhancement called for {len(rule_suggestions)} suggestions")
            
            # Call Gemini API to enhance suggestions
            enhanced = await self._call_ai_api(rule_suggestions, context)
            return enhanced
            
        except Exception as e:
            # Always fallback to rule-based on error
            logger.warning(f"AI enhancement failed, using fallback: {e}")
            return rule_suggestions
    

    """
        Prepare context data structure for AI enhancement.
        
        Args:
            request: Original room analysis request
            zone_scores: Calculated zone scores
            rule_violations: List of rule violations detected
            rule_compliances: List of good placements detected
        
        Returns:
            Structured context dictionary for AI
    """
    def _prepare_context_for_ai(
        self,
        request: AnalyzeRoomRequest,
        zone_scores: Dict[str, int],
        rule_violations: List[str],
        rule_compliances: List[str]
    ) -> Dict:

        return {
            "room_metadata": {
                "room_type": request.room_metadata.room_type,
                "room_style": request.room_metadata.room_style,
                "feng_shui_intention": request.room_metadata.feng_shui_intention,
                "birth_year": request.room_metadata.birth_year,
                "north_direction_deg": request.room_metadata.north_direction_deg
            },
            "room_dimensions": {
                "length_m": request.room_dimensions.length_m,
                "width_m": request.room_dimensions.width_m,
                "height_m": request.room_dimensions.height_m
            },
            "object_count": len(request.objects),
            "object_types": list(set(obj.type.lower() for obj in request.objects)),
            "zone_scores": zone_scores,
            "rule_violations": rule_violations,
            "rule_compliances": rule_compliances,
            "summary": {
                "has_windows": any(obj.type.lower() == "window" for obj in request.objects),
                "has_plants": any(obj.type.lower() == "plant" for obj in request.objects),
                "total_suggestions": len(rule_violations) + len(rule_compliances)
            }
        }
    
    """
        Call Gemini API to enhance suggestions.
        
        Args:
            suggestions: Rule-based suggestions to enhance
            context: Room context data
        
        Returns:
            Enhanced suggestions with AI-generated content
    """
    async def _call_ai_api(
        self,
        suggestions: List[Suggestion],
        context: Dict
    ) -> List[Suggestion]:
        
        if not self.gemini_model:
            return suggestions
        
        try:
            # Build prompt for Gemini
            prompt = self._build_enhancement_prompt(suggestions, context)
            
            # Call Gemini API (sync call in async context)
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: self.gemini_model.generate_content(prompt)
            )
            
            # Parse response and enhance suggestions
            enhanced_suggestions = self._parse_ai_response(response.text, suggestions)
            
            logger.info(f"Successfully enhanced {len(enhanced_suggestions)} suggestions with Gemini")
            return enhanced_suggestions
            
        except Exception as e:
            logger.warning(f"Gemini API call failed: {e}. Using original suggestions.")
            return suggestions
    
    def _build_enhancement_prompt(
        self,
        suggestions: List[Suggestion],
        context: Dict
    ) -> str:
        """
        Build prompt for Gemini to enhance suggestions.
        
        Args:
            suggestions: Current rule-based suggestions
            context: Room context data
        
        Returns:
            Formatted prompt string for Gemini
        """
        metadata = context.get("room_metadata", {})
        room_type = metadata.get("room_type", "room")
        room_style = metadata.get("room_style", "")
        intention = metadata.get("feng_shui_intention", "")
        birth_year = metadata.get("birth_year")
        
        # Format suggestions for prompt
        suggestions_text = "\n".join([
            f"- [{s.id}] {s.title}: {s.description} (Severity: {s.severity})"
            for s in suggestions
        ])
        
        prompt = f"""You are an expert Feng Shui consultant. Enhance these Feng Shui suggestions with personalized, actionable advice.

ROOM CONTEXT:
- Room Type: {room_type}
- Style: {room_style if room_style else 'Not specified'}
- Feng Shui Intention: {intention if intention else 'Not specified'}
- Birth Year: {birth_year if birth_year else 'Not specified'}
- Zone Scores: {context.get('zone_scores', {})}
- Rule Violations: {context.get('rule_violations', [])}
- Rule Compliances: {context.get('rule_compliances', [])}

CURRENT SUGGESTIONS:
{suggestions_text}

TASK:
Enhance each suggestion's description with personalized, actionable advice based on:
1. Room style ({room_style}) - incorporate style-specific recommendations
2. Feng Shui intention ({intention}) - relate to their goal
3. Birth year ({birth_year}) - if provided, add relevant Chinese astrology insights
4. Make descriptions more engaging and actionable
5. Keep the same suggestion IDs, titles, and severity levels

IMPORTANT:
- Return ONLY valid JSON array format
- Keep all suggestion IDs exactly the same
- Keep all titles (you can refine them slightly)
- Keep all severity levels (low, medium, high)
- Enhance descriptions with personalized, actionable advice
- Keep related_object_ids the same

FORMAT: JSON array of suggestions
[
  {{
    "id": "suggestion_id",
    "title": "Enhanced title (optional refinement)",
    "description": "Enhanced description with personalization",
    "severity": "low|medium|high",
    "related_object_ids": ["object_id1", "object_id2"]
  }},
  ...
]

Return the enhanced suggestions as JSON:"""
        
        return prompt
    
    def _parse_ai_response(
        self,
        response_text: str,
        original_suggestions: List[Suggestion]
    ) -> List[Suggestion]:
        """
        Parse Gemini response and create enhanced suggestions.
        
        Args:
            response_text: Raw response text from Gemini
            original_suggestions: Original rule-based suggestions (fallback)
        
        Returns:
            List of enhanced suggestions
        """
        try:
            # Try to extract JSON from response (Gemini may wrap in markdown)
            response_text = response_text.strip()
            
            # Remove markdown code blocks if present
            if response_text.startswith("```json"):
                response_text = response_text[7:]
            if response_text.startswith("```"):
                response_text = response_text[3:]
            if response_text.endswith("```"):
                response_text = response_text[:-3]
            response_text = response_text.strip()
            
            # Parse JSON
            enhanced_data = json.loads(response_text)
            
            if not isinstance(enhanced_data, list):
                raise ValueError("Expected JSON array")
            
            # Create enhanced suggestions
            enhanced_suggestions = []
            
            # Create lookup map of original suggestions by ID
            original_map = {s.id: s for s in original_suggestions}
            
            for item in enhanced_data:
                suggestion_id = item.get("id")
                
                # Use original suggestion as base (ensures all fields present)
                if suggestion_id in original_map:
                    original = original_map[suggestion_id]
                    
                    # Create enhanced version with updated description
                    enhanced = Suggestion(
                        id=suggestion_id,
                        title=item.get("title", original.title),
                        description=item.get("description", original.description),
                        severity=item.get("severity", original.severity),
                        related_object_ids=item.get("related_object_ids", original.related_object_ids)
                    )
                    enhanced_suggestions.append(enhanced)
                else:
                    # If ID not found, try to create from item (shouldn't happen)
                    logger.warning(f"Suggestion ID {suggestion_id} not found in originals")
            
            # If parsing failed or no enhanced suggestions, return original
            if not enhanced_suggestions:
                logger.warning("No enhanced suggestions parsed, using originals")
                return original_suggestions
            
            # Ensure all original suggestions are included (in case AI missed some)
            enhanced_ids = {s.id for s in enhanced_suggestions}
            for orig in original_suggestions:
                if orig.id not in enhanced_ids:
                    enhanced_suggestions.append(orig)
            
            return enhanced_suggestions
            
        except json.JSONDecodeError as e:
            logger.warning(f"Failed to parse Gemini JSON response: {e}")
            logger.debug(f"Response text: {response_text[:200]}")
            return original_suggestions
        except Exception as e:
            logger.warning(f"Error parsing AI response: {e}")
            return original_suggestions
