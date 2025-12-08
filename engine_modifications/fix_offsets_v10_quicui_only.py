#!/usr/bin/env python3
"""
V10: ONLY add QuicUI entries, do NOT shift any other offsets.
This is a minimal change to test if the build works with just the new entries.
"""

import re

def parse_offset_value(text):
    match = re.search(r'= (0x[0-9a-fA-F]+);', text)
    if match:
        return int(match.group(1), 16)
    match = re.search(r'(0x[0-9a-fA-F]+);', text)
    if match:
        return int(match.group(1), 16)
    return None

def format_offset_value(value):
    return f'0x{value:x}'

def get_prefix(text):
    if 'AOT_Thread_' in text:
        return 'AOT_Thread_'
    elif 'Thread_' in text:
        return 'Thread_'
    return None

def process_file(input_file, output_file):
    with open(input_file, 'r') as f:
        content = f.read()
    
    lines = content.split('\n')
    result = []
    quicui_inserted = 0
    ptr_size = 8
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Detect architecture for pointer size
        if '#if defined(TARGET_ARCH_' in line:
            if 'ARM)' in line or 'IA32)' in line or 'RISCV32)' in line:
                ptr_size = 4
            else:
                ptr_size = 8
        
        # Handle QuicUI insertion after call_native_through_safepoint_stub_offset
        if 'call_native_through_safepoint_stub_offset' in line and '_entry_point_offset' not in line:
            prefix = get_prefix(line)
            if prefix:
                if '=' in line and ';' in line:
                    # Single line format
                    stub_offset = parse_offset_value(line)
                    result.append(line)
                else:
                    # Multi-line - value on next line
                    result.append(line)
                    i += 1
                    next_line = lines[i]
                    result.append(next_line)
                    stub_offset = parse_offset_value(next_line)
                
                if stub_offset is not None:
                    # Calculate QuicUI offsets - they come right after call_native_through_safepoint_stub
                    quicui1_offset = stub_offset + ptr_size
                    quicui2_offset = quicui1_offset + ptr_size
                    
                    result.append(f'static constexpr dart::compiler::target::word')
                    result.append(f'    {prefix}quicui_interpreter_entry_stub_offset = {format_offset_value(quicui1_offset)};')
                    result.append(f'static constexpr dart::compiler::target::word')
                    result.append(f'    {prefix}quicui_dispatch_stub_offset = {format_offset_value(quicui2_offset)};')
                    quicui_inserted += 1
                i += 1
                continue
        
        result.append(line)
        i += 1
    
    with open(output_file, 'w') as f:
        f.write('\n'.join(result))
    
    return quicui_inserted

if __name__ == '__main__':
    input_file = "/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart/runtime/vm/compiler/runtime_offsets_extracted.h"
    output_file = input_file
    
    quicui_count = process_file(input_file, output_file)
    print(f"Processed {input_file}")
    print(f"  - Inserted QuicUI entries at {quicui_count} locations (no offset shifting)")
