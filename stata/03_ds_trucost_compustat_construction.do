* ============================================================
* Carbon Emissions Bank Lending. Matching Trucost to Dealscan
* Christian Eufinger, Yuki Sakasai, Igor Kadach, Emilio Sáenz
* Author: Emilio Luis Sáenz Guillén
* Date: November, 2021
* ============================================================

clear all
set more off
set checksum off
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
 	
 
/* 1. Organizing Dealscan Database [DS] */	
	
	use Lender_Parent_Name Lender_Parent_Id Lender_Name Lender_Id Borrower_Name Borrower_Id LPC_Deal_ID Deal_Active_Date LPC_Tranche_ID Tranche_Active_Date using "$input/Dealscan/Dealscan (New)/Emilio/Dealscan_1980_2021_nonUS.dta", clear
	
	save "$output/temp/Dealscan_1980_2021_nonUS", replace
	
	use Lender_Parent_Name Lender_Parent_Id Lender_Name Lender_Id Borrower_Name Borrower_Id LPC_Deal_ID Deal_Active_Date LPC_Tranche_ID Tranche_Active_Date using "$input/Dealscan/Dealscan (New)/Emilio/Dealscan_1980_2021_US.dta", clear
	
	append using "$output/temp/Dealscan_1980_2021_nonUS"
	
	destring Lender_Parent_Id Lender_Id Borrower_Id LPC_Deal_ID LPC_Tranche_ID, ignore("N/A") replace
	
	compress
	
	save "$output/temp/Dealscan_1980_2021", replace
	
	erase "$output/temp/Dealscan_1980_2021_nonUS.dta"
	
	*** Translation ***
	/*
For users who need translation between the IDs in the legacy database and the IDs in the new database (facility id to tranche id, package id to deal id, LPC company id to LoanConnector company id), the linking tables are available on wrds-cloud: lpc_loanconnector_company_id_map, wrds_loanconnector_ids
	*/
	
	* A) LPC_Tranche_ID/facilityid
	import excel "$input/Dealscan/WRDS_to_LoanConnector_IDs.xlsx", sheet("Sheet1") firstrow clear
	
	drop LoanConnectorDealID WRDSpackage_id // I'm not interested in packageids
	
	rename LoanConnectorTrancheID LPC_Tranche_ID
	rename WRDSfacility_id facilityid
	
	unique LPC_Tranche_ID // 337,287 unique LPC_Tranche_IDs (337,286 if we don't count the missings)
	unique facilityid // 363,311 unique facilityids, out of 363,311 observations
	count if missing(LPC_Tranche_ID) // 104 facilityids that don't have a corresponding LPC_Tranche_ID (old facilities)
	
	save "$output/temp/WRDS_to_LoanConnector_IDs", replace
	
	* B) Borrower_Id/borrowercompanyid; Lender_Id/lenderid; Lender_Parent_Id/lenderparentid
	import excel "$input/Dealscan/LPC_Loanconnector_Company_ID_Mappings.xlsx", sheet("in") firstrow clear	
	
	rename LoanConnectorCompanyID Borrower_Id
	rename LPC_COMPANY_ID borrowercompanyid
	
	gen Lender_Id = Borrower_Id
	gen lenderid = borrowercompanyid
	
	gen Lender_Parent_Id = Borrower_Id
	gen lenderparentid = borrowercompanyid
	
	unique Lender_Id // 148,146 unique Lender_Ids, out of 148,146 observations
	unique lenderid // 147,138 unique lenderids (147,137 if we don't count the missings)
	count if missing(lenderid) // 1,009 Lender_Ids that don't have a corresponding lenderid (new companies only present in ds_new)
	
	save "$output/temp/LPC_Loanconnector_Company_ID_Mappings", replace	
		
		// Append the newly translated LPC_COMPANY_IDs to LPC_Loanconnector_Company_ID_Mappings
		import excel "$output/excels/untranslatable_company_ids_dealscan_1.xlsx", sheet("Sheet1") firstrow clear	
	
		drop if missing(Borrower_Id)
		drop borrower
		rename Borrower_Name CompanyName
	
		gen Lender_Id = Borrower_Id
		gen lenderid = borrowercompanyid
		
		gen Lender_Parent_Id = Borrower_Id
		gen lenderparentid = borrowercompanyid
	
		order CompanyName Borrower_Id borrowercompanyid Lender_Id lenderid Lender_Parent_Id lenderparentid
		
		save "$output/temp/untranslatable_company_ids_dealscan_1", replace
	
		use "$output/temp/LPC_Loanconnector_Company_ID_Mappings", clear
	
		append using "$output/temp/untranslatable_company_ids_dealscan_1"
	
		save "$output/temp/LPC_Loanconnector_Company_ID_Mappings", replace
	
	*** Merge ***
	
	* A) facilityid	
	use "$output/temp/WRDS_to_LoanConnector_IDs", clear
	drop if missing(facilityid) | missing(LPC_Tranche_ID) // don't want to match a missing facilityid and can't use a missing LPC_Tranche_ID to merge
	sort LPC_Tranche_ID facilityid // unique order
	quietly by LPC_Tranche_ID: gen dup = cond(_N==1,0,_n)
	tab dup // facilityids repeat; need to do the merge step by step:

		drop if dup>1 
		drop dup
		save "$output/temp/aux1", replace

		forvalues i=2/13{
		use "$output/temp/WRDS_to_LoanConnector_IDs", clear
		sort LPC_Tranche_ID facilityid // unique order
		quietly by LPC_Tranche_ID: gen dup = cond(_N==1,0,_n)
		keep if dup==`i'
		drop dup
		save "$output/temp/aux`i'", replace
		sleep 100
		}
		
		use "$output/temp/Dealscan_1980_2021", clear
		merge m:1 LPC_Tranche_ID using "$output/temp/aux1", keepusing(facilityid)			
			drop if _merge==2
			drop _merge
		save "$output/temp/aux1", replace
	
		//add the other obs of the repeated LPC_Tranche_IDs
		forvalues i=2/13{
		use "$output/temp/Dealscan_1980_2021", clear
		merge m:1 LPC_Tranche_ID using "$output/temp/aux`i'", keepusing(facilityid)
			keep if _merge==3 
			drop _merge
		save "$output/temp/aux`i'.dta", replace
		sleep 100
		}
			
		use "$output/temp/aux1", clear
		forvalues i=2/13{
		append using "$output/temp/aux`i'"
		}
		
		unique LPC_Tranche_ID if missing(facilityid) // matched a facilityid to every LPC_Tranche_ID
	
	save "$output/temp/Dealscan_1980_2021", replace
	
	* B) lenderid, borrowercompanyid	
	
	use "$output/temp/Dealscan_1980_2021", clear
	
	merge m:1 Borrower_Id using "$output/temp/LPC_Loanconnector_Company_ID_Mappings", keepusing(borrowercompanyid)
		unique Borrower_Id if _merge==1 // 4,768 Borrower_Ids to which I couldn't assign a borrowercompanyid
		drop if _merge==2
		drop _merge
		
	merge m:1 Lender_Id using "$output/temp/LPC_Loanconnector_Company_ID_Mappings", keepusing(lenderid)
		unique Lender_Id if _merge==1 // 331 Lender_Ids to which I couldn't assign a lenderid
		drop if _merge==2 
		drop _merge	
		
	merge m:1 Lender_Parent_Id using "$output/temp/LPC_Loanconnector_Company_ID_Mappings", keepusing(lenderparentid)
		unique Lender_Parent_Id if _merge==1 // 286 Lender_Parent_Ids to which I couldn't assign an lenderparentid
		drop if _merge==2
		drop _merge
		
	*** Merge lenders to ultimateparentid ***
	rename lenderid companyid
	merge m:1 companyid using "$input/Dealscan/Dealscan (Old)/company.dta", keepusing(ultimateparentid) 
		drop if _merge==2 // keep only the observations of the master db
		drop _merge
	rename companyid lenderid
	
	unique Lender_Id if !missing(Lender_Id) & missing(ultimateparentid) // 1,917 Lender_Ids to which I couldn't assign an ultimateparentid
		
	compress
		
	save "$output/temp/dealscan", replace
	
		// erase all the auxiliar files		
		forvalues i=1/13{
			erase "$output/temp/aux`i'.dta"
			sleep 100
			}				
		

