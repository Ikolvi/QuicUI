#!/usr/bin/env python3
"""
Script to update ALL offsets in runtime_offsets_extracted.h to account for
QuicUI entries (2 x 8-byte pointers = 16 bytes for 64-bit, 2 x 4 bytes = 8 bytes for 32-bit)

The QuicUI entries are added after call_native_through_safepoint_stub_offset,
so all offsets AFTER this point need to be increased.
"""

import re
import sys

def update_offsets(input_file, output_file):
    with open(input_file, 'r') as f:
        content = f.read()
    
    # Offsets that come AFTER call_native_through_safepoint_stub in Thread structure
    # These need to be increased by ptr_size * 2
    # Based on the error messages, the difference is 16 bytes for 64-bit
    
    # Pattern: Thread_xxx_offset = 0xNNN;
    # We need to find all offsets and increase those that come after QuicUI
    
    # List of offset names that need to be increased (from error message)
    # These are the entry_point and address offsets that come after the stub list
    offsets_to_increase = [
        "Thread_AllocateArray_entry_point_offset",
        "Thread_active_exception_offset",
        "Thread_active_stacktrace_offset", 
        "Thread_array_write_barrier_entry_point_offset",
        "Thread_allocate_mint_with_fpu_regs_entry_point_offset",
        "Thread_allocate_mint_without_fpu_regs_entry_point_offset",
        "Thread_allocate_object_entry_point_offset",
        "Thread_allocate_object_parameterized_entry_point_offset",
        "Thread_allocate_object_slow_entry_point_offset",
        "Thread_api_top_scope_offset",
        "Thread_auto_scope_native_wrapper_entry_point_offset",
        "Thread_bootstrap_native_wrapper_entry_point_offset",
        "Thread_call_to_runtime_entry_point_offset",
        "Thread_dart_stream_offset",
        "Thread_double_truncate_round_supported_offset",
        "Thread_service_extension_stream_offset",
        "Thread_optimize_entry_offset",
        "Thread_deoptimize_entry_offset",
        "Thread_double_abs_address_offset",
        "Thread_double_negate_address_offset",
        "Thread_execution_state_offset",
        "Thread_call_native_through_safepoint_entry_point_offset",
        "Thread_float_absolute_address_offset",
        "Thread_float_negate_address_offset",
        "Thread_float_not_address_offset",
        "Thread_float_zerow_address_offset",
        "Thread_global_object_pool_offset",
        "Thread_interpret_call_entry_point_offset",
        "Thread_exit_through_ffi_offset",
        "Thread_isolate_offset",
        "Thread_isolate_group_offset",
        "Thread_old_marking_stack_block_offset",
        "Thread_new_marking_stack_block_offset",
        "Thread_megamorphic_call_checked_entry_offset",
        "Thread_switchable_call_miss_entry_offset",
        "Thread_no_scope_native_wrapper_entry_point_offset",
        "Thread_predefined_symbols_address_offset",
        "Thread_resume_interpreter_adjusted_entry_point_offset",
        "Thread_resume_pc_offset",
        "Thread_saved_shadow_call_stack_offset",
        "Thread_safepoint_state_offset",
        "Thread_slow_type_test_entry_point_offset",
        "Thread_saved_stack_limit_offset",
        "Thread_stack_overflow_flags_offset",
        "Thread_stack_overflow_shared_with_fpu_regs_entry_point_offset",
        "Thread_stack_overflow_shared_without_fpu_regs_entry_point_offset",
        "Thread_store_buffer_block_offset",
        "Thread_suspend_state_await_entry_point_offset",
        "Thread_suspend_state_await_with_type_check_entry_point_offset",
        "Thread_suspend_state_init_async_entry_point_offset",
        "Thread_suspend_state_return_async_entry_point_offset",
        "Thread_suspend_state_return_async_not_future_entry_point_offset",
        "Thread_suspend_state_init_async_star_entry_point_offset",
        "Thread_suspend_state_yield_async_star_entry_point_offset",
        "Thread_suspend_state_return_async_star_entry_point_offset",
        "Thread_suspend_state_init_sync_star_entry_point_offset",
        "Thread_suspend_state_suspend_sync_star_at_start_entry_point_offset",
        "Thread_suspend_state_handle_exception_entry_point_offset",
        "Thread_top_exit_frame_info_offset",
        "Thread_unboxed_runtime_arg_offset",
        "Thread_vm_tag_offset",
        "Thread_write_barrier_entry_point_offset",
        "Thread_next_task_id_offset",
        "Thread_random_offset",
        "Thread_jump_to_frame_entry_point_offset",
        "Thread_tsan_utils_offset",
        "Thread_current_tag_offset",
        "Thread_default_tag_offset",
        "Thread_user_tag_offset",
        "Thread_write_barrier_wrappers_thread_offset",
    ]
    
    lines = content.split('\n')
    new_lines = []
    
    # Track which configuration we're in (to determine ptr_size)
    current_ptr_size = 8  # Default to 64-bit
    
    for line in lines:
        # Check for architecture hints to determine pointer size
        if 'defined(TARGET_ARCH_ARM)' in line and 'ARM64' not in line:
            current_ptr_size = 4
        elif 'defined(TARGET_ARCH_IA32)' in line:
            current_ptr_size = 4
        elif 'defined(TARGET_ARCH_ARM64)' in line or 'defined(TARGET_ARCH_X64)' in line or 'defined(TARGET_ARCH_RISCV' in line:
            current_ptr_size = 8
        
        # Check if this line contains an offset we need to update
        modified = False
        for offset_name in offsets_to_increase:
            # Handle both regular and AOT prefixes
            for prefix in ['', 'AOT_']:
                full_name = prefix + offset_name
                if full_name in line and '=' in line and '0x' in line:
                    # Extract and update the hex value
                    match = re.search(r'= (0x[0-9a-fA-F]+);', line)
                    if match:
                        old_value = int(match.group(1), 16)
                        # Increase by ptr_size * 2 (for 2 QuicUI entries)
                        new_value = old_value + (current_ptr_size * 2)
                        line = line.replace(match.group(1), f'0x{new_value:x}')
                        modified = True
                        break
            if modified:
                break
        
        new_lines.append(line)
    
    with open(output_file, 'w') as f:
        f.write('\n'.join(new_lines))
    
    print(f"Updated offsets in {output_file}")

if __name__ == "__main__":
    input_file = "/Users/admin/Documents/quicui2/engine_modifications/cleaned_files/runtime_offsets_extracted.h"
    output_file = "/Users/admin/Documents/quicui2/engine_modifications/cleaned_files/runtime_offsets_extracted.h"
    update_offsets(input_file, output_file)
