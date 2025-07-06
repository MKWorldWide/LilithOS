"""
⚙️ Configuration Management

Centralized configuration management for the TrafficFlou system,
including Athena AI model and Phantom Flair settings.

Author: TrafficFlou Team
Version: 1.0.0
"""

import os
from typing import Dict, List, Any

# =============================================================================
# 🚀 TRAFFICFLOU CONFIGURATION - ENHANCED GAMEDIN.XYZ MULTI-PAGE TARGETING
# =============================================================================
# Configuration for TrafficFlou with comprehensive GameDin.xyz page targeting
# Features: 7x traffic increase, exponential acceleration, multi-page routing
# =============================================================================

class TrafficFlouConfig:
    """Enhanced configuration for TrafficFlou with multi-page GameDin.xyz targeting"""
    
    # =============================================================================
    # 🎯 PRIMARY TARGETS - GAMEDIN.XYZ MULTI-PAGE SYSTEM
    # =============================================================================
    
    # Main GameDin.xyz pages with comprehensive targeting
    GAMEDIN_PAGES = {
        "main": "https://gamedin.xyz",
        "psychotherapy_shepard": "https://gamedin.xyz/psychotherapy-shepard",
        "primal_genesis_engine": "https://gamedin.xyz/primal-genesis-engine%E2%84%A2",
        "novasanctum_systems": "https://gamedin.xyz/novasanctum-systems", 
        "mkworldwide_inc": "https://gamedin.xyz/mkworldwide-inc",
        "about": "https://gamedin.xyz/about",
        "support": "https://gamedin.xyz/support",
        "projects": "https://gamedin.xyz/projects"
    }
    
    # Enhanced traffic settings with 7x increase
    TRAFFIC_SETTINGS = {
        "base_rate_per_minute": 70,  # 7x increase from 10
        "exponential_factor": 2.0,   # Increased from 1.5
        "max_concurrent_sessions": 21,  # 7x increase from 3
        "session_duration_range": (300, 900),  # 5-15 minutes
        "request_delay_range": (0.5, 2.0),  # Faster requests
        "page_visit_weight": {
            "main": 0.25,  # 25% of traffic to main page
            "psychotherapy_shepard": 0.20,  # 20% to therapy page
            "primal_genesis_engine": 0.20,  # 20% to engine page
            "novasanctum_systems": 0.15,  # 15% to systems page
            "mkworldwide_inc": 0.15,  # 15% to company page
            "about": 0.03,  # 3% to about
            "support": 0.01,  # 1% to support
            "projects": 0.01   # 1% to projects
        }
    }
    
    # =============================================================================
    # 📱 INSTAGRAM TARGETS - ENHANCED ROUTING
    # =============================================================================
    
    INSTAGRAM_ACCOUNTS = [
        "@M.K.Lux",
        "@TheSovereignSunny"
    ]
    
    INSTAGRAM_SETTINGS = {
        "base_rate_per_minute": 35,  # 7x increase from 5
        "exponential_factor": 2.0,
        "max_concurrent_sessions": 14,  # 7x increase from 2
        "session_duration_range": (180, 600),
        "request_delay_range": (1.0, 3.0)
    }
    
    # =============================================================================
    # 🧠 AI MODEL CONFIGURATION
    # =============================================================================
    
    AI_MODELS = {
        "athena": {
            "enabled": True,
            "api_key": os.getenv("ATHENA_API_KEY", ""),
            "model": "athena-v1",
            "max_tokens": 2048,
            "temperature": 0.7
        },
        "openai": {
            "enabled": True,
            "api_key": os.getenv("OPENAI_API_KEY", ""),
            "model": "gpt-4",
            "max_tokens": 1024,
            "temperature": 0.8
        },
        "anthropic": {
            "enabled": True,
            "api_key": os.getenv("ANTHROPIC_API_KEY", ""),
            "model": "claude-3-sonnet-20240229",
            "max_tokens": 1024,
            "temperature": 0.7
        }
    }
    
    # =============================================================================
    # 🎮 GAMING USER PROFILES - ENHANCED FOR GAMEDIN.XYZ
    # =============================================================================
    
    GAMING_USER_PROFILES = {
        "competitive_player": {
            "age_range": "16-24",
            "interests": ["esports", "competitive_gaming", "tournaments"],
            "behavior_patterns": ["aggressive_browsing", "rapid_navigation", "detail_analysis"],
            "session_duration": 600,  # 10 minutes
            "request_rate": 22,  # requests per minute
            "target_pages": ["main", "primal_genesis_engine", "projects"]
        },
        "casual_gamer": {
            "age_range": "25-35", 
            "interests": ["casual_gaming", "community", "social_gaming"],
            "behavior_patterns": ["exploratory_browsing", "social_interaction", "content_consumption"],
            "session_duration": 480,  # 8 minutes
            "request_rate": 18,
            "target_pages": ["main", "psychotherapy_shepard", "about"]
        },
        "gaming_enthusiast": {
            "age_range": "18-30",
            "interests": ["gaming_technology", "innovation", "future_gaming"],
            "behavior_patterns": ["technical_analysis", "deep_reading", "research_oriented"],
            "session_duration": 720,  # 12 minutes
            "request_rate": 20,
            "target_pages": ["main", "novasanctum_systems", "primal_genesis_engine"]
        },
        "business_gamer": {
            "age_range": "30-45",
            "interests": ["gaming_business", "investment", "industry_analysis"],
            "behavior_patterns": ["business_analysis", "strategic_thinking", "market_research"],
            "session_duration": 540,  # 9 minutes
            "request_rate": 16,
            "target_pages": ["main", "mkworldwide_inc", "about"]
        },
        "therapy_seeker": {
            "age_range": "20-40",
            "interests": ["mental_health", "healing", "personal_growth"],
            "behavior_patterns": ["contemplative_browsing", "emotional_engagement", "support_seeking"],
            "session_duration": 600,  # 10 minutes
            "request_rate": 15,
            "target_pages": ["psychotherapy_shepard", "main", "support"]
        },
        "tech_innovator": {
            "age_range": "25-40",
            "interests": ["technology", "innovation", "systems_design"],
            "behavior_patterns": ["technical_exploration", "innovation_research", "system_analysis"],
            "session_duration": 660,  # 11 minutes
            "request_rate": 19,
            "target_pages": ["primal_genesis_engine", "novasanctum_systems", "main"]
        }
    }
    
    # =============================================================================
    # 🔄 EXPONENTIAL ACCELERATION SETTINGS
    # =============================================================================
    
    ACCELERATION_SETTINGS = {
        "enabled": True,
        "base_multiplier": 7.0,  # 7x base increase
        "exponential_growth_rate": 1.8,  # Increased growth rate
        "max_cycles": 50,  # More cycles for sustained growth
        "cycle_duration": 300,  # 5 minutes per cycle
        "phase_increase_factor": 1.5,  # Each phase increases by 50%
        "adaptive_scaling": True,
        "performance_thresholds": {
            "cpu_usage": 80.0,
            "memory_usage": 85.0,
            "network_usage": 90.0
        }
    }
    
    # =============================================================================
    # 📊 ANALYTICS AND MONITORING
    # =============================================================================
    
    ANALYTICS = {
        "enabled": True,
        "log_level": "INFO",
        "metrics_collection": True,
        "performance_monitoring": True,
        "real_time_dashboard": True,
        "data_retention_days": 30
    }
    
    # =============================================================================
    # 🔒 SECURITY AND COMPLIANCE
    # =============================================================================
    
    SECURITY = {
        "rate_limiting": True,
        "max_requests_per_minute": 1000,
        "user_agent_rotation": True,
        "proxy_rotation": True,
        "request_validation": True,
        "ethical_guidelines": True
    }
    
    # =============================================================================
    # 🌐 NETWORK AND PROXY SETTINGS
    # =============================================================================
    
    NETWORK = {
        "timeout": 30,
        "max_retries": 3,
        "connection_pool_size": 100,
        "proxy_enabled": True,
        "proxy_list": [],  # Will be populated from proxy service
        "ssl_verification": True
    }
    
    # =============================================================================
    # 📝 LOGGING CONFIGURATION
    # =============================================================================
    
    LOGGING = {
        "level": "INFO",
        "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        "file": "trafficflou.log",
        "max_file_size": "10MB",
        "backup_count": 5
    }

