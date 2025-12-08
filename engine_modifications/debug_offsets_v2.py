#!/usr/bin/env python3
"""
Debug version - prints info for specific lines
"""

import re

def parse_offset_value(line):
    match = re.search(r'= (0x[0-9a-fA-F]+);', line)
    if match:
        return int(match.group(1), 16)
    return None

def format_offset_value(value):
    return f'0x{value:x}'

def get_prefix_for_line(line):
    if 'AOT_Thread_' in line:
        return 'AOT_Thread_'
    elif 'Thread_' in line:
        return 'Thread_'
    return None

STUB_SUFFIXES_NO_SHIFT = [
    'fix_callers_target_code_offset',
    'fix_allocation_stub_code_offset',
    'invoke_dart_code_stub_offset',
    'invoke_dart_code_from_bytecode_stub_offset',
    'call_to_runtime_stub_offset',
    'call_native_through_safepoint_stub_offset',
]

NON_VM_STUB_SUFFIXES_NO_SHIFT = ['object_null_offset']
EARLY_FIELDS_NO_SHIFT = ['stack_limit_offset']

def should_shift(line, prefix):
    for suffix in STUB_SUFFIXES_NO_SHIFT:
        if f'{prefix}{suffix}' in line:
            return False
    for suffix in NON_VM_STUB_SUFFIXES_NO_SHIFT:
        if f'{prefix}{suffix}' in line:
            return False
    for suffix in EARLY_FIELDS_NO_SHIFT:
        if f'{prefix}{suffix}' in line:
            return False
    return True

input_path = '/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart/runtime/vm/compiler/runtime_offsets_extracted.h'

with open(input_path, 'r') as f:
    lines = f.readlines()

result = []
i = 0
current_ptr_size = 8
insertion_count = 0
shift_count = 0
debug_lines = [13389, 18957]  # Line numbers with 0x6b0

while i < len(lines):
    line = lines[i]
    line_num = i + 1
    
    # Detect architecture
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
    
    shift_amount = current_ptr_size * 2
    
    # Debug output for specific lines
    if line_num in debug_lines:
        print(f'DEBUG Line {line_num}: {line.strip()[:60]}')
    
    # Check if this is the insertion point
    if 'call_native_through_safepoint_stub_offset' in line and '=' in line:
        prefix = get_prefix_for_line(line)
        if prefix:
            if line_num in debug_lines:
                print(f'  -> Insertion point detected, skipping shift check')
            result.append(line)
            
            base_offset = parse_offset_value(line)
            if base_offset is not None:
                quicui_interp_offset = base_offset + current_ptr_size
                quicui_dispatch_offset = base_offset + (current_ptr_size * 2)
                quicui_lines = f'''static constexpr dart::compiler::target::word
    {prefix}quicui_interpreter_entry_stub_offset = {format_offset_value(quicui_interp_offset)};
static constexpr dart::compiler::target::word
    {prefix}quicui_dispatch_stub_offset = {format_offset_value(quicui_dispatch_offset)};
'''
                result.append(quicui_lines)
                insertion_count += 1
            
            i += 1
            continue
    
    # Check if this is a Thread offset that needs to be shifted
    prefix = get_prefix_for_line(line)
    
    if line_num in debug_lines:
        has_offset = '_offset' in line
        has_eq = '=' in line
        print(f'  prefix={prefix}, _offset in line={has_offset}, = in line={has_eq}')
    
    if prefix and '_offset' in line and '=' in line:
        ss = should_shift(line, prefix)
        if line_num in debug_lines:
            print(f'  should_shift={ss}')
        if ss:
            old_value = parse_offset_value(line)
            if old_value is not None:
                new_value = old_value + shift_amount
                new_line = re.sub(r'= 0x[0-9a-fA-F]+;', f'= {format_offset_value(new_value)};', line)
                if line_num in debug_lines:
                    print(f'  Shifting from 0x{old_value:x} to 0x{new_value:x}')
                result.append(new_line)
                shift_count += 1
                i += 1
                continue
    
    result.append(line)
    i += 1

print(f'\nInserted QuicUI entries at {insertion_count} locations')
print(f'Shifted {shift_count} offset values')

# Write file
output_path = '/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart/runtime/vm/compiler/runtime_offsets_extracted.h'
with open(output_path, 'w') as f:
    f.writelines(result)
print(f'Wrote to {output_path}')
