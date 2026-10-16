
/*** HELP START ***//*

### Macro:
    %build_cdisc

### Purpose:
    Builds final SDTM or ADaM datasets from a programmed intermediate
    SAS dataset using synchronized CDISC specification metadata.

    The macro applies specification-defined variable order, labels,
    sorting, and SDTM sequence numbering. For SDTM, it also creates
    the corresponding SUPPxx dataset when supplemental qualifiers
    are defined and contain nonmissing values.

### Parameters:

 - `dev` (required)
      Specifies the CDISC dataset type.

      Valid values:
      - SDTM
      - ADAM

      The macro uses this value to determine the output library
      and corresponding specification metadata.

 - `inds` (required)
      Input intermediate SAS dataset containing the programmed
      variables.

      Example: `WORK.DM_FINAL`

      The dataset must exist before executing the macro.

 - `dsn` (required)
      Name of the final CDISC dataset to create.

      Examples:
      - DM
      - AE
      - ADSL
      - ADAE

      The dataset name must be defined in the corresponding
      specification metadata.

 - `debug` (optional)
      Controls whether temporary BUILD_CDISC datasets are retained.

      Valid values:
      - Y: Retain temporary WORK._BC_* datasets.
      - N: Delete temporary WORK._BC_* datasets.

      Default: N

### Input Datasets:

    Programmed intermediate dataset:
    - Dataset specified by `inds`

    SDTM specification metadata:
    - SPEC.SDTM_DATASETS
    - SPEC.SDTM_VARIABLES
    - SPEC.SDTM_SUPPVARIABLES

    ADaM specification metadata:
    - SPEC.ADAM_DATASETS
    - SPEC.ADAM_VARIABLES

### Output Datasets:

    SDTM:
    - SDTM.<dsn>
    - SDTM.SUPP<dsn>, when applicable

    ADaM:
    - ADAM.<dsn>

    Temporary datasets:
    - WORK._BC_VARS
    - WORK._BC_MAIN
    - WORK._BC_SUPP
    - WORK._BC_ONE_SUPP

    Temporary datasets are retained only when DEBUG=Y.

### How it works:

 1. Validates the required parameters and input dataset.

 2. Determines the output library and metadata datasets
    based on DEV=SDTM or DEV=ADAM.

 3. Retrieves dataset sorting information from the
    specification dataset metadata.

 4. Retrieves variable metadata in specification order.

 5. Identifies variables defined in the specification
    but missing from the programmed intermediate dataset
    and writes a warning to the SAS log.

 6. Sorts the intermediate dataset using the
    specification-defined key variables.

 7. For SDTM datasets, generates the --SEQ variable
    when defined in the specification.

    Sequence numbering is performed within STUDYID
    and/or USUBJID when those variables are available.

 8. Applies variable labels and retains variables
    in the specification-defined order.

 9. Creates the final dataset in the SDTM or ADAM
    output library.

10. Applies the final specification-defined sort order.

11. For SDTM, creates SUPPxx from supplemental
    specification metadata when applicable.

12. Deletes temporary WORK datasets unless DEBUG=Y.

### Sample code:

#### Example 1: Build an SDTM DM dataset

~~~sas
%build_cdisc(
    dev=SDTM,
    inds=WORK.DM_FINAL,
    dsn=DM
);
~~~

#### Example 2: Build an SDTM AE dataset

~~~sas
%build_cdisc(
    dev=SDTM,
    inds=WORK.AE_FINAL,
    dsn=AE,
    debug=N
);
~~~

#### Example 3: Build an ADaM ADSL dataset

~~~sas
%build_cdisc(
    dev=ADAM,
    inds=WORK.ADSL_FINAL,
    dsn=ADSL
);
~~~

#### Example 4: Retain intermediate datasets for debugging

~~~sas
%build_cdisc(
    dev=SDTM,
    inds=WORK.LB_FINAL,
    dsn=LB,
    debug=Y
);
~~~

### Prerequisites:

 - The SPEC library must be assigned.

 - The SDTM or ADAM output library must be assigned.

 - Specification metadata must be synchronized before
   executing the macro.

 - The input intermediate dataset must exist.

 - The target dataset must have corresponding variable
   metadata in the specification.

 - For SDTM supplemental qualifiers, source variables
   must use an underscore prefix in the intermediate
   dataset.

### Notes:

 - The macro supports both SDTM and ADaM datasets.

 - Existing target datasets are deleted before the
   replacement dataset is created.

 - Only variables defined in the specification
   are retained in the final dataset.

 - Missing input variables defined in the specification
   generate warnings in the SAS log.

 - SDTM --SEQ numbering is generated when a sequence
   variable is defined in the specification.

 - Supplemental qualifier datasets are created only
   when applicable and nonmissing supplemental
   values are available.

 - The macro does not perform general CDISC compliance
   validation.

 - DEBUG=Y retains temporary datasets to support
   troubleshooting and review.

### Author:
    Manivannan Mathialagan

### Created Date:
    2026-10-04

### Latest Update Date:
    2026-10-04

### Change History:

| Version | Date       | Description     |
|---------|------------|-----------------|
| 1.0     | 2026-10-04 | Initial version |

*//*** HELP END ***/



