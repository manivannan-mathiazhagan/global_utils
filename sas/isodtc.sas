***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    isodtc .sas                                                                      ***;
***                                                                                                 ***;
*** Purpose:       Assign DTC based on input Date and Time variables                                ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    27Apr2023                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:                                                                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Name     | Description                                            | Default value   | Required  ***;
***          |                                                        |                 | Parameter ***;
*** ---------|--------------------------------------------------------|-----------------|-----------***;
** DATETIMEN |  the variable name of Datetime variable which contains | No default      |   No      ***;
***          |   the Numeric datetime value                           |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DATEN    |  the variable name of Date variable which contains the | No default      |   No      ***;
***          |  Numeric date value                                    |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DATEC    |  the variable name of Date variable which contains the | No default      |   No      ***;
***          |  Character date value                                  |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** TIMEN    |  the variable name of Time variable which contains the | No default      |   No      ***;
***          |  Numeric time value                                    |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** TIMEC    |  the variable name of Time variable which contains the | No default      |   No      ***;
***          |  character time value                                  |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** OUTDTC   | the respective date variable in character format       | No default      |   Yes     ***;
***          | which is needed to be mapped                           |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** RMZERTIM | Flag to use zero time in data to DTC or Not            |  N              |   Yes     ***;
***          | Y - If time is 00:00 - then it is removed              |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** RMZERSEC | Flag to use zero second in data to DTC or Not          |  Y              |   Yes     ***;
***          | Y - If time is 00:56:00 - then it is changed as 00:56  |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** NOSECOND | Flag to use  second in data to DTC or Not              |  Y              |   Yes     ***;
***          | Y - If time is 00:56:25 - then it is changed as 00:56  |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DEBUG    | Used for debugging - if it is given as Y, the          | No default      |   No      ***; 
***          |  intermediate Variables will not be deleted            |                 |           ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          Called within a data statement                                              ***;
***                                                                                                 ***;
*** Variables:          new variable &DTCVAR is added                                               ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Dependencies                                                                                    ***;
***                                                                                                 ***;
*** Data sets:          None                                                                        ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Macros:             None                                                                        ***;
***                                                                                                 ***;
*** Other:              None                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;

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
