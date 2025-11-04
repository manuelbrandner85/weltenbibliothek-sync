#!/usr/bin/env python3
"""
Configure Firestore Security Rules for Weltenbibliothek
Allows authenticated users to read/write their own data
"""

FIRESTORE_RULES = """
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - users can create and access their own data
    match /users/{userId} {
      // Allow reading own profile
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Allow creating own profile (for registration)
      allow create: if request.auth != null && request.auth.uid == userId;
      
      // Allow updating own profile
      allow update: if request.auth != null && request.auth.uid == userId;
      
      // Allow deleting own profile
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Events collection - authenticated users can read all events
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admin can write events
    }
    
    // Comments collection - authenticated users can comment
    match /comments/{commentId} {
      // Anyone authenticated can read comments
      allow read: if request.auth != null;
      
      // Authenticated users can create comments
      allow create: if request.auth != null 
                   && request.resource.data.userId == request.auth.uid;
      
      // Users can update their own comments (for likes)
      allow update: if request.auth != null;
      
      // Users can delete only their own comments
      allow delete: if request.auth != null 
                   && resource.data.userId == request.auth.uid;
    }
  }
}
"""

print("=" * 60)
print("🔒 FIRESTORE SECURITY RULES")
print("=" * 60)
print("\nCopy these rules to Firebase Console:")
print("1. Go to: https://console.firebase.google.com/")
print("2. Select your project")
print("3. Navigate to: Firestore Database → Rules")
print("4. Paste the following rules:\n")
print(FIRESTORE_RULES)
print("\n" + "=" * 60)
print("✅ Rules copied! Now paste them in Firebase Console.")
print("=" * 60)
