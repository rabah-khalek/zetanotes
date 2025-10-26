# App Review Submission Package

## Files to Upload to App Store Connect

When submitting your app for review, attach these files to help the review process:

### 📄 Documentation

**File:** `ZetaNotes_App_Review_Documentation.docx` (or `.pdf`)
- Comprehensive app documentation
- Testing instructions for reviewers
- Technical details about entitlements
- FAQ for common review questions

### 🎥 Demo Video

**Your video file** (e.g., `ZetaNotes_Demo_v1.0.0.mp4`)
- Shows app functionality
- Demonstrates purchase flow
- Shows Pro features
- Proves offline capability

---

## How to Attach Files in App Store Connect

1. **Go to App Store Connect**
   - Navigate to your app
   - Select version for review

2. **App Review Information Section**
   - Scroll to "App Review Information"
   - Find "Attachment" section
   - Click "Choose File"

3. **Upload Files**
   - Upload the .docx (or .pdf) documentation
   - Upload your demo video (.mp4)
   - Both files will be visible to reviewers

---

## What to Write in "Notes" Section

### Copy this into the Notes field:

```
TESTING INSTRUCTIONS:

No sign-in required. ZetaNotes is a local-first app with no user accounts.

FOR IN-APP PURCHASE TESTING:
Please use Sandbox testing to test Pro features. All three purchase tiers
(Monthly $1, Annual $6, Lifetime $20) are available in Sandbox mode.

DEMO VIDEO:
A comprehensive demo video has been attached showing:
- Free tier features
- In-app purchase flow (all tiers)
- Pro features (AI models, chat, custom prompts)
- Offline functionality

DETAILED DOCUMENTATION:
Please see attached .docx file for complete testing instructions, technical
details, and FAQ.

SPECIAL ENTITLEMENTS:
This app uses llama.cpp for on-device AI processing, which requires:
- com.apple.security.cs.allow-jit (Metal GPU acceleration)
- com.apple.security.cs.allow-unsigned-executable-memory (model loading)

These are essential for the app's core AI functionality and are properly
declared. See attached documentation for full technical justification.

PRIVACY:
- No user accounts
- No data collection
- All AI processing happens offline
- No analytics or tracking

Thank you for reviewing ZetaNotes!
```

---

## Sign-In Information

**Username:** (leave blank or enter "Not applicable")
**Password:** (leave blank or enter "Not applicable")

**Check box:** ☐ Sign-in required

**Do NOT check this box** - no sign-in is needed!

---

## Checklist Before Submission

- [ ] .docx file created (`ZetaNotes_App_Review_Documentation.docx`)
- [ ] Demo video ready (.mp4 format recommended)
- [ ] IAP products created in App Store Connect
- [ ] App binary uploaded
- [ ] Screenshots uploaded
- [ ] App description filled out
- [ ] Privacy policy URL added
- [ ] Support URL added
- [ ] Notes section filled (use template above)
- [ ] Files attached (documentation + video)
- [ ] "Sign-in required" box is UNCHECKED

---

## File Locations

All review files are in the `docs/` directory:

```
docs/
├── ZetaNotes_App_Review_Documentation.docx  ← Upload this
├── ZetaNotes_App_Review_Documentation.pdf   ← Alternative format
├── ZetaNotes_App_Review_Documentation.md    ← Source markdown
└── APP_REVIEW_NOTES.md                      ← Reference (don't upload)
```

Your demo video should be in:
```
[Wherever you saved your video]
└── ZetaNotes_Demo_v1.0.0.mp4                ← Upload this
```

---

## Accepted File Formats

Apple accepts these formats for attachments:

**Documents:**
- .pdf ✅
- .doc ✅
- .docx ✅ (we created this)
- .rtf ✅
- .pages ✅

**Videos:**
- .mp4 ✅ (recommended)
- .avi ✅
- .mov ✅

**Images:**
- .jpg ✅
- .png ✅

**Other:**
- .zip ✅
- .plist ✅

---

## Tips for Faster Approval

1. **Clear Documentation**
   - ✅ We've provided comprehensive docs
   - ✅ Testing instructions are detailed
   - ✅ Technical details explained

2. **Demo Video**
   - Shows all major features
   - Demonstrates purchase flow
   - Proves app works as described

3. **Responsive to Questions**
   - Monitor App Store Connect for reviewer questions
   - Respond quickly if they ask for clarification
   - Be polite and professional

4. **Complete Metadata**
   - All required fields filled
   - Screenshots are high quality
   - Description is clear and accurate

---

## Expected Timeline

- **Initial Review:** 1-3 days typically
- **If Questions:** Add 1-2 days per round
- **Approval:** Usually within 24-48 hours after all questions resolved

---

## If Rejected

**Common rejection reasons and solutions:**

### "Need clarification on entitlements"
- **Response:** Refer to attached documentation section on llama.cpp
- Explain it's industry-standard for local AI processing

### "Can't test In-App Purchases"
- **Response:** Ensure IAP products are "Ready for Sale" in App Store Connect
- Products must be submitted with the app

### "Demo account needed"
- **Response:** No account needed - it's a local-first app
- Refer to documentation and demo video

---

## Questions?

If reviewers have questions, they'll contact you via App Store Connect:
- Check "Resolution Center" daily
- Respond within 24-48 hours
- Be detailed but concise in responses

---

**You're ready to submit!** 🚀

Upload the .docx and your video, fill in the notes, and hit submit!