%macro build_cdisc(dev=, inds=, dsn=, debug=N);

    %local _dev _dsn _debug _outlib _dsmeta _varmeta _suppmeta _keep _sort _sort_no_seq _seqvar _seqcnt
           _suppcnt _suppobs _nvars _seqby _dsid _rc _attr _missing _i _var _has_eval _has_idvar;

    %let _dev=%upcase(%sysfunc(strip(%superq(dev))));
    %let _dsn=%upcase(%sysfunc(strip(%superq(dsn))));
    %let _debug=%upcase(%sysfunc(strip(%superq(debug))));

    /* Validate required parameters */
    %if %superq(_dev)= %then %do;
        %put ERROR: BUILD_CDISC: DEV is required.;
        %return;
    %end;

    %if %superq(inds)= %then %do;
        %put ERROR: BUILD_CDISC: INDS is required.;
        %return;
    %end;

    %if %superq(_dsn)= %then %do;
        %put ERROR: BUILD_CDISC: DSN is required.;
        %return;
    %end;

    %if &_dev ne SDTM and &_dev ne ADAM %then %do;
        %put ERROR: BUILD_CDISC: DEV must be SDTM or ADAM. Received DEV=&_dev..;
        %return;
    %end;

    %if &_debug ne Y and &_debug ne N %then %do;
        %put ERROR: BUILD_CDISC: DEBUG must be Y or N. Received DEBUG=&_debug..;
        %return;
    %end;

    %if not %sysfunc(exist(&inds)) %then %do;
        %put ERROR: BUILD_CDISC: Input dataset &inds does not exist.;
        %return;
    %end;

    /* Resolve synchronized metadata and output library */
    %if &_dev=SDTM %then %do;
        %let _outlib=SDTM;
        %let _dsmeta=SPEC.SDTM_DATASETS;
        %let _varmeta=SPEC.SDTM_VARIABLES;
        %let _suppmeta=SPEC.SDTM_SUPPVARIABLES;
    %end;
    %else %do;
        %let _outlib=ADAM;
        %let _dsmeta=SPEC.ADAM_DATASETS;
        %let _varmeta=SPEC.ADAM_VARIABLES;
        %let _suppmeta=;
    %end;

    /* Validate synchronized metadata */
    %if not %sysfunc(exist(&_dsmeta)) %then %do;
        %put ERROR: BUILD_CDISC: Dataset metadata &_dsmeta does not exist.;
        %return;
    %end;

    %if not %sysfunc(exist(&_varmeta)) %then %do;
        %put ERROR: BUILD_CDISC: Variable metadata &_varmeta does not exist.;
        %return;
    %end;

    /* Get final sort order from dataset metadata */
    %let _sort=;

    proc sql noprint;
        select strip(KEY_VARIABLES) into :_sort trimmed
        from &_dsmeta
        where upcase(strip(DATASET))="&_dsn";
    quit;

    %let _sort=%sysfunc(tranwrd(%superq(_sort),%str(,),%str( )));
    %let _sort=%sysfunc(compbl(%superq(_sort)));

    /* Get runtime variable metadata in specification order */
    proc sql;
        create table work._bc_vars as
        select *
        from &_varmeta
        where upcase(strip(DATASET))="&_dsn"
        order by ORDER;
    quit;

    %let _nvars=0;
    %let _keep=;

    proc sql noprint;
        select count(*) into :_nvars trimmed
        from work._bc_vars;

        select strip(VARIABLE) into :_keep separated by " "
        from work._bc_vars;
    quit;

    %if &_nvars=0 %then %do;
        %put ERROR: BUILD_CDISC: No variable metadata found for &_dsn in &_varmeta..;
        %return;
    %end;

    /* Identify variables required by metadata but absent from the input */
    %let _missing=;
    %let _dsid=%sysfunc(open(&inds,i));

    %if &_dsid %then %do;
        %do _i=1 %to %sysfunc(countw(%superq(_keep),%str( )));
            %let _var=%scan(%superq(_keep),&_i,%str( ));
            %if %sysfunc(varnum(&_dsid,&_var))=0 %then %let _missing=&_missing &_var;
        %end;
        %let _rc=%sysfunc(close(&_dsid));
    %end;

    %let _missing=%sysfunc(compbl(%superq(_missing)));

    %if %length(%superq(_missing)) %then
        %put WARNING: BUILD_CDISC: Variables in SPEC but not present in &inds: &_missing..;

    /* Identify the SDTM sequence variable when one is defined */
    %let _seqvar=;
    %let _seqcnt=0;

    %if &_dev=SDTM %then %do;
        proc sql noprint;
            select count(*) into :_seqcnt trimmed
            from work._bc_vars
            where upcase(strip(VARIABLE)) like '%SEQ';

            select strip(VARIABLE) into :_seqvar trimmed
            from work._bc_vars
            where upcase(strip(VARIABLE)) like '%SEQ';
        quit;

        %if &_seqcnt > 1 %then %do;
            %put ERROR: BUILD_CDISC: More than one --SEQ variable was found for &_dsn..;
            %return;
        %end;
    %end;

    /* Exclude --SEQ from the pre-sequence sort */
    %let _sort_no_seq=&_sort;

    %if %length(%superq(_seqvar)) %then %do;
        %let _sort_no_seq=%sysfunc(prxchange(s/\b&_seqvar\b//i,-1,%superq(_sort_no_seq)));
        %let _sort_no_seq=%sysfunc(compbl(%superq(_sort_no_seq)));
    %end;

    /* Sort the programmed dataset before sequence generation */
    %if %length(%superq(_sort_no_seq)) %then %do;
        proc sort data=&inds out=work._bc_main;
            by &_sort_no_seq;
        run;
    %end;
    %else %do;
        data work._bc_main;
            set &inds;
        run;
    %end;

    /* Generate SDTM --SEQ within subject when applicable */
    %if &_dev=SDTM and %length(%superq(_seqvar)) %then %do;
        %let _seqby=;
        %let _dsid=%sysfunc(open(work._bc_main,i));

        %if &_dsid %then %do;
            %if %sysfunc(varnum(&_dsid,STUDYID)) > 0 %then %let _seqby=STUDYID;
            %if %sysfunc(varnum(&_dsid,USUBJID)) > 0 %then %let _seqby=&_seqby USUBJID;
            %let _rc=%sysfunc(close(&_dsid));
        %end;

        %let _seqby=%sysfunc(compbl(%superq(_seqby)));

        %if %length(%superq(_seqby)) %then %do;
            proc sort data=work._bc_main;
                by &_seqby &_sort_no_seq;
            run;

            data work._bc_main;
                set work._bc_main;
                by &_seqby &_sort_no_seq;
                retain &_seqvar;
                if first.%scan(&_seqby,-1,%str( )) then &_seqvar=1;
                else &_seqvar+1;
            run;
        %end;
        %else %do;
            data work._bc_main;
                set work._bc_main;
                &_seqvar=_N_;
            run;
        %end;
    %end;

    /* Build one ATTRIB statement for variable labels */
    %let _attr=;

    data _null_;
        set work._bc_vars end=eof;
        length _piece _all $32767;
        retain _all;

        if not missing(LABEL) then do;
            _piece=catx(' ',strip(VARIABLE),cats('label=',quote(trim(LABEL))));
            _all=catx(' ',_all,_piece);
        end;

        if eof then call symputx('_attr',_all,'L');
    run;

    /* Remove an existing target so success reflects this execution */
    proc datasets library=&_outlib nolist;
        delete &_dsn;
    quit;

    /* Create final dataset in specification variable order */
    data &_outlib..&_dsn;
        %if %length(%superq(_attr)) %then %do;
            attrib &_attr;
        %end;
        retain &_keep;
        set work._bc_main;
        keep &_keep;
    run;

    /* Apply final dataset sort order */
    %if %sysfunc(exist(&_outlib..&_dsn)) and %length(%superq(_sort)) %then %do;
        proc sort data=&_outlib..&_dsn;
            by &_sort;
        run;
    %end;

    /* Create SUPPxx for SDTM when supplemental variables are defined */
    %let _suppcnt=0;
    %let _suppobs=0;

    %if &_dev=SDTM and %sysfunc(exist(&_suppmeta)) %then %do;
        proc sql noprint;
            select count(*) into :_suppcnt trimmed
            from &_suppmeta
            where upcase(strip(DATASET))="&_dsn";
        quit;

        %if &_suppcnt > 0 %then %do;
            /* Determine whether optional SUPP metadata columns are available */
            %let _has_eval=0;
            %let _has_idvar=0;
            %let _dsid=%sysfunc(open(&_suppmeta,i));

            %if &_dsid %then %do;
                %if %sysfunc(varnum(&_dsid,EVALUATOR)) > 0 %then %let _has_eval=1;
                %if %sysfunc(varnum(&_dsid,IDVAR)) > 0 %then %let _has_idvar=1;
                %let _rc=%sysfunc(close(&_dsid));
            %end;

            /* Build each supplemental qualifier directly from WORK._BC_MAIN. */
            proc sql;
                create table work._bc_supp as
                select STUDYID, USUBJID,
                       "" as RDOMAIN length=8,
                       "" as IDVAR length=32,
                       "" as IDVARVAL length=200,
                       "" as QNAM length=8,
                       "" as QLABEL length=40,
                       "" as QVAL length=200,
                       "" as QORIG length=20,
                       "" as QEVAL length=40
                from work._bc_main
                where 0;
            quit;

            data _null_;
                set &_suppmeta;
                where upcase(strip(DATASET))="&_dsn";
                length _code $32767 _source _eval _idvar $200;

                _source=cats('_',strip(VARIABLE));
                _eval='';
                _idvar='';

                %if &_has_eval %then %do;
                    _eval=strip(vvaluex('EVALUATOR'));
                %end;

                %if &_has_idvar %then %do;
                    _idvar=strip(vvaluex('IDVAR'));
                %end;

                _code=catx(' ',
                    'data work._bc_one_supp;',
                    'set work._bc_main;',
                    'length RDOMAIN $8 IDVAR $32 IDVARVAL $200 QNAM $8 QLABEL $40 QVAL $200 QORIG $20 QEVAL $40;',
                    cats('RDOMAIN=',quote(trim(DATASET)),';'),
                    cats('QNAM=',quote(trim(VARIABLE)),';'),
                    cats('QLABEL=',quote(trim(LABEL)),';'),
                    cats('QVAL=strip(vvaluex(',quote(trim(_source)),'));'),
                    cats('QORIG=',quote(trim(ORIGIN)),';')
                );

                if not missing(_eval) then
                    _code=catx(' ',_code,cats('QEVAL=',quote(trim(_eval)),';'));
                else
                    _code=catx(' ',_code,'QEVAL="";');

                if not missing(_idvar) then do;
                    _code=catx(' ',_code,cats('IDVAR=',quote(trim(_idvar)),';'));
                    _code=catx(' ',_code,cats('IDVARVAL=strip(vvaluex(',quote(trim(_idvar)),'));'));
                end;
                else do;
                    _code=catx(' ',_code,'IDVAR="";');
                    _code=catx(' ',_code,'IDVARVAL="";');
                end;

                _code=catx(' ',_code,
                    'if not missing(QVAL);',
                    'keep STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QNAM QLABEL QVAL QORIG QEVAL;',
                    'run;',
                    'proc append base=work._bc_supp data=work._bc_one_supp force;',
                    'run;'
                );

                call execute(_code);
            run;

            %if %sysfunc(exist(work._bc_supp)) %then %do;
                proc sql noprint;
                    select count(*) into :_suppobs trimmed
                    from work._bc_supp;
                quit;
            %end;

            %if &_suppobs > 0 %then %do;
                proc datasets library=&_outlib nolist;
                    delete SUPP&_dsn;
                quit;

                data &_outlib..SUPP&_dsn;
                    set work._bc_supp;
                run;

                proc sort data=&_outlib..SUPP&_dsn;
                    by STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QNAM;
                run;
            %end;
            %else %do;
                %put NOTE: BUILD_CDISC: No nonmissing supplemental values found for &_dsn. SUPP&_dsn was not created.;
            %end;
        %end;
    %end;

    %if &_debug=Y %then %do;
        %put NOTE: BUILD_CDISC DEBUG: DEV=&_dev INDS=&inds DSN=&_dsn.;
        %put NOTE: BUILD_CDISC DEBUG: VARIABLES=&_nvars SORT=&_sort SEQ=&_seqvar.;
        %put NOTE: BUILD_CDISC DEBUG: SUPP METADATA=&_suppcnt SUPP OBSERVATIONS=&_suppobs.;
        %if %length(%superq(_missing)) %then
            %put NOTE: BUILD_CDISC DEBUG: MISSING INPUT VARIABLES=&_missing.;
        %put NOTE: BUILD_CDISC DEBUG: Temporary WORK._BC_* datasets retained.;
    %end;
    %else %do;
        proc datasets library=WORK nolist;
            delete _bc_vars _bc_main _bc_supp _bc_one_supp;
        quit;
    %end;

    %if %sysfunc(exist(&_outlib..&_dsn)) %then
        %put NOTE: BUILD_CDISC: &_outlib..&_dsn successfully created.;
    %else
        %put ERROR: BUILD_CDISC: &_outlib..&_dsn was not created.;

    %if &_dev=SDTM and &_suppobs > 0 %then %do;
        %if %sysfunc(exist(&_outlib..SUPP&_dsn)) %then
            %put NOTE: BUILD_CDISC: &_outlib..SUPP&_dsn successfully created.;
        %else
            %put ERROR: BUILD_CDISC: &_outlib..SUPP&_dsn was not created.;
    %end;

%mend build_cdisc;
