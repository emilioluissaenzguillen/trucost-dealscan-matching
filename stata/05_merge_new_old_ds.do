* ============================================================
* Carbon Emissions Bank Lending. Matching Trucost to Dealscan
* Christian Eufinger, Yuki Sakasai, Igor Kadach, Emilio Sáenz
* Author: Emilio Luis Sáenz Guillén
* Date: November, 2021
* ============================================================

clear all
set more off
global main "C:/Users/addj700/Dropbox/Carbon Emissions Bank Lending/Databases"
global output "$main/output/Dealscan_tcst_cpst Tables"
global input "$main/input"

use "$output/output_ds(new)/temp/not_matched_wrds_dsnew"

merge 1:1 borrowercompanyid using "$output/output_ds(old)/temp/not_matched_wrds_dsold"
	keep if _merge==1 // there are 99 firms that I didn't match with Dealscan (New) which aren't of those that I didn't match with Dealscan (Old)
	drop _merge
	
// Translate this 99 firms 	
merge 1:m borrowercompanyid using "$output/output_ds(new)/temp/LPC_Loanconnector_Company_ID_Mappings", keepusing(Borrower_Id)
	drop if _merge==2
	drop _merge	
	
merge 1:m Borrower_Id using "$output/output_ds(new)/temp/Dealscan_1980_2021", keepusing(Borrower_Id) // effectively these don't appear in Dealscan (New)
	drop if _merge==2
	drop _merge

merge 1:m borrowercompanyid using "$output/output_ds(old)/temp/dealscan", keepusing(borrowercompanyid lender lenderid) // and they do appear in Dealscan (Old)
	keep if _merge==3
	drop _merge
	
unique lenderid // 236 different lender banks that lend to these 88 firms

sort lenderid
quietly by lenderid: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

* 1) Let's check if these 236 banks are already included in output_ds(new)/ds_trucost_compustat_1

merge 1:m lenderid using "$output/output_ds(new)/ds_trucost_compustat_1", keepusing(lenderid) // 117 already included, so no need of including them again
	keep if _merge==1 // keep the lenders not included in output_ds(new)/identifiers.xlsx
	drop _merge
	
* 2) So we're left 121 "not included"; the easiest is just to add to output_ds(new)/ds_trucost_compustat_1 the observations from output_ds(old)/ds_trucost_compustat_1 that aren't present in output_ds(new)/ds_trucost_compustat_1

use "$output/output_ds(new)/temp/LPC_Loanconnector_Company_ID_Mappings", clear
drop if missing(lenderid)
save "$output/output_ds(new)/temp/LPC_Loanconnector_Company_ID_Mappings_1", replace


use "$output/output_ds(old)/ds_trucost_compustat_1", clear

merge 1:m lenderid gvkey_ultparent isin_ultparent using "$output/output_ds(new)/ds_trucost_compustat_1", keepusing(lenderid gvkey_ultparent isin_ultparent)
	keep if _merge==1 // keep those only present in output_ds(old)/ds_trucost_compustat_1
	drop _merge
	
// before appending need to add the New Dealscan identifiers

* i) Lender_Id CompanyName
merge m:1 lenderid using "$output/output_ds(new)/temp/LPC_Loanconnector_Company_ID_Mappings_1", keepusing(Lender_Id CompanyName)
	drop if _merge==2 // no lenderid that I couldn't translate
	drop _merge

rename CompanyName Lender_Name

save "$output/temp/ds_trucost_compustat_1_old", replace

erase "$output/output_ds(new)/temp/LPC_Loanconnector_Company_ID_Mappings_1.dta"

* ii) Lender_Parent_Name Lender_Parent_Id
use "$output/output_ds(new)/temp/Dealscan_1980_2021", clear
sort Lender_Id Lender_Parent_Id // I don't care about other identifiers
quietly by Lender_Id Lender_Parent_Id: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup
save "$output/temp/aux0", replace

