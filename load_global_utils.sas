/**************************************************************************
Program : load_global_utils.sas
Purpose : Install and load Global_Utils from public GitHub
**************************************************************************/

/* Initialize SAS Packages Framework */
%include "P:\BSP_LocalDev\Manivannan.Mathialag\zzzz_My_SAS_Files\My GitHub\SAS_PACKAGES\SPF\SPFinit.sas";

/* Define package installation directory */
filename packages "%sysfunc(pathname(work))";

/* Install package from GitHub */
%installPackage(
    global_utils,
    github=manivannan-mathiazhagan,
    githubRepo=global_utils,
    replace=1);

/* Load package */
%loadPackage(global_utils);

/* Verify macro availability */
%put NOTE: BUILD_CDISC=%sysmacexist(build_cdisc);
%put NOTE: ISODTC=%sysmacexist(isodtc);

/* Display installed packages */
%listPackages();

/* Display package documentation */
%helpPackage(global_utils);

/* Display Individual macro documentation*/
%helpPackage(global_utils, isodtc);
