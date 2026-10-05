# Python Utilities

Reusable Python utilities for clinical programming and workflow automation.

## Available Utilities

### `sync_specs.py`

Synchronizes study specification metadata from Excel workbooks for use in
clinical programming workflows.

The utility reads specification workbooks from the study repository `Specs`
folder, applies programming-specific filtering and validation, and can optionally
create corresponding metadata datasets in the SAS `SPEC` library.

### Supported Specifications

The utility currently supports:

```text
SDTM_Specification.xlsx
ADaM_Specification.xlsx
TLF_Specification.xlsx
```

For SDTM programming, the following specification sheets are processed:

```text
Datasets
Variables
SuppVariables
```

For ADaM programming:

```text
Datasets
Variables
```

TLF specifications are also recognized by the synchronization process.

## Main Features

- Reads specification workbooks from `<study_root>/Specs`
- Processes SDTM, ADaM, and TLF specifications when available
- Uses the `Select` column to determine selected datasets
- Retains selected variables for selected datasets
- Retains mandatory variables even when they are not explicitly selected
- Processes SDTM supplemental-variable metadata
- Removes non-runtime specification columns before creating SAS metadata
- Converts column names to valid SAS variable names
- Validates unexpected `Select` values
- Supports standalone Python execution
- Supports SASPy integration
- Creates synchronized metadata datasets in the SAS `SPEC` library
- Can be called directly from SASPyStudio using an existing SAS session

## Requirements

Required Python packages:

```text
pandas
openpyxl
```

For SAS integration:

```text
saspy
```

Install the required packages using:

```powershell
pip install pandas openpyxl
```

If SAS integration is required:

```powershell
pip install saspy
```

## Usage

### Standalone Python

Process and validate the specification workbooks without creating SAS datasets:

```powershell
python sync_specs.py "D:\Work\MyGithub\TRN001-Code"
```

### SASPy

Process the specifications and synchronize the resulting metadata to SAS:

```powershell
python sync_specs.py "D:\Work\MyGithub\TRN001-Code" --sas --cfgname oda
```

The SASPy configuration name defaults to:

```text
oda
```

### From Python

The utility can also be imported and called from another Python application:

```python
from sync_specs import sync_specs

result = sync_specs(
    study_root=r"D:\Work\MyGithub\TRN001-Code"
)
```

### From SASPyStudio

When an existing SASPy session is available:

```python
from sync_specs import sync_specs

result = sync_specs(
    study_root=self.study_root,
    sas=self.sas
)
```

This allows SASPyStudio to reuse its active SAS session rather than creating a
separate SAS connection.

## SAS Metadata

When a SAS session is supplied, the utility creates and assigns the `SPEC`
library and writes the processed programming metadata as SAS datasets.

Examples include:

```text
SPEC.SDTM_DATASETS
SPEC.SDTM_VARIABLES
SPEC.SDTM_SUPPVARIABLES

SPEC.ADAM_DATASETS
SPEC.ADAM_VARIABLES
```

These metadata datasets can then be consumed by downstream SAS utilities such
as `%build_cdisc`.

## SASPy Configuration

When executed from the command line with `--sas`, the utility searches for
`sas_config.json` and uses the configured authentication information to establish
the SASPy connection.

Credentials and authentication files should not be committed to this repository.

## Study Repository

A typical study repository using this utility may contain:

```text
TRN001-Code/
├── Specs/
│   ├── SDTM_Specification.xlsx
│   ├── ADaM_Specification.xlsx
│   └── TLF_Specification.xlsx
├── sas/
├── python/
└── r/
```

The specification workbooks remain study-specific. Only the reusable
`sync_specs.py` utility is maintained in this global utilities repository.

## License

This utility is distributed under the repository's [MIT License](../LICENSE).
