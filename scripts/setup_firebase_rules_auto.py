#!/usr/bin/env python3
"""
Automatische Firebase Rules Setup
Setzt ALLE Firestore und Storage Rules automatisch
"""

import sys
import os
import subprocess
import json

# ANSI color codes
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

def print_header(text):
    """Print colored header"""
    print(f"\n{BLUE}{'=' * 60}{RESET}")
    print(f"{BLUE}{text}{RESET}")
    print(f"{BLUE}{'=' * 60}{RESET}\n")

def print_success(text):
    """Print success message"""
    print(f"{GREEN}✅ {text}{RESET}")

def print_error(text):
    """Print error message"""
    print(f"{RED}❌ {text}{RESET}")

def print_warning(text):
    """Print warning message"""
    print(f"{YELLOW}⚠️  {text}{RESET}")

def print_info(text):
    """Print info message"""
    print(f"{BLUE}ℹ️  {text}{RESET}")

# Firestore Rules (komplett, minified)
FIRESTORE_RULES = """rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() { return request.auth != null; }
    function isOwner(userId) { return isAuthenticated() && request.auth.uid == userId; }
    function isSuperAdmin() { return isAuthenticated() && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin'; }
    function isModerator() { return isAuthenticated() && (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'moderator'); }
    function hasModeratorPermission(permission) { let userData = get(/databases/$(database)/documents/users/$(request.auth.uid)).data; return isModerator() && (userData.role == 'super_admin' || (userData.permissions != null && userData.permissions[permission] == true)); }
    match /users/{userId} { allow read: if isAuthenticated(); allow create: if isAuthenticated() && isOwner(userId); allow update: if isOwner(userId) || isModerator(); allow delete: if isSuperAdmin(); }
    match /chat_rooms/{roomId} { allow read: if isAuthenticated(); allow create: if isAuthenticated(); allow update: if isAuthenticated() && (request.auth.uid in resource.data.participants || isModerator()); allow delete: if isSuperAdmin(); match /messages/{messageId} { allow read: if isAuthenticated() && request.auth.uid in get(/databases/$(database)/documents/chat_rooms/$(roomId)).data.participants; allow create: if isAuthenticated() && request.auth.uid in get(/databases/$(database)/documents/chat_rooms/$(roomId)).data.participants; allow update: if isOwner(resource.data.senderId) || hasModeratorPermission('canDeleteMessages'); allow delete: if isOwner(resource.data.senderId) || hasModeratorPermission('canDeleteMessages'); } match /typing/{typingUserId} { allow read: if isAuthenticated(); allow write: if isAuthenticated() && isOwner(typingUserId); } }
    match /audio_rooms/{roomId} { allow read: if isAuthenticated(); allow create: if isAuthenticated(); allow update: if isAuthenticated(); allow delete: if isSuperAdmin() || (isAuthenticated() && request.auth.uid == resource.data.hostId); match /participants/{participantId} { allow read: if isAuthenticated(); allow write: if isAuthenticated(); allow delete: if isAuthenticated(); } }
    match /notifications/{notificationId} { allow read: if isAuthenticated() && isOwner(resource.data.userId); allow create: if isModerator(); allow update: if isOwner(resource.data.userId); allow delete: if isOwner(resource.data.userId) || isModerator(); }
    match /moderation_logs/{logId} { allow read: if isModerator(); allow create: if isModerator(); allow update: if false; allow delete: if isSuperAdmin(); }
    match /blocked_users/{blockId} { allow read: if isModerator(); allow create: if hasModeratorPermission('canBlockUsers'); allow update: if hasModeratorPermission('canBlockUsers'); allow delete: if hasModeratorPermission('canBlockUsers'); }
    match /muted_users/{muteId} { allow read: if isModerator(); allow create: if hasModeratorPermission('canMuteUsers'); allow update: if hasModeratorPermission('canMuteUsers'); allow delete: if hasModeratorPermission('canMuteUsers'); }
    match /deleted_users/{userId} { allow read: if isModerator(); allow create: if isSuperAdmin(); allow update: if isSuperAdmin(); allow delete: if isSuperAdmin(); }
    match /posts/{postId} { allow read: if isAuthenticated(); allow create: if isAuthenticated(); allow update: if isAuthenticated() && (isOwner(resource.data.authorId) || isModerator()); allow delete: if isAuthenticated() && (isOwner(resource.data.authorId) || isModerator()); match /reactions/{reactionId} { allow read: if isAuthenticated(); allow write: if isAuthenticated(); } }
    match /comments/{commentId} { allow read: if isAuthenticated(); allow create: if isAuthenticated(); allow update: if isOwner(resource.data.userId) || isModerator(); allow delete: if isOwner(resource.data.userId) || isModerator(); }
    match /reports/{reportId} { allow read: if isModerator(); allow create: if isAuthenticated(); allow update: if isModerator(); allow delete: if isModerator(); }
    match /user_profiles/{userId} { allow read: if isAuthenticated(); allow write: if isOwner(userId); }
    match /bookmarks/{bookmarkId} { allow read: if isAuthenticated() && isOwner(resource.data.userId); allow write: if isAuthenticated() && isOwner(resource.data.userId); allow delete: if isAuthenticated() && isOwner(resource.data.userId); }
    match /user_activity/{activityId} { allow read: if isAuthenticated() && (isOwner(resource.data.userId) || isSuperAdmin()); allow create: if isAuthenticated(); allow update: if false; allow delete: if isSuperAdmin(); }
    match /app_config/{configId} { allow read: if isAuthenticated(); allow write: if isSuperAdmin(); }
    match /user_settings/{userId} { allow read: if isAuthenticated() && isOwner(userId); allow write: if isAuthenticated() && isOwner(userId); }
    match /threads/{threadId} { allow read: if isAuthenticated(); allow create: if isAuthenticated(); allow update: if isAuthenticated() && (isOwner(resource.data.creatorId) || isModerator()); allow delete: if isOwner(resource.data.creatorId) || isModerator(); match /replies/{replyId} { allow read: if isAuthenticated(); allow create: if isAuthenticated(); allow update: if isOwner(resource.data.userId) || isModerator(); allow delete: if isOwner(resource.data.userId) || isModerator(); } }
    match /tags/{tagId} { allow read: if isAuthenticated(); allow write: if isSuperAdmin(); }
    match /categories/{categoryId} { allow read: if isAuthenticated(); allow write: if isSuperAdmin(); }
    match /search_index/{docId} { allow read: if isAuthenticated(); allow write: if isSuperAdmin(); }
    match /statistics/{statId} { allow read: if isModerator(); allow write: if isSuperAdmin(); }
    match /invitations/{inviteId} { allow read: if isAuthenticated(); allow create: if isAuthenticated(); allow update: if isAuthenticated(); allow delete: if isOwner(resource.data.senderId) || isOwner(resource.data.recipientId); }
    match /{document=**} { allow read, write: if false; }
  }
}"""

