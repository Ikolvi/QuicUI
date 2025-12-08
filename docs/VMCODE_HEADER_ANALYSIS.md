# .vmcode File Format Analysis

## Discovery Summary

Successfully generated and analyzed a Shorebird `.vmcode` file from actual patch generation process.

**File**: `test_apps/sample.vmcode` (4.6MB)

## Header Structure

### Key Finding: Header is **65536 bytes (0x10000)** exactly

```
Offset 0x00000000: [Shorebird Header - 65536 bytes]
Offset 0x00010000: [ELF File begins here with 0x7F 'E' 'L' 'F']
```

### Hex Dump of First 64 Bytes

```
00000000: 4a1f 0000 8000 0000 8000 0000 4801 0000  J...........H...
00000010: 4801 0000 6c01 0000 6c01 0000 8c01 0000  H...l...l.......
00000020: 8c01 0000 ec01 0000 ec01 0000 9802 0000  ................
00000030: 9802 0000 0003 0000 0003 0000 4003 0000  ............@...
```

## Header Analysis

### Bytes 0-3: Possible Entry Count or Magic?
- **Value**: `0x00001f4a` (little-endian) = 8010 decimal
- **Hypothesis**: Could be:
  - Number of entries in link table
  - Magic number for format identification
  - Header version

### Bytes 4-7: First Offset
- **Value**: `0x00008000` = 32768 decimal
- Appears to be an offset within the header region

### Pattern Observation

The header contains many pairs of 4-byte values:
```
0x00008000, 0x00008000  (offset 4-11)
0x00000148, 0x00000148  (offset 12-19)
0x0000016c, 0x0000016c  (offset 20-27)
... continues ...
```

These appear to be **duplicate offset pairs**, possibly indicating:
- Start and end of data sections
- Offsets to link table entries
- Size and position markers

### Link Table Hypothesis

Based on Shorebird CLI code, the header likely contains:
- **Class Table**: Information from `.ct.link` and `.class_table.json`
- **Field Table**: Information from `.ft.link` and `.field_table.json`
- **Dispatch Table**: Information from `.dt.link` and `.dispatch_table.json`

These tables are needed for the linker to properly merge the patch with the release.

## ELF Section

Starting at offset `0x10000`:
```
00010000: 7f45 4c46 0201 0100 0000 0000 0000 0000  .ELF............
```

Standard ELF format:
- **Magic**: `0x7F 'E' 'L' 'F'`
- **Class**: 02 (64-bit)
- **Data**: 01 (little-endian)
- **Version**: 01 (current)

## Implementation Plan

### Phase 1: Simple Header Reading (Immediate)

Since we now know the header is exactly **65536 bytes**, we can implement a simple version:

```cpp
// shell/common/quicui/quicui_header.cc
int QuicUI_ReadLinkHeader(const uint8_t* data, size_t size) {
  // Basic validation
  if (size < 65536 + 4) {  // Header + ELF magic
    return -1;
  }
  
  // Check if ELF magic is at offset 65536
  if (data[65536] == 0x7F &&
      data[65537] == 'E' &&
      data[65538] == 'L' &&
      data[65539] == 'F') {
    return 65536;  // ELF starts here
  }
  
  return -1;  // Invalid format
}
```

### Phase 2: Full Header Parsing (Future)

For a complete implementation, we would:
1. Parse the link table entries
2. Validate the format version
3. Support different header sizes if needed
4. Use the link information for patch merging

## Validation

To verify this is correct, we need to:
1. Implement the header reading function
2. Test with our sample.vmcode file
3. Verify `Dart_LoadELF()` successfully loads from offset 65536
4. Confirm symbols can be extracted

## Files Generated

During patch creation, Shorebird also generates:
- `out.vmcode` - The patch file we analyzed
- `out.aot` - Patch AOT snapshot (ELF)
- Supplement files:
  - `.ct.link` - Class table link info
  - `.class_table.json` - Class table data  
  - `.ft.link` - Field table link info
  - `.field_table.json` - Field table data
  - `.dt.link` - Dispatch table link info
  - `.dispatch_table.json` - Dispatch table data

## Next Steps

1. ✅ **DONE**: Obtain real .vmcode file
2. ✅ **DONE**: Identify header structure (65536 bytes)
3. ✅ **DONE**: Locate ELF offset (0x10000)
4. **NEXT**: Implement `QuicUI_ReadLinkHeader()` with fixed offset
5. **NEXT**: Port dart_snapshot.cc loading code to engine
6. **NEXT**: Test loading with our sample.vmcode

## References

- Sample file: `test_apps/sample.vmcode`
- Shorebird engine code: `runtime/dart_snapshot.cc:59-116`
- Our implementation doc: `docs/SHOREBIRD_REVERSE_ENGINEERING.md`
