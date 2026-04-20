* ============================================================
* Carbon Emissions Bank Lending. Matching Trucost to Dealscan
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
	
	* Get the ISINs' GVKEYs using the S&P Capital IQ excel add-in	
	sort isin
	quietly by isin: gen dup = cond(_N==1,0,_n)
	drop if dup>1 // keep the unique isins
	keep name isin
	
	export excel using "$output/excels/trucost_2021_isins.xlsx", firstrow(variables) replace 	
		
		// A) use =CIQ("IQ_ISIN";"IQ_GVKEY") to retrieve the corresponding gvkeys
		import excel using "$output/excels/trucost_2021_isins_1.xlsx", sheet("Sheet1") firstrow clear
		replace gvkey="" if gvkey=="(Invalid Identifier)"  | gvkey=="0"
		drop if missing(gvkey)
		split gvkey, parse(,)
		keep if missing(gvkey2) // i.e. keep the one with one only gvkey
		forvalues i=1/4{
			drop gvkey`i'		
		}
		
		save "$output/temp/aux_ciq", replace
		
		// B) DOUBLE: isins that present more than one gvkey		
		import excel using "$output/excels/trucost_2021_isins_1.xlsx", sheet("Sheet1") firstrow clear
		split gvkey, parse(,) // up to 4 different gvkeys		
		drop gvkey
		drop if missing(gvkey2) // keep those that have multiple gvkeys and decide which one to use
		export excel using "$output/excels/trucost_2021_double_gvkey.xlsx", firstrow(variables) replace 
		// use =CIQ("IQ_GVKEY"; "IQ_ISIN") to retrieve the corresponding isins
		import excel using "$output/excels/trucost_2021_double_gvkey_1.xlsx", sheet("Sheet1") firstrow clear
		forvalues i=1/4{
		replace isin`i'="" if isin`i'=="(Invalid Identifier)"  | isin`i'=="0"
		gen isin_1 = substr(isin`i', 3, .)
		drop isin`i'
		rename isin_1 isin`i'
		}		
		
		// Keep the GVKEY that returns the original Trucost ISIN		
		gen gvkey=""
		forvalues i=1/4{
			replace gvkey=gvkey`i' if isin`i'==isin
			}	
		
		count if gvkey=="" // 5; for these cases I keep the gvkeys that returned a non-missing isin		
		forvalues i=1/4{
			replace gvkey=gvkey`i' if !missing(isin`i') & gvkey==""
			}
		
		forvalues i=1/4{
			drop gvkey`i' isin`i'		
		}		
		
		save "$output/temp/aux_double", replace
		
		// C) MISSINGS: 14 isins to which I couldn't assign a gvkey; check "by hand" whether I can match them a gvkey 
		import excel using "$output/excels/trucost_2021_isins_1.xlsx", sheet("Sheet1") firstrow clear
		replace gvkey="" if gvkey=="(Invalid Identifier)" | gvkey=="0"
		keep if missing(gvkey)
		export excel using "$output/excels/trucost_2021_missing_gvkey.xlsx", firstrow(variables) replace 
		// was able to get the gvkey for 7 entities
		import excel using "$output/excels/trucost_2021_missing_gvkey_1.xlsx", sheet("Sheet1") firstrow clear
		drop if missing(gvkey) 
		gen gvkey1 = "GV_" + string(gvkey, "%06.0f")
		drop gvkey
		rename gvkey1 gvkey
		save "$output/temp/aux_missings", replace			
	
	/* merge the gvkeys to trucost_2021 */	
	use "$output/temp/trucost_2021_1.dta", clear
		
	foreach v in ciq double missings{
	merge m:1 isin using "$output/temp/aux_`v'", keepusing(gvkey) update
		drop if _merge==2
		drop _merge		
		}
		
	// destring gvkey
	gen gvkey_1 = substr(gvkey, 4, .)
	drop gvkey
	rename gvkey_1 gvkey
	destring gvkey, replace			
	
	save "$output/temp/trucost_2021_1", replace

	unique isin if missing(gvkey) // 7; check ok!
	unique gvkey // 17,796 different gvkeys (17,795 not counting the missings)

		foreach v in ciq double missings{
		erase "$output/temp/aux_`v'.dta"
		sleep 100
		}		
	

** 2. DEALSCAN_WORLDSCOPE_LINKING_TABLE **

