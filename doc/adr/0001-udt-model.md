# ADR 0001: Unified Document Tree (UDT) Model

**Status**: Accepted

**Date**: 2024-2025 (Design Phase)

---

## Context

When designing HyperRender, we needed to decide how to represent HTML/Markdown/Delta documents internally. We had several options:

### Option 1: Direct HTML DOM Tree
- Keep HTML structure as-is
- Each HTML element becomes a Dart object
- Mirrors browser DOM closely

**Pros**:
- Familiar to web developers
- Easy to understand
- Direct mapping from HTML

**Cons**:
- Tightly coupled to HTML semantics
- Hard to support non-HTML formats (Delta, Markdown)
- HTML-specific attributes/behaviors leak everywhere
- Different content types need separate parsers AND renderers

### Option 2: Multiple Document Models
- Separate models for HTML, Delta, Markdown
- Convert to Flutter widgets differently for each type

**Pros**:
- Each format optimized independently
- Clear separation of concerns per format

**Cons**:
- Code duplication (3× renderer implementations)
- Inconsistent rendering across formats
- Hard to maintain consistency
- New format = complete rewrite

### Option 3: Unified Document Tree (UDT) - **CHOSEN**
- Single intermediate representation
- All formats convert to UDT
- Single renderer for all content types

**Pros**:
- Format-agnostic rendering
- Single source of truth for layout/paint logic
- New formats only need parser (not renderer)
- Consistent behavior across all content types
- Easier testing (test UDT, not each format)

**Cons**:
- Extra abstraction layer
- Parsing requires conversion step
- Need to design abstract node types

---

## Decision

We chose **Unified Document Tree (UDT)** as our intermediate representation.

### UDT Node Types

```dart
// Base node
abstract class UDTNode {
  String? id;
  List<String> classes;
  Map<String, String> attributes;
  ComputedStyle? style;
}

// Block-level elements
class BlockNode extends UDTNode {
  NodeType type;       // paragraph, heading, div, etc.
  String? tagName;     // Original tag for semantics
  List<UDTNode> children;
}

// Inline text
class TextNode extends UDTNode {
  String text;
}

// Atomic elements (images, videos, etc.)
class AtomicNode extends UDTNode {
  String tagName;
  String? src;
  double? width;
  double? height;
  // ... atomic-specific properties
}

// Root document
class DocumentNode extends UDTNode {
  List<UDTNode> children;
}
```

### Parsing Pipeline

```
HTML       ──┐
             ├──> UDT ──> CSS Resolution ──> Layout ──> Paint
Markdown   ──┤
             │
Delta JSON ──┘
```

**Each format has a parser (adapter)**:
- `HtmlAdapter`: HTML → UDT
- `MarkdownAdapter`: Markdown → UDT
- `DeltaAdapter`: Quill Delta → UDT

**Single renderer**:
- `RenderHyperBox`: UDT → Flutter RenderObject

---

## Consequences

### Positive

**Format Independence**
- Adding new formats is easy (just write adapter)
- Rendering logic shared across all formats
- Example: Added Delta support in < 200 lines

**Consistency**
- Same CSS rules work for HTML/Markdown/Delta
- Same layout algorithm for all content
- Users get identical output regardless of input format

**Maintainability**
- Single place to fix bugs (renderer)
- Single place to add features (renderer)
- Reduced code duplication by ~70%

**Testing**
- Test UDT structure, not HTML/Markdown/Delta specifics
- Snapshot testing on UDT trees
- Format-specific tests only for parsers

**Performance**
- Can optimize UDT representation once
- Benefits all formats automatically
- Example: Adding caching to UDT benefits HTML, Markdown, Delta

### Negative

**Abstraction Overhead**
- Extra conversion step (Format → UDT)
- Slight parsing time increase (~5-10%)
- More complex mental model for contributors

**Loss of Format-Specific Features**
- Must map to common UDT structure
- Some HTML-specific attributes need workarounds
- Example: HTML5 `data-*` attributes need special handling

**Learning Curve**
- Contributors must understand UDT model
- Can't just "edit HTML renderer"
- Need to think in abstract terms

### Mitigations

We mitigate the negatives by:

1. **Documentation**: Clear UDT documentation with examples
2. **Helpers**: Utility functions to build UDT nodes easily
3. **Type Safety**: Strong typing prevents invalid UDT structures
4. **Extension Points**: `widgetBuilder` allows format-specific customization

---

## Experience Report

After 6+ months of development:

**UDT proved extremely valuable**:
- Added Markdown support in 1 day
- Added Delta support in 2 days
- Zero changes to renderer needed for new formats
- CSS resolver works identically for all formats

**Performance is excellent**:
- Conversion overhead negligible (<5% of total time)
- Ability to cache UDT trees saves more time than conversion costs
- Isolate parsing works seamlessly with UDT

**Maintenance is easier**:
- Fixed float layout bug → all formats benefit
- Added error boundaries → all formats benefit
- Improved CJK line-breaking → all formats benefit

**Some challenges**:
- Explaining UDT to new contributors takes ~30 minutes
- Occasionally need format-specific hacks (e.g., Delta embed types)
- Balancing abstraction vs. format-specific features

---

## Alternatives Considered

### Why not use Flutter's existing Widget tree?

**Considered**:
```dart
HTML → Column/Row/Text widgets → Flutter render tree
```

**Rejected because**:
- Too many widgets created (100KB HTML → 10,000+ widgets)
- Widget tree rebuild cost too high
- No CSS cascade (widgets don't inherit styles)
- Selection across widgets is complex
- Float layout impossible with widgets

See [ADR 0002](0002-single-renderobject.md) for why we chose single RenderObject.

### Why not use Flutter's RichText structure?

**Considered**:
```dart
HTML → TextSpan tree → RichText widget
```

**Rejected because**:
- TextSpan only supports inline content
- No block layout (paragraphs, divs, floats)
- No CSS box model
- No positioned elements

UDT supports both inline and block content seamlessly.

---

## Related Decisions

- [ADR 0002: Single RenderObject Architecture](0002-single-renderobject.md)
- [ADR 0005: InlineSpan Over Widget Tree](0005-inline-span-paradigm.md)

---

## References

- Initial design doc: `docs/design/udt-architecture.md`
- Implementation: `lib/src/model/node.dart`
- Adapters: `lib/src/adapter/`

---

**Decision makers**: vietnguyen (Lead Developer)

**Last updated**: February 2026
