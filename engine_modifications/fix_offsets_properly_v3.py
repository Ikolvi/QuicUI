#!/usr/bin/env python3
"""
Script to properly add QuicUI entries to runtime_offsets_extracted.h.
This script:
1. Finds the insertion points (after call_native_through_safepoint_stub_offset)
2. Inserts QuicUI offset entries with correct values
3. Shifts ALL subsequent Thread offsets by the appropriate amount
   - 8 bytes for 32-bit architectures (2 x 4-byte pointers)
   - 16 bytes for 64-bit architectures (2 x 8-byte pointers)
4. Handles BOTH regular (Thread_) and AOT prefixed (AOT_Thread_) entries
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
    # 32-bit: ARM (not ARM64), IA32, RISCV32
    # 64-bit: ARM64, X64, RISCV64
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
        
        # Check if this is the insertion point - matches both Thread_ and AOT_Thread_ versions
        if 'call_native_through_safepoint_stub_offset' in line and '=' in line:
            # Determine the prefix used in this line
            prefix = get_prefix_for_line(line)
            if prefix:
                # Add this line
                result.append(line)
                
                # Get the value of call_native_through_safepoint_stub_offset
                base_offset = parse_offset_value(line)
                if base_offset is not None:
                    # Calculate QuicUI offsets
                    quicui_interp_offset = base_offset + current_ptr_size
                    quicui_dispatch_offset = base_offset + (current_ptr_size * 2)
                    
                    # Insert QuicUI entries with the same prefix as the source line
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
        # These come AFTER call_native_through_safepoint_stub_offset in the Thread structure
        prefix = get_prefix_for_line(line)
        if prefix and '_offset' in line and '=' in line:
            # List of offset SUFFIXES that come AFTER the stubs and need shifting
            offsets_to_shift = [
                'call_native_through_safepoint_entry_point_offset',
                'AllocateArray_entry_point_offset',
                'active_exception_offset',
                'active_stacktrace_offset',
                'array_write_barrier_entry_point_offset',
                'allocate_mint_with_fpu_regs_entry_point_offset',
                'allocate_mint_without_fpu_regs_entry_point_offset',
                'allocate_object_entry_point_offset',
                'allocate_object_parameterized_entry_point_offset',
                'allocate_object_slow_entry_point_offset',
                'api_top_scope_offset',
                'auto_scope_native_wrapper_entry_point_offset',
                'bootstrap_native_wrapper_entry_point_offset',
                'call_to_runtime_entry_point_offset',
                'dart_stream_offset',
                'double_truncate_round_supported_offset',
                'service_extension_stream_offset',
                'optimize_entry_offset',
                'deoptimize_entry_offset',
                'double_abs_address_offset',
                'double_negate_address_offset',
                'execution_state_offset',
                'float_absolute_address_offset',
                'float_negate_address_offset',
                'float_not_address_offset',
                'float_zerow_address_offset',
                'global_object_pool_offset',
                'interpret_call_entry_point_offset',
                'exit_through_ffi_offset',
                'isolate_offset',
                'isolate_group_offset',
                'old_marking_stack_block_offset',
                'new_marking_stack_block_offset',
                'megamorphic_call_checked_entry_offset',
                'switchable_call_miss_entry_point_offset',
                'switchable_call_miss_entry_offset',
                'no_scope_native_wrapper_entry_point_offset',
                'predefined_symbols_address_offset',
                'resume_interpreter_adjusted_entry_point_offset',
                'resume_pc_offset',
                'saved_shadow_call_stack_offset',
                'safepoint_state_offset',
                'slow_type_test_entry_point_offset',
                'saved_stack_limit_offset',
                'stack_overflow_flags_offset',
                'stack_overflow_shared_with_fpu_regs_entry_point_offset',
                'stack_overflow_shared_without_fpu_regs_entry_point_offset',
                'store_buffer_block_offset',
                'suspend_state_await_entry_point_offset',
                'suspend_state_await_with_type_check_entry_point_offset',
                'suspend_state_init_async_entry_point_offset',
                'suspend_state_return_async_entry_point_offset',
                'suspend_state_return_async_not_future_entry_point_offset',
                'suspend_state_init_async_star_entry_point_offset',
                'suspend_state_yield_async_star_entry_point_offset',
                'suspend_state_return_async_star_entry_point_offset',
                'suspend_state_init_sync_star_entry_point_offset',
                'suspend_state_suspend_sync_star_at_start_entry_point_offset',
                'suspend_state_handle_exception_entry_point_offset',
                'top_exit_frame_info_offset',
                'unboxed_runtime_arg_offset',
                'vm_tag_offset',
                'write_barrier_entry_point_offset',
                'next_task_id_offset',
                'random_offset',
                'jump_to_frame_entry_point_offset',
                'tsan_utils_offset',
                'current_tag_offset',
                'default_tag_offset',
                'user_tag_offset',
                'write_barrier_wrappers_thread_offset',
                'single_step_offset',
            ]
            
            # Check if this offset should be shifted
            shift_this = False
            for offset_suffix in offsets_to_shift:
                # Build the full name with prefix
                full_name = f'{prefix}{offset_suffix}'
                if full_name in line:
                    shift_this = True
                    break
            
            if shift_this:
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
