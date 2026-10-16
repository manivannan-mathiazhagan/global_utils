# Global Utilities

Reusable **SAS, Python, and R utilities** for statistical programming and clinical data development.

Global Utilities is an open-source repository containing reusable tools designed to support clinical programming, CDISC dataset development, specification processing, data validation, and workflow automation.

The utilities are maintained independently of individual studies and projects, allowing them to be reused across different programming environments.

## Repository Structure

```text
global_utils/
├── python/
│   ├── sync_specs.py
│   └── readme.md
│
├── r/
│   └── README.md
│
├── sas/
│   ├── 001_macro/
│   │   ├── build_cdisc.sas
│   │   └── isodtc.sas
│   │
│   ├── 999_code/
│   │   ├── build_global_utils.sas
│   │   └── load_global_utils.sas
│   │
│   └── description.sas
│
├── global_utils.zip
├── global_utils.md
├── .gitignore
├── LICENSE
└── README.md
```

## SAS Utilities

The SAS utilities are developed and distributed using the [SAS Packages Framework (SPF)](https://github.com/yabwon/SAS_PACKAGES).

The package is named **Global_Utils** and contains reusable SAS macros for clinical and statistical programming.

### Available SAS Macros — `sas/001_macro/`

The [`sas/001_macro/`](sas/001_macro/) directory contains the SAS macros included in the Global_Utils SPF package.

Each macro is maintained as an individual `.sas` file with standardized HELP documentation covering its purpose, parameters, usage examples, prerequisites, and change history.

| Macro | Description |
|---|---|
| `%build_cdisc` | Builds final SDTM or ADaM datasets using synchronized specification metadata, including variable ordering, labels, sorting, sequence generation, and supplemental qualifiers |
| `%isodtc` | Derives ISO 8601-style character date/time values from numeric or character date and time inputs |

Additional macros will be introduced in future package releases.

### Package Metadata — `sas/description.sas`

The [`sas/description.sas`](sas/description.sas) file contains the package-level metadata used by SPF to identify, describe, and build Global_Utils.

It is the central configuration file for maintaining the package name, version, author, maintainer, license, encoding, software requirements, dependencies, and description.

Current package metadata:

```text
Type        : Package
Package     : Global_Utils
Title       : Global_Utils -- Reusable SAS Utilities for Clinical Programming
Version     : 0.1.0
Author      : [Manivannan Mathialagan]
Maintainer  : Manivannan Mathialagan
License     : MIT
Encoding    : UTF8
Required    : "Base SAS Software"
ReqPackages :
```

#### Metadata Fields

| Field | Description |
|---|---|
| `Type` | Identifies the component as an SPF package |
| `Package` | Defines the package name used during installation and loading |
| `Title` | Provides a descriptive title for the package |
| `Version` | Defines the current package version |
| `Author` | Identifies the package author |
| `Maintainer` | Identifies the person responsible for maintaining the package |
| `License` | Specifies the package license |
| `Encoding` | Defines the character encoding |
| `Required` | Identifies the required SAS software |
| `ReqPackages` | Lists other SPF package dependencies, when applicable |

The file also contains a `DESCRIPTION START:` / `DESCRIPTION END:` section providing an overview of the package in Markdown format.

#### Package Version Management

The `Version` field in `sas/description.sas` is the **authoritative source for the Global_Utils package version**.

For example:

```text
Version : 0.1.0
```

The package version is updated when preparing a new release.

Individual SAS macros may maintain their own change history within their HELP headers. These macro-level versions are independent of the overall Global_Utils package version.

The build and load example programs do not require separate version numbers.

### Macro Documentation

Each SAS macro maintains its documentation directly within the source file using SPF-compatible HELP blocks.

The documentation typically includes:

- Macro name and purpose
- Input parameters and default values
- Input and output datasets or variables
- Usage examples
- Prerequisites and notes
- Author, creation date, and change history

Standard HELP header format:

```sas
/*** HELP START ***//*

### Macro:
    %macro_name

### Purpose:
    Description of the macro.

### Parameters:
    Parameter descriptions and default values.

### Input Datasets:
    Input dataset requirements.

### Output Datasets:
    Expected outputs.

### Sample code:

~~~sas
%macro_name(
    parameter=value
);
~~~

### Notes:
    Additional information.

### Author:
    Author name

### Latest Update Date:
    YYYY-MM-DD

*//*** HELP END ***/
```

Maintaining documentation alongside the macro source helps keep the usage instructions synchronized with code changes.

The package build process generates Markdown documentation using SPF's `markdownDoc=1` option.

The generated documentation is available in [`global_utils.md`](global_utils.md).

### Package Build and Loading Programs — `sas/999_code/`

The [`sas/999_code/`](sas/999_code/) directory contains supporting programs for building, installing, and loading the Global_Utils package.

These are utility scripts rather than callable macros from `001_macro`.

| Program | Purpose |
|---|---|
| [`build_global_utils.sas`](sas/999_code/build_global_utils.sas) | Generates the package ZIP and Markdown documentation, copies the generated artifacts into the repository, and verifies the ZIP |
| [`load_global_utils.sas`](sas/999_code/load_global_utils.sas) | Demonstrates installation and loading of Global_Utils from the public GitHub repository |

The intended SPF distribution consists of the package metadata and reusable macro components. The build and loading scripts are maintained separately for development and usage examples.

### Building the SPF Package

The package is generated using:

[`sas/999_code/build_global_utils.sas`](sas/999_code/build_global_utils.sas)

The build process:

1. Initializes the SAS Packages Framework.
2. Reads package metadata from `sas/description.sas`.
3. Reads the reusable macro source files from `sas/001_macro/`.
4. Generates the SPF package ZIP and Markdown documentation in the SAS WORK directory.
5. Copies the generated files into the repository.
6. Verifies that the copied ZIP can be opened successfully.

The build process produces two main artifacts:

| File | Description |
|---|---|
| [`global_utils.zip`](global_utils.zip) | Installable SPF package containing the Global_Utils macros |
| [`global_utils.md`](global_utils.md) | Generated package documentation |

These files are stored at the repository root so users can access the published package without building it themselves.

### Installing Global_Utils from GitHub

Global_Utils can be installed directly from this public GitHub repository using the SAS Packages Framework.

**Prerequisites:**

- A compatible SAS environment
- SAS Packages Framework initialized
- Network access to GitHub

After initializing SPF, execute:

```sas
/* Assign package installation directory */
filename packages "%sysfunc(pathname(work))";

/* Install Global_Utils from GitHub */
%installPackage(
    global_utils,
    github=manivannan-mathiazhagan,
    githubRepo=global_utils,
    replace=1
);

/* Load the package */
%loadPackage(global_utils);
```

For an environment-specific example that includes SPF initialization, refer to [`sas/999_code/load_global_utils.sas`](sas/999_code/load_global_utils.sas).

Using SAS WORK as the installation directory means the package must be installed again in a new SAS session. A persistent package directory may be configured for regular use.

### Verify Package Loading

After loading the package, check whether the macros are available:

```sas
%put NOTE: BUILD_CDISC=%sysmacexist(build_cdisc);
%put NOTE: ISODTC=%sysmacexist(isodtc);
```

Expected results:

```text
NOTE: BUILD_CDISC=1
NOTE: ISODTC=1
```

A result of `1` confirms that the corresponding macro is available in the current SAS session.

This does not constitute functional validation of the macro.

### Package Releases and Generated Artifacts

Global_Utils uses the package version defined in `sas/description.sas`.

When preparing a new package release:

1. Update or add SAS macros in `sas/001_macro/`.
2. Update the HELP documentation within the affected macro files.
3. Update the package version in `sas/description.sas`.
4. Execute `sas/999_code/build_global_utils.sas`.
5. Regenerate `global_utils.zip` and `global_utils.md`.
6. Verify the package contents and test the affected macros.
7. Commit the updated macro source, package metadata, ZIP, and Markdown documentation to GitHub.
8. Create a GitHub tag or release corresponding to the package version.

The generated `global_utils.zip` and `global_utils.md` files are updated and committed whenever a new package version is released.

Package builds may also be performed during development without publishing a new release.

The package version is managed independently of individual macro change histories.

## Python Utilities

The [`python/`](python/) directory contains reusable Python utilities supporting clinical programming, specification processing, SAS integration, and workflow automation.

### Available Python Utilities

| Utility | Description |
|---|---|
| [`sync_specs.py`](python/sync_specs.py) | Utility for specification synchronization workflows |

Python utilities are maintained independently of the SAS SPF package.

Refer to [`python/readme.md`](python/readme.md) for additional documentation and usage instructions.

## R Utilities

The [`r/`](r/) directory is intended for reusable R functions and utilities supporting statistical programming and clinical data workflows.

R utilities are maintained independently of the SAS SPF package.

Refer to [`r/README.md`](r/README.md) for additional information.

## Design Principles

Global Utilities follows these principles:

- **Reusable:** Utilities are designed for use across multiple studies and projects.
- **Modular:** SAS, Python, and R utilities are organized independently.
- **Specification-driven:** Utilities may use standardized metadata to support clinical programming.
- **Documented:** SAS macros maintain standardized HELP documentation within their source files.
- **Version-controlled:** Source code and published package artifacts are maintained in GitHub.
- **Maintainable:** Package build and loading programs are separated from reusable macros.
- **Extensible:** Additional utilities can be introduced without changing the overall repository structure.

Study-specific programs, specifications, data, outputs, credentials, and configurations should remain outside this repository.

## Validation

Utilities should be appropriately reviewed and validated before use in production clinical programming workflows.

Successful package installation or loading does not constitute functional validation.

Users are responsible for confirming that generated datasets, metadata, and outputs meet applicable study requirements, organizational procedures, CDISC standards, and regulatory requirements.

## License

This project is licensed under the [MIT License](LICENSE).
