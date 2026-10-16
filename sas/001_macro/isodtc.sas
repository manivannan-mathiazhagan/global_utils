
/*** HELP START ***//*

### Macro:
    %isodtc

### Purpose:
    Derives a character date/time variable in ISO 8601-style format
    from numeric SAS datetime, numeric SAS date, character date,
    numeric time, and/or character time variables.

    Supports partial character dates and provides options to control
    the inclusion of zero time values and seconds.

    This macro is intended to be called inside a DATA step.

### Parameters:

 - `datetimen` (optional)
      Name of the input numeric SAS datetime variable.

      The date and time components are extracted from the
      supplied datetime value.

      Example: AESTDTM

      Default: (blank)

 - `daten` (optional)
      Name of the input numeric SAS date variable.

      The numeric date is converted to YYYY-MM-DD format.

      Example: AESTDT

      Default: (blank)

 - `datec` (optional)
      Name of the input character date variable.

      The macro extracts the year, month, and day from
      space-separated date components.

      Supported month representations include abbreviated
      month names and numeric month values.

      The macro also handles missing or unknown date components.

      Example: AESTDAT

      Default: (blank)

 - `timen` (optional)
      Name of the input numeric time-related variable.

      The macro uses TIMEPART() to derive the time component.

      Example: AESTTIM

      Default: (blank)

 - `timec` (optional)
      Name of the input character time variable.

      The value is interpreted using the SAS TIME informat
      and converted into a character time component.

      Example: AESTTIMC

      Default: (blank)

 - `outdtc` (required)
      Name of the output character date/time variable.

      The macro creates this variable with a length of $19.

      Example: AESTDTC

      Default: (blank)

 - `rmzertim` (optional)
      Controls whether zero time values are removed.

      Valid values:
      - Y: Remove zero time values where supported.
      - N: Retain zero time values.

      Default: N

 - `rmzersec` (optional)
      Controls the removal of zero seconds from time values.

      Valid values:
      - Y: Use time without seconds where supported.
      - N: Do not explicitly remove zero seconds.

      Default: Y

 - `nosecond` (optional)
      Controls whether seconds are included in the
      selected time format.

      Valid values:
      - Y: Use HH:MM format.
      - N: Use HH:MM:SS format where supported.

      Default: Y

 - `debug` (optional)
      Controls whether intermediate variables are retained.

      Valid values:
      - Y: Retain intermediate variables.
      - N: Drop intermediate variables.

      Default: N

### Input Variables:

    At least one of the following inputs must be specified:
    - DATETIMEN
    - DATEN
    - DATEC
    - TIMEN
    - TIMEC

    The input variables must exist in the current DATA step.

### Output Variables:

    The macro creates the character variable specified
    by OUTDTC.

    Output length: $19

    Depending on the available date and time components,
    the output may contain:

    - YYYY-MM-DD
    - YYYY-MM-DDTHH:MM
    - YYYY-MM-DDTHH:MM:SS
    - YYYY-MM
    - YYYY

    The macro also contains logic for constructing
    partial date/time values.

### How it works:

 1. Determines the time format based on NOSECOND.

 2. Extracts date and time components from DATETIMEN,
    when supplied.

 3. Converts DATEN to an ISO-style date using the
    SAS IS8601DA format.

 4. Parses DATEC into year, month, and day components.

 5. Converts supported abbreviated and numeric month
    representations into two-digit month values.

 6. Applies the RMZERTIM, RMZERSEC, and NOSECOND
    options to the time components.

 7. Converts character time values using the SAS
    TIME informat.

 8. Selects the final date component in this order:
    - DATETIMEN
    - DATEN
    - DATEC

 9. Selects the final time component in this order:
    - DATETIMEN
    - TIMEN
    - TIMEC

10. Combines the available date and time components
    into the output character variable.

11. Writes warning messages for certain invalid
    year or month values from DATEC.

12. Drops intermediate variables when DEBUG=N.

### Sample code:

#### Example 1: Numeric SAS date to ISO date

~~~sas
data want;
    set have;

    %isodtc(
        daten=VISITDT,
        outdtc=VISITDTC
    );
run;
~~~

#### Example 2: Numeric SAS datetime to ISO datetime

~~~sas
data want;
    set have;

    %isodtc(
        datetimen=AESTDTM,
        outdtc=AESTDTC,
        nosecond=N,
        rmzersec=N
    );
run;
~~~

#### Example 3: Character date to ISO-style date

~~~sas
data want;
    set have;

    %isodtc(
        datec=AESTDAT,
        outdtc=AESTDTC
    );
run;
~~~

#### Example 4: Separate numeric date and character time

~~~sas
data want;
    set have;

    %isodtc(
        daten=AESTDT,
        timec=AESTTIMC,
        outdtc=AESTDTC
    );
run;
~~~

#### Example 5: Remove zero time and zero seconds

~~~sas
data want;
    set have;

    %isodtc(
        datetimen=AESTDTM,
        outdtc=AESTDTC,
        rmzertim=Y,
        rmzersec=Y
    );
run;
~~~

#### Example 6: Retain intermediate variables

~~~sas
data want;
    set have;

    %isodtc(
        daten=VISITDT,
        outdtc=VISITDTC,
        debug=Y
    );
run;
~~~

### Prerequisites:

 - The macro must be called inside a DATA step.

 - Input variables must be available in the current
   DATA step.

 - Numeric date and datetime inputs must use
   appropriate SAS date/datetime values.

 - Character date inputs are expected to contain
   space-separated date components.

 - The macro references the UWARN macro variable
   when reporting certain invalid date components.

### Notes:

 - The macro does not create a separate dataset.

 - The output variable is character with length $19.

 - Date and time input parameters are optional,
   but OUTDTC and at least one input are needed
   to derive an output.

 - If multiple date inputs are supplied, DATETIMEN
   takes precedence over DATEN and DATEC.

 - If multiple time inputs are supplied, DATETIMEN
   takes precedence over TIMEN and TIMEC.

 - NOSECOND, RMZERSEC, and RMZERTIM interact;
   their effects depend on the selected input path.

 - Character dates with unknown components may
   produce partial dates.

 - DEBUG=Y retains intermediate variables whose
   names are prefixed with double underscores.

 - The macro does not perform comprehensive ISO 8601
   validation of all possible input combinations.

### Author:
    Manivannan Mathialagan

### Created Date:
    2023-04-27

### Latest Update Date:
    2023-04-27

### Change History:

| Version | Date       | Description     |
|---------|------------|-----------------|
| 1.0     | 2023-04-27 | Initial version |

*//*** HELP END ***/

