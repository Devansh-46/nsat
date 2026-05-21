#!/usr/bin/env python3
"""
setup_admin.py — Create the first Firebase admin user and set custom claims.

Prerequisites:
  1. pip install firebase-admin
  2. Place your Firebase service account key as serviceAccountKey.json in this directory
  3. Set ADMIN_EMAIL and ADMIN_PASS environment variables, or pass them as arguments

Usage:
  python setup_admin.py <admin_email> <admin_password>
  
  Or with env vars:
  ADMIN_EMAIL=admin@niu.edu.in ADMIN_PASS=securepassword python setup_admin.py
"""

import sys
import os
import firebase_admin
from firebase_admin import credentials, auth

SERVICE_ACCOUNT_PATH = os.path.join(os.path.dirname(__file__), "serviceAccountKey.json")


def setup_admin(email: str, password: str) -> None:
    """Create a Firebase Auth user with admin custom claims."""
    
    if not os.path.exists(SERVICE_ACCOUNT_PATH):
        print(f"ERROR: Service account key not found at {SERVICE_ACCOUNT_PATH}")
        print("Download it from Firebase Console > Project Settings > Service Accounts")
        sys.exit(1)
    
    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    
    # Avoid re-initializing if already done
    try:
        app = firebase_admin.get_app()
    except ValueError:
        app = firebase_admin.initialize_app(cred)
    
    try:
        # Check if user already exists
        try:
            user = auth.get_user_by_email(email)
            print(f"User {email} already exists (UID: {user.uid})")
            uid = user.uid
        except auth.UserNotFoundError:
            # Create new user
            user = auth.create_user(
                email=email,
                password=password,
                display_name="NIU Administrator",
            )
            uid = user.uid
            print(f"Created new user: {email} (UID: {uid})")
        
        # Set admin custom claim
        auth.set_custom_user_claims(uid, {"admin": True})
        print(f"Admin claim set for {email}")
        
        # Verify
        user = auth.get_user(uid)
        print(f"Custom claims: {user.custom_claims}")
        print("\n✅ Setup complete! Admin can now sign in via the app.")
        
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) == 3:
        email = sys.argv[1]
        password = sys.argv[2]
    else:
        email = os.environ.get("ADMIN_EMAIL")
        password = os.environ.get("ADMIN_PASS")
        
        if not email or not password:
            print("Usage: python setup_admin.py <admin_email> <admin_password>")
            print("   or: ADMIN_EMAIL=... ADMIN_PASS=... python setup_admin.py")
            sys.exit(1)
    
    setup_admin(email, password)
