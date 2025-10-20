# Mangled Chat Template Marker Fix

## Problem
The output was showing mangled chat template markers at the end:
```
---
`Reformulated • Oct 20, 4:05 AM`
---

</|end_header
```

## Root Cause
The text `</|end_header` is a **broken/partial version** of Llama 3.2's chat template marker `<|end_header_id|>`.

This happens when:
1. The model starts generating a chat template marker
2. Generation is cut off mid-token (by max tokens limit or other stop conditions)
3. The partial marker appears in the output

### Why It Wasn't Caught
- ✅ **Full marker** `<|end_header_id|>` → Removed by `LLMOutputCleaner`
- ❌ **Partial marker** `</|end_header` → Not in stop sequences, not in output cleaner

## Solution

### 1. Added to Stop Sequences (All Services)
Prevent generation from even producing these markers:

**ReformulationService.swift**, **SummarizationService.swift**, **TranslationService.swift**, **AutoCorrectService.swift**:
```swift
stopSequences: [
    // ... existing sequences ...
    "\n---\n`", // Service delimiter start
    "<|end_header", // Llama 3.2 mangled chat template marker
    "</|end_header" // Another mangled variant
]
```

### 2. Added to Output Cleaner
Belt-and-suspenders approach - remove if it appears anyway:

**LLMOutputCleaner.swift**:
```swift
// Mangled/partial Llama 3.2 variants (appear when generation is cut off)
cleaned = cleaned.replacingOccurrences(of: "<|end_header", with: "")
cleaned = cleaned.replacingOccurrences(of: "</|end_header", with: "")
cleaned = cleaned.replacingOccurrences(of: "<|eot_", with: "")
cleaned = cleaned.replacingOccurrences(of: "<|start_header", with: "")
```

## Why This Happens

### Llama 3.2 Chat Template
```
<|begin_of_text|><|start_header_id|>system<|end_header_id|>
System prompt here<|eot_id|><|start_header_id|>user<|end_header_id|>
User input here<|eot_id|><|start_header_id|>assistant<|end_header_id|>
Assistant response
```

When the model generates the response and approaches the end, it sometimes tries to:
1. Add a closing marker like `<|eot_id|>` or `<|end_header_id|>`
2. Generation gets cut off mid-marker
3. Partial text like `<|end_header` or `</|end_header` appears

### Why the Mangled Format?
The `/` in `</|end_header` suggests the model is confusing chat templates with HTML/XML tags:
- HTML: `</tag>`
- Llama 3.2: `<|end_header_id|>`
- Mangled: `</|end_header` (hybrid of both)

This is common in smaller models or when context is very long.

## Files Modified

1. ✅ `/ZetaNotes/AI/ReformulationService.swift` - Added stop sequences
2. ✅ `/ZetaNotes/AI/SummarizationService.swift` - Added stop sequences
3. ✅ `/ZetaNotes/AI/TranslationService.swift` - Added stop sequences
4. ✅ `/ZetaNotes/AI/AutoCorrectService.swift` - Added stop sequences
5. ✅ `/ZetaNotes/AI/LLMOutputCleaner.swift` - Added mangled variant removal

## Testing

Test with large text (3000+ chars) on Llama 3.2 models to verify:
- [ ] No `</|end_header` in output
- [ ] No `<|end_header` in output
- [ ] No other partial markers like `<|eot_` or `<|start_header`
- [ ] Clean output ends properly

## Related Issues

This is similar to other chat template artifacts we've seen:
- `<|im_end|>` mangling to `|im_end|>` (already fixed)
- `<|assistant|>` appearing in output (already fixed)
- `_id|>` partial tokens (already fixed)

The pattern: **Models sometimes generate partial chat template markers when generation is cut off.**

## Prevention Strategy

**Two-layer defense:**
1. **Stop sequences** - Prevent generation in the first place
2. **Output cleaner** - Remove if it slips through

This ensures clean output even when models misbehave.

---

**Date**: October 20, 2025
**Issue**: Mangled chat template markers in output
**Fix**: Added partial markers to stop sequences and output cleaner
