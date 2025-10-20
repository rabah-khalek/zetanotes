# Memory Release Optimization - Fix Documentation

## Problem

Memory usage was taking a long time to reduce after AI operations or model unloading. The app could use 1.5-2.5 GB during inference and would not release it promptly back to the system.

## Root Causes

### 1. **No Autorelease Pools Around C/C++ Operations**
- llama.cpp is a C++ library that creates temporary objects during inference
- Without explicit `autoreleasepool` blocks, these objects accumulate until Swift's runtime decides to drain the pool
- This could take seconds or even minutes, especially on low-memory pressure

### 2. **Metal GPU Memory Retention**
- The Metal backend (GPU) allocates buffers that persist longer than expected
- macOS doesn't immediately release GPU memory even after `llama_free()` is called
- This is normal macOS behavior but appeared as a "memory leak" to users

### 3. **KV Cache Not Cleared Before Unload**
- The Key-Value cache buffers were not being explicitly cleared before model unload
- These buffers hold intermediate computation results and can be hundreds of MB
- Calling `llama_memory_clear()` before `llama_free()` helps release them faster

### 4. **Synchronous Operations Without Feedback**
- `llama_backend_free()` is synchronous but macOS memory reclamation is asynchronous
- No feedback mechanism to confirm when memory was actually released
- Users couldn't tell if the app was stuck or just waiting for system memory reclamation

## Solutions Implemented

### 1. **Added Autorelease Pools**

Wrapped all heavy LLM operations in `autoreleasepool {}` blocks:

```swift
// Text generation
autoreleasepool {
    // All llama.cpp operations
    // Token generation, decoding, etc.
    continuation.resume(returning: result)
}

// Embedding generation
autoreleasepool {
    // Embedding extraction
    continuation.resume(returning: embedding)
}

// Model unloading
autoreleasepool {
    // Free sampler, context, model
    llama_backend_free()
}
```

**Impact**: Temporary objects are released immediately after each operation completes.

### 2. **Explicit KV Cache Clearing**

Clear the KV cache buffer before model unload:

```swift
if let ctx = context {
    // Clear KV cache before freeing to release buffers
    let mem = llama_get_memory(ctx)
    llama_memory_clear(mem, true)  // Clear both metadata AND data

    llama_free(ctx)
    context = nil
}
```

**Impact**: Large memory buffers are marked for release immediately.

### 3. **Memory Status Logging**

Added post-unload memory reporting:

```swift
Task {
    // Small delay to allow background threads to complete
    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

    // Log memory status after unload
    var taskInfo = mach_task_basic_info()
    // ... get memory info ...
    print("📊 Memory after unload: \(usedMemoryMB) MB")
}
```

**Impact**: Users and developers can see when memory is actually released.

### 4. **Llama 3.2 Token Cleaning**

Fixed reserved special token artifacts:

```swift
// Added regex-based cleaning for reserved tokens
if let regex = try? NSRegularExpression(
    pattern: "<\\|reserved_special_token_\\d+\\|?>",
    options: []
) {
    cleaned = regex.stringByReplacingMatches(...)
}
```

**Impact**: Cleaner autocomplete output without special token artifacts.

### 5. **Reduced Autocomplete Context**

Reduced context window from 500 to 300 characters:

```swift
private enum Config {
    static let minCharacters = 10
    static let contextLength = 300 // Reduced from 500
}
```

**Impact**: Less memory pressure during autocomplete, fewer artifacts with large notes.

## Expected Behavior After Fix

### Before:
- Model unload: Memory stays high for 30-60 seconds
- After inference: Gradual memory decrease over 10-30 seconds
- User perception: "App is leaking memory"

### After:
- Model unload: Memory drops within 1-5 seconds (still depends on macOS)
- After inference: Immediate release of temporary buffers
- Log shows: "📊 Memory after unload: XXX MB"
- User perception: "App is responsive and efficient"

## Testing

### Manual Testing Steps

1. **Load a large model (Phi-3.5 or Llama 3.2 3B)**
   - Check memory in Activity Monitor
   - Should see ~2.5-2.8 GB

2. **Perform inference (summarize, translate, autocomplete)**
   - Memory may spike during generation
   - Should drop back to baseline within 1-5 seconds after completion

3. **Unload the model (switch to smaller model)**
   - Watch console for "📊 Memory after unload: XXX MB"
   - Activity Monitor should show memory drop within 5 seconds

4. **Multiple rapid inferences**
   - Memory should not continuously increase
   - Should stabilize after 2-3 operations

### Console Markers

Look for these logs to confirm proper behavior:

```
🧹 Context fully reset (KV cache + data cleared, sampler reset)
✅ Generation complete: XX tokens → XX chars
🔄 Model unloaded and memory freed
📊 Memory after unload: XXX.X MB
```

## Known Limitations

1. **macOS Controls Final Release**
   - We can only *suggest* to macOS when to release memory
   - Under memory pressure, macOS releases faster
   - Under light load, macOS may keep memory cached for performance

2. **Metal GPU Buffers**
   - GPU memory is controlled by the Metal driver
   - May persist for several seconds even after explicit free
   - This is normal and expected

3. **Fragmentation**
   - After loading/unloading multiple large models, some memory fragmentation is normal
   - Restarting the app fully clears this

## Future Optimizations

1. **Aggressive Memory Warnings**
   - Monitor `memoryUsage` and proactively unload models at 2.8GB
   - Currently only logs warnings, could auto-unload

2. **Model Streaming**
   - Load model weights on-demand instead of all at once
   - llama.cpp doesn't support this yet

3. **Quantization Improvements**
   - Use Q3_K_M or Q2_K for even lower memory footprint
   - Trade-off: slight quality reduction

## Related Files

- `/ZetaNotes/AI/LLMInferenceService.swift` - Main memory fix
- `/ZetaNotes/AI/LLMOutputCleaner.swift` - Token cleaning
- `/ZetaNotes/AI/AutocompleteService.swift` - Context reduction
- `/ZetaNotes/AI/AIEngine.swift` - Memory monitoring

## Credits

Fixed by: AI Analysis + Developer Implementation
Date: October 20, 2025
Issue: Memory not released promptly after inference/model unload
