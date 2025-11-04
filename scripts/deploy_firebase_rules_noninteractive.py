#!/usr/bin/env python3
"""
Vollautomatisches Firebase Rules Deployment (Non-Interactive)
Deployed ALLE Firestore und Storage Rules ohne Benutzerinteraktion
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
    print(f"\n{BLUE}{'=' * 60}{RESET}")
    print(f"{BLUE}{text}{RESET}")
    print(f"{BLUE}{'=' * 60}{RESET}\n")

def print_success(text):
    print(f"{GREEN}✅ {text}{RESET}")

def print_error(text):
    print(f"{RED}❌ {text}{RESET}")

def print_warning(text):
    print(f"{YELLOW}⚠️  {text}{RESET}")

def print_info(text):
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
            return None
    
    print_error("google-services.json nicht gefunden unter /opt/flutter/")
    return None

def create_firebase_json(work_dir):
    """Create firebase.json configuration"""
    firebase_config = {
        "firestore": {
            "rules": "firestore.rules"
        },
        "storage": {
            "rules": "storage.rules"
        }
    }
    
    config_path = os.path.join(work_dir, 'firebase.json')
    with open(config_path, 'w') as f:
        json.dump(firebase_config, f, indent=2)
    
    print_success(f"firebase.json erstellt: {config_path}")
    return config_path

def deploy_rules(project_id):
    """Deploy all Firebase rules automatically"""
    print_header("🚀 Vollautomatisches Firebase Rules Deployment")
    
    # Create working directory
    work_dir = '/tmp/firebase_rules_deploy'
    os.makedirs(work_dir, exist_ok=True)
    
    # Write Firestore rules
    firestore_rules_path = os.path.join(work_dir, 'firestore.rules')
    with open(firestore_rules_path, 'w') as f:
        f.write(FIRESTORE_RULES)
    print_success(f"Firestore Rules geschrieben: {firestore_rules_path}")
    
    # Write Storage rules
    storage_rules_path = os.path.join(work_dir, 'storage.rules')
    with open(storage_rules_path, 'w') as f:
        f.write(STORAGE_RULES)
    print_success(f"Storage Rules geschrieben: {storage_rules_path}")
    
    # Create firebase.json
    create_firebase_json(work_dir)
    
    print_info(f"\n🎯 Deploying zu Project: {project_id}")
    
    # Try to deploy using Firebase CLI with CI token (non-interactive)
    try:
        # First, check if already logged in
        list_result = subprocess.run(
            ['firebase', 'login:list'],
            capture_output=True,
            text=True,
            cwd=work_dir
        )
        
        if list_result.returncode != 0 or "No authorized accounts" in list_result.stdout:
            print_warning("Nicht bei Firebase eingeloggt")
            print_info("Verwende 'firebase login:ci' für non-interactive deployment")
            print_info("Oder führe manuell aus: firebase login")
            
            # Save rules locally as fallback
            save_rules_locally()
            return False
        
        print_success("Firebase Authentifizierung gefunden")
        
        # Deploy Firestore rules
        print_info("\n🔥 Deploying Firestore Rules...")
        firestore_result = subprocess.run(
            ['firebase', 'deploy', '--only', 'firestore:rules', '--project', project_id, '--non-interactive'],
            capture_output=True,
            text=True,
            cwd=work_dir,
            timeout=60
        )
        
        if firestore_result.returncode == 0:
            print_success("✅ Firestore Rules erfolgreich deployed!")
        else:
            print_error(f"❌ Firestore Rules deployment fehlgeschlagen:")
            print(firestore_result.stderr)
        
        # Deploy Storage rules
        print_info("\n📁 Deploying Storage Rules...")
        storage_result = subprocess.run(
            ['firebase', 'deploy', '--only', 'storage', '--project', project_id, '--non-interactive'],
            capture_output=True,
            text=True,
            cwd=work_dir,
            timeout=60
        )
        
        if storage_result.returncode == 0:
            print_success("✅ Storage Rules erfolgreich deployed!")
        else:
            print_error(f"❌ Storage Rules deployment fehlgeschlagen:")
            print(storage_result.stderr)
        
        if firestore_result.returncode == 0 and storage_result.returncode == 0:
            print_header("🎉 DEPLOYMENT ERFOLGREICH!")
            print_success("Alle Firebase Rules wurden deployed!")
            print_info("\n📊 Nächste Schritte:")
            print("   1. Gehe zu Firebase Console: https://console.firebase.google.com/")
            print(f"   2. Wähle Projekt: {project_id}")
            print("   3. Prüfe Firestore Database → Rules")
            print("   4. Prüfe Storage → Rules")
            print("   5. Teste deine App!")
            return True
        else:
            print_warning("\n⚠️  Einige Rules konnten nicht deployed werden")
            save_rules_locally()
            return False
            
    except subprocess.TimeoutExpired:
        print_error("Deployment Timeout - Firebase CLI reagiert nicht")
        save_rules_locally()
        return False
    except Exception as e:
        print_error(f"Deployment Fehler: {e}")
        save_rules_locally()
        return False

def save_rules_locally():
    """Save rules locally for manual deployment"""
    print_header("💾 Speichere Rules lokal (Fallback)")
    
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
    
    # Create firebase.json
    firebase_config = {
        "firestore": {
            "rules": "firestore.rules"
        },
        "storage": {
            "rules": "storage.rules"
        }
    }
    
    with open(f'{rules_dir}/firebase.json', 'w') as f:
        json.dump(firebase_config, f, indent=2)
    print_success(f"firebase.json erstellt: {rules_dir}/firebase.json")
    
    print_info(f"\n📋 Manuelle Deployment-Optionen:")
    print(f"\n{YELLOW}Option A: Via Firebase CLI{RESET}")
    print(f"   1. cd {rules_dir}")
    print(f"   2. firebase login")
    print(f"   3. firebase deploy --only firestore:rules,storage")
    
    print(f"\n{YELLOW}Option B: Via Firebase Console{RESET}")
    print("   1. Öffne: https://console.firebase.google.com/")
    print("   2. Firestore: Kopiere firestore.rules → Veröffentlichen")
    print("   3. Storage: Kopiere storage.rules → Veröffentlichen")
    
    return rules_dir

def main():
    """Main function"""
    print_header("🚀 Firebase Rules Auto-Deployment")
    print_info("Vollautomatisches Deployment ohne Benutzerinteraktion\n")
    
    # Get project ID
    project_id = get_project_id()
    
    if not project_id:
        print_error("Konnte Project ID nicht ermitteln")
        print_info("Speichere Rules lokal für manuelles Deployment")
        save_rules_locally()
        return 1
    
    # Try automatic deployment
    success = deploy_rules(project_id)
    
    if success:
        return 0
    else:
        print_warning("\n⚠️  Automatisches Deployment nicht möglich")
        print_info("Rules wurden lokal gespeichert für manuelles Deployment")
        return 1

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
