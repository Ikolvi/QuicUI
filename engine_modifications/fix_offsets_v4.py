#!/usr/bin/env python3
"""
Script to properly add QuicUI entries to runtime_offsets_extracted.h.

Key insight: The runtime_offsets_extracted.h file has Thread offsets in a different
order than the actual Thread struct. We need to:
1. Insert QuicUI entries after call_native_through_safepoint_stub_offset
2. Shift ALL Thread offsets EXCEPT stub offsets (which come BEFORE QuicUI in struct)

The struct layout in thread.h is:
- CACHED_NON_VM_STUB_LIST (objects, not stubs)  <- comes before stubs
- CACHED_VM_STUBS_LIST (stub pointers)
  - ... many stubs ...
  - call_native_through_safepoint_stub_ 
  - quicui_interpreter_entry_stub_ <- NEW
  - quicui_dispatch_stub_ <- NEW
- CACHED_ADDRESSES_LIST (entry points, addresses) <- comes AFTER stubs, needs shift
- Other fields <- need shift

So we DON'T shift:
- Stub offsets (except QuicUI which we insert)
- Fields in CACHED_NON_VM_STUB_LIST (object_null, bool_true, bool_false, dispatch_table)

We DO shift:
- All entry_point offsets
- All address offsets  
- All other Thread fields
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

# Stub offsets that come BEFORE QuicUI in the struct - don't shift these
STUB_SUFFIXES_NO_SHIFT = [
    'fix_callers_target_code_offset',
    'fix_allocation_stub_code_offset',
    'invoke_dart_code_stub_offset',
    'invoke_dart_code_from_bytecode_stub_offset',
    'call_to_runtime_stub_offset',
    'late_initialization_error_shared_without_fpu_regs_stub_offset',
    'late_initialization_error_shared_with_fpu_regs_stub_offset',
    'null_error_shared_without_fpu_regs_stub_offset',
    'null_error_shared_with_fpu_regs_stub_offset',
    'null_arg_error_shared_without_fpu_regs_stub_offset',
    'null_arg_error_shared_with_fpu_regs_stub_offset',
    'null_cast_error_shared_without_fpu_regs_stub_offset',
    'null_cast_error_shared_with_fpu_regs_stub_offset',
    'range_error_shared_without_fpu_regs_stub_offset',
    'range_error_shared_with_fpu_regs_stub_offset',
    'write_error_shared_without_fpu_regs_stub_offset',
    'write_error_shared_with_fpu_regs_stub_offset',
    'field_access_error_shared_without_fpu_regs_stub_offset',
    'field_access_error_shared_with_fpu_regs_stub_offset',
    'allocate_mint_with_fpu_regs_stub_offset',
    'allocate_mint_without_fpu_regs_stub_offset',
    'async_exception_handler_stub_offset',
    'resume_stub_offset',
    'return_async_stub_offset',
    'return_async_not_future_stub_offset',
    'return_async_star_stub_offset',
    'stack_overflow_shared_without_fpu_regs_stub_offset',
    'stack_overflow_shared_with_fpu_regs_stub_offset',
    'switchable_call_miss_stub_offset',
    'throw_stub_offset',
    're_throw_stub_offset',
    'optimize_stub_offset',
    'deoptimize_stub_offset',
    'lazy_deopt_from_return_stub_offset',
    'lazy_deopt_from_throw_stub_offset',
    'slow_type_test_stub_offset',
    'lazy_specialize_type_test_stub_offset',
    'enter_safepoint_stub_offset',
    'exit_safepoint_stub_offset',
    'call_native_through_safepoint_stub_offset',
]

# Fields from CACHED_NON_VM_STUB_LIST that come BEFORE the stubs - don't shift these
NON_VM_STUB_SUFFIXES_NO_SHIFT = [
    'object_null_offset',
    'bool_true_offset',
    'bool_false_offset',
    'dispatch_table_array_offset',
    'field_table_values_offset',
    'shared_field_table_values_offset',
]

# Special fields that are NOT in any list but come early in the Thread class
EARLY_FIELDS_NO_SHIFT = [
    'stack_limit_offset',
    'end_offset',
]

def should_shift(line, prefix):
    """Determine if a Thread offset should be shifted."""
    # Check if it's a stub that comes before QuicUI
    for suffix in STUB_SUFFIXES_NO_SHIFT:
        if f'{prefix}{suffix}' in line:
            return False
    
    # Check if it's a non-VM stub field
    for suffix in NON_VM_STUB_SUFFIXES_NO_SHIFT:
        if f'{prefix}{suffix}' in line:
            return False
    
    # Check early fields
    for suffix in EARLY_FIELDS_NO_SHIFT:
        if f'{prefix}{suffix}' in line:
            return False
    
    # All other Thread fields should be shifted
    return True

def process_file(input_path, output_path):
    with open(input_path, 'r') as f:
        lines = f.readlines()
    
    result = []
    i = 0
    
    # Track which architecture section we're in to determine pointer size
    current_ptr_size = 8  # Default
    insertion_count = 0
    shift_count = 0
    
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
        
        # Calculate shift amount (2 pointers for QuicUI entries)
        shift_amount = current_ptr_size * 2
        
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
        
        # Check if this is a Thread offset that needs to be shifted
        prefix = get_prefix_for_line(line)
        if prefix and '_offset' in line and '=' in line:
            if should_shift(line, prefix):
                old_value = parse_offset_value(line)
                if old_value is not None:
                    new_value = old_value + shift_amount
                    new_line = re.sub(r'= 0x[0-9a-fA-F]+;', f'= {format_offset_value(new_value)};', line)
                    result.append(new_line)
                    shift_count += 1
                    i += 1
                    continue
        
        result.append(line)
        i += 1
    
    with open(output_path, 'w') as f:
        f.writelines(result)
    
    print(f"Processed {input_path}")
    print(f"  - Inserted QuicUI entries at {insertion_count} locations")
    print(f"  - Shifted {shift_count} offset values")

if __name__ == "__main__":
    input_file = "/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart/runtime/vm/compiler/runtime_offsets_extracted.h"
    output_file = input_file
    process_file(input_file, output_file)
