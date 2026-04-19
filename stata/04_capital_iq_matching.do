* ============================================================ 
* Carbon Emissions Bank Lending. Matching Trucost to Dealscan  
* Christian Eufinger, Yuki Sakasai, Igor Kadach, Emilio Sáenz  
* Author: Emilio Luis Sáenz Guillén							   	
* Date: November, 2021										   	
* ============================================================ 

clear all
set more off
global main "C:/Users/addj700/Dropbox/Carbon Emissions Bank Lending"
global input "$main/Databases/input"
global output "$main/Databases/output/Dealscan_tcst_cpst Tables/output_ds(new)"
cd "$output"
	

use "$output/temp/ds_trucost_0", clear

* List of banks that lend to firms in trucost and have info in Compustat
	drop if missing(gvkey_ultparent)

	unique gvkey_ultparent // 427 gvkeys
	
	// keep only the lender identifiers
	keep Lender_Parent_Name Lender_Parent_Id Lender_Name Lender_Id lenderid lenderparentid ultimateparentid gvkey_ultparent comp_start comp_end conm
	sort Lender_Name
		
save "$output/temp/ds_trucost_compustat", replace
	


* keep unique observations Lender_Id-gvkey_ultparent-isin_lender
sort Lender_Id gvkey_ultparent
quietly by Lender_Id gvkey_ultparent: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup


**********************************************************************************************************
 /* AND WITH THE GVKEY WE CAN GET THE CORRESPONDING (ULTIMATE PARENT) CIQ ID, ISIN AND CUSIP  */
**********************************************************************************************************

gen gvkey = "GV_" + string(gvkey_ultparent, "%06.0f")

export excel using "$output/excels/ds_trucost_compustat.xlsx", firstrow(variables) replace

/* Manually using the S&P Capital IQ excel plug-in formula =CIQ("GV_GVKEY", "IQ_COMPANY_ID") and =CIQ("IQ_COMPANY_ID", "IQ_ISIN")
to retrieve CIQ IDs, ISINs and CUSIPs; save as "ds_trucost_compustat_1.xlsx"
I suggest to use global classification system, say, GICS. This is managed by S&P and readily available on Capital IQ with data code “IQ_INDUSTRY_SECTOR”. These are industry classifications and do NOT tell us anything about ownership structure. You can use Capital IQ data code “IQ_COMPANY_TYPE” to identify Private company.
*/

import excel "$output/excels/ds_trucost_compustat_1.xlsx", sheet("Sheet1") firstrow clear

replace ciqid_gvkey="" if ciqid_gvkey=="(Invalid Identifier)"  | ciqid_gvkey=="0"
replace isin_gvkey="" if isin_gvkey=="(Invalid Identifier)"  | isin_gvkey=="0"
missings dropobs *, force

drop gvkey
rename ciqid_gvkey ciqid_lender
gen isin_ultparent = substr(isin_gvkey, 3, .)
drop isin_gvkey

save "$output/ds_trucost_compustat_1", replace

rename conm cpname_ultparent
rename comp_start cpstart_ultparent
rename comp_end cpend_ultparent
rename ciqid_lender ciqid_ultparent	

order Lender_Name Lender_Id Lender_Parent_Name Lender_Parent_Id lenderid lenderparentid ultimateparentid gvkey_ultparent cpstart_ultparent cpend_ultparent cpname_ultparent ciqid_ultparent gics_ultparent comptype_ultparent
sort Lender_Id Lender_Name


save "$output/ds_trucost_compustat_1", replace

export excel using "$output/excels/identifiers.xlsx", sheet("link_data") firstrow(variables) replace

erase "$output/temp/ds_trucost_compustat.dta"
