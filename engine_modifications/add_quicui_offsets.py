#!/usr/bin/env python3
"""
Script to add QuicUI stub offsets to runtime_offsets_extracted.h

The QuicUI stubs are added at the END of CACHED_VM_STUBS_LIST, so their
offsets are after call_native_through_safepoint_stub_offset.

For 32-bit archs: CodePtr = 4 bytes
For 64-bit archs: CodePtr = 8 bytes
"""

import re
import sys

def add_quicui_offsets(input_file, output_file):
    with open(input_file, 'r') as f:
        content = f.read()
    
    lines = content.split('\n')
    new_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        new_lines.append(line)
        
        # Look for call_native_through_safepoint_stub_offset and add QuicUI after it
        if 'Thread_call_native_through_safepoint_stub_offset' in line and '=' in line:
            # Extract the offset value
            match = re.search(r'= (0x[0-9a-fA-F]+);', line)
            if match:
                base_offset = int(match.group(1), 16)
                
                # Determine pointer size based on offset value
                # 32-bit archs have offsets around 0xf4 (244), 64-bit around 0x1e8 (488) or 0x1f0 (496)
                if base_offset < 0x180:  # 32-bit
                    ptr_size = 4
                else:  # 64-bit
                    ptr_size = 8
                
                # Calculate new offsets (after call_native_through_safepoint_stub)
                quicui_interpreter_offset = base_offset + ptr_size
                quicui_dispatch_offset = quicui_interpreter_offset + ptr_size
                
                # Check if this is an AOT offset
                prefix = "AOT_" if "AOT_Thread" in line else ""
                
                # Add QuicUI offset lines
                new_lines.append(f"static constexpr dart::compiler::target::word")
                new_lines.append(f"    {prefix}Thread_quicui_interpreter_entry_stub_offset = 0x{quicui_interpreter_offset:x};")
                new_lines.append(f"static constexpr dart::compiler::target::word")
                new_lines.append(f"    {prefix}Thread_quicui_dispatch_stub_offset = 0x{quicui_dispatch_offset:x};")
        
        i += 1
    
    with open(output_file, 'w') as f:
        f.write('\n'.join(new_lines))
    
    print(f"Added QuicUI offsets to {output_file}")

if __name__ == "__main__":
    input_file = "/Users/admin/Documents/quicui2/engine_modifications/cleaned_files/runtime_offsets_extracted.h"
    output_file = "/Users/admin/Documents/quicui2/engine_modifications/cleaned_files/runtime_offsets_extracted.h"
    add_quicui_offsets(input_file, output_file)
