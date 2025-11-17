#!/usr/bin/env python3
"""
QuicUI Patch Generator (QUICUI01 format)

Generates patches in QUICUI01 custom format for QuicUI Code Push.
Uses a simple diff algorithm to find changes between old and new files.
"""

import sys
import struct
import hashlib
from pathlib import Path

# Patch format constants
MAGIC = b"QUICUI01"
OP_COPY = 0
OP_ADD = 1

def sha256_file(file_path):
    """Calculate SHA256 hash of a file"""
    sha256 = hashlib.sha256()
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            sha256.update(chunk)
    return sha256.hexdigest()

def find_differences(old_bytes, new_bytes, min_copy_length=32):
    """
    Find differences between old and new bytes.
    Returns list of operations (COPY or ADD).
    
    Simple algorithm:
    - Scan through new_bytes
    - Try to find matching sequences in old_bytes
    - If match found and >= min_copy_length, emit COPY
    - Otherwise, accumulate bytes for ADD operation
    """
    operations = []
    new_pos = 0
    pending_add = bytearray()
    
    while new_pos < len(new_bytes):
        # Try to find a matching sequence in old file
        best_match_offset = -1
        best_match_length = 0
        
        # Search for matches (simple O(n²) algorithm, can be optimized with suffix arrays)
        for old_pos in range(len(old_bytes)):
            # Find how many bytes match
            match_length = 0
            while (new_pos + match_length < len(new_bytes) and
                   old_pos + match_length < len(old_bytes) and
                   new_bytes[new_pos + match_length] == old_bytes[old_pos + match_length]):
                match_length += 1
            
            if match_length > best_match_length:
                best_match_length = match_length
                best_match_offset = old_pos
        
        # If we found a good match, use COPY
        if best_match_length >= min_copy_length:
            # First, flush any pending ADD bytes
            if pending_add:
                operations.append((OP_ADD, 0, len(pending_add), bytes(pending_add)))
                pending_add = bytearray()
            
            # Emit COPY operation
            operations.append((OP_COPY, best_match_offset, best_match_length, None))
            new_pos += best_match_length
        else:
            # No good match, add this byte to pending ADD
            pending_add.append(new_bytes[new_pos])
            new_pos += 1
    
    # Flush any remaining ADD bytes
    if pending_add:
        operations.append((OP_ADD, 0, len(pending_add), bytes(pending_add)))
    
    return operations

def generate_patch(old_file, new_file, patch_file):
    """Generate QUICUI01 format patch"""
    print(f"📝 Generating QUICUI01 patch")
    print(f"   Old file: {old_file}")
    print(f"   New file: {new_file}")
    print(f"   Patch file: {patch_file}")
    print()
    
    # Read files
    print("📖 Reading files...")
    old_bytes = Path(old_file).read_bytes()
    new_bytes = Path(new_file).read_bytes()
    
    old_size = len(old_bytes)
    new_size = len(new_bytes)
    
    print(f"   Old size: {old_size:,} bytes ({old_size/1024/1024:.2f} MB)")
    print(f"   New size: {new_size:,} bytes ({new_size/1024/1024:.2f} MB)")
    print()
    
    # Calculate hashes
    print("🔐 Calculating hashes...")
    old_hash = hashlib.sha256(old_bytes).hexdigest()
    new_hash = hashlib.sha256(new_bytes).hexdigest()
    
    print(f"   Old hash: {old_hash}")
    print(f"   New hash: {new_hash}")
    print()
    
    # Find differences
    print("🔍 Finding differences...")
    operations = find_differences(old_bytes, new_bytes)
    
    print(f"   Operations: {len(operations)}")
    
    # Calculate stats
    copy_ops = sum(1 for op in operations if op[0] == OP_COPY)
    add_ops = sum(1 for op in operations if op[0] == OP_ADD)
    copy_bytes = sum(op[2] for op in operations if op[0] == OP_COPY)
    add_bytes = sum(op[2] for op in operations if op[0] == OP_ADD)
    
    print(f"   COPY operations: {copy_ops} ({copy_bytes:,} bytes)")
    print(f"   ADD operations: {add_ops} ({add_bytes:,} bytes)")
    print()
    
    # Build patch file
    print("📦 Building patch file...")
    patch_data = bytearray()
    
    # Header
    patch_data.extend(MAGIC)  # Magic (8 bytes)
    patch_data.extend(struct.pack('<Q', old_size))  # Old size (int64 little-endian)
    patch_data.extend(struct.pack('<Q', new_size))  # New size (int64 little-endian)
    patch_data.extend(struct.pack('<I', len(operations)))  # Operation count (int32 little-endian)
    patch_data.extend(old_hash.encode('utf-8'))  # Old hash (64 bytes)
    patch_data.extend(new_hash.encode('utf-8'))  # New hash (64 bytes)
    
    # Operations
    for op_type, old_offset, length, data in operations:
        patch_data.append(op_type)  # Type (1 byte)
        patch_data.extend(struct.pack('<Q', old_offset))  # Old offset (int64 little-endian)
        patch_data.extend(struct.pack('<I', length))  # Length (int32 little-endian)
        
        if op_type == OP_ADD and data:
            patch_data.extend(data)  # Data (variable length)
    
    # Write patch file
    Path(patch_file).write_bytes(patch_data)
    
    patch_size = len(patch_data)
    compression_ratio = (1 - patch_size / new_size) * 100
    
    print(f"✅ Patch generated successfully!")
    print(f"   Patch size: {patch_size:,} bytes ({patch_size/1024/1024:.2f} MB)")
    print(f"   Compression: {compression_ratio:.1f}% smaller than new file")
    print(f"   Saved: {patch_file}")
    print()
    
    return patch_file

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 generate_quicui_patch.py <old_file> <new_file> <patch_file>")
        print()
        print("Example:")
        print("  python3 generate_quicui_patch.py \\")
        print("    v1_extracted/lib/arm64-v8a/libapp.so \\")
        print("    v2_extracted/lib/arm64-v8a/libapp.so \\")
        print("    patch_v2.0.0.quicui")
        sys.exit(1)
    
    old_file = sys.argv[1]
    new_file = sys.argv[2]
    patch_file = sys.argv[3]
    
    # Validate files exist
    if not Path(old_file).exists():
        print(f"❌ Error: Old file not found: {old_file}")
        sys.exit(1)
    
    if not Path(new_file).exists():
        print(f"❌ Error: New file not found: {new_file}")
        sys.exit(1)
    
    generate_patch(old_file, new_file, patch_file)
