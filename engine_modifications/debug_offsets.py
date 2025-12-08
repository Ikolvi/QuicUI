#!/usr/bin/env python3
"""
Debug version of the offset fix script
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

NON_VM_STUB_SUFFIXES_NO_SHIFT = [
    'object_null_offset',
    'bool_true_offset',
    'bool_false_offset',
    'dispatch_table_array_offset',
    'field_table_values_offset',
    'shared_field_table_values_offset',
]

EARLY_FIELDS_NO_SHIFT = [
    'stack_limit_offset',
    'end_offset',
]

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

# Read file
with open('/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart/runtime/vm/compiler/runtime_offsets_extracted.h', 'r') as f:
    lines = f.readlines()

current_ptr_size = 8

for i, line in enumerate(lines):
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
    
    if 'AOT_Thread_active_exception_offset' in line and '0x6b0' in line:
        prefix = get_prefix_for_line(line)
        if prefix and '_offset' in line and '=' in line:
            ss = should_shift(line, prefix)
            old_val = parse_offset_value(line)
            print(f'Line {i+1}: prefix={prefix}, should_shift={ss}, old_val=0x{old_val:x}, ptr_size={current_ptr_size}')
            if ss:
                new_val = old_val + (current_ptr_size * 2)
                print(f'  Would shift to: 0x{new_val:x}')
