# Data Requirements

This repository now includes a selected set of safe input and output files, but it still does not include the full licensed inputs used in the original matching workflow. The notes below separate what is already present in the repo from what a user would still need to provide for a full rerun.

## Included In The Repo

These files are already available in the public version:

- `Databases/input/Linking Tables/Chava_roberts_ds_cs_link_April_2018_post.xlsx`
- `Databases/input/Linking Tables/Dealscan_Lender_Link_Schwert_2020.xlsx`
- `Databases/input/Linking Tables/dealscan_linking_table/dealscan_worldscope_linking_table.dta`
- `Databases/input/Linking Tables/Jan Keil/rssd_lenderid.csv`
- `Databases/input/Linking Tables/Jan Keil/rssd_ultimateparentid.csv`
- `Databases/output/Dealscan_tcst_cpst Tables/Borrowers_linkingtable_matches.xlsx`
- `Databases/output/Dealscan_tcst_cpst Tables/Identifiers - Final.dta`
- `Databases/output/Dealscan_tcst_cpst Tables/Identifiers - Final.xlsx`
- `Databases/output/Dealscan_tcst_cpst Tables/output_ds(new)/temp/matches_chava_new.dta`
- `Databases/output/Dealscan_tcst_cpst Tables/output_ds(new)/temp/matches_schwert.dta`
- `Databases/output/Dealscan_tcst_cpst Tables/output_ds(new)/temp/ds_lender_link_schwert_compustat_bankscope_1.dta`

## Still Required For A Full Rerun

## Main Input Groups

### Trucost emissions input

Expected location in the original workflow:

- `Databases/input/Trucost/trucost_2021.dta`

Core fields used by the matching scripts:

- `company`
- `isin`
- `tcuid`
- `financialyear`
- emissions scope variables

Safe reference file:

- [templates/trucost_2021_mock.csv](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/templates/trucost_2021_mock.csv)

### DealScan-Worldscope linking input

Expected location in the original workflow:

- `Databases/input/Linking Tables/dealscan_linking_table/dealscan_worldscope_linking_table`

Core fields used by the matching scripts:

- `companyID`
- `company`
- `cleaned_matched_name`
- `cusip`
- `sedol`
- `isin`
- `gvkey`
- `sic`

Included in repo:

- `Databases/input/Linking Tables/dealscan_linking_table/dealscan_worldscope_linking_table.dta`

Safe reference file:

- [templates/dealscan_worldscope_linking_table_mock.csv](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/templates/dealscan_worldscope_linking_table_mock.csv)

### Supplemental missing-ISIN review file

Expected location in the original workflow:

- `Databases/input/Linking Tables/supplemental_dealscan_linking_table_isin_missing.xlsx`

Core fields used by the matching scripts:

- `companyID`
- `cleaned_matched_name`
- `isin`
- `gvkey`

Safe reference file:

- [templates/dealscan_linking_table_isin_missing_template.csv](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/templates/dealscan_linking_table_isin_missing_template.csv)

### DealScan identifier translation tables

Expected locations in the original workflow:

- `Databases/input/Dealscan/WRDS_to_LoanConnector_IDs.xlsx`
- `Databases/input/Dealscan/LPC_Loanconnector_Company_ID_Mappings.xlsx`

Core fields used by the matching scripts:

- tranche and facility identifier mapping fields
- LoanConnector company IDs
- LPC company IDs

Safe reference files:

- [templates/wrds_to_loanconnector_ids_mock.csv](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/templates/wrds_to_loanconnector_ids_mock.csv)
- [templates/lpc_loanconnector_company_id_mappings_mock.csv](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/templates/lpc_loanconnector_company_id_mappings_mock.csv)

### Review files produced and re-imported

Several scripts export candidate matches to Excel, expect manual review, and then import an enriched version back into the pipeline.

Safe reference files:

- [templates/trucost_2021_isins_enriched_template.csv](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/templates/trucost_2021_isins_enriched_template.csv)
- [templates/dealscan_worldscope_isins_enriched_template.csv](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/templates/dealscan_worldscope_isins_enriched_template.csv)
- [templates/chava_roberts_matches_review_template.csv](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/templates/chava_roberts_matches_review_template.csv)
- [templates/ds_trucost_compustat_review_template.csv](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/templates/ds_trucost_compustat_review_template.csv)
- [templates/identifiers_review_template.csv](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/templates/identifiers_review_template.csv)

## Why Templates Instead Of Real Samples

The templates use fake values and safe placeholders. They are intended to show the schema and the human-review interface without redistributing vendor-derived or project-specific data.

## Practical Run Status

People can now inspect and reuse the real safe linking tables and selected final outputs included in the repo. However, they still cannot run the entire pipeline from scratch unless they also have access to the missing licensed DealScan and Trucost inputs and place them in the expected folder structure.
