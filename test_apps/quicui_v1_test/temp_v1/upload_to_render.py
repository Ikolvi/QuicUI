#!/usr/bin/env python3
"""Upload patch file to Render backend using base64-encoded JSON upload."""

import base64
import hashlib
import json
import sys
import urllib.request
import urllib.error
import ssl

def upload_patch(patch_file):
    """Upload patch file to backend using base64 encoding."""
    
    # Read the patch file
    with open(patch_file, 'rb') as f:
        patch_data = f.read()
    
    print(f"Patch file size: {len(patch_data)} bytes ({len(patch_data)/1024/1024:.2f} MB)")
    
    # Calculate hash
    file_hash = hashlib.sha256(patch_data).hexdigest()
    print(f"SHA-256 hash: {file_hash}")
    
    # Base64 encode
    file_data_base64 = base64.b64encode(patch_data).decode('utf-8')
    print(f"Base64 encoded size: {len(file_data_base64)} bytes ({len(file_data_base64)/1024/1024:.2f} MB)")
    
    # Create JSON payload
    payload = {
        'patchId': 'patch-v2.0.0',
        'version': '2.0.0',
        'appId': 'com.quicui.quicui_v1_test',
        'compression': 'xz',
        'size': len(patch_data),
        'hash': file_hash,
        'fileData': file_data_base64
    }
    
    url = 'https://quicui-backend.onrender.com/api/v1/patches/upload'
    
    print(f"\nUploading to {url}...")
    try:
        # Create SSL context that doesn't verify certificates (for testing)
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        
        # Create request
        req = urllib.request.Request(
            url,
            data=json.dumps(payload).encode('utf-8'),
            headers={'Content-Type': 'application/json'},
            method='POST'
        )
        
        # Send request
        with urllib.request.urlopen(req, timeout=60, context=ctx) as response:
            response_data = response.read().decode('utf-8')
            print(f"Status: {response.status}")
            print(f"Response: {response_data}")
            return response.status == 200
    except urllib.error.HTTPError as e:
        print(f"HTTP Error {e.code}: {e.reason}")
        print(f"Response: {e.read().decode('utf-8')}")
        return False
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python3 upload_to_render.py <patch_file>")
        sys.exit(1)
    
    patch_file = sys.argv[1]
    success = upload_patch(patch_file)
    sys.exit(0 if success else 1)