# Storage Rules (komplett, minified)
STORAGE_RULES = """rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function isAuthenticated() { return request.auth != null; }
    function isOwner(userId) { return request.auth.uid == userId; }
    function isSuperAdmin() { return firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'super_admin'; }
    function isModerator() { return firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role in ['super_admin', 'moderator']; }
    function isImage() { return request.resource.contentType.matches('image/.*'); }
    function isAudio() { return request.resource.contentType.matches('audio/.*'); }
    function isVideo() { return request.resource.contentType.matches('video/.*'); }
    function isValidImageSize() { return request.resource.size < 10 * 1024 * 1024; }
    function isValidAudioSize() { return request.resource.size < 5 * 1024 * 1024; }
    function isValidVideoSize() { return request.resource.size < 50 * 1024 * 1024; }
    function isValidDocumentSize() { return request.resource.size < 20 * 1024 * 1024; }
    match /profile_images/{userId}/{fileName} { allow read: if true; allow write: if isAuthenticated() && isOwner(userId) && isImage() && isValidImageSize(); allow delete: if isAuthenticated() && (isOwner(userId) || isModerator()); }
    match /chat_images/{chatRoomId}/{fileName} { allow read: if isAuthenticated(); allow write: if isAuthenticated() && isImage() && isValidImageSize(); allow delete: if isAuthenticated() || isModerator(); }
    match /voice_messages/{chatRoomId}/{fileName} { allow read: if isAuthenticated(); allow write: if isAuthenticated() && isAudio() && isValidAudioSize(); allow delete: if isAuthenticated() || isModerator(); }
    match /post_images/{postId}/{fileName} { allow read: if true; allow write: if isAuthenticated() && isImage() && isValidImageSize(); allow delete: if isAuthenticated() || isModerator(); }
    match /category_images/{categoryId}/{fileName} { allow read: if true; allow write: if isSuperAdmin() && isImage() && isValidImageSize(); allow delete: if isSuperAdmin(); }
    match /videos/{userId}/{fileName} { allow read: if isAuthenticated(); allow write: if isAuthenticated() && isOwner(userId) && isVideo() && isValidVideoSize(); allow delete: if isAuthenticated() && (isOwner(userId) || isModerator()); }
    match /documents/{userId}/{fileName} { allow read: if isAuthenticated(); allow write: if isAuthenticated() && isOwner(userId) && isValidDocumentSize(); allow delete: if isAuthenticated() && (isOwner(userId) || isModerator()); }
    match /post_attachments/{postId}/{fileName} { allow read: if isAuthenticated(); allow write: if isAuthenticated() && isValidDocumentSize(); allow delete: if isAuthenticated() || isModerator(); }
    match /admin_uploads/{fileName} { allow read: if isAuthenticated(); allow write: if isModerator() && request.resource.size < 50 * 1024 * 1024; allow delete: if isSuperAdmin(); }
    match /backups/{fileName} { allow read: if isSuperAdmin(); allow write: if isSuperAdmin(); allow delete: if isSuperAdmin(); }
    match /temp/{userId}/{fileName} { allow read: if isAuthenticated() && isOwner(userId); allow write: if isAuthenticated() && isOwner(userId) && request.resource.size < 20 * 1024 * 1024; allow delete: if isAuthenticated() && isOwner(userId); }
    match /thumbnails/{resourceId}/{fileName} { allow read: if true; allow write: if isAuthenticated(); allow delete: if isModerator(); }
    match /exports/{userId}/{fileName} { allow read: if isAuthenticated() && isOwner(userId); allow write: if isAuthenticated() && isOwner(userId); allow delete: if isAuthenticated() && isOwner(userId); }
    match /{allPaths=**} { allow read, write: if false; }
  }
}"""