/* 2. Merge the trucost-dealscan matching table (i.e. trucost_dealscan_worldscope_linking_table) with dealscan */

use "$output/temp/trucost_dealscan_worldscope_linking_table", clear
sort borrowercompanyid cusip sedol scope1 scope2 scope3 // unique order
quietly by borrowercompanyid: gen dup = cond(_N==1,0,_n) // only variable in common trucost_dealscan_worldscope_linking_table and dealscan is companyID
tab dup // borrowercompanyids repeat; need to do the merge step by step:

	drop if dup>1 
	drop dup
	save "$output/temp/aux1", replace

	forvalues i=2/16{
	use "$output/temp/trucost_dealscan_worldscope_linking_table", clear
	sort borrowercompanyid cusip sedol scope1 scope2 scope3 // unique order
	quietly by borrowercompanyid: gen dup = cond(_N==1,0,_n)
	keep if dup==`i'
	drop dup
	save "$output/temp/aux`i'", replace
	sleep 100
	}

	/* merge step by step so that each observation in dealscan presents each of the (corresponding) observations of trucost*/

	forvalues i=1/16{
	use "$output/temp/dealscan", clear
	merge m:1 borrowercompanyid using "$output/temp/aux`i'", keepusing(tcuid)
		keep if _merge==3 // restrain the db to those dealscan borrowers that are present in trucost
		drop _merge
	save "$output/temp/aux`i'.dta", replace
	sleep 100
	}

	use "$output/temp/aux1", clear
	forvalues i=2/16{
	append using "$output/temp/aux`i'"
	}	
	
			
	// rename the merged variables:
	rename tcuid tcuid_brwr			

	* unique borrower companies
	unique borrowercompanyid 
	unique Borrower_Id // 6,790 different borrower companies (i.e. "lost 188 companies of those present in the dealscan-worldscope-trucost linking_table", originally lost 230 companies, but I was then able to translate by hand 42 borrowercompanyids; I think there might be some banks in trucost, i.e., not borrowers but lenders)	
				
	* unique lender banks
	unique lenderid	// 8,435
	unique Lender_Id // 8,464
	unique Lender_Id if !missing(Lender_Id) & missing(lenderid) // 30 Lender_Ids for which I don't have a lenderid	
	
	compress
	