sort Lender_Id Lender_Parent_Id Borrower_Id // unique order
quietly by Lender_Id: gen dup = cond(_N==1,0,_n)
tab dup // Lender_Ids repeat; need to do the merge step by step:
	
	drop if dup>1
	drop dup
	save "$output/temp/aux1", replace
	
	use "$output/temp/aux0"
	sort Lender_Id Lender_Parent_Id Borrower_Id // unique order
	quietly by Lender_Id: gen dup = cond(_N==1,0,_n)
	keep if dup==2
	drop dup
	save "$output/temp/aux2", replace
	
	// Merge
	
	use "$output/temp/ds_trucost_compustat_1_old", clear
	merge m:1 Lender_Id using "$output/temp/aux1", keepusing(Lender_Parent_Name Lender_Parent_Id)
		drop if _merge==2
		drop _merge
	save "$output/temp/aux1", replace
	
	use "$output/temp/ds_trucost_compustat_1_old", clear
	merge m:1 Lender_Id using "$output/temp/aux2", keepusing(Lender_Parent_Name Lender_Parent_Id)
		keep if _merge==3
		drop _merge
	save "$output/temp/aux2", replace
	
	use "$output/temp/aux1", clear		
	append using "$output/temp/aux2"
	
order Lender_Name Lender_Id Lender_Parent_Name Lender_Parent_Id lenderid lenderparentid ultimateparentid gvkey_ultparent cpstart_ultparent cpend_ultparent cpname_ultparent ciqid_ultparent gics_ultparent comptype_ultparent
drop lender // old name
	
save "$output/temp/ds_trucost_compustat_1_old", replace

forvalues i=0/2{
	erase "$output/temp/aux`i'.dta"
	sleep 100
	}	

use "$output/output_ds(new)/ds_trucost_compustat_1", clear

append using "$output/temp/ds_trucost_compustat_1_old"

sort Lender_Id gvkey_ultparent
quietly by Lender_Id gvkey_ultparent: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

// Yuki's CIQ ID corrections
replace ciqid_ultparent="IQ198119" if Lender_Name=="Pacific Life Insurance Co"
replace ciqid_ultparent="IQ741165" if Lender_Name=="TCW Group Inc"
replace ciqid_ultparent="IQ111588627" if Lender_Name=="Caisse Nationale des Caisses d'Epargne et de Prevoyance [CNCEP)"
replace ciqid_ultparent="IQ643289773" if Lender_Name=="Deerfield Funding Corp"
replace ciqid_ultparent="IQ3548077" if Lender_Name=="First National Bank of Commerce"
replace ciqid_ultparent="IQ111588627" if Lender_Name=="Groupe Caisse d'Epargne"
replace ciqid_ultparent="IQ111588627" if Lender_Name=="IXIS CIB"
replace ciqid_ultparent="IQ111588627" if Lender_Name=="IXIS CIB [ex-CDC IXIS Capital Markets]"
replace ciqid_ultparent="IQ111588627" if Lender_Name=="IXIS Corporate & Investment Bank [ICIB]"
replace ciqid_ultparent="IQ111588627" if Lender_Name=="Natexis Banques Populaires [ex-Banque Francaise du Commerce Exterieur]"
replace ciqid_ultparent="IQ111588627" if Lender_Name=="Natixis SA"
replace ciqid_ultparent="IQ111588627" if Lender_Name=="Natixis SA [Ex-Natexis Banques Populaires]"
replace ciqid_ultparent="IQ111588627" if Lender_Name=="Natixis SA [Ex-Natexis Banques Populaires] [Singapore]"
replace ciqid_ultparent="IQ4762042" if Lender_Name=="Nationwide Credit"
replace ciqid_ultparent="IQ9329302" if Lender_Name=="Russian Agricultural Bank [Rosselkhozbank]"
replace ciqid_ultparent="IQ27347849" if Lender_Name=="Sabanci Bank Ltd [Ex-Sabanci Bank Plc]"
replace ciqid_ultparent="IQ99221288" if Lender_Name=="Solar Capital Ltd"
replace ciqid_ultparent="IQ99221288" if Lender_Name=="Solar Capital Partners LLC"
replace ciqid_ultparent="IQ741165" if Lender_Name=="Trust Co of the West"
replace ciqid_ultparent="IQ47318406" if Lender_Name=="United Community Bancshares Inc"

replace ciqid_ultparent="IQ658776" if ciqid_ultparent=="IQ3548077"
replace ciqid_ultparent="IQ30796" if Lender_Name=="Liberty Media Corp"
replace ciqid_ultparent="IQ318091" if cpname_ultparent=="MACY'S INC"

replace ciqid_ultparent="IQ9778651" if ciqid_ultparent=="IQ621956"