// A) First of all, for the observations where isin is missing, add some gvkeys and some extra isins from the supplementary missing-ISIN review table
	import excel "$input/Linking Tables/supplemental_dealscan_linking_table_isin_missing.xlsx", sheet("Cleaned_Table") firstrow clear

	drop if missing(isin) & missing(gvkey)

	save "$output/temp/dealscan_linking_table_ISIN_missing", replace

	use "$input/Linking Tables/dealscan_linking_table/dealscan_worldscope_linking_table", clear 
	
	replace isin="GB00BWFY5505" if company=="NIELSEN MEDIA RESEARCH" // This company is now a private subsidiary of Nielsen Holdings plc (GB00BWFY5505). Trucost data is available for this entity, so I match it to that identifier.
	unique isin // 16,343 unique isins (16,342 not counting the missings)
	
	count if missing(isin) // 808 observations for which the ISIN is missing
	
	// add gvkey and some extra isins
	merge m:1 companyID cleaned_matched_name using "$output/temp/dealscan_linking_table_ISIN_missing", keepusing(isin gvkey) update	
		drop if _merge==2
		drop _merge

	destring gvkey, replace
	count if missing(isin) & missing(gvkey) // 23 (the remaining are small private companies)
	save "$output/temp/dealscan_worldscope_linking_table_1", replace
	
	unique isin // 16,400 (16,399 not counting the missings)
	unique gvkey // 764 gvkeys (763 not counting the missings)
	
// B) Add the gvkey for the rest of the isins
	use "$output/temp/dealscan_worldscope_linking_table_1", clear
	drop if missing(isin) | !missing(gvkey)
	sort isin
	quietly by isin: gen dup = cond(_N==1,0,_n)
	drop if dup>1
	keep companyID company cleaned_matched_name cusip sedol isin

	export excel using "$output/excels/dealscan_worldscope_linking_table_1_isins.xlsx", firstrow(variables) replace 	
		
		// I) use =CIQ("IQ_ISIN";"IQ_GVKEY") to retrieve the corresponding gvkeys
		import excel using "$output/excels/dealscan_worldscope_linking_table_1_isins_1.xlsx", sheet("Sheet1") firstrow clear
		replace gvkey="" if gvkey=="(Invalid Identifier)"  | gvkey=="0"
		drop if missing(gvkey)
		split gvkey, parse(,)
		keep if missing(gvkey2) // Keep the one with one only gvkey
		forvalues i=1/4{
			drop gvkey`i'				
		}
		
		// destring gvkey		
		gen gvkey_1 = substr(gvkey, 4, .)
		drop gvkey
		rename gvkey_1 gvkey
		destring gvkey, replace
		
		save "$output/temp/aux_ciq", replace
		
		// II) DOUBLE: isins that present more than one gvkey		
		import excel using "$output/excels/dealscan_worldscope_linking_table_1_isins_1.xlsx", sheet("Sheet1") firstrow clear
		replace gvkey="" if gvkey=="(Invalid Identifier)"  | gvkey=="0"
		drop if missing(gvkey)
		split gvkey, parse(,) // up to 4 different gvkeys		
		drop gvkey
		drop if missing(gvkey2) // Keep those that have multiple gvkeys and decide which one to use
		export excel using "$output/excels/dealscan_worldscope_linking_table_1_double_gvkey.xlsx", firstrow(variables) replace 
		// Look up for the ISIN for each of the GVKEYs.
		import excel using "$output/excels/dealscan_worldscope_linking_table_1_double_gvkey_1.xlsx", sheet("Sheet1") firstrow clear
		forvalues i=1/4{
		replace isin`i'="" if isin`i'=="(Invalid Identifier)"  | isin`i'=="0"
		gen isin_1 = substr(isin`i', 3, .)
		drop isin`i'
		rename isin_1 isin`i'
		}		
		
		* a) Keep the GVKEY from which I retrieve the original ISIN. 
		gen gvkey=""
		forvalues i=1/4{
			replace gvkey=gvkey`i' if isin`i'==isin
			}
			
		save "$output/temp/aux_double", replace
		
		* b) If none of the GVKEYs turns me back the original ISIN:  
		
			// i) If there is more than one GVKEY from which I retrieve an ISIN, look up for the ISIN in S&P Capital IQ:	
			keep if isin1!=isin2 & !missing(isin1) & !missing(isin2) & missing(gvkey)
			keep cleaned_matched_name isin1 isin2
			export excel using "$output/excels/aux_double_conflictings.xlsx", firstrow(variables) replace 	
