#!/usr/bin/env python3
"""
Precise approach: Only shift offsets that come AFTER the CACHED_VM_OBJECTS_LIST
in the Thread struct layout. QuicUI stubs are at the END of CACHED_VM_OBJECTS_LIST.

Things that should NOT be shifted (come before or within the stub array):
- top_offset, end_offset (before cached constants)
- dispatch_table_array_offset, field_table_values_offset, shared_field_table_values_offset (before cached constants)
- All *_stub_offset (part of CACHED_VM_STUBS_LIST, same array as QuicUI)
- bool_true_offset, bool_false_offset, object_null_offset, empty_array_offset, 
  empty_type_arguments_offset, dynamic_type_offset (CACHED_NON_VM_STUB_LIST, before stubs)

Things that SHOULD be shifted (come after CACHED_VM_OBJECTS_LIST):
- All *_entry_point_offset (from CACHED_ADDRESSES_LIST)
- *_address_offset (from CACHED_ADDRESSES_LIST)
- AllocateArray_entry_point_offset (from RUNTIME_ENTRY_LIST)
- write_barrier_wrappers_thread_offset
- suspend_state_*_entry_point_offset (from CACHED_FUNCTION_ENTRY_POINTS_LIST)
- isolate_offset, isolate_group_offset, saved_stack_limit_offset, etc. (after cached constants)
- active_exception_offset, active_stacktrace_offset, etc.
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

# Offsets that should NOT be shifted - they come BEFORE or ARE PART OF the cached objects array
# This includes all stubs and the cached non-VM stubs
NO_SHIFT_PATTERNS = {
    # Fields that come BEFORE CACHED_CONSTANTS_LIST in Thread class
    'top_offset',
    'end_offset',
    'dispatch_table_array_offset',
    'field_table_values_offset',
    'shared_field_table_values_offset',
    'top_resource_offset',  # At the very start of Thread
    
    # CACHED_NON_VM_STUB_LIST - these come before the VM stubs
    'object_null_offset',
    'bool_true_offset',
    'bool_false_offset',
    'empty_array_offset',
    'empty_type_arguments_offset',
    'dynamic_type_offset',
    
    # All stub offsets - they're part of CACHED_VM_STUBS_LIST, same array QuicUI is added to
    # We identify stubs by having "_stub_" or "_stub_code_" in the name
}

def should_shift_offset(offset_name):
    """
    Determine if this offset should be shifted based on its name.
    We shift offsets that come AFTER the cached objects in Thread layout.
    """
    # Don't shift stubs - they're part of the array QuicUI is added to
    if '_stub_' in offset_name or '_stub_code_' in offset_name:
        return False
    
    # Don't shift known early fields
    for pattern in NO_SHIFT_PATTERNS:
        if pattern in offset_name:
            return False
    
    # Shift entry points - they come after the stubs
    if '_entry_point_offset' in offset_name or '_entry_offset' in offset_name:
        return True
    
    # Shift address offsets - they're in CACHED_ADDRESSES_LIST
    if '_address_offset' in offset_name:
        return True
        
    # Shift predefined_symbols_address_offset
    if 'predefined_symbols' in offset_name:
        return True
    
    # Shift write_barrier_wrappers (comes after CACHED_ADDRESSES_LIST)
    if 'write_barrier_wrappers' in offset_name:
        return True
    
    # Shift these known fields that come after cached constants
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
        'stack_limit_offset',
        'heap_base_offset',
        'write_barrier_mask_offset',
        'unboxed_runtime_arg_offset',
    }
    
    for field in SHIFT_FIELDS:
        if field in offset_name:
            return True
    
    return False

def process_file(input_file, output_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()
    
    result = []
    quicui_inserted = 0
    shifted_count = 0
    ptr_size = 8  # default to 64-bit
    current_arch = ""
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Detect architecture from #if defined(TARGET_ARCH_*)
        if '#if defined(TARGET_ARCH_' in line:
            current_arch = line.strip()
            if 'ARM)' in line or 'IA32)' in line or 'RISCV32)' in line:
                ptr_size = 4
            else:
                ptr_size = 8
        
        # Look for call_native_through_safepoint_stub_offset to insert QuicUI after it
        if 'call_native_through_safepoint_stub_offset' in line and '_entry_point_offset' not in line:
            prefix = get_prefix_for_line(line)
            if prefix:
                # Get the offset value and calculate QuicUI offsets
                stub_offset = parse_offset_value(line)
                if stub_offset is not None:
                    quicui1_offset = stub_offset + ptr_size
                    quicui2_offset = quicui1_offset + ptr_size
                    
                    # Output original line
                    result.append(line)
                    
                    # Insert QuicUI entries
                    result.append(f'static constexpr dart::compiler::target::word\n')
                    result.append(f'    {prefix}quicui_interpreter_entry_stub_offset = {format_offset_value(quicui1_offset)};\n')
                    result.append(f'static constexpr dart::compiler::target::word\n')
                    result.append(f'    {prefix}quicui_dispatch_stub_offset = {format_offset_value(quicui2_offset)};\n')
                    quicui_inserted += 1
                    i += 1
                    continue
        
        # Check if this is a Thread offset line that needs shifting
        prefix = get_prefix_for_line(line)
        if prefix and '=' in line and ';' in line:
            # Extract offset name
            match = re.search(rf'{prefix}(\w+)', line)
            if match:
                offset_name = match.group(1)
                if should_shift_offset(offset_name):
                    old_val = parse_offset_value(line)
                    if old_val is not None:
                        new_val = old_val + (ptr_size * 2)
                        new_line = re.sub(r'= 0x[0-9a-fA-F]+;', f'= {format_offset_value(new_val)};', line)
                        result.append(new_line)
                        shifted_count += 1
                        i += 1
                        continue
        
        result.append(line)
        i += 1
    
    with open(output_file, 'w') as f:
        f.writelines(result)
    
    return quicui_inserted, shifted_count

if __name__ == '__main__':
    input_file = "/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart/runtime/vm/compiler/runtime_offsets_extracted.h"
    output_file = input_file  # overwrite
    
    quicui_count, shift_count = process_file(input_file, output_file)
    print(f"Processed {input_file}")
    print(f"  - Inserted QuicUI entries at {quicui_count} locations")
    print(f"  - Shifted {shift_count} offset values")