%macro isodtc(DATETIMEN=,DATEN=,DATEC=,TIMEN=,TIMEC=,OUTDTC=,RMZERTIM=N,RMZERSEC=Y,NOSECOND=Y,debug=N);

%if "&NOSECOND." ne "Y" %then
    %do;
        %let timfrmt=tod8;
    %end;
%else
    %do;
        %let timfrmt=tod5;
    %end;

%if  %length(&OUTDTC.) ne 0 and "&DATETIMEN.&DATEC.&DATEN.&TIMEN.&TIMEC." ne  "" %then
    %do;
        /* Assigning length for all intermediate variables going to be created */
        length  &OUTDTC $19.
                __&OUTDTC._IS_DA __&OUTDTC._1_IS_DA __&OUTDTC._2_IS_DA $10.
                __&OUTDTC._IS_TI __&OUTDTC._1_IS_TI __&OUTDTC._4_IS_TI __&OUTDTC._5_IS_TI $8.
                __&OUTDTC._3_IS_YY $4. __&OUTDTC._3_IS_MO __&OUTDTC._3_IS_DD $2.
                __&OUTDTC._EY  __&OUTDTC._EM $1.;

        /* Taking values from Parameter 1: DATETIMEN  */
        %if "&DATETIMEN." ne "" %then
            %do;
                if &DATETIMEN. ne . then
                __&OUTDTC._INDATM  = &DATETIMEN.;
                else __&OUTDTC._INDATM = .;

                /*  Separating date and time parts*/
                if not missing(__&OUTDTC._INDATM) then
                    do;
                        if not missing(datepart(__&OUTDTC._INDATM)) and datepart(__&OUTDTC._INDATM) ne 0 then
                        __&OUTDTC._1_IS_DA = strip(put(datepart(__&OUTDTC._INDATM),is8601da.));
                        else __&OUTDTC._1_IS_DA = "";

                        if not missing(timepart(__&OUTDTC._INDATM)) then
                            do;
                                /* Not removing both - Zero Second and Zero Time - keeping format as per NOSECOND*/
                                %if "&RMZERSEC." eq "N" and "&RMZERTIM." eq "N" %then
                                    %do;
                                        __&OUTDTC._1_IS_TI = strip(put(timepart(__&OUTDTC._INDATM),&timfrmt..));
                                    %end;
                                /* Not removing Zero Second but Removing Zero Time - keeping format as per NOSECOND*/
                                %else %if "&RMZERSEC." eq "N" and "&RMZERTIM." eq "Y" %then
                                    %do;
                                        if timepart(__&OUTDTC._INDATM) ne 0 then __&OUTDTC._1_IS_TI = strip(put(timepart(__&OUTDTC._INDATM),&timfrmt..));
                                    %end;
                                /* Not removing Zero Time but Removing Zero Second - hence assigning format as TOD5 */
                                %else %if "&RMZERTIM." eq "N" and "&RMZERSEC." eq "Y"  %then
                                    %do;
                                        __&OUTDTC._1_IS_TI = strip(put(timepart(__&OUTDTC._INDATM),tod5.));
                                    %end;
                                /* removing both - Zero Second and Zero Time - keeping format as per NOSECOND*/
                                %else %if "&RMZERSEC." eq "Y" and "&RMZERTIM." eq "Y" %then
                                    %do;
                                        if timepart(__&OUTDTC._INDATM) ne 0 and second(__&OUTDTC._INDATM) ne 0 then
                                        __&OUTDTC._1_IS_TI = strip(put(timepart(__&OUTDTC._INDATM),&timfrmt..));
                                        else if  timepart(__&OUTDTC._INDATM) ne 0 and second(__&OUTDTC._INDATM) eq 0 then
                                        __&OUTDTC._1_IS_TI = strip(put(timepart(__&OUTDTC._INDATM),tod5.));
                                    %end;
                            end;
                        else __&OUTDTC._1_IS_TI = "";
                    end;
                else
                    do;
                        /* Assigning blanks if both date and time parts are missing*/
                        __&OUTDTC._1_IS_TI = "";
                        __&OUTDTC._1_IS_DA = "";
                    end;
            %end;
        %else
            %do;
                /* Assigning blanks if Field is not passed*/
                __&OUTDTC._1_IS_TI = "";
                __&OUTDTC._1_IS_DA = "";
            %end;

        /* Taking values from Parameter 2: DATEN  */
        %if "&DATEN." ne "" %then
            %do;
                if &DATEN. ne . then __&OUTDTC._2_IS_DA  = strip(put(&DATEN.,is8601da.));
                else __&OUTDTC._2_IS_DA = "";
            %end;
        %else
            %do;
                /* Assigning blanks if Field is not passed*/
                __&OUTDTC._2_IS_DA = "";
            %end;

        /* Taking values from Parameter 3: DATEC  */
        %if "&DATEC." ne "" %then
            %do;
                /*  Separating Year, Month and Date parts*/
                __&OUTDTC._INYR = upcase(strip(scan(&DATEC,1)));
                __&OUTDTC._INMO = upcase(strip(scan(&DATEC,2)));
                __&OUTDTC._INDD = upcase(strip(scan(&DATEC,3)));

                /* Year part */
                if upcase(strip(vvalue(__&OUTDTC._INYR)))  ne "UUUU" and
                    upcase(strip(vvalue(__&OUTDTC._INYR))) ne "UNUN" and
                    upcase(strip(vvalue(__&OUTDTC._INYR))) ne "UNK" and
                    upcase(strip(vvalue(__&OUTDTC._INYR))) ne "0000"  and
                    compress(vvalue(__&OUTDTC._INYR),,'d') eq "" then
                    __&OUTDTC._3_IS_YY = vvalue(__&OUTDTC._INYR);
                else if upcase(strip(vvalue(__&OUTDTC._INYR))) ne "UUUU" and
                    upcase(strip(vvalue(__&OUTDTC._INYR))) ne "UNUN" and
                    upcase(strip(vvalue(__&OUTDTC._INYR))) ne "UNK" and
                    upcase(strip(vvalue(__&OUTDTC._INYR))) ne "0000" then
                    do;
                        __&OUTDTC._3_IS_YY = "";
                        /* Flagging if Year is Invalid  */
                        __&OUTDTC._EY      = "Y";
                    end;

                /* Month part*/
                array  MONTH_IN_&OUTDTC.[36]  $200. ( "JAN" "FEB" "MAR" "APR" "MAY" "JUN" "JUL" "AUG" "SEP"
                    "OCT" "NOV" "DEC" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "01" "02" "03"
                    "04" "05" "06" "07" "08" "09" "UU" "UNK" "UU");
                array  MONTH_OU_&OUTDTC.[36]  $200. ( "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12"
                    "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12"
                    "01" "02" "03" "04" "05" "06" "07" "08" "09" "" "" "" );

                if  not missing(__&OUTDTC._INMO) then
                    do;
                        do ___i = 1 to dim(MONTH_IN_&OUTDTC.) until ( upcase(__&OUTDTC._INMO) eq upcase(MONTH_IN_&OUTDTC.[___i]));
                            __&OUTDTC._3_IS_MO =  MONTH_OU_&OUTDTC.[___i];
                            /* Flagging if Month is Invalid  */
                            if indexw(upcase(__&OUTDTC._INMO),upcase(MONTH_IN_&OUTDTC.[___i])) eq 0 then
                                __&OUTDTC._EM ="Y";
                            else __&OUTDTC._EM = "";
                        end;
                    end;
                else __&OUTDTC._3_IS_MO = "";

                /* Date part*/
                if  not missing( __&OUTDTC._INDD) then
                do;
                    if compress(vvalue( __&OUTDTC._INDD),,'kd') ne "" then
                        __&OUTDTC._3_IS_DD = strip(put(input(compress(vvalue( __&OUTDTC._INDD),,'kd'),best.),z2.));
                    else __&OUTDTC._3_IS_DD = "";
                end;

                /* Adding Hyphens for missing intermediate fields*/
                if missing(__&OUTDTC._3_IS_YY) and not missing(__&OUTDTC._3_IS_MO) then __&OUTDTC._3_IS_YY  = "-";
                if missing(__&OUTDTC._3_IS_MO) and not missing(__&OUTDTC._3_IS_DD) then __&OUTDTC._3_IS_MO  = "-";

                drop MONTH_IN_&OUTDTC.: MONTH_OU_&OUTDTC.: ___i;
            %end;
        %else
            %do;
                /* Assigning blanks if Field is not passed*/
                __&OUTDTC._3_IS_YY = "";
                __&OUTDTC._3_IS_MO = "";
                __&OUTDTC._3_IS_DD = "";
                __&OUTDTC._EY      = "";
                __&OUTDTC._EM      = "";
            %end;

        /* Taking values from Parameter 3: TIMEN  */
        %if "&TIMEN." ne "" %then
            %do;
                if not missing(&TIMEN.) then
                    do;
                        /* Not removing both - Zero Second and Zero Time - keeping format as per NOSECOND*/
                        %if "&RMZERSEC." eq "N" and "&RMZERTIM." eq "N" %then
                            %do;
                                __&OUTDTC._4_IS_TI = strip(put(timepart(&TIMEN.),&timfrmt..));
                            %end;
                        /* Not removing Zero Second but Removing Zero Time - keeping format as per NOSECOND*/
                        %else %if "&RMZERSEC." eq "N" and "&RMZERTIM." eq "Y" %then
                            %do;
                                if timepart(&TIMEN.) ne 0 then __&OUTDTC._4_IS_TI = strip(put(timepart(&TIMEN.),&timfrmt..));
                            %end;
                        /* Not removing Zero Time but Removing Zero Second - hence assigning format as TOD5 */
                        %else %if "&RMZERTIM." eq "N" and "&RMZERSEC." eq "Y"  %then
                            %do;
                                __&OUTDTC._4_IS_TI = strip(put(timepart(&TIMEN.),tod5.));
                            %end;
                        /* removing both - Zero Second and Zero Time - keeping format as per NOSECOND*/
                        %else %if "&RMZERSEC." eq "Y" and "&RMZERTIM." eq "Y" %then
                            %do;
                                if timepart(&TIMEN.) ne 0 and second(&TIMEN.) ne 0 then
                                __&OUTDTC._4_IS_TI = strip(put(timepart(&TIMEN.),&timfrmt..));
                                else if  timepart(&TIMEN.) ne 0 and second(&TIMEN.) eq 0 then
                                __&OUTDTC._4_IS_TI = strip(put(timepart(&TIMEN.),tod5.));
                            %end;
                    end;
                else __&OUTDTC._4_IS_TI = "";
            %end;
        %else
            %do;
                /* Assigning blanks if Field is not passed*/
                __&OUTDTC._4_IS_TI = "";
            %end;

        %if "&TIMEC." ne "" %then
            %do;
                if not missing(&TIMEC.) then
                    do;
                        __&OUTDTC._5_IS_TI_IN = input(&TIMEC.,??time.);
                        %if "&RMZERSEC." eq "Y" and "&RMZERTIM." eq "Y" %then
                            %do;
                                if __&OUTDTC._5_IS_TI_IN ne . and __&OUTDTC._5_IS_TI = strip(put(__&OUTDTC._5_IS_TI_IN,tod8.));
                            %end;
                        %else %if "&RMZERSEC." eq "N" and "&RMZERTIM." eq "Y" %then
                            %do;
                                if __&OUTDTC._5_IS_TI_IN ne . and timepart(__&OUTDTC._5_IS_TI_IN) ne 0 and second(__&OUTDTC._5_IS_TI_IN) ne 0 then
                                __&OUTDTC._5_IS_TI = strip(put(__&OUTDTC._5_IS_TI_IN,tod8.));
                                else if __&OUTDTC._5_IS_TI_IN ne . and  timepart(__&OUTDTC._5_IS_TI_IN) ne 0 and second(__&OUTDTC._5_IS_TI_IN) eq 0 then
                                __&OUTDTC._5_IS_TI = strip(put(__&OUTDTC._5_IS_TI_IN,tod5.));
                            %end;
                        %else %if "&RMZERTIM." eq "N" %then
                            %do;
                                if __&OUTDTC._5_IS_TI_IN ne . then __&OUTDTC._5_IS_TI = strip(put(__&OUTDTC._5_IS_TI_IN,tod5.));
                            %end;
                    end;
                else __&OUTDTC._5_IS_TI = "";
            %end;
        %else
            %do;
                /* Assigning blanks if Field is not passed*/
                 __&OUTDTC._5_IS_TI = "";
            %end;

        %if "&DATEC." ne "" %then
            %do;
                /* Checking the Month or Year is not valid and raising warnings in log*/
                if  __&OUTDTC._EY = "Y" then
                    do;
                        put "&uwarn.: [ISODATE] Check the Date: Year seems to be invalid. Record no " _n_;;
                    end;
                if  __&OUTDTC._EM = "Y" then
                    do;
                        put "&uwarn.: [ISODATE] Check the Date: Month seems to be invalid. Record no " _n_;;
                    end;
                drop  __&OUTDTC._EY __&OUTDTC._EM;
            %end;

        if cmiss(__&OUTDTC._1_IS_DA,__&OUTDTC._2_IS_DA) eq 2 then
            do;
                __&OUTDTC._IS_DA = catx("-",__&OUTDTC._3_IS_YY,__&OUTDTC._3_IS_MO,__&OUTDTC._3_IS_DD);
            end;
        else
            do;
                __&OUTDTC._IS_DA = coalescec(__&OUTDTC._1_IS_DA,__&OUTDTC._2_IS_DA);
            end;
        __&OUTDTC._IS_TI    = coalescec(__&OUTDTC._1_IS_TI,__&OUTDTC._4_IS_TI,__&OUTDTC._5_IS_TI);

        if length(__&OUTDTC._IS_DA) eq 10 then
            do;
                &OUTDTC.=catx("T",__&OUTDTC._IS_DA,__&OUTDTC._IS_TI);
            end;
        else if length(__&OUTDTC._IS_DA) eq 7 and __&OUTDTC._IS_TI ne "" then
            do;
                &OUTDTC.=cats(__&OUTDTC._IS_DA,"--T",__&OUTDTC._IS_TI);
            end;
        else if length(__&OUTDTC._IS_DA) eq 4 and __&OUTDTC._IS_TI ne "" then
            do;
                &OUTDTC.=cats(__&OUTDTC._IS_DA,"----T",__&OUTDTC._IS_TI);
            end;
        else if __&OUTDTC._IS_DA ne "" and __&OUTDTC._IS_TI eq "" then
            do;
                &OUTDTC.=__&OUTDTC._IS_DA;
            end;
        else if __&OUTDTC._IS_DA eq "" and __&OUTDTC._IS_TI ne "" then
            do;
                &OUTDTC.=cats(__&OUTDTC._IS_DA,"-----T",__&OUTDTC._IS_TI);
            end;

        /* dropping the intermediate variables created */
        %if "%upcase(&debug.)" eq "N" %then
            %do;
                drop  __&OUTDTC._:;
            %end;
    %end;
%mend;