/*	
cleaned_matched_name						isin1			iq_company_name1							isin2		iq_company_name2
AIR CANADA									CA0089118776	Air Canada									CA00440P4096	ACE Aviation Holdings Inc.
APARTMENT INVESTMENT AND MANAGEMENT COMPANY	US03748R7474	Apartment Investment and Management Company	US03750L1098	Apartment Income REIT Corp.
BALTIMORE GAS AND ELECTRIC COMPANY			US2103711006	Constellation Energy Group, Inc.			US0591651007	Baltimore Gas and Electric Company
LIBERTY MEDIA CORPORATION					US85571Q1022	Starz										US74915M1009	Qurate Retail, Inc.
PACIFIC GAS & ELECTRIC COMPANY				US69331C1080	PG&E Corporation							NL0000470854	Pacific Gas and Electric Company
UNION ELECTRIC CO							US0236081024	Ameren Corporation							US9065481023	Union Electric Company

With respect to LIBERTY MEDIA CORPORATION:
"For purposes of the summary below, “Old Liberty” refers to Liberty Media Corporation (including its predecessors), which changed its name to Liberty Interactive Corporation on September 22, 2011 and subsequently changed its name to Qurate Retail, Inc. on April 9, 2018.2
*/
		
			use "$output/temp/aux_double", clear	
			
			replace gvkey=gvkey1 if isin1=="CA0089118776"
			replace gvkey=gvkey1 if isin1=="US03748R7474"
			replace gvkey=gvkey2 if isin1=="US2103711006"
			replace gvkey=gvkey2 if isin1=="US85571Q1022"
			replace gvkey=gvkey2 if isin1=="US69331C1080"
			replace gvkey=gvkey2 if isin1=="US0236081024"		
		
			// ii) Keep the GVKEY that does not turn an error when retrieving the ISIN. 
			count if gvkey=="" // 79; for these cases I keep the gvkeys that returned a non-missing isin
			forvalues i=1/4{
			replace gvkey=gvkey`i' if !missing(isin`i') & gvkey==""
			}
		
			forvalues i=1/4{
			drop gvkey`i' isin`i'		
			}		
		
		// destring gvkey
		gen gvkey_1 = substr(gvkey, 4, .)
		drop gvkey
		rename gvkey_1 gvkey
		destring gvkey, replace
		
		save "$output/temp/aux_double", replace		
		
		// III) MISSINGS: 185 isins to which I couldn't assign a gvkey: use gvkey_dictionary_cusip_1.dta and gvkey_dictionary_sedol_1.dta to add gvkey
		
		* CUSIP
		use "$output/dictionaries/gvkey_dictionary_cusip_1", clear
		sort cusip gvkey // unique order
		quietly by cusip: gen dup = cond(_N==1,0,_n)
		tab dup // one cusip that repeats (UNILEVER PLC)		
		drop if gvkey==10845 & cusip=="904767704" // keep the newer one
		save "$output/temp/aux1", replace			
			
		import excel using "$output/excels/dealscan_worldscope_linking_table_1_isins_1.xlsx", sheet("Sheet1") firstrow clear
		replace gvkey="" if gvkey=="(Invalid Identifier)"  | gvkey=="0"
		keep if missing(gvkey)
		destring gvkey, replace
			
		merge m:1 cusip using "$output/temp/aux1", keepusing(gvkey) update // 3 updates
			drop if _merge==2 
			drop _merge
		erase "$output/temp/aux1.dta"
			
		* SEDOL
		merge m:1 sedol using "$output/dictionaries/gvkey_dictionary_sedol_1", keepusing(gvkey) update // 8 updates
			drop if _merge==2 
			drop _merge
			
		save "$output/temp/aux_missings", replace 
		
		* 174 isins to which I still couldn't assign a gvkey: use Chava and Roberts (2008) to match them a gvkey
				
		use "$output/temp/ds_cs_link_April_2018_post", clear
		drop if missing(gvkey) | missing(borrowercompanyid)
		
		sort gvkey borrowercompanyid
		quietly by gvkey borrowercompanyid: gen dup = cond(_N==1,0,_n)
		drop if dup>1 // don't care about other identifiers
		
		rename borrowercompanyid companyID
		
		save "$output/temp/aux0", replace
		
		use "$output/temp/aux_missings", clear
		keep if missing(gvkey)
		count // 174 observations
		
		sort companyID isin // unique order
		quietly by companyID: gen dup = cond(_N==1,0,_n)
		tab dup // companyIDs repeat; need to do the merge step by step:
			
			drop if dup>1
			drop dup
			save "$output/temp/aux1", replace
			
			use "$output/temp/aux_missings", clear
			keep if missing(gvkey)
			sort companyID isin // unique order
			quietly by companyID: gen dup = cond(_N==1,0,_n)
			keep if dup==2
			save "$output/temp/aux2", replace
			
			/* merge step by step */		
			forvalues i=1/2{
			use "$output/temp/aux`i'", clear
			merge 1:m companyID using "$output/temp/aux0", keepusing(gvkey) update
			/* keep only the updates and check the matches done through Chava and Roberts (2008) */
				keep if _merge==4 
				drop _merge
			save "$output/temp/aux`i'", replace
			}

			use "$output/temp/aux1", clear		
			append using "$output/temp/aux2"
			
			// add the Trucost name
			merge 1:m gvkey using "$output/temp/trucost_2021_1", keepusing(name)
				drop if _merge==2
				drop _merge
			
			keep companyID company cleaned_matched_name isin gvkey name
			sort gvkey companyID
			quietly by gvkey companyID: gen dup = cond(_N==1,0,_n)
			drop if dup>1
			drop dup
			
			// add the Compustat conm
			merge 1:m gvkey using "$output/dictionaries/gvkey_dictionary", keepusing(conm)
				drop if _merge==2
				drop _merge
				
			sort gvkey			
			
			gen gvkey_1 = "GV_" + string(gvkey, "%06.0f")
			drop gvkey
			rename gvkey_1 gvkey
			
			order companyID company cleaned_matched_name isin gvkey
			
			export excel using "$output/excels/chava_roberts_matches.xlsx", firstrow(variables) replace 
			// check if the gvkey is properly matched, as Chava and Roberts (2008) use to match the parents; from the isin/gvkey I can retrieve the more actualized name
			import excel "$output/excels/chava_roberts_matches_1.xlsx", sheet("Sheet1") firstrow clear
			
			drop if missing(gvkey_1)
			keep companyID gvkey_1 
			rename gvkey_1 gvkey	
			
			sort * 
			quietly by *: gen dup = cond(_N==1,0,_n)
			drop if dup>1
			drop dup
			count // 39 extra gvkeys I will assign
			save "$output/temp/chava_roberts_matches_1", replace
			
			sort companyID gvkey // unique order
			quietly by companyID: gen dup = cond(_N==1,0,_n)
			tab dup // companyIDs repeat; need to do the merge step by step:
				
				drop if dup>1
				drop dup
				save "$output/temp/aux1", replace
			
				use "$output/temp/chava_roberts_matches_1", clear
				sort companyID gvkey // unique order
				quietly by companyID: gen dup = cond(_N==1,0,_n)
				keep if dup==2
				save "$output/temp/aux2", replace
				
				/* merge step by step */
				use "$output/temp/aux_missings", clear			
				merge m:1 companyID using "$output/temp/aux1", keepusing(gvkey) update
					drop if _merge==2
					drop _merge
				save "$output/temp/aux1", replace
				
				use "$output/temp/aux_missings", clear			
				merge m:1 companyID using "$output/temp/aux2", keepusing(gvkey) update
					keep if _merge==3
					drop _merge
				save "$output/temp/aux2", replace			
			

				use "$output/temp/aux1", clear		
				append using "$output/temp/aux2"
			
				
			forvalues i=0/2{
			erase "$output/temp/aux`i'.dta"
			}
			erase "$output/temp/chava_roberts_matches_1.dta"
		
		gen gvkey_1 = "GV_" + string(gvkey, "%06.0f")
		drop gvkey
		rename gvkey_1 gvkey
		replace gvkey="" if gvkey=="GV_."
		
		save "$output/temp/aux_missings", replace
		
		* 136 isins still with no gvkey: by hand matching
		
		keep if missing(gvkey) // 136 isins with no gvkey
		drop gvkey
		
		export excel using "$output/excels/dealscan_worldscope_linking_table_1_missing_isins.xlsx", firstrow(variables) replace  
		/* by hand look for the gvkey and using "SPCIQ Identifier Converter.xlsx" */
		import excel using "$output/excels/dealscan_worldscope_linking_table_1_missing_isins_1.xlsx", sheet("Sheet1") firstrow clear
		
		drop if missing(gvkey) // 7 isins to which I could match a gvkey
			
		gen gvkey_1 = "GV_" + string(gvkey, "%06.0f")
		drop gvkey
		rename gvkey_1 gvkey		
		replace gvkey="" if gvkey=="GV_."		
		
		save "$output/temp/aux1", replace
		
		use "$output/temp/aux_missings", clear		
		
		merge 1:1 isin using "$output/temp/aux1", keepusing(gvkey) update
			drop if _merge==2
			drop _merge
			erase "$output/temp/aux1.dta"
			
		// destring gvkey
		gen gvkey_1 = substr(gvkey, 4, .)
		drop gvkey
		rename gvkey_1 gvkey
		destring gvkey, replace
		
		save "$output/temp/aux_missings", replace
		
		unique isin if missing(gvkey) // 129; check ok!
			
	/* merge the gvkeys to dealscan_worldscope_linking_table */
		
	use "$output/temp/dealscan_worldscope_linking_table_1", clear
	
		foreach v in ciq double missings{
			merge m:1 isin using "$output/temp/aux_`v'", keepusing(gvkey) update
			drop if _merge==2
			drop _merge		
		}
		
	save  "$output/temp/dealscan_worldscope_linking_table_1", replace
	
	unique gvkey // 16,725 different gvkeys (16,724 not counting the missings)

		foreach v in ciq double missings{
		erase "$output/temp/aux_`v'.dta"
		sleep 100
		}