def check_firebase_cli():
    """Check if Firebase CLI is installed"""
    try:
        result = subprocess.run(['firebase', '--version'], 
                              capture_output=True, text=True, check=False)
        if result.returncode == 0:
            print_success(f"Firebase CLI installiert: {result.stdout.strip()}")
            return True
        else:
            print_error("Firebase CLI nicht gefunden")
            return False
    except FileNotFoundError:
        print_error("Firebase CLI nicht installiert")
        print_info("Installiere mit: npm install -g firebase-tools")
        return False

def login_firebase():
    """Login to Firebase"""
    print_info("Prüfe Firebase Login...")
    result = subprocess.run(['firebase', 'login:list'], 
                          capture_output=True, text=True, check=False)
    
    if "No authorized accounts" in result.stdout or result.returncode != 0:
        print_warning("Nicht eingeloggt. Starte Login...")
        subprocess.run(['firebase', 'login'], check=False)
        return True
    else:
        print_success("Bereits bei Firebase eingeloggt")
        return True

def get_project_id():
    """Get Firebase project ID from google-services.json"""
    google_services_path = '/opt/flutter/google-services.json'
    
    if os.path.exists(google_services_path):
        try:
            with open(google_services_path, 'r') as f:
                data = json.load(f)
                project_id = data['project_info']['project_id']
                print_success(f"Project ID gefunden: {project_id}")
                return project_id
        except Exception as e:
            print_error(f"Fehler beim Lesen von google-services.json: {e}")
    
    print_warning("google-services.json nicht gefunden")
    project_id = input(f"{YELLOW}Gib deine Firebase Project ID ein: {RESET}").strip()
    return project_id if project_id else None

