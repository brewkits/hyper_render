# Publishing Guide for HyperRender v1.0

This guide explains how to publish HyperRender packages to pub.dev.

## Package Structure

HyperRender v1.0 uses a monorepo structure with multiple packages:

```
hyper_render/
├── packages/
│   ├── hyper_render_core/         # Core package (no dependencies)
│   └── hyper_render_clipboard/    # Clipboard plugin (depends on core)
└── hyper_render (root)             # Main package (depends on core)
```

## Publishing Order

**IMPORTANT**: Packages must be published in dependency order:

1. **First**: `hyper_render_core` (has no dependencies on other packages)
2. **Second**: Plugin packages (all depend on core):
   - `hyper_render_clipboard`
3. **Last**: `hyper_render` (main package that depends on core)

## Before Publishing

### 1. Update Version Numbers

Ensure all packages have consistent version numbers in their `pubspec.yaml`:

```yaml
version: 1.0.0
```

### 2. Replace Path Dependencies with Version Dependencies

During development, packages use `path:` dependencies for easier testing:

```yaml
# DEVELOPMENT (current)
dependencies:
  hyper_render_core:
    path: ../hyper_render_core
```

**Before publishing**, replace with version dependencies:

```yaml
# PRODUCTION (for publishing)
dependencies:
  hyper_render_core: ^1.0.0
```

### Files to Update:

#### packages/hyper_render_clipboard/pubspec.yaml
```yaml
dependencies:
  hyper_render_core: ^1.0.0  # Change from: path: ../hyper_render_core
```

#### pubspec.yaml (root package)
```yaml
dependencies:
  hyper_render_core: ^1.0.0  # Change from: path: packages/hyper_render_core
```

## Publishing Steps

### Step 1: Publish Core Package

```bash
cd packages/hyper_render_core
flutter pub publish --dry-run  # Test first
flutter pub publish            # Actual publish
```

### Step 2: Update and Publish Plugin Packages

After `hyper_render_core` is published and available on pub.dev:

```bash
# Update clipboard package pubspec.yaml to use hyper_render_core: ^1.0.0
cd packages/hyper_render_clipboard
flutter pub publish --dry-run
flutter pub publish
```

### Step 3: Publish Main Package

After all plugin packages are published:

```bash
# Update root pubspec.yaml to use version dependencies
cd ../..  # Back to root
flutter pub publish --dry-run
flutter pub publish
```

## After Publishing

### Revert to Path Dependencies for Development

After successful publishing, **revert the pubspec.yaml files back to path dependencies** for continued development:

```bash
git checkout packages/hyper_render_clipboard/pubspec.yaml
git checkout pubspec.yaml
```

Or manually change them back to `path:` dependencies.

## Automated Publishing (Recommended)

Consider using a tool like [Melos](https://melos.invertase.dev/) to automate monorepo publishing:

1. Install Melos: `dart pub global activate melos`
2. Create `melos.yaml` configuration
3. Use `melos publish` to handle all packages automatically

## Checklist

Before each release:

- [ ] All tests pass: `flutter test`
- [ ] Code analysis clean: `flutter analyze`
- [ ] Version numbers updated consistently
- [ ] CHANGELOG.md updated for each package
- [ ] README.md examples are up-to-date
- [ ] Path dependencies replaced with version dependencies
- [ ] Dry-run publish successful for all packages
- [ ] Published in correct order (core → plugins → umbrella)
- [ ] Reverted to path dependencies after publishing

## Common Issues

### "Package depends on unpublished package"

**Cause**: Trying to publish a package that depends on another package not yet on pub.dev.

**Solution**: Publish dependencies first (see Publishing Order above).

### "Publishable packages can't have 'path' dependencies"

**Cause**: Forgot to replace `path:` with version number.

**Solution**: Update pubspec.yaml as described in "Replace Path Dependencies" section.

### Version conflict after publishing

**Cause**: Packages have mismatched version numbers.

**Solution**: Ensure all packages use the same version (e.g., `1.0.0`).

## Support

For issues or questions:
- GitHub Issues: https://github.com/brewkits/hyper_render/issues
- Documentation: See README.md and MIGRATION_GUIDE.md