# Global configuration instance
config = TrafficFlouConfig()

# =============================================================================
# 🚀 CONFIGURATION VALIDATION AND INITIALIZATION
# =============================================================================

def validate_config() -> bool:
    """Validate the configuration settings"""
    try:
        # Validate required settings
        assert config.TRAFFIC_SETTINGS["base_rate_per_minute"] > 0
        assert config.TRAFFIC_SETTINGS["exponential_factor"] > 1.0
        assert len(config.GAMEDIN_PAGES) > 0
        assert len(config.INSTAGRAM_ACCOUNTS) > 0
        
        # Validate page weights sum to 1.0
        total_weight = sum(config.TRAFFIC_SETTINGS["page_visit_weight"].values())
        assert abs(total_weight - 1.0) < 0.01, f"Page weights must sum to 1.0, got {total_weight}"
        
        return True
    except Exception as e:
        print(f"❌ Configuration validation failed: {e}")
        return False

def get_config() -> TrafficFlouConfig:
    """Get the global configuration instance"""
    return config

# Initialize configuration validation
if __name__ == "__main__":
    if validate_config():
        print("✅ TrafficFlou configuration validated successfully")
        print(f"🎯 GameDin.xyz pages configured: {len(config.GAMEDIN_PAGES)}")
        print(f"📱 Instagram accounts configured: {len(config.INSTAGRAM_ACCOUNTS)}")
        print(f"🚀 Base traffic rate: {config.TRAFFIC_SETTINGS['base_rate_per_minute']} req/min")
        print(f"📈 Exponential factor: {config.TRAFFIC_SETTINGS['exponential_factor']}")
    else:
        print("❌ Configuration validation failed") 