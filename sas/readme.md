# SAS Utilities

Reusable SAS macros for Statistical programming and CDISC dataset development.

## Available Macros

### `%build_cdisc`

**File:** `build_cdisc.sas`

Builds final SDTM or ADaM datasets from a programmed intermediate dataset using
synchronized specification metadata.

#### Main Features

- Creates final datasets in the `SDTM` or `ADAM` library
- Uses synchronized dataset and variable metadata from the `SPEC` library
- Retains variables in specification order
- Applies variable labels from specification metadata
- Sorts datasets using the Key Variables defined in dataset metadata
- Generates SDTM `--SEQ` variables when applicable
- Creates SDTM `SUPPxx` datasets from supplemental-variable metadata
- Checks for variables defined in the specification but missing from the input dataset
- Supports debug mode for retaining intermediate processing datasets

#### Syntax

```sas
%build_cdisc(
    dev=,
    inds=,
    dsn=,
    debug=N
);
```

#### Parameters

| Parameter | Description | Required | Default |
|---|---|---:|---|
| `DEV` | Development standard: `SDTM` or `ADAM` | Yes | |
| `INDS` | Programmed intermediate SAS dataset | Yes | |
| `DSN` | Final CDISC dataset name | Yes | |
| `DEBUG` | `Y` retains temporary `WORK._BC_*` datasets | No | `N` |

#### Examples

```sas
%build_cdisc(dev=SDTM, inds=dm_pre, dsn=DM);

%build_cdisc(dev=ADAM, inds=adsl_pre, dsn=ADSL);
```

#### Required Metadata

For SDTM:

```text
SPEC.SDTM_DATASETS
SPEC.SDTM_VARIABLES
SPEC.SDTM_SUPPVARIABLES
```

For ADaM:

```text
SPEC.ADAM_DATASETS
SPEC.ADAM_VARIABLES
```

The required specification metadata must be synchronized before the macro is
executed.

For SDTM supplemental qualifiers, source variables in the programmed
intermediate dataset use an underscore prefix. For example, a supplemental
variable `STATUS` is sourced from `_STATUS`.

---

### `%isodtc`

**File:** `isodtc.sas`

Creates an ISO 8601 character date/time value from available numeric or
character date and time variables.

The macro is designed to be called within a SAS DATA step.

#### Supported Inputs

The macro can derive the output DTC value using:

- Numeric SAS datetime
- Numeric SAS date
- Character date
- Numeric time
- Character time
- Combinations of available date and time inputs

It also provides options for controlling zero times and seconds in the resulting
ISO 8601 value.

#### Syntax

```sas
%isodtc(
    DATETIMEN=,
    DATEN=,
    DATEC=,
    TIMEN=,
    TIMEC=,
    OUTDTC=,
    RMZERTIM=N,
    RMZERSEC=Y,
    NOSECOND=Y,
    DEBUG=N
);
```

#### Parameters

| Parameter | Description | Required | Default |
|---|---|---:|---|
| `DATETIMEN` | Numeric SAS datetime variable | No | |
| `DATEN` | Numeric SAS date variable | No | |
| `DATEC` | Character date variable | No | |
| `TIMEN` | Numeric time variable | No | |
| `TIMEC` | Character time variable | No | |
| `OUTDTC` | Output ISO 8601 character variable | Yes | |
| `RMZERTIM` | Removes a zero time (`00:00`) when set to `Y` | No | `N` |
| `RMZERSEC` | Removes zero seconds when set to `Y` | No | `Y` |
| `NOSECOND` | Omits seconds from the time when set to `Y` | No | `Y` |
| `DEBUG` | Retains intermediate variables when set to `Y` | No | `N` |

#### Example

```sas
data dm;
    set raw.dm;

    %isodtc(
        daten=brthdt,
        outdtc=brthdtc
    );
run;
```

The macro supports partial character dates and constructs the corresponding DTC
value based on the available date and time components.

## Usage

Include the required macro before calling it in a SAS program.

For example:

```sas
%include "/path/to/global_utils/sas/build_cdisc.sas";
%include "/path/to/global_utils/sas/isodtc.sas";
```

Additional reusable SAS macros will be documented here as they are added to the
repository.

## License

These utilities are distributed under the repository's [MIT License](../LICENSE).
