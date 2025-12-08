#!/usr/bin/env python3
"""
V8: Fixed elif chain issue - Case 1 must always continue or append
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

def get_offset_name(text, prefix):
    match = re.search(rf'{prefix}(\w+)', text)
    if match:
        return match.group(1)
    return None

NO_SHIFT_EXACT = {
    # Fields that come BEFORE CACHED_CONSTANTS_LIST (first block in Thread)
    # Use exact name matches to avoid substring issues
    'stack_limit_offset',
    'write_barrier_mask_offset',
    'heap_base_offset',
    'top_offset',
    'end_offset',
    'dispatch_table_array_offset',
    'field_table_values_offset',
    'shared_field_table_values_offset',
    'top_resource_offset',
    # CACHED_NON_VM_STUB_LIST items (before stubs in CACHED_VM_OBJECTS_LIST)
    'object_null_offset',
    'bool_true_offset',
    'bool_false_offset',
    'empty_array_offset',
    'empty_type_arguments_offset',
    'dynamic_type_offset',
}

SHIFT_FIELDS = {
    'isolate_offset',
    'isolate_group_offset',
    'saved_stack_limit_offset',
    'stack_overflow_flags_offset',
    'top_exit_frame_info_offset',
    'store_buffer_block_offset',
    'old_marking_stack_block_offset',
    'new_marking_stack_block_offset',
    'vm_tag_offset',
    'active_exception_offset',
    'active_stacktrace_offset',
    'global_object_pool_offset',
    'resume_pc_offset',
    'execution_state_offset',
    'safepoint_state_offset',
    'exit_through_ffi_offset',
    'api_top_scope_offset',
    'saved_shadow_call_stack_offset',
    'random_offset',
    'next_task_id_offset',
    'tsan_utils_offset',
    'current_tag_offset',
    'default_tag_offset',
    'user_tag_offset',
    'dart_stream_offset',
    'service_extension_stream_offset',
    'double_truncate_round_supported_offset',
    'single_step_offset',
    'unboxed_runtime_arg_offset',
}

def should_shift_offset(offset_name):
    if '_stub_' in offset_name or '_stub_code_' in offset_name:
        return False
    
    # Use exact match for no-shift fields
    if offset_name in NO_SHIFT_EXACT:
        return False
    
    if '_entry_point_offset' in offset_name or '_entry_offset' in offset_name:
        return True
    
    if '_address_offset' in offset_name:
        return True
        
    if 'predefined_symbols' in offset_name:
        return True
    
    if 'write_barrier_wrappers' in offset_name:
        return True
    
    for field in SHIFT_FIELDS:
        if field in offset_name:
            return True
    
    return False

def process_file(input_file, output_file):
    with open(input_file, 'r') as f:
        content = f.read()
    
    lines = content.split('\n')
    result = []
    quicui_inserted = 0
    shifted_count = 0
    ptr_size = 8
    pending_name = None
    pending_prefix = None
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Detect architecture
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
                    stub_offset = parse_offset_value(line)
                    result.append(line)
                else:
                    result.append(line)
                    i += 1
                    next_line = lines[i]
                    result.append(next_line)
                    stub_offset = parse_offset_value(next_line)
                
                if stub_offset is not None:
                    quicui1_offset = stub_offset + ptr_size
                    quicui2_offset = quicui1_offset + ptr_size
                    
                    result.append(f'static constexpr dart::compiler::target::word')
                    result.append(f'    {prefix}quicui_interpreter_entry_stub_offset = {format_offset_value(quicui1_offset)};')
                    result.append(f'static constexpr dart::compiler::target::word')
                    result.append(f'    {prefix}quicui_dispatch_stub_offset = {format_offset_value(quicui2_offset)};')
                    quicui_inserted += 1
                i += 1
                continue
        
        prefix = get_prefix(line)
        
        # Case 1: Complete single-line declaration with Thread_ prefix
        if prefix and '=' in line and ';' in line:
            offset_name = get_offset_name(line, prefix)
            if offset_name and should_shift_offset(offset_name):
                old_val = parse_offset_value(line)
                if old_val is not None:
                    new_val = old_val + (ptr_size * 2)
                    new_line = re.sub(r'= 0x[0-9a-fA-F]+;', f'= {format_offset_value(new_val)};', line)
                    result.append(new_line)
                    shifted_count += 1
                    i += 1
                    continue
            # Not shifting - just append unchanged
            result.append(line)
            i += 1
            continue
        
        # Case 2: Multi-line declaration - name line (has = but no ;)
        if prefix and '=' in line and ';' not in line:
            offset_name = get_offset_name(line, prefix)
            if offset_name:
                pending_name = offset_name
                pending_prefix = prefix
            result.append(line)
            i += 1
            continue
        
        # Case 3: Multi-line declaration - value line
        if pending_name is not None and ';' in line:
            if should_shift_offset(pending_name):
                old_val = parse_offset_value(line)
                if old_val is not None:
                    new_val = old_val + (ptr_size * 2)
                    new_line = re.sub(r'0x[0-9a-fA-F]+;', f'{format_offset_value(new_val)};', line)
                    result.append(new_line)
                    shifted_count += 1
                    pending_name = None
                    pending_prefix = None
                    i += 1
                    continue
            # Not shifting - just append unchanged
            result.append(line)
            pending_name = None
            pending_prefix = None
            i += 1
            continue
        
        # Default: append line unchanged
        result.append(line)
        i += 1
    
    with open(output_file, 'w') as f:
        f.write('\n'.join(result))
    
    return quicui_inserted, shifted_count

if __name__ == '__main__':
    input_file = "/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart/runtime/vm/compiler/runtime_offsets_extracted.h"
    output_file = input_file
    
    quicui_count, shift_count = process_file(input_file, output_file)
    print(f"Processed {input_file}")
    print(f"  - Inserted QuicUI entries at {quicui_count} locations")
    print(f"  - Shifted {shift_count} offset values")
