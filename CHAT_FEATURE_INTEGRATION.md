# Chat Feature Integration Guide

## Files Created

The following files have been created for the chat feature:

### Models
- `/Users/projects/Documents/zetanotes/ZetaNotes/Models/ChatMessage.swift`
- `/Users/projects/Documents/zetanotes/ZetaNotes/Models/ChatSettings.swift`

### Managers
- `/Users/projects/Documents/zetanotes/ZetaNotes/Managers/ChatManager.swift`

### AI Services
- `/Users/projects/Documents/zetanotes/ZetaNotes/AI/ChatService.swift`

### Views
- `/Users/projects/Documents/zetanotes/ZetaNotes/Views/ChatView.swift` (OLD - can be removed)
- `/Users/projects/Documents/zetanotes/ZetaNotes/Views/ChatSidebarView.swift` (NEW - native sidebar)

### Modified Files
- `/Users/projects/Documents/zetanotes/ZetaNotes/Views/ContentView.swift` - Uses native 3-column NavigationSplitView with chat sidebar
- `/Users/projects/Documents/zetanotes/ZetaNotes/Views/AISettingsView.swift` - Added Chat settings tab
- `/Users/projects/Documents/zetanotes/ZetaNotes/Views/UpgradePromptView.swift` - Added chat to Pro features

## Integration Steps

### 1. Add Files to Xcode Project

You need to add the newly created files to the Xcode project:

1. Open `ZetaNotes.xcodeproj` in Xcode
2. Right-click on the `Models` folder in the Project Navigator
3. Select "Add Files to ZetaNotes..."
4. Navigate to and select:
   - `ChatMessage.swift`
   - `ChatSettings.swift`
5. Ensure "Add to targets: ZetaNotes" is checked
6. Click "Add"

7. Right-click on the `Managers` folder
8. Add `ChatManager.swift` (same process as above)

9. Right-click on the `AI` folder
10. Add `ChatService.swift`

11. Right-click on the `Views` folder
12. Add `ChatSidebarView.swift`

**Note:** The old `ChatView.swift` can be optionally removed from the project as it's been replaced by `ChatSidebarView.swift`.

### 2. Build and Test

After adding the files, build the project:
```bash
cd /Users/projects/Documents/zetanotes
xcodebuild -project ZetaNotes.xcodeproj -scheme ZetaNotes -configuration Debug build
```

## Feature Description

### User-Facing Features

1. **Chat Button** - Located next to the "New Note" button in the toolbar
   - Shows lock icon for free users
   - Opens chat sidebar for Pro users
   - Orange color for locked, normal for unlocked

2. **Chat Sidebar** - Slides in from the left when activated
   - Resizable (250px - 500px width, default 350px)
   - Persists conversation across notes
   - Clear button to reset conversation
   - "Dump to Note" button to export conversation

3. **Chat Interface**
   - User and assistant message bubbles
   - Timestamps in format "Oct 17, 10:10 PM"
   - Text input with send button
   - Loading indicator during generation
   - Empty state when no messages

4. **Chat Settings** (Pro only)
   - Temperature (0.0 - 2.0)
   - Max Tokens (256 - 2048)
   - Top P (0.0 - 1.0)
   - Top K (1 - 100)
   - Repeat Penalty (1.0 - 2.0)
   - System Prompt (customizable)
   - Reset to Defaults button

5. **Dump Conversation**
   - Exports to current note in markdown format
   - Format: `--- Chat (Oct 17, 2025 at 10:10 PM) ---`
   - Each message shows role, timestamp, and content
   - System messages are excluded from export

### Technical Implementation

1. **ChatMessage Model**
   - Stores role (user/assistant/system)
   - Content and timestamp
   - Formatted timestamp method
   - Markdown export format

2. **ChatSettings Model**
   - All LLM parameters
   - Saves to UserDefaults
   - Default values optimized for conversation

3. **ChatManager**
   - Singleton managing conversation state
   - Persists to `chat_history.json` in Documents
   - Load/save on app lifecycle
   - Export to markdown

4. **ChatService**
   - Uses AIEngine's llmService
   - Formats conversation with ChatML format
   - Limits context to last 10 messages
   - Applies chat-specific parameters

5. **Pro Feature Lock**
   - Checked via `LicenseManager.shared.isPro`
   - Shows upgrade prompt with `.chat` type
   - Settings tab shows Pro prompt for free users

## Testing Checklist

### Free Tier Testing
- [ ] Chat button shows lock icon
- [ ] Clicking chat button shows upgrade prompt
- [ ] Upgrade prompt mentions "AI Chat Assistant"
- [ ] Chat settings tab shows Pro prompt

### Pro Tier Testing
- [ ] Chat button works without lock icon
- [ ] Chat sidebar slides in smoothly
- [ ] Chat sidebar is resizable (drag divider)
- [ ] Can send messages and receive responses
- [ ] Messages show correct timestamps
- [ ] Clear button removes all messages
- [ ] Conversation persists when switching notes
- [ ] Conversation persists when closing/reopening chat
- [ ] "Dump to Note" adds conversation to current note
- [ ] Chat settings apply to conversations
- [ ] Model selection uses currently selected AI model

### Edge Cases
- [ ] Chat works with all available models
- [ ] Chat handles empty input gracefully
- [ ] Chat handles very long messages
- [ ] Chat maintains context across 10+ messages
- [ ] Sidebar width persists across app restarts
- [ ] Closing chat doesn't clear conversation

## Architecture Notes

### Chat Prompt Format

Uses ChatML format for compatibility with instruction-tuned models:

```
<|im_start|>system
{system_prompt}<|im_end|>
<|im_start|>user
{user_message}<|im_end|>
<|im_start|>assistant
{assistant_message}<|im_end|>
<|im_start|>assistant

```

### Storage

- **Chat History**: `~/Documents/chat_history.json`
- **Chat Settings**: UserDefaults key `"chatSettings"`
- **Sidebar Width**: Not persisted (could be added to UserDefaults)

### Future Enhancements

1. **Token-by-Token Streaming**
   - Requires modification to LLMInferenceService
   - Would show AI response appearing gradually

2. **Multiple Conversations**
   - Per-note conversations
   - Named conversation threads
   - Conversation history viewer

3. **Context Options**
   - "Include current note" checkbox
   - Select specific notes to include
   - Reference past conversations

4. **Export Options**
   - Export to new note
   - Export to file (PDF, TXT)
   - Share conversation

## Troubleshooting

### Build Errors

If you see "cannot find 'ChatManager' in scope":
- Ensure all new files are added to the Xcode project target
- Clean build folder (Product > Clean Build Folder)
- Rebuild project

### Runtime Errors

If chat doesn't appear:
- Check that Pro status is correctly detected
- Verify chat button is visible in toolbar
- Check console for any error messages

If messages don't save:
- Verify Documents directory is writable
- Check for JSON encoding/decoding errors in console

## Questions?

If you encounter any issues during integration, check:
1. All files are added to the Xcode project
2. Build succeeds without errors
3. LicenseManager correctly reports Pro status
4. AIEngine is properly initialized
