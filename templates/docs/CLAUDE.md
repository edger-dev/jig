<!-- jig:docs -->
## Documentation

This project uses [mdbook](https://rust-lang.github.io/mdBook/) for documentation.
Source files are in `docs/src/`, built output goes to `docs/dist/`.

- `mise run _docs-serve` — start live-reload dev server
- `mise run docs-build` — build static site

When making changes that affect user-facing behavior, update the relevant
documentation in `docs/src/` as part of the same commit.
<!-- /jig:docs -->