def deploy_firestore_rules(project_id):
    """Deploy Firestore rules"""
    print_header("🔥 Deploying Firestore Rules")
    
    # Write rules to temporary file
    rules_file = '/tmp/firestore.rules'
    with open(rules_file, 'w') as f:
        f.write(FIRESTORE_RULES)
    
    print_info(f"Rules geschrieben nach: {rules_file}")
    
    # Deploy using Firebase CLI
    cmd = ['firebase', 'deploy', '--only', 'firestore:rules', '--project', project_id]
    
    print_info(f"Führe aus: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd='/tmp', capture_output=True, text=True)
    
    if result.returncode == 0:
        print_success("Firestore Rules erfolgreich deployed!")
        return True
    else:
        print_error(f"Firestore Rules deployment fehlgeschlagen: {result.stderr}")
        return False

def deploy_storage_rules(project_id):
    """Deploy Storage rules"""
    print_header("📁 Deploying Storage Rules")
    
    # Write rules to temporary file
    rules_file = '/tmp/storage.rules'
    with open(rules_file, 'w') as f:
        f.write(STORAGE_RULES)
    
    print_info(f"Rules geschrieben nach: {rules_file}")
    
    # Deploy using Firebase CLI
    cmd = ['firebase', 'deploy', '--only', 'storage', '--project', project_id]
    
    print_info(f"Führe aus: {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd='/tmp', capture_output=True, text=True)
    
    if result.returncode == 0:
        print_success("Storage Rules erfolgreich deployed!")
        return True
    else:
        print_error(f"Storage Rules deployment fehlgeschlagen: {result.stderr}")
        return False

def save_rules_locally():
    """Save rules to local files for manual deployment"""
    print_header("💾 Speichere Rules lokal")
    
    # Create rules directory
    rules_dir = '/home/user/firebase_rules'
    os.makedirs(rules_dir, exist_ok=True)
    
    # Save Firestore rules
    with open(f'{rules_dir}/firestore.rules', 'w') as f:
        f.write(FIRESTORE_RULES)
    print_success(f"Firestore Rules gespeichert: {rules_dir}/firestore.rules")
    
    # Save Storage rules
    with open(f'{rules_dir}/storage.rules', 'w') as f:
        f.write(STORAGE_RULES)
    print_success(f"Storage Rules gespeichert: {rules_dir}/storage.rules")
    
    # Create firebase.json for manual deployment
    firebase_json = {
        "firestore": {
            "rules": "firestore.rules"
        },
        "storage": {
            "rules": "storage.rules"
        }
    }
    
    with open(f'{rules_dir}/firebase.json', 'w') as f:
        json.dump(firebase_json, f, indent=2)
    print_success(f"firebase.json erstellt: {rules_dir}/firebase.json")
    
    print_info(f"\n📋 Manuelle Deployment-Anleitung:")
    print(f"   1. cd {rules_dir}")
    print(f"   2. firebase login")
    print(f"   3. firebase deploy --only firestore:rules,storage")
    
    return rules_dir

def main():
    """Main function"""
    print_header("🚀 Automatisches Firebase Rules Setup")
    print_info("Dieses Script setzt ALLE Firebase Rules automatisch")
    
    # Method 1: Try automatic deployment via Firebase CLI
    if check_firebase_cli():
        print_info("\n✅ Firebase CLI gefunden - Automatisches Deployment möglich!")
        
        if login_firebase():
            project_id = get_project_id()
            
            if project_id:
                print_info(f"\n🎯 Target Project: {project_id}")
                confirm = input(f"{YELLOW}Möchtest du die Rules jetzt deployen? (y/n): {RESET}").lower()
                
                if confirm == 'y':
                    firestore_ok = deploy_firestore_rules(project_id)
                    storage_ok = deploy_storage_rules(project_id)
                    
                    if firestore_ok and storage_ok:
                        print_header("🎉 ERFOLG!")
                        print_success("Alle Firebase Rules wurden erfolgreich deployed!")
                        print_info("\n📊 Nächste Schritte:")
                        print("   1. Gehe zu Firebase Console")
                        print("   2. Prüfe Firestore Database → Rules")
                        print("   3. Prüfe Storage → Rules")
                        print("   4. Teste deine App!")
                        return 0
                    else:
                        print_warning("Einige Rules konnten nicht deployed werden")
    
    # Method 2: Save rules locally for manual deployment
    print_header("📦 Alternative: Lokales Speichern")
    rules_dir = save_rules_locally()
    
    print_header("📋 Manuelle Installation")
    print_info("Da automatisches Deployment nicht möglich, nutze diese Anleitung:\n")
    print(f"{YELLOW}Option A: Via Firebase CLI{RESET}")
    print(f"   1. cd {rules_dir}")
    print(f"   2. firebase login")
    print(f"   3. firebase deploy --only firestore:rules,storage\n")
    
    print(f"{YELLOW}Option B: Via Firebase Console (Copy & Paste){RESET}")
    print("   1. Firestore: Kopiere Inhalt von firestore.rules")
    print("   2. Storage: Kopiere Inhalt von storage.rules")
    print("   3. Füge in Firebase Console ein\n")
    
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print_warning("\n\nAbgebrochen durch Benutzer")
        sys.exit(1)
    except Exception as e:
        print_error(f"\nUnerwarteter Fehler: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
