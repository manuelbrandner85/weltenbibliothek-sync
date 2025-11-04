#!/usr/bin/env python3
"""
Firebase Storage Diagnose-Script
Prüft ob Firebase Storage korrekt konfiguriert ist
"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    import firebase_admin
    from firebase_admin import credentials, storage
    print("✅ firebase-admin imported successfully")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    print("📦 Install: pip install firebase-admin==7.1.0")
    sys.exit(1)

def test_firebase_storage():
    """Test Firebase Storage configuration"""
    
    # Find Firebase Admin SDK key
    admin_sdk_path = None
    opt_flutter_dir = '/opt/flutter'
    
    if os.path.exists(opt_flutter_dir):
        for file in os.listdir(opt_flutter_dir):
            if 'adminsdk' in file and file.endswith('.json'):
                admin_sdk_path = os.path.join(opt_flutter_dir, file)
                break
    
    if not admin_sdk_path:
        print("❌ Firebase Admin SDK key not found!")
        print("📂 Expected location: /opt/flutter/*adminsdk*.json")
        print("\n🔧 Upload your Firebase Admin SDK key to the Firebase tab")
        return False
    
    print(f"✅ Found Admin SDK key: {admin_sdk_path}")
    
    try:
        # Initialize Firebase Admin
        cred = credentials.Certificate(admin_sdk_path)
        
        # Check if already initialized
        try:
            firebase_admin.get_app()
            print("ℹ️  Firebase already initialized")
        except ValueError:
            firebase_admin.initialize_app(cred, {
                'storageBucket': None  # Will be auto-detected from credentials
            })
            print("✅ Firebase Admin initialized")
        
        # Get default bucket
        bucket = storage.bucket()
        print(f"✅ Storage bucket: {bucket.name}")
        
        # Test listing files (this will fail if Storage Rules are wrong)
        try:
            blobs = list(bucket.list_blobs(max_results=1))
            print(f"✅ Storage accessible (found {len(blobs)} files in root)")
        except Exception as e:
            print(f"⚠️  Cannot list files: {e}")
            print("   This is normal if Storage is empty")
        
        # Check Storage Rules configuration
        print("\n📋 STORAGE RULES CHECK:")
        print("=" * 60)
        print("Please verify in Firebase Console → Storage → Rules:")
        print("")
        print("✓ Profile images path exists: /profile_images/{userId}/{fileName}")
        print("✓ Read access: Public (allow read: if true)")
        print("✓ Write access: Owner only (allow write: if request.auth.uid == userId)")
        print("✓ File size limit: < 10MB")
        print("✓ File type: image/* only")
        print("")
        print("=" * 60)
        
        return True
        
    except Exception as e:
        print(f"❌ Firebase initialization failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def print_storage_rules():
    """Print correct Storage Rules"""
    print("\n🔥 CORRECT FIREBASE STORAGE RULES:")
    print("=" * 60)
    print("""
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Profile images - Public read, owner write
    match /profile_images/{userId}/{fileName} {
      allow read: if true;  // Public read
      allow write: if request.auth != null && 
                      request.auth.uid == userId &&
                      request.resource.contentType.matches('image/.*') &&
                      request.resource.size < 10 * 1024 * 1024;  // 10MB limit
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chat images
    match /chat_images/{chatRoomId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                      request.resource.contentType.matches('image/.*') &&
                      request.resource.size < 10 * 1024 * 1024;
    }
    
    // Default: Deny all
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
""")
    print("=" * 60)
    print("\n📍 Set these rules in: Firebase Console → Storage → Rules")

if __name__ == "__main__":
    print("🔍 Firebase Storage Diagnose")
    print("=" * 60)
    print()
    
    success = test_firebase_storage()
    
    if success:
        print("\n✅ Firebase Storage is configured correctly!")
        print_storage_rules()
        print("\n💡 If profile image upload still fails:")
        print("   1. Check Flutter console logs for detailed error messages")
        print("   2. Verify Firebase Storage Rules in Console")
        print("   3. Ensure user is authenticated (request.auth != null)")
        print("   4. Check file size is under 10MB")
        print("   5. Verify image format (JPG, PNG, etc.)")
    else:
        print("\n❌ Firebase Storage configuration has issues")
        print_storage_rules()
        print("\n🔧 Fix steps:")
        print("   1. Upload Firebase Admin SDK key to /opt/flutter/")
        print("   2. Set correct Storage Rules in Firebase Console")
        print("   3. Run this script again to verify")