** 3. MERGE TRUCOST WITH DEALSCAN_WORLDSCOPE_LINKING_TABLE **

* Matching through gvkey
	
	use "$output/temp/dealscan_worldscope_linking_table_1", clear
	drop if missing(gvkey) | missing(companyID)
	sort companyID gvkey
	quietly by companyID gvkey: gen dup = cond(_N==1,0,_n)	
	drop if dup>1 // drop the companyID-gvkey duplicates (I'm not interested in other identifiers)
	drop dup
	save "$output/temp/aux0", replace
	sort gvkey companyID // unique order
	quietly by gvkey: gen dup = cond(_N==1,0,_n)
	tab dup // gvkeys repeat (different companyIDs per gvkey); need to do the merge step by step:		
	
		drop if dup>1
		drop dup
		save "$output/temp/aux1", replace
		
		forvalues i=2/4{
			use "$output/temp/aux0", clear
			sort gvkey companyID // unique order
			quietly by gvkey: gen dup = cond(_N==1,0,_n)
			keep if dup==`i'
			drop dup
			save "$output/temp/aux`i'", replace
			}
			
		/* merge step by step so that each observation in trucost_2021 presents each of the corresponding dealscan info */		
		forvalues i=1/4{
		use "$output/temp/trucost_2021_1", clear
		merge m:1 gvkey using "$output/temp/aux`i'", keepusing(companyID company cleaned_matched_name cusip sedol sic) update
			keep if _merge==3 // restrain the db to those for which I have info both in trucost and ds
			drop _merge
		save "$output/temp/aux`i'", replace
		}

		use "$output/temp/aux1", clear
		forvalues i=2/4{
		append using "$output/temp/aux`i'"	
		}
		
	// eliminate repeated observations
	sort *
	quietly by *: gen dup = cond(_N==1,0,_n)	
	drop if dup>1
	drop dup
	
	drop if missing(tcuid)
	drop if missing(companyID) // keep only the firms for which I have info in both trucost and dealscan	
	
save "$output/temp/trucost_dealscan_worldscope_linking_table", replace

	forvalues i=0/4{
	erase "$output/temp/aux`i'.dta"	
	sleep 100
	}	

// Number of dealscan companies for which we have info in trucost:	
unique companyID // 6,975 different dealscan companies (of the ds-wrds matching table) for which we have info in trucost
	
gen borrower = company
gen borrowercompanyid = companyID
gen lender = company
gen lenderid = companyID // in order to do the merges

order companyID company borrowercompanyid borrower lenderid lender cusip sedol isin sic

save "$output/temp/trucost_dealscan_worldscope_linking_table", replace
