#!/usr/bin/env python3
"""
Script to properly add QuicUI entries to runtime_offsets_extracted.h.
This script:
1. Finds the insertion point (after call_native_through_safepoint_stub_offset)
2. Inserts QuicUI offset entries with correct values
3. Shifts ALL subsequent Thread offsets by the appropriate amount
   - 8 bytes for 32-bit architectures (2 x 4-byte pointers)
   - 16 bytes for 64-bit architectures (2 x 8-byte pointers)
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

def process_file(input_path, output_path):
    with open(input_path, 'r') as f:
        lines = f.readlines()
    
    result = []
    i = 0
    
    # Track which architecture section we're in to determine pointer size
    # 32-bit: ARM (not ARM64), IA32
    # 64-bit: ARM64, X64, RISCV32, RISCV64
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
        
        # Check if this is the insertion point (call_native_through_safepoint_stub_offset)
        if 'Thread_call_native_through_safepoint_stub_offset' in line and '=' in line:
            # Add this line
            result.append(line)
            
            # Get the value of call_native_through_safepoint_stub_offset
            base_offset = parse_offset_value(line)
            if base_offset is not None:
                # Calculate QuicUI offsets
                quicui_interp_offset = base_offset + current_ptr_size
                quicui_dispatch_offset = base_offset + (current_ptr_size * 2)
                
                # Insert QuicUI entries
                quicui_lines = f"""static constexpr dart::compiler::target::word
    Thread_quicui_interpreter_entry_stub_offset = {format_offset_value(quicui_interp_offset)};
static constexpr dart::compiler::target::word
    Thread_quicui_dispatch_stub_offset = {format_offset_value(quicui_dispatch_offset)};
"""
                result.append(quicui_lines)
                insertion_count += 1
            
            i += 1
            continue
        
        # Check if this is a Thread offset that needs to be shifted
        # These come AFTER call_native_through_safepoint_stub_offset
        if 'Thread_' in line and '_offset' in line and '=' in line:
            # List of offsets that come AFTER the stubs and need shifting
            # These are entry_points, addresses, and other fields that follow the stub list
            offsets_to_shift = [
                'Thread_call_native_through_safepoint_entry_point_offset',
                'Thread_AllocateArray_entry_point_offset',
                'Thread_active_exception_offset',
                'Thread_active_stacktrace_offset',
                'Thread_array_write_barrier_entry_point_offset',
                'Thread_allocate_mint_with_fpu_regs_entry_point_offset',
                'Thread_allocate_mint_without_fpu_regs_entry_point_offset',
                'Thread_allocate_object_entry_point_offset',
                'Thread_allocate_object_parameterized_entry_point_offset',
                'Thread_allocate_object_slow_entry_point_offset',
                'Thread_api_top_scope_offset',
                'Thread_auto_scope_native_wrapper_entry_point_offset',
                'Thread_bootstrap_native_wrapper_entry_point_offset',
                'Thread_call_to_runtime_entry_point_offset',
                'Thread_dart_stream_offset',
                'Thread_double_truncate_round_supported_offset',
                'Thread_service_extension_stream_offset',
                'Thread_optimize_entry_offset',
                'Thread_deoptimize_entry_offset',
                'Thread_double_abs_address_offset',
                'Thread_double_negate_address_offset',
                'Thread_execution_state_offset',
                'Thread_float_absolute_address_offset',
                'Thread_float_negate_address_offset',
                'Thread_float_not_address_offset',
                'Thread_float_zerow_address_offset',
                'Thread_global_object_pool_offset',
                'Thread_interpret_call_entry_point_offset',
                'Thread_exit_through_ffi_offset',
                'Thread_isolate_offset',
                'Thread_isolate_group_offset',
                'Thread_old_marking_stack_block_offset',
                'Thread_new_marking_stack_block_offset',
                'Thread_megamorphic_call_checked_entry_offset',
                'Thread_switchable_call_miss_entry_point_offset',
                'Thread_switchable_call_miss_entry_offset',
                'Thread_no_scope_native_wrapper_entry_point_offset',
                'Thread_predefined_symbols_address_offset',
                'Thread_resume_interpreter_adjusted_entry_point_offset',
                'Thread_resume_pc_offset',
                'Thread_saved_shadow_call_stack_offset',
                'Thread_safepoint_state_offset',
                'Thread_slow_type_test_entry_point_offset',
                'Thread_saved_stack_limit_offset',
                'Thread_stack_overflow_flags_offset',
                'Thread_stack_overflow_shared_with_fpu_regs_entry_point_offset',
                'Thread_stack_overflow_shared_without_fpu_regs_entry_point_offset',
                'Thread_store_buffer_block_offset',
                'Thread_suspend_state_await_entry_point_offset',
                'Thread_suspend_state_await_with_type_check_entry_point_offset',
                'Thread_suspend_state_init_async_entry_point_offset',
                'Thread_suspend_state_return_async_entry_point_offset',
                'Thread_suspend_state_return_async_not_future_entry_point_offset',
                'Thread_suspend_state_init_async_star_entry_point_offset',
                'Thread_suspend_state_yield_async_star_entry_point_offset',
                'Thread_suspend_state_return_async_star_entry_point_offset',
                'Thread_suspend_state_init_sync_star_entry_point_offset',
                'Thread_suspend_state_suspend_sync_star_at_start_entry_point_offset',
                'Thread_suspend_state_handle_exception_entry_point_offset',
                'Thread_top_exit_frame_info_offset',
                'Thread_unboxed_runtime_arg_offset',
                'Thread_vm_tag_offset',
                'Thread_write_barrier_entry_point_offset',
                'Thread_next_task_id_offset',
                'Thread_random_offset',
                'Thread_jump_to_frame_entry_point_offset',
                'Thread_tsan_utils_offset',
                'Thread_current_tag_offset',
                'Thread_default_tag_offset',
                'Thread_user_tag_offset',
                'Thread_write_barrier_wrappers_thread_offset',
                'Thread_single_step_offset',
            ]
            
            # Check if this offset should be shifted
            should_shift = False
            for offset_name in offsets_to_shift:
                if offset_name in line:
                    should_shift = True
                    break
            
            if should_shift:
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
