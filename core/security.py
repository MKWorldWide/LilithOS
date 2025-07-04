"""
LilithOS Security Manager
========================

Handles all security aspects of the LilithOS system:
- Encryption and decryption
- Authentication and authorization
- Access control and permissions
- Security monitoring and logging
- Threat detection and response
"""

import os
import hashlib
import hmac
import base64
import secrets
import time
import asyncio
import logging
import threading
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field
from enum import Enum
import json
import yaml
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import serialization

class SecurityLevel(Enum):
    """Security level enumeration"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class Permission(Enum):
    """Permission enumeration"""
    READ = "read"
    WRITE = "write"
    EXECUTE = "execute"
    ADMIN = "admin"
    SYSTEM = "system"

@dataclass
class User:
    """User information container"""
    username: str
    password_hash: str
    salt: str
    permissions: List[Permission] = field(default_factory=list)
    security_level: SecurityLevel = SecurityLevel.MEDIUM
    created_at: float = field(default_factory=time.time)
    last_login: Optional[float] = None
    failed_attempts: int = 0
    locked: bool = False
    session_token: Optional[str] = None

@dataclass
class SecurityEvent:
    """Security event container"""
    timestamp: float
    event_type: str
    severity: SecurityLevel
    user: Optional[str] = None
    details: Dict[str, Any] = field(default_factory=dict)
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None

class EncryptionManager:
    """Handles encryption and decryption operations"""
    
    def __init__(self, master_key: Optional[str] = None):
        self.master_key = master_key or self._generate_master_key()
        self.fernet = Fernet(self._derive_key(self.master_key))
        self.key_cache: Dict[str, Fernet] = {}
    
    def _generate_master_key(self) -> str:
        """Generate a new master key"""
        return base64.urlsafe_b64encode(secrets.token_bytes(32)).decode()
    
    def _derive_key(self, password: str, salt: Optional[bytes] = None) -> bytes:
        """Derive encryption key from password"""
        if salt is None:
            salt = secrets.token_bytes(16)
        
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
        )
        key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
        return key
    
    def encrypt(self, data: bytes, key_id: Optional[str] = None) -> Tuple[bytes, bytes]:
        """Encrypt data"""
        if key_id and key_id in self.key_cache:
            fernet = self.key_cache[key_id]
        else:
            fernet = self.fernet
        
        encrypted_data = fernet.encrypt(data)
        return encrypted_data, b''  # No additional metadata needed for Fernet
    
    def decrypt(self, encrypted_data: bytes, key_id: Optional[str] = None) -> bytes:
        """Decrypt data"""
        if key_id and key_id in self.key_cache:
            fernet = self.key_cache[key_id]
        else:
            fernet = self.fernet
        
        return fernet.decrypt(encrypted_data)
    
    def add_key(self, key_id: str, key: str):
        """Add a new encryption key"""
        derived_key = self._derive_key(key)
        self.key_cache[key_id] = Fernet(derived_key)
    
    def remove_key(self, key_id: str):
        """Remove an encryption key"""
        if key_id in self.key_cache:
            del self.key_cache[key_id]

class AuthenticationManager:
    """Handles user authentication and session management"""
    
    def __init__(self, security_manager: 'SecurityManager'):
        self.security_manager = security_manager
        self.users: Dict[str, User] = {}
        self.sessions: Dict[str, Dict[str, Any]] = {}
        self.session_timeout = 3600  # 1 hour
        self.max_failed_attempts = 5
        self.lockout_duration = 1800  # 30 minutes
    
    def _hash_password(self, password: str, salt: Optional[str] = None) -> Tuple[str, str]:
        """Hash a password with salt"""
        if salt is None:
            salt = secrets.token_hex(16)
        
        # Use PBKDF2 for password hashing
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt.encode(),
            iterations=100000,
        )
        password_hash = base64.urlsafe_b64encode(kdf.derive(password.encode())).decode()
        return password_hash, salt
    
    def _verify_password(self, password: str, password_hash: str, salt: str) -> bool:
        """Verify a password against its hash"""
        try:
            expected_hash, _ = self._hash_password(password, salt)
            return hmac.compare_digest(password_hash, expected_hash)
        except Exception:
            return False
    
    def create_user(self, username: str, password: str, permissions: List[Permission] = None, security_level: SecurityLevel = SecurityLevel.MEDIUM) -> bool:
        """Create a new user"""
        try:
            if username in self.users:
                return False
            
            password_hash, salt = self._hash_password(password)
            
            user = User(
                username=username,
                password_hash=password_hash,
                salt=salt,
                permissions=permissions or [Permission.READ],
                security_level=security_level
            )
            
            self.users[username] = user
            self.security_manager.logger.info(f"User '{username}' created successfully")
            return True
            
        except Exception as e:
            self.security_manager.logger.error(f"Failed to create user '{username}': {e}")
            return False
    
    def authenticate(self, username: str, password: str, ip_address: Optional[str] = None) -> Optional[str]:
        """Authenticate a user and return session token"""
        try:
            user = self.users.get(username)
            if not user:
                self._log_security_event("failed_login", SecurityLevel.MEDIUM, username, {"reason": "user_not_found"}, ip_address)
                return None
            
            # Check if account is locked
            if user.locked:
                if time.time() - user.last_login < self.lockout_duration:
                    self._log_security_event("failed_login", SecurityLevel.HIGH, username, {"reason": "account_locked"}, ip_address)
                    return None
                else:
                    # Unlock account after lockout duration
                    user.locked = False
                    user.failed_attempts = 0
            
            # Verify password
            if not self._verify_password(password, user.password_hash, user.salt):
                user.failed_attempts += 1
                user.last_login = time.time()
                
                if user.failed_attempts >= self.max_failed_attempts:
                    user.locked = True
                    self._log_security_event("account_locked", SecurityLevel.HIGH, username, {"failed_attempts": user.failed_attempts}, ip_address)
                else:
                    self._log_security_event("failed_login", SecurityLevel.MEDIUM, username, {"failed_attempts": user.failed_attempts}, ip_address)
                
                return None
            
            # Successful authentication
            user.failed_attempts = 0
            user.last_login = time.time()
            
            # Generate session token
            session_token = secrets.token_urlsafe(32)
            user.session_token = session_token
            
            # Create session
            self.sessions[session_token] = {
                "username": username,
                "created_at": time.time(),
                "last_activity": time.time(),
                "ip_address": ip_address,
                "permissions": [p.value for p in user.permissions],
                "security_level": user.security_level.value
            }
            
            self._log_security_event("successful_login", SecurityLevel.LOW, username, {}, ip_address)
            return session_token
            
        except Exception as e:
            self.security_manager.logger.error(f"Authentication failed for '{username}': {e}")
            return None
    
    def validate_session(self, session_token: str) -> Optional[Dict[str, Any]]:
        """Validate a session token"""
        try:
            session = self.sessions.get(session_token)
            if not session:
                return None
            
            # Check session timeout
            if time.time() - session["last_activity"] > self.session_timeout:
                self._logout(session_token)
                return None
            
            # Update last activity
            session["last_activity"] = time.time()
            return session
            
        except Exception as e:
            self.security_manager.logger.error(f"Session validation failed: {e}")
            return None
    
    def _logout(self, session_token: str):
        """Logout a user"""
        if session_token in self.sessions:
            username = self.sessions[session_token]["username"]
            if username in self.users:
                self.users[username].session_token = None
            del self.sessions[session_token]
    
    def logout(self, session_token: str) -> bool:
        """Logout a user"""
        try:
            if session_token in self.sessions:
                username = self.sessions[session_token]["username"]
                self._logout(session_token)
                self._log_security_event("logout", SecurityLevel.LOW, username, {})
                return True
            return False
        except Exception as e:
            self.security_manager.logger.error(f"Logout failed: {e}")
            return False
    
    def has_permission(self, session_token: str, permission: Permission) -> bool:
        """Check if a session has a specific permission"""
        session = self.validate_session(session_token)
        if not session:
            return False
        
        return permission.value in session["permissions"]
    
    def _log_security_event(self, event_type: str, severity: SecurityLevel, user: Optional[str], details: Dict[str, Any], ip_address: Optional[str] = None):
        """Log a security event"""
        event = SecurityEvent(
            timestamp=time.time(),
            event_type=event_type,
            severity=severity,
            user=user,
            details=details,
            ip_address=ip_address
        )
        self.security_manager.log_security_event(event)

class AccessControlManager:
    """Handles access control and permissions"""
    
    def __init__(self, security_manager: 'SecurityManager'):
        self.security_manager = security_manager
        self.resources: Dict[str, Dict[str, Any]] = {}
        self.policies: Dict[str, Dict[str, Any]] = {}
    
    def register_resource(self, resource_id: str, resource_type: str, owner: str, permissions: Dict[str, List[str]] = None):
        """Register a new resource"""
        self.resources[resource_id] = {
            "type": resource_type,
            "owner": owner,
            "permissions": permissions or {},
            "created_at": time.time(),
            "last_accessed": time.time()
        }
    
    def check_access(self, session_token: str, resource_id: str, permission: Permission) -> bool:
        """Check if a session has access to a resource"""
        try:
            session = self.security_manager.auth.validate_session(session_token)
            if not session:
                return False
            
            resource = self.resources.get(resource_id)
            if not resource:
                return False
            
            username = session["username"]
            
            # Owner has full access
            if resource["owner"] == username:
                return True
            
            # Check explicit permissions
            resource_permissions = resource["permissions"]
            if username in resource_permissions:
                if permission.value in resource_permissions[username]:
                    return True
            
            # Check group permissions (if implemented)
            # TODO: Implement group-based permissions
            
            return False
            
        except Exception as e:
            self.security_manager.logger.error(f"Access check failed: {e}")
            return False
    
    def grant_permission(self, resource_id: str, username: str, permission: Permission) -> bool:
        """Grant permission to a user for a resource"""
        try:
            if resource_id not in self.resources:
                return False
            
            if username not in self.resources[resource_id]["permissions"]:
                self.resources[resource_id]["permissions"][username] = []
            
            if permission.value not in self.resources[resource_id]["permissions"][username]:
                self.resources[resource_id]["permissions"][username].append(permission.value)
            
            return True
            
        except Exception as e:
            self.security_manager.logger.error(f"Failed to grant permission: {e}")
            return False
    
    def revoke_permission(self, resource_id: str, username: str, permission: Permission) -> bool:
        """Revoke permission from a user for a resource"""
        try:
            if resource_id not in self.resources:
                return False
            
            if username in self.resources[resource_id]["permissions"]:
                if permission.value in self.resources[resource_id]["permissions"][username]:
                    self.resources[resource_id]["permissions"][username].remove(permission.value)
            
            return True
            
        except Exception as e:
            self.security_manager.logger.error(f"Failed to revoke permission: {e}")
            return False

class SecurityManager:
    """
    LilithOS Security Manager
    
    Manages all security aspects of the system:
    - User authentication and session management
    - Access control and permissions
    - Encryption and data protection
    - Security monitoring and threat detection
    - Audit logging and compliance
    """
    
    def __init__(self, core):
        self.core = core
        self.logger = logging.getLogger("SecurityManager")
        self.encryption = EncryptionManager()
        self.auth = AuthenticationManager(self)
        self.access_control = AccessControlManager(self)
        self.security_events: List[SecurityEvent] = []
        self.threat_detection_enabled = True
        self.audit_logging_enabled = True
        self.lock = threading.RLock()
        
        # Security configuration
        self.max_events = 10000
        self.event_retention_days = 90
    
    async def initialize(self) -> bool:
        """Initialize the security manager"""
        try:
            self.logger.info("Initializing Security Manager...")
            
            # Load existing users and configuration
            await self._load_security_config()
            
            # Create default admin user if none exists
            if not self.auth.users:
                self.auth.create_user(
                    username="admin",
                    password="admin123",  # Should be changed immediately
                    permissions=[Permission.ADMIN, Permission.SYSTEM],
                    security_level=SecurityLevel.HIGH
                )
                self.logger.warning("Default admin user created. Please change the password immediately!")
            
            # Start security monitoring
            asyncio.create_task(self._security_monitor())
            
            self.logger.info("Security Manager initialized successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to initialize Security Manager: {e}")
            return False
    
    async def _load_security_config(self):
        """Load security configuration from file"""
        try:
            config_path = Path("config/security.yaml")
            if config_path.exists():
                with open(config_path, 'r', encoding='utf-8') as f:
                    config = yaml.safe_load(f) or {}
                
                # Load users
                users_data = config.get('users', {})
                for username, user_data in users_data.items():
                    user = User(
                        username=username,
                        password_hash=user_data['password_hash'],
                        salt=user_data['salt'],
                        permissions=[Permission(p) for p in user_data.get('permissions', [])],
                        security_level=SecurityLevel(user_data.get('security_level', 'medium')),
                        created_at=user_data.get('created_at', time.time()),
                        last_login=user_data.get('last_login'),
                        failed_attempts=user_data.get('failed_attempts', 0),
                        locked=user_data.get('locked', False)
                    )
                    self.auth.users[username] = user
                
                # Load security events
                events_data = config.get('security_events', [])
                for event_data in events_data:
                    event = SecurityEvent(
                        timestamp=event_data['timestamp'],
                        event_type=event_data['event_type'],
                        severity=SecurityLevel(event_data['severity']),
                        user=event_data.get('user'),
                        details=event_data.get('details', {}),
                        ip_address=event_data.get('ip_address')
                    )
                    self.security_events.append(event)
            
        except Exception as e:
            self.logger.error(f"Failed to load security configuration: {e}")
    
    async def _save_security_config(self):
        """Save security configuration to file"""
        try:
            config_path = Path("config/security.yaml")
            config_path.parent.mkdir(parents=True, exist_ok=True)
            
            config = {
                'users': {},
                'security_events': []
            }
            
            # Save users
            for username, user in self.auth.users.items():
                config['users'][username] = {
                    'password_hash': user.password_hash,
                    'salt': user.salt,
                    'permissions': [p.value for p in user.permissions],
                    'security_level': user.security_level.value,
                    'created_at': user.created_at,
                    'last_login': user.last_login,
                    'failed_attempts': user.failed_attempts,
                    'locked': user.locked
                }
            
            # Save recent security events
            recent_events = [e for e in self.security_events if time.time() - e.timestamp < self.event_retention_days * 86400]
            config['security_events'] = [
                {
                    'timestamp': e.timestamp,
                    'event_type': e.event_type,
                    'severity': e.severity.value,
                    'user': e.user,
                    'details': e.details,
                    'ip_address': e.ip_address
                }
                for e in recent_events
            ]
            
            with open(config_path, 'w', encoding='utf-8') as f:
                yaml.dump(config, f, default_flow_style=False, indent=2)
            
        except Exception as e:
            self.logger.error(f"Failed to save security configuration: {e}")
    
    def log_security_event(self, event: SecurityEvent):
        """Log a security event"""
        try:
            with self.lock:
                self.security_events.append(event)
                
                # Limit the number of stored events
                if len(self.security_events) > self.max_events:
                    self.security_events = self.security_events[-self.max_events:]
                
                # Log to system log
                log_level = {
                    SecurityLevel.LOW: logging.INFO,
                    SecurityLevel.MEDIUM: logging.WARNING,
                    SecurityLevel.HIGH: logging.ERROR,
                    SecurityLevel.CRITICAL: logging.CRITICAL
                }.get(event.severity, logging.INFO)
                
                self.logger.log(log_level, f"Security Event: {event.event_type} - User: {event.user} - Details: {event.details}")
                
        except Exception as e:
            self.logger.error(f"Failed to log security event: {e}")
    
    async def _security_monitor(self):
        """Security monitoring loop"""
        while True:
            try:
                # Check for suspicious activity
                await self._detect_threats()
                
                # Clean up old sessions
                await self._cleanup_sessions()
                
                # Save configuration periodically
                await self._save_security_config()
                
                await asyncio.sleep(300)  # Run every 5 minutes
                
            except Exception as e:
                self.logger.error(f"Security monitoring error: {e}")
                await asyncio.sleep(60)
    
    async def _detect_threats(self):
        """Detect potential security threats"""
        if not self.threat_detection_enabled:
            return
        
        try:
            current_time = time.time()
            
            # Check for multiple failed login attempts
            for user in self.auth.users.values():
                if user.failed_attempts >= 3:
                    self.log_security_event(SecurityEvent(
                        timestamp=current_time,
                        event_type="suspicious_activity",
                        severity=SecurityLevel.HIGH,
                        user=user.username,
                        details={"type": "multiple_failed_logins", "count": user.failed_attempts}
                    ))
            
            # Check for unusual session activity
            for session_token, session in self.auth.sessions.items():
                if current_time - session["last_activity"] > 3600:  # 1 hour
                    self.log_security_event(SecurityEvent(
                        timestamp=current_time,
                        event_type="inactive_session",
                        severity=SecurityLevel.MEDIUM,
                        user=session["username"],
                        details={"session_token": session_token}
                    ))
            
        except Exception as e:
            self.logger.error(f"Threat detection error: {e}")
    
    async def _cleanup_sessions(self):
        """Clean up expired sessions"""
        try:
            current_time = time.time()
            expired_sessions = []
            
            for session_token, session in self.auth.sessions.items():
                if current_time - session["last_activity"] > self.auth.session_timeout:
                    expired_sessions.append(session_token)
            
            for session_token in expired_sessions:
                self.auth._logout(session_token)
            
            if expired_sessions:
                self.logger.info(f"Cleaned up {len(expired_sessions)} expired sessions")
                
        except Exception as e:
            self.logger.error(f"Session cleanup error: {e}")
    
    def encrypt_data(self, data: bytes, key_id: Optional[str] = None) -> Tuple[bytes, bytes]:
        """Encrypt data"""
        return self.encryption.encrypt(data, key_id)
    
    def decrypt_data(self, encrypted_data: bytes, key_id: Optional[str] = None) -> bytes:
        """Decrypt data"""
        return self.encryption.decrypt(encrypted_data, key_id)
    
    def authenticate_user(self, username: str, password: str, ip_address: Optional[str] = None) -> Optional[str]:
        """Authenticate a user"""
        return self.auth.authenticate(username, password, ip_address)
    
    def validate_user_session(self, session_token: str) -> Optional[Dict[str, Any]]:
        """Validate a user session"""
        return self.auth.validate_session(session_token)
    
    def check_resource_access(self, session_token: str, resource_id: str, permission: Permission) -> bool:
        """Check if a user has access to a resource"""
        return self.access_control.check_access(session_token, resource_id, permission)
    
    def get_security_stats(self) -> Dict[str, Any]:
        """Get security statistics"""
        return {
            "total_users": len(self.auth.users),
            "active_sessions": len(self.auth.sessions),
            "security_events": len(self.security_events),
            "locked_accounts": len([u for u in self.auth.users.values() if u.locked]),
            "high_severity_events": len([e for e in self.security_events if e.severity in [SecurityLevel.HIGH, SecurityLevel.CRITICAL]])
        }
    
    async def cleanup(self):
        """Cleanup security manager resources"""
        try:
            await self._save_security_config()
            self.logger.info("Security Manager cleanup completed")
        except Exception as e:
            self.logger.error(f"Security Manager cleanup failed: {e}")
    
    async def run_maintenance(self) -> bool:
        """Run security maintenance tasks"""
        try:
            # Clean up old security events
            current_time = time.time()
            self.security_events = [
                e for e in self.security_events
                if current_time - e.timestamp < self.event_retention_days * 86400
            ]
            
            # Update security statistics
            stats = self.get_security_stats()
            self.logger.info(f"Security maintenance completed: {stats}")
            
            return True
            
        except Exception as e:
            self.logger.error(f"Security maintenance failed: {e}")
            return False 