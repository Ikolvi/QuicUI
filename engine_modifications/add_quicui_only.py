#!/usr/bin/env python3
"""
Script to add QuicUI entries to runtime_offsets_extracted.h.

The key insight is that runtime_offsets_extracted.h contains EXPECTED offset values.
When we add QuicUI entries to thread.h (the actual Thread struct), the compiler
will automatically compute the new offsets for subsequent fields.

So we ONLY need to:
1. Insert QuicUI offset entries with correct values (after call_native_through_safepoint)
2. NOT shift other offsets - they will be checked against computed values from thread.h

Wait, that's still wrong. Let me re-think this:

The runtime_offsets_extracted.h contains PRE-COMPUTED values that MUST match what the 
C++ compiler computes from the actual struct definitions.

When we add 2 new fields (QuicUI stubs) to the Thread struct in thread.h:
- All fields AFTER those new fields will have their offsets shifted by 2*ptr_size
- The runtime_offsets_extracted.h MUST have the updated offset values

So we DO need to shift the offsets. But the error shows we shifted too much!

Actually wait - looking at the error more carefully:
- Thread::active_exception_offset() got 1728 (computed from thread.h)
- Thread_active_exception_offset expected 1712 (from runtime_offsets_extracted.h)
- The computed value (1728) is 16 bytes MORE than expected (1712)

This means the thread.h HAS the QuicUI entries (causing +16 shift in computed values),
but the runtime_offsets_extracted.h does NOT have shifted values.

But I DID shift them! Let me check if the shift was applied correctly...

Actually, I think the problem is that I shifted the WRONG direction or the 
thread.h doesn't actually have the QuicUI entries in the right place!

Let me verify thread.h first.
"""

import re
import sys

def parse_offset_value(line):
    """Extract hex offset value from a line."""
    match = re.search(r'= (0x[0-9a-fA-F]+);', line)
    if match:
        return int(match.group(1), 16)
    return None

def format_offset_value(value):
    """Format offset value as hex string."""
    return f'0x{value:x}'

def get_prefix_for_line(line):
    """Determine if line uses AOT_ prefix or not."""
    if 'AOT_Thread_' in line:
        return 'AOT_Thread_'
    elif 'Thread_' in line:
        return 'Thread_'
    return None

def process_file(input_path, output_path):
    with open(input_path, 'r') as f:
        lines = f.readlines()
    
    result = []
    i = 0
    
    # Track which architecture section we're in to determine pointer size
    current_ptr_size = 8  # Default
    insertion_count = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Detect architecture to determine pointer size
        if 'defined(TARGET_ARCH_ARM)' in line and 'ARM64' not in line:
            current_ptr_size = 4
        elif 'defined(TARGET_ARCH_IA32)' in line:
            current_ptr_size = 4
        elif 'defined(TARGET_ARCH_ARM64)' in line:
            current_ptr_size = 8
        elif 'defined(TARGET_ARCH_X64)' in line:
            current_ptr_size = 8
        elif 'defined(TARGET_ARCH_RISCV32)' in line:
            current_ptr_size = 4
        elif 'defined(TARGET_ARCH_RISCV64)' in line:
            current_ptr_size = 8
        
        # Check if this is the insertion point
        if 'call_native_through_safepoint_stub_offset' in line and '=' in line:
            prefix = get_prefix_for_line(line)
            if prefix:
                result.append(line)
                
                base_offset = parse_offset_value(line)
                if base_offset is not None:
                    quicui_interp_offset = base_offset + current_ptr_size
                    quicui_dispatch_offset = base_offset + (current_ptr_size * 2)
                    
                    quicui_lines = f"""static constexpr dart::compiler::target::word
    {prefix}quicui_interpreter_entry_stub_offset = {format_offset_value(quicui_interp_offset)};
static constexpr dart::compiler::target::word
    {prefix}quicui_dispatch_stub_offset = {format_offset_value(quicui_dispatch_offset)};
"""
                    result.append(quicui_lines)
                    insertion_count += 1
                
                i += 1
                continue
        
        result.append(line)
        i += 1
    
    with open(output_path, 'w') as f:
        f.writelines(result)
    
    print(f"Processed {input_path}")
    print(f"  - Inserted QuicUI entries at {insertion_count} locations")
    print(f"  - Did NOT shift other offsets (they should match computed values from thread.h)")

if __name__ == "__main__":
    input_file = "/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart/runtime/vm/compiler/runtime_offsets_extracted.h"
    output_file = input_file
    process_file(input_file, output_file)
