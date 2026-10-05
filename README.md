# Global Utilities

Reusable **SAS, Python, and R utilities** for clinical programming workflows.

This repository contains general-purpose utilities developed to support clinical
data programming, CDISC dataset development, specification processing, validation,
and workflow automation.

## Repository Structure

```text
global_utils/
├── sas/        # SAS macros and utilities
├── python/     # Python utilities and automation
└── r/          # R utilities
```

## Utilities

### SAS

Reusable SAS macros and utilities for clinical programming and CDISC dataset
development.

See [SAS Utilities](sas/README.md) for available utilities, documentation, and
usage examples.

### Python

Reusable Python utilities for specification processing, SAS integration, and
clinical programming automation.

See [Python Utilities](python/README.md) for available utilities, documentation,
and usage examples.

### R

Reusable R utilities for clinical programming workflows.

See [R Utilities](r/README.md) for available utilities and documentation.

## Design

The utilities in this repository are intended to be:

- Reusable across studies and projects
- Independent of study-specific data and configuration
- Suitable for integration into automated programming workflows
- Maintained separately from study programming repositories
- Extensible across SAS, Python, and R

Study-specific programs, specifications, data, outputs, credentials, and
configuration should be maintained outside this repository.

## Validation

Utilities should be appropriately reviewed and validated before use in production
clinical programming workflows.

Users are responsible for confirming that generated datasets, metadata, and
outputs meet applicable study requirements, organizational procedures, CDISC
standards, and regulatory requirements.

## License

This project is licensed under the [MIT License](LICENSE).
