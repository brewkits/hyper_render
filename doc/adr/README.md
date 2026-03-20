# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records (ADRs) for HyperRender - documents that capture important architectural decisions along with their context and consequences.

## What is an ADR?

An Architecture Decision Record (ADR) is a document that captures a significant architectural decision made along with its context and consequences.

## Format

Each ADR follows this structure:
- **Title**: Short noun phrase
- **Status**: Proposed, Accepted, Deprecated, Superseded
- **Context**: The issue motivating this decision
- **Decision**: The change we're proposing or have agreed to
- **Consequences**: The impacts of this decision (positive and negative)

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-udt-model.md) | Unified Document Tree (UDT) Model | Accepted |
| [0002](0002-single-renderobject.md) | Single RenderObject Architecture | Accepted |
| [0003](0003-css-float-support.md) | CSS Float Layout Support | Accepted |
| [0004](0004-kinsoku-processor.md) | CJK Line-Breaking (Kinsoku Shori) | Accepted |
| [0005](0005-inline-span-paradigm.md) | InlineSpan Over Widget Tree | Accepted |

## Creating a New ADR

1. Copy `template.md` to `NNNN-title-with-dashes.md`
2. Fill in the sections
3. Submit for review
4. Update this index

## References

- [ADR GitHub Organization](https://adr.github.io/)
- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
