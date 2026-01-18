"""
Configuration settings for the application
"""
import os
from typing import Optional

# Load environment variables from .env file (if it exists)
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    # python-dotenv not installed, skip loading .env
    pass

# AI Enhancement Configuration (Gemini)
USE_AI_ENHANCEMENT = os.getenv("USE_AI_ENHANCEMENT", "false").lower() == "true"
AI_API_KEY: Optional[str] = os.getenv("AI_API_KEY")
AI_MODEL = os.getenv("AI_MODEL", "gemini-2.5-flash")  # Default to Gemini 2.5 Flash (fast & affordable)
AI_TIMEOUT = int(os.getenv("AI_TIMEOUT", "5"))

# Application Configuration
DEBUG = os.getenv("DEBUG", "false").lower() == "true"
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
