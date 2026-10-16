/**************************************************************************
Program : build_global_utils.sas
Purpose : Build, copy and validate the Global_Utils SPF package
**************************************************************************/

/* Assign Constant base directory */
%let gitroot=P:\BSP_LocalDev\Manivannan.Mathialag\zzzz_My_SAS_Files\My GitHub;

/* Package Repository and SPF locations */
%let repo=global_utils;
%let repopath=&gitroot.\&repo.;
%let spfinit=&gitroot.\SAS_PACKAGES\SPF\SPFinit.sas;

/* Derived paths */
%let pkgsource=&repopath.\sas;
%let pkgoutput=%sysfunc(pathname(work));

/* Initialize SPF */
%include "&spfinit.";

/* Generate package */
%generatePackage(
    filesLocation=&pkgsource.,
    buildLocation=&pkgoutput.,
    markdownDoc=1
);

/* Copy package ZIP in binary mode */
filename src "&pkgoutput.\global_utils.zip" recfm=N;
filename dst "&repopath.\global_utils.zip" recfm=N;

data _null_;
    length msg $500;
    rc = fcopy('src','dst');

    if rc = 0 then
        put "NOTE: Global_Utils ZIP copied successfully.";
    else do;
        msg = sysmsg();
        put "ERROR: ZIP copy failed. " rc= msg=;
    end;
run;

filename src clear;
filename dst clear;

/* Copy Markdown documentation */
filename src "&pkgoutput.\global_utils.md";
filename dst "&repopath.\global_utils.md";

data _null_;
    length msg $500;
    rc = fcopy('src','dst');

    if rc = 0 then
        put "NOTE: Markdown documentation copied successfully.";
    else do;
        msg = sysmsg();
        put "ERROR: Markdown copy failed. " rc= msg=;
    end;
run;

filename src clear;
filename dst clear;

/* Verify generated ZIP */
filename testzip ZIP "&repopath.\global_utils.zip";

data _null_;
    length msg $500;
    did = dopen('testzip');

    if did > 0 then do;
        n = dnum(did);
        put "NOTE: Global_Utils ZIP verified successfully.";
        put "NOTE: Number of package members=" n;
        rc = dclose(did);
    end;
    else do;
        msg = sysmsg();
        put "ERROR: Global_Utils ZIP verification failed. " msg;
    end;
run;

filename testzip clear;
