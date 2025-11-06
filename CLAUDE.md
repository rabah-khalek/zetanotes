# Development Notes

## Version Bumping Checklist

When bumping versions for App Store release:

1. **Update MARKETING_VERSION** in `ZetaNotes.xcodeproj/project.pbxproj` (both Debug and Release configs)
2. **Update CFBundleShortVersionString** in `ZetaNotes/Info.plist` (must match MARKETING_VERSION)
3. **Increment CFBundleVersion** in `ZetaNotes/Info.plist` (must be higher than previous App Store build)
4. **Update CURRENT_PROJECT_VERSION** in `ZetaNotes.xcodeproj/project.pbxproj` (must match CFBundleVersion)

**Note:** CFBundleVersion must always increment, even for the same MARKETING_VERSION (e.g., v1.0.2 build 7, v1.0.2 build 8, etc.)