save "$output/temp/ds_trucost", replace

	// erase all the auxiliar files		
	forvalues i=1/16{
		erase "$output/temp/aux`i'.dta"
		sleep 100
		}	
	

/* 3. Match to Compustat */	
	
	* 3.1 Departing from Schwert (2020) Dealscan Lender Link Table, https://sites.google.com/site/mwschwert/data-and-code
	/* lcoid: Lender CompanyID from Dealscan.
	lender: Lender name from Dealscan.
	ds_start: Facilitystartdate of first loan by lender in Dealscan.
	ds_end: Facilitystartdate of last loan by lender in Dealscan.
	comp_start: First filing date for matched Compustat BHC.
	comp_end: Last filing date for matched Compustat BHC.*/			  
	
	* Take Schwert_Compustat + Schwert_Bankscope 2010 onwards
	use "$output/temp/ds_lender_link_schwert_compustat_bankscope_1", clear 
	sort lenderid gvkey_ultparent // unique order
	quietly by lenderid: gen dup = cond(_N==1,0,_n)
	tab dup // lenderids repeat; need to do the merge step by step:
	
		drop if dup>1
		drop dup
		save "$output/temp/aux1", replace // 87 unique gvkeys
		
		use "$output/temp/ds_lender_link_schwert_compustat_bankscope_1", clear
		sort lenderid gvkey_ultparent // unique order
		quietly by lenderid: gen dup = cond(_N==1,0,_n)
		keep if dup==2
		drop dup
		save "$output/temp/aux2", replace // 4 unique gvkeys (3 of which are already included in aux1)

		use "$output/temp/ds_trucost", clear
		merge m:1 lenderid using "$output/temp/aux1", keepusing(gvkey_ultparent comp_start comp_end conm)
			drop if _merge==2		
			drop _merge
		save "$output/temp/aux1.dta", replace
	
		// add the other obs of the repeated lenderids
		use "$output/temp/ds_trucost", clear
		merge m:1 lenderid using "$output/temp/aux2", keepusing(gvkey_ultparent comp_start comp_end conm)
			keep if _merge==3
			drop _merge
		save "$output/temp/aux2.dta", replace	

		use "$output/temp/aux1", clear	
		append using "$output/temp/aux2"		
			
		
	unique gvkey_ultparent // 89 unique gvkey_ultparent (88 not counting the missings); CapitalSource Bank the only one I don't match (lenderids 129090 and 106117)

	unique gvkey_ultparent Lender_Id if !missing(gvkey_ultparent) // 922 unique gvkey_ultparent-lenderid observations
	
	save "$output/temp/ds_trucost", replace	
	
	// erase all the auxiliar files		
	forvalues i=1/2{
		erase "$output/temp/aux`i'.dta"
		sleep 100
		}
		
	
	/* 3.2. There are some borrowers that also act as lenders; so even if the Roberts linking file is for DS borrowers, 
	maybe I can use it to link the gvkey to those borrowers that also act as lenders*/
	
	use "$output/temp/aux0_reviewed", replace
	
	unique gvkey_ultparent // 12,975 unique gvkeys (after adjustments and keeping 2010 onwards)
	
	sort lenderid facilityid gvkey_ultparent // unique order
	quietly by lenderid: gen dup = cond(_N==1,0,_n)
	tab dup // need to do the merge step by step:
	
		drop if dup>1
		drop dup
		save "$output/temp/aux1", replace	

		forvalues i=2/12{
		use "$output/temp/aux0_reviewed", clear
		sort lenderid facilityid gvkey_ultparent // unique order
		quietly by lenderid: gen dup = cond(_N==1,0,_n)
		keep if dup==`i'
		drop dup
		save "$output/temp/aux`i'", replace
		sleep 100
		}

	/* merge step by step so that each observation in ds_trucost presents each of the correspondings gvkey_ultparent */
		
		use "$output/temp/ds_trucost", clear
		merge m:1 lenderid using "$output/temp/aux1", keepusing(gvkey_ultparent comp_start comp_end conm) update // give priority to those matched through Schwert
			drop if _merge==2
			drop _merge
		save "$output/temp/aux1", replace
		
		// merge the other obs of the repeated lenderid-lenderid
		forvalues i=2/12{
		use "$output/temp/ds_trucost", clear
		merge m:1 lenderid using "$output/temp/aux`i'", keepusing(gvkey_ultparent comp_start comp_end conm) update
			keep if _merge==4
			drop _merge
		save "$output/temp/aux`i'", replace
		sleep 100
}

		use "$output/temp/aux1", clear
		forvalues i=2/12{
		append using "$output/temp/aux`i'"
		}
		
	/* 3.3 Guarantee that our Lender-BHC matching Table covers at least those banks covered by Kacperczyk and Peydro. */
	
		/*
		gvkey	conm		comp_start	comp_end
		61067	BANCOLOMBIA SA	31mar1994	30sep2021
		*/
		
		replace gvkey_ultparent=61067 if lenderid==33003
		replace conm="BANCOLOMBIA SA" if lenderid==33003
		replace comp_start=td(31mar1994) if lenderid==33003
		replace comp_end=td(30sep2021) if lenderid==33003
	
	unique gvkey_ultparent // 428 gvkeys (427 not counting the missings); and maybe I also match to a gvkey_ultparent lenderids that I hadn't previously matched
	unique gvkey_ultparent Lender_Id if !missing(gvkey_ultparent) // 1,653
	
	save "$output/temp/ds_trucost_0", replace
	
	
	/* SUMMARY OF THE MATCHING */
	
	* i) gvkey_ultparents matched from  Schwert_Compustat and from Schwert_BankScope
	use "$output/temp/ds_trucost_0", clear
	sort gvkey_ultparent
	quietly by gvkey_ultparent: gen dup = cond(_N==1,0,_n)
	drop if dup>1
	drop if missing(gvkey_ultparent)
	rename gvkey_ultparent gvkey
	merge 1:m gvkey using "$output/temp/ds_lender_link_schwert_compustat_1", keepusing(gvkey) // merge Schwert_Compustat 2010 onwards
		keep if _merge==3
		drop _merge
	unique gvkey // 69 matched from Schwert_Compustat; 16 matched from Schwert_BankScope (69+13=82 gvkeys that I matched)
	
	* ii) gvkey_ultparents matched from Schwert and from Chava
	use "$output/temp/ds_trucost_0", clear
	sort gvkey_ultparent
	quietly by gvkey_ultparent: gen dup = cond(_N==1,0,_n)
	drop if dup>1 // keep unique gvkey_ultparents
	drop dup
	drop if missing(gvkey_ultparent)	
	merge 1:m gvkey_ultparent using "$output/temp/ds_lender_link_schwert_compustat_bankscope_1", keepusing(gvkey_ultparent) // merge Schwert Compustat+BankScope 2010 onwards
		keep if _merge==1  | gvkey_ultparent==136265
		drop _merge
	unique gvkey_ultparent // 340 matched from Chava and Roberts' (2008); 89 matched from Schwert (seems I was able to match CapitalSource (in fact, PacWest) through lenderid 37623 (First Community Bancorp) of Chava and Roberts (presents lenderids 37623 and 152570))
	
	// erase all the auxiliar files		
	forvalues i=1/12{
		erase "$output/temp/aux`i'.dta"
		sleep 100
		}		
	
	
erase "$output/temp/ds_lender_link_schwert_bankscope_1.dta"
erase "$output/temp/ds_lender_link_schwert_compustat.dta"
erase "$output/temp/ds_lender_link_schwert_compustat_bankscope.dta"	
erase "$output/temp/ds_lender_link_schwert_compustat_bankscope_1.dta"
erase "$output/temp/ds_trucost.dta"
erase "$output/temp/trucost_dealscan_worldscope_linking_table.dta"
erase "$output/temp/untranslatable_company_ids_dealscan_1.dta"
erase "$output/temp/WRDS_to_LoanConnector_IDs.dta"
