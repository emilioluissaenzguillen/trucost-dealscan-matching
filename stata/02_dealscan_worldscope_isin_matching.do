* ============================================================
* Carbon Emissions Bank Lending. Matching Trucost to Dealscan
* Christian Eufinger, Yuki Sakasai, Igor Kadach, Emilio Sáenz
* Author: Emilio Luis Sáenz Guillén
* Date: November, 2021
* ============================================================

clear all
set more off
local __pwd = subinstr(`"`c(pwd)'"', "\", "/", .)
capture confirm global cebl_root
if _rc {
	global cebl_root `"`__pwd'"'
}
if length("$cebl_root")>=6 & substr("$cebl_root", length("$cebl_root")-5, 6)=="/stata" {
	global cebl_root = substr("$cebl_root", 1, length("$cebl_root")-6)
}
global main "$cebl_root"
global input "$main/Databases/input"
global output "$main/Databases/output/Dealscan_tcst_cpst Tables/output_ds(new)"
cd "$output"

*** TRUCOST-DEALSCAN MATCHING ***

** 1. TRUCOST
use "$input/Trucost/trucost_2021.dta", clear
drop dup
rename company name
drop if name=="StarPoint Energy Trust" // Trucost data is available for StarPoint Energy Trust only for 2005 and 2006, so I would not include this in the matched sample.
unique isin // 17,864 unique isins 
save "$output/temp/trucost_2021_1", replace	
	

** 2. DEALSCAN_WORLDSCOPE_LINKING_TABLE **

// A) First of all, for the observations where isin is missing, add some gvkeys and some extra isins from the supplementary missing-ISIN review table
	import excel "$input/Linking Tables/supplemental_dealscan_linking_table_isin_missing.xlsx", sheet("Cleaned_Table") firstrow clear

	drop if missing(isin) & missing(gvkey)

	save "$output/temp/dealscan_linking_table_ISIN_missing", replace

	use "$input/Linking Tables/dealscan_linking_table/dealscan_worldscope_linking_table", clear 
	
	replace isin="GB00BWFY5505" if company=="NIELSEN MEDIA RESEARCH" // This company is now a private subsidiary of Nielsen Holdings plc (GB00BWFY5505). Trucost data is available for this entity, so I match it to that identifier.
	unique isin // 16,343 unique isins (16,342 not counting the missings)
	count if missing(isin) // 808 missing isins that we try to fill using the supplementary review table

	// add gvkey and some extra isins
	merge m:1 companyID cleaned_matched_name using "$output/temp/dealscan_linking_table_ISIN_missing", keepusing(isin gvkey) update	
		drop if _merge==2
		drop _merge

	destring gvkey, replace
	
	save "$output/temp/dealscan_worldscope_linking_table_1", replace
	
	// keep the unique GVKEYs and transform them to ISINs
	sort gvkey
	quietly by gvkey: gen dup = cond(_N==1,0,_n)	
	drop if dup>1
	keep gvkey
	gen gvkey1 = "GV_" + string(gvkey, "%06.0f")
	drop gvkey
	rename gvkey1 gvkey
	export excel using "$output/excels/tcost_gvkeys.xlsx", firstrow(variables) replace 	
	// use =CIQ("IQ_GVKEY";"IQ_ISIN") to retrieve the corresponding isins
	import excel using "$output/excels/tcost_gvkeys_1.xlsx", sheet("Sheet1") firstrow clear
	replace isin="" if isin=="(Invalid Identifier)" | isin=="0"
	drop if missing(isin)
	
	gen gvkey_1 = substr(gvkey, 4, .)
	drop gvkey
	rename gvkey_1 gvkey
	destring gvkey, replace
	
	gen isin_1 = substr(isin, 3, .)
	drop isin
	rename isin_1 isin
	destring isin, replace
	
	save "$output/temp/tcost_gvkeys_1", replace
	
	use "$output/temp/dealscan_worldscope_linking_table_1", clear
	
	merge m:1 gvkey using "$output/temp/tcost_gvkeys_1", keepusing(isin) update
		drop if _merge==2
		drop _merge
	
	unique isin // 16,554 (16,553 not counting the missings)
	unique gvkey // 764 gvkeys (763 not counting the missings)
	count if missing(isin) // 576
	
	save "$output/temp/dealscan_worldscope_linking_table_1", replace	
	
	sort companyID
	quietly by companyID: gen dup = cond(_N==1,0,_n)	
	drop if dup>1
	
	save "$output/temp/dealscan_worldscope_linking_table_1_unique_companyID", replace	


** 3. MERGE TRUCOST WITH DEALSCAN_WORLDSCOPE_LINKING_TABLE **

* Matching through isin
	
	use "$output/temp/dealscan_worldscope_linking_table_1", clear
	drop if missing(isin) | missing(companyID)
	sort companyID isin
	quietly by companyID isin: gen dup = cond(_N==1,0,_n)	
	drop if dup>1 // drop the companyID-isin duplicates (I'm not interested in other identifiers)
	drop dup
	save "$output/temp/aux0", replace
	sort isin companyID // unique order
	quietly by isin: gen dup = cond(_N==1,0,_n)
	tab dup // isins repeat (different companyIDs per isin); need to do the merge step by step:		
	
		drop if dup>1
		drop dup
		save "$output/temp/aux1", replace
		
		forvalues i=2/3{
			use "$output/temp/aux0", clear
			sort isin companyID // unique order
			quietly by isin: gen dup = cond(_N==1,0,_n)
			keep if dup==`i'
			drop dup
			save "$output/temp/aux`i'", replace
			}
			
		/* merge step by step so that each observation in trucost_2021 presents each of the corresponding dealscan info */		
		forvalues i=1/3{
		use "$output/temp/trucost_2021_1", clear
		merge m:1 isin using "$output/temp/aux`i'", keepusing(companyID company cleaned_matched_name cusip sedol sic) update
			keep if _merge==3 // restrain the db to those for which I have info both in trucost and ds
			drop _merge
		save "$output/temp/aux`i'", replace
		}

		use "$output/temp/aux1", clear
		forvalues i=2/3{
		append using "$output/temp/aux`i'"	
		}
		
	// eliminate repeated observations
	sort *
	quietly by *: gen dup = cond(_N==1,0,_n)	
	drop if dup>1
	drop dup
	
	drop if missing(tcuid)
	drop if missing(companyID) // keep only the firms for which I have info in both trucost and dealscan	
	
save "$output/temp/trucost_dealscan_worldscope_linking_table_1", replace

	forvalues i=0/3{
	erase "$output/temp/aux`i'.dta"	
	sleep 100
	}	

// Number of dealscan companies for which we have info in trucost:	
unique companyID // 6,557 different dealscan companies (of the ds-wrds matching table) for which we have info in trucost
	
gen borrower = company
gen borrowercompanyid = companyID
gen lender = company
gen lenderid = companyID // in order to do the merges

order companyID company cleaned_matched_name borrowercompanyid borrower lenderid lender cusip sedol isin sic

save "$output/temp/trucost_dealscan_worldscope_linking_table_1", replace

/* ADD THE EXTRA MATCHES OBTAINED FROM DOING THE MATCHING THROUGH THE GVKEY IN "Trucost and dealscan_worldscope_linking_table GVKEY Matching" */

use "$output/temp/trucost_dealscan_worldscope_linking_table_1", clear

sort companyID
quietly by companyID: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup 

save "$output/temp/aux0", replace

use "$output/temp/trucost_dealscan_worldscope_linking_table", clear
order companyID company cleaned_matched_name borrowercompanyid borrower lenderid lender cusip sedol isin sic

	merge m:1 companyID using "$output/temp/aux0", keepusing(companyID)	
		keep if _merge==1 // keep those only obtained when matching through the gvkey  
		drop _merge		
	
	sort companyID
	quietly by companyID: gen dup = cond(_N==1,0,_n)
	drop if dup>1
	drop dup 

	keep companyID company cleaned_matched_name cusip sedol isin sic tcuid name gvkey

	export excel using "$output/excels/tcost_linkingtable_gvkey_matches.xlsx", firstrow(variables) replace 	

use "$output/temp/trucost_dealscan_worldscope_linking_table", clear
order companyID company cleaned_matched_name borrowercompanyid borrower lenderid lender cusip sedol isin sic

merge m:1 companyID using "$output/temp/aux0", keepusing(companyID)	
	keep if _merge==1 // keep those only obtained when matching through the gvkey  
	drop _merge
	erase "$output/temp/aux0.dta"
	
append using "$output/temp/trucost_dealscan_worldscope_linking_table_1"

unique companyID // 6,978 (421 extra matches added)

save "$output/temp/trucost_dealscan_worldscope_linking_table", replace

erase "$output/temp/dealscan_worldscope_linking_table_1.dta"
erase "$output/temp/dealscan_linking_table_ISIN_missing.dta"
erase "$output/temp/dealscan_worldscope_linking_table_1_unique_companyID.dta"
erase "$output/temp/trucost_dealscan_worldscope_linking_table_1.dta"
erase "$output/temp/trucost_2021_1.dta"
erase "$output/temp/tcost_gvkeys_1.dta"

	sort companyID
	quietly by companyID: gen dup = cond(_N==1,0,_n)
	drop if dup>1
	drop dup 

	keep companyID company cleaned_matched_name cusip sedol isin sic tcuid name gvkey
	
	rename companyID borrowercompanyid
	rename company borrower

	export excel using "$main/Databases/output/Dealscan_tcst_cpst Tables/Borrowers_linkingtable_matches.xlsx", firstrow(variables) replace 	
