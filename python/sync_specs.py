"""sync_specs.py

Sync SDTM, ADaM and TLF specification workbooks from <study_root>/Specs.

Standalone:
    python sync_specs.py "D:\\Work\\MyGithub\\TRN001-Code"

With SASPy from CLI:
    python sync_specs.py "D:\\Work\\MyGithub\\TRN001-Code" --sas --cfgname oda

From SASPyStudio / existing SASPy session:
    from sync_specs import sync_specs
    result = sync_specs(study_root=self.study_root, sas=self.sas)

Dependencies: pandas, openpyxl. SASPy is optional unless SAS output is requested.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Any, Dict, Optional

try:
    import pandas as pd
except ImportError as exc:
    raise SystemExit("pandas is required. Install with: pip install pandas openpyxl") from exc

SPEC_FILES = {
    "SDTM": "SDTM_Specification.xlsx",
    "ADAM": "ADaM_Specification.xlsx",
    "TLF": "TLF_Specification.xlsx",
}
YES_VALUES = {"Y", "YES", "TRUE", "1"}
NO_VALUES = {"N", "NO", "FALSE", "0"}
DROP_RUNTIME_COLUMNS = {"LENGTH", "SIGNIFICANT DIGITS"}
PROGRAMMING_SHEETS = {
    "SDTM": {"DATASETS", "VARIABLES", "SUPPVARIABLES"},
    "ADAM": {"DATASETS", "VARIABLES"},
}


def _text(value: Any) -> str:
    return "" if pd.isna(value) else str(value).strip()


def _yes(value: Any) -> bool:
    return _text(value).upper() in YES_VALUES


def _lookup(df: pd.DataFrame) -> Dict[str, str]:
    return {str(c).strip().upper(): c for c in df.columns}


def _column(df: pd.DataFrame, name: str) -> Optional[str]:
    return _lookup(df).get(name.strip().upper())


def _sas_name(value: str, max_len: int = 32) -> str:
    name = re.sub(r"[^A-Za-z0-9_]", "_", str(value).strip())
    name = re.sub(r"_+", "_", name).strip("_").upper() or "SHEET"
    if not re.match(r"^[A-Za-z_]", name):
        name = "_" + name
    return name[:max_len]


def _unique_sas_columns(columns) -> list[str]:
    used, result = set(), []
    for original in columns:
        base = _sas_name(str(original))
        candidate, n = base, 2
        while candidate in used:
            suffix = f"_{n}"
            candidate = base[: 32 - len(suffix)] + suffix
            n += 1
        used.add(candidate)
        result.append(candidate)
    return result


def _remove_empty(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    for col in df.columns:
        if df[col].dtype == object:
            df[col] = df[col].map(
                lambda x: pd.NA if isinstance(x, str) and not x.strip() else x
            )
    return df.dropna(axis=0, how="all").dropna(axis=1, how="all").reset_index(drop=True)


def _read_workbook(path: Path) -> Dict[str, pd.DataFrame]:
    book = pd.ExcelFile(path, engine="openpyxl")
    sheets = {}
    for sheet in book.sheet_names:
        df = pd.read_excel(book, sheet_name=sheet, dtype=object, engine="openpyxl")
        df = _remove_empty(df)
        if not df.empty and len(df.columns):
            sheets[sheet] = df
    return sheets


def _find_sheet(sheets, requested):
    for name, df in sheets.items():
        if name.strip().upper() == requested.upper():
            return name, df
    return None, None


def _validate_select(df, sheet, warnings):
    col = _column(df, "Select")
    if not col:
        return
    values = {_text(v).upper() for v in df[col] if _text(v)}
    bad = sorted(values - YES_VALUES - NO_VALUES)
    if bad:
        warnings.append(f"{sheet}: unexpected Select value(s): {', '.join(bad)}; expected Y/N.")


def _selected_datasets(sheets, warnings):
    sheet, df = _find_sheet(sheets, "Datasets")
    if df is None:
        return None
    ds = _column(df, "Dataset")
    sel = _column(df, "Select")
    if not ds:
        warnings.append("Datasets sheet does not contain a Dataset column.")
        return None
    _validate_select(df, sheet or "Datasets", warnings)
    if sel:
        values = df.loc[df[sel].map(_yes), ds]
    else:
        warnings.append("Datasets sheet has no Select column; all datasets will be retained.")
        values = df[ds]
    return {_text(v).upper() for v in values if _text(v)}


def _filter_sheet(sheet_name, df, selected, warnings):
    out = df.copy()
    upper = sheet_name.strip().upper()
    ds = _column(out, "Dataset")
    sel = _column(out, "Select")

    if upper == "DATASETS":
        if sel:
            out = out.loc[out[sel].map(_yes)].copy()
        elif selected is not None and ds:
            out = out.loc[out[ds].map(lambda x: _text(x).upper() in selected)].copy()

    elif upper == "VARIABLES":
        if ds and selected is not None:
            out = out.loc[out[ds].map(lambda x: _text(x).upper() in selected)].copy()
        if sel:
            _validate_select(out, "Variables", warnings)
            keep = out[sel].map(_yes)
            mandatory = _column(out, "Mandatory")
            if mandatory:
                keep = keep | out[mandatory].map(_yes)
            out = out.loc[keep].copy()
        else:
            warnings.append("Variables sheet has no Select column; all variables for retained datasets will be retained.")

    elif ds and selected is not None:
        # ValueLevel and any other dataset-scoped sheets follow dataset selection.
        out = out.loc[out[ds].map(lambda x: _text(x).upper() in selected)].copy()

    return out.reset_index(drop=True)


def _runtime_df(df):
    out = df.copy()
    lookup = _lookup(out)
    drop = []
    if "SELECT" in lookup:
        drop.append(lookup["SELECT"])
    for name in DROP_RUNTIME_COLUMNS:
        if name in lookup:
            drop.append(lookup[name])
    if drop:
        out = out.drop(columns=drop)
    out.columns = _unique_sas_columns(out.columns)
    for col in out.columns:
        if out[col].dtype == object:
            out[col] = out[col].map(lambda x: "" if pd.isna(x) else str(x).strip())
    return out.reset_index(drop=True)


def _process_standard(standard, path):
    raw = _read_workbook(path)
    warnings = []
    selected = _selected_datasets(raw, warnings)
    sheets = {}
    allowed = PROGRAMMING_SHEETS.get(standard.upper())
    for name, df in raw.items():
        if allowed is not None and name.strip().upper() not in allowed:
            continue
        filtered = _filter_sheet(name, df, selected, warnings)
        if not filtered.empty:
            sheets[name] = _runtime_df(filtered)
    return {"standard": standard, "path": path, "selected_datasets": selected,
            "sheets": sheets, "warnings": warnings}


def _ensure_spec_library(sas):
    code = r'''
%let _spec_parent=%sysfunc(pathname(work));
%let _spec_dir=&_spec_parent/spec;
data _null_;
  length parent child $1024;
  parent=pathname("work");
  child=cats(parent,"/spec");
  if fileexist(child)=0 then rc=dcreate("spec",parent);
run;
libname spec "&_spec_dir";
'''
    result = sas.submit(code)
    log = str(result.get("LOG", "")) if isinstance(result, dict) else ""
    if "ERROR:" in log.upper():
        raise RuntimeError("SAS error while assigning SPEC library:\n" + log)


def _write_to_sas(sas, processed, verbose):
    _ensure_spec_library(sas)
    written = {}
    for standard, info in processed.items():
        for sheet, df in info["sheets"].items():
            member = _sas_name(f"{standard}_{sheet}")
            if verbose:
                print(f"  -> SPEC.{member}: {len(df):,} row(s), {len(df.columns):,} column(s)")
            sas.submit(f"proc datasets library=spec nolist; delete {member}; quit;")
            result = sas.df2sd(df, table=member, libref="SPEC")
            if result is None:
                raise RuntimeError(f"SASPy did not confirm creation of SPEC.{member}.")
            written[f"SPEC.{member}"] = len(df)
    return written


def sync_specs(study_root: str | Path, sas=None, specs_folder="Specs", verbose=True):
    """Process all supported specification files present in <study_root>/Specs."""
    root = Path(study_root).expanduser().resolve()
    specs_dir = root / specs_folder
    if not root.exists():
        raise FileNotFoundError(f"Study root not found: {root}")
    if not specs_dir.exists():
        raise FileNotFoundError(f"Specs folder not found: {specs_dir}")

    if verbose:
        print("=" * 68)
        print("SYNC SPECS")
        print("=" * 68)
        print(f"Study root : {root}")
        print(f"Specs      : {specs_dir}\n")

    processed, missing = {}, []
    for standard, filename in SPEC_FILES.items():
        path = specs_dir / filename
        if not path.exists():
            missing.append(filename)
            if verbose:
                print(f"- {filename}: not found")
            continue
        if verbose:
            print(f"+ {filename}")
        info = _process_standard(standard, path)
        processed[standard] = info
        if verbose:
            selected = info["selected_datasets"]
            if selected is not None:
                print(f"  Selected datasets : {len(selected):,}")
            for sheet, df in info["sheets"].items():
                print(f"  {sheet:<20} {len(df):>6,} row(s)")
            for warning in info["warnings"]:
                print(f"  WARNING: {warning}")
            print()

    if not processed:
        raise FileNotFoundError(
            f"No supported specification files found in {specs_dir}. Expected one or more of: "
            + ", ".join(SPEC_FILES.values())
        )

    sas_tables = {}
    if sas is not None:
        if verbose:
            print("Synchronizing specifications to SAS...")
        sas_tables = _write_to_sas(sas, processed, verbose)
        if verbose:
            print("SPEC library synchronized successfully.\n")
    elif verbose:
        print("Standalone mode: no SAS connection supplied; read/filter/validation completed.\n")

    summary = {
        "study_root": str(root),
        "specs_folder": str(specs_dir),
        "found": {k: str(v["path"]) for k, v in processed.items()},
        "missing": missing,
        "standards": {
            standard: {
                "selected_datasets": sorted(info["selected_datasets"]) if info["selected_datasets"] is not None else None,
                "sheets": {sheet: {"rows": len(df), "columns": len(df.columns)} for sheet, df in info["sheets"].items()},
                "warnings": info["warnings"],
            }
            for standard, info in processed.items()
        },
        "sas_tables": sas_tables,
    }
    if verbose:
        print("=" * 68)
        print("SYNC SPECS COMPLETE")
        print("=" * 68)
    return summary


def _connect_saspy(cfgname):
    """Connect with SASPy using the same sas_config.json/authinfo approach as SASPyStudio."""
    import json
    import os

    try:
        import saspy
    except ImportError as exc:
        raise RuntimeError("SASPy is not installed. Run without --sas, or install/configure SASPy.") from exc

    script_dir = Path(__file__).resolve().parent
    candidates = [
        Path.cwd() / "sas_config.json",
        script_dir / "sas_config.json",
        script_dir.parent.parent.parent / "SASPyStudio" / "sas_config.json",
    ]
    config_file = next((path for path in candidates if path.exists()), None)
    if config_file is None:
        raise FileNotFoundError(
            "sas_config.json was not found. Keep it in the current folder, beside sync_specs.py, "
            "or in the SASPyStudio folder."
        )

    cfg = json.loads(config_file.read_text(encoding="utf-8"))
    authinfo = Path(str(cfg.get("authinfo", "_authinfo"))).expanduser()
    if not authinfo.is_absolute():
        authinfo = config_file.parent / authinfo
    authinfo = authinfo.resolve()
    if not authinfo.exists():
        raise FileNotFoundError(f"Authinfo file not found: {authinfo}")

    runtime_cfg = config_file.parent / ".saspy_runtime_cfg.py"
    runtime_cfg.write_text(
        "SAS_config_names = ['" + cfgname + "']\n"
        + cfgname + " = {\n"
        f"    'java': r'{cfg['java_path']}',\n"
        f"    'iomhost': '{cfg['iom_host']}',\n"
        f"    'iomport': {int(cfg['iom_port'])},\n"
        f"    'authkey': '{cfg.get('authkey', cfgname)}',\n"
        f"    'encoding': '{cfg.get('encoding', 'utf-8')}',\n"
        "}\n",
        encoding="utf-8",
    )

    old_userprofile = os.environ.get("USERPROFILE")
    old_home = os.environ.get("HOME")
    try:
        os.environ["USERPROFILE"] = str(authinfo.parent)
        os.environ["HOME"] = str(authinfo.parent)
        return saspy.SASsession(cfgname=cfgname, cfgfile=str(runtime_cfg))
    finally:
        if old_userprofile is None:
            os.environ.pop("USERPROFILE", None)
        else:
            os.environ["USERPROFILE"] = old_userprofile
        if old_home is None:
            os.environ.pop("HOME", None)
        else:
            os.environ["HOME"] = old_home


def main():
    parser = argparse.ArgumentParser(description="Process study specs and optionally synchronize them to SAS.")
    parser.add_argument("study_root", help=r"Study root, e.g. D:\Work\MyGithub\TRN001-Code")
    parser.add_argument("--sas", action="store_true", help="Connect with SASPy and create SPEC datasets.")
    parser.add_argument("--cfgname", default="oda", help="SASPy config name (default: oda).")
    parser.add_argument("--specs-folder", default="Specs", help="Specs folder beneath study root.")
    args = parser.parse_args()
    sas = None
    try:
        if args.sas:
            print(f"Connecting to SASPy configuration: {args.cfgname}")
            sas = _connect_saspy(args.cfgname)
            print("SAS connection established.\n")
        sync_specs(args.study_root, sas=sas, specs_folder=args.specs_folder)
        return 0
    except Exception as exc:
        print(f"\nERROR: {exc}", file=sys.stderr)
        return 1
    finally:
        if args.sas and sas is not None:
            try:
                sas.endsas()
            except Exception:
                pass


if __name__ == "__main__":
    raise SystemExit(main())
