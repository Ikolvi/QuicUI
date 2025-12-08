#!/usr/bin/env python3
"""
Simpler approach: Shift ALL Thread offsets except stub offsets that come 
before call_native_through_safepoint_stub_offset in the struct.
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

# Stub offsets that come BEFORE QuicUI in the Thread struct - don't shift
STUB_OFFSETS_NO_SHIFT = {
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
}

# Non-Thread fields - don't shift
NON_THREAD_EARLY_FIELDS = {
    'object_null_offset',
    'bool_true_offset',
    'bool_false_offset',
    'dispatch_table_array_offset',
    'field_table_values_offset',
    'shared_field_table_values_offset',
    'stack_limit_offset',
    'end_offset',
}

def should_shift(line, prefix):
    """Check if this Thread offset should be shifted."""
    # Extract the suffix (everything after Thread_)
    suffix_match = re.search(rf'{re.escape(prefix)}([a-z_0-9]+)', line)
    if not suffix_match:
        return False
    suffix = suffix_match.group(1)
    
    # Don't shift stub offsets that come before QuicUI
    if suffix in STUB_OFFSETS_NO_SHIFT:
        return False
    
    # Don't shift early non-Thread fields
    if suffix in NON_THREAD_EARLY_FIELDS:
        return False
    
    return True

def process_file(input_path, output_path):
    with open(input_path, 'r') as f:
        lines = f.readlines()
    
    result = []
    i = 0
    current_ptr_size = 8
    insertion_count = 0
    shift_count = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Detect architecture for pointer size
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
        
        # Insert QuicUI entries after call_native_through_safepoint_stub_offset
        if 'call_native_through_safepoint_stub_offset' in line and '=' in line:
            prefix = get_prefix_for_line(line)
            if prefix:
                result.append(line)
                base_offset = parse_offset_value(line)
                if base_offset is not None:
                    quicui_interp = base_offset + current_ptr_size
                    quicui_dispatch = base_offset + (current_ptr_size * 2)
                    quicui_lines = f"""static constexpr dart::compiler::target::word
    {prefix}quicui_interpreter_entry_stub_offset = {format_offset_value(quicui_interp)};
static constexpr dart::compiler::target::word
    {prefix}quicui_dispatch_stub_offset = {format_offset_value(quicui_dispatch)};
"""
                    result.append(quicui_lines)
                    insertion_count += 1
                i += 1
                continue
        
        # Shift Thread offsets
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
    process_file(input_file, input_file)