export excel using "$output/temp/ds_trucost_compustat.xlsx", firstrow(variables) replace
// re run =CIQ("IQ_COMPANY_ID";"IQ_ISIN"), =CIQ("IQ_COMPANY_ID";"IQ_INDUSTRY_SECTOR") and =CIQ("IQ_COMPANY_ID";"IQ_COMPANY_TYPE")
import excel "$output/temp/ds_trucost_compustat_1.xlsx", sheet("Sheet1") firstrow clear

gen isin_ultparent_1 = substr(isin_ultparent, 3, .)
drop isin_ultparent
rename isin_ultparent_1 isin_ultparent
replace isin_ultparent="" if isin_ultparent=="(Invalid Identifier)"  | isin_ultparent=="0"

/* Make following changes for variable “cpname_ultparent” in "identifiers - Final.xlsx" */
replace cpname_ultparent="US BANCORP" if  cpname_ultparent=="U S BANCORP"
replace cpname_ultparent="CoBank, ACB" if ciqid_ultparent=="IQ4727249"
replace cpname_ultparent="NATWEST GROUP PLC" if cpname_ultparent=="ROYAL BANK OF SCOTLAND GROUP"
replace cpname_ultparent="DNB BANK ASA" if cpname_ultparent=="BERGEN BANK AS"
replace cpname_ultparent="TCW Group Inc" if cpname_ultparent=="TCW STRATEGIC INCOME FUND"

	
sort Lender_Name Lender_Id

unique gvkey_ultparent // 442 unique gvkey_ultparent
unique ciqid_ultparent // 442 (difference with the number of gvkey_ultparent has to do w/the CIQ ID last adjustments)
unique lenderid // 1617 unique lenderids
unique isin_ultparent // 424 unique isin_ultparent


save "$output/Identifiers - Final", replace
export excel using "$output/temp/identifiers.xlsx", sheet("link_data") firstrow(variables) replace
erase "$output/temp/ds_trucost_compustat_1_old.dta"

/* Get the identifiers I didn't match through Schwert's Compustat */
use "$output/Identifiers - Final", clear

rename gvkey_ultparent gvkey

merge 1:m lenderid gvkey using "$output/output_ds(new)/temp/ds_lender_link_schwert_compustat_1", keepusing(lenderid gvkey) // merge Schwert_Compustat 2010 onwards
	keep if _merge==1
	drop _merge
rename gvkey gvkey_ultparent
sort Lender_Name Lender_Id

export excel using "$output/temp/identifiers_by_hand.xlsx", sheet("link_data") firstrow(variables) replace 

use "$output/Identifiers - Final", clear

/* Industry tables */
sort gvkey_ultparent
quietly by gvkey_ultparent: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

count if missing(sic_ultparent) // 48 missings

table sic_ultparent_grouped

table gics_ultparent

table comptype_ultparent


/* Ownership Data downloading */

use "$output/Identifiers - Final", clear

/*
DNB Bank ASA (old entity, IQ621956) bought another bank in July 2021 and they appear to have set up a combined bank as new entity (IQ9778651) in the form of new bank (with the same name) absorbing the old bank. Therefore “OLD” entity is labelled as private. Economically speaking they are the same and we should treat them accordingly. We just use IQ9778651to retrieve historical ownership data (and by the moment the file provided by Yuki already present in hard copies folder)
*/
replace comptype_ultparent="Public Company" if ciqid_ultparent=="IQ621956"

keep if gics_ultparent=="Financials"
keep if comptype_ultparent=="Public Company"| comptype_ultparent=="Public Fund"  | comptype_ultparent=="Public Investment Firm"

sort ciqid_ultparent
quietly by ciqid_ultparent: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

export excel using "$output/ciqids.xlsx", firstrow(variables) replace

/* Check how many of the matched are in Compustat Banks */

use "$input/Compustat/Bank/cp1.dta", clear
destring gvkey, replace
drop cusip
save "$output/temp/cp1.dta", replace
use "$input/Compustat/Bank/cp2.dta", clear
destring gvkey, replace
drop cusip
save "$output/temp/cp2.dta", replace

use "$output/temp/cp1.dta", clear
append using "$output/temp/cp2.dta"

sort gvkey
quietly by gvkey: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup
	
rename gvkey gvkey_ultparent

merge 1:m gvkey_ultparent using "$output/Identifiers - Final"
	keep if _merge==3
	drop _merge

unique gvkey_ultparent // 104 gvkeys that appear in Compustat Banks

// erase all the auxiliar files		
	forvalues i=1/2{
		erase "$output/temp/cp`i'.dta"		
		}		
		
