# Public Data Included

This public repo now includes a narrow set of safe data assets under `Databases/` so that readers can inspect the real matching inputs and final linking outputs that sit closest to the curated scripts.

## Included Input Tables

- `Databases/input/Linking Tables/Chava_roberts_ds_cs_link_April_2018_post.xlsx`
- `Databases/input/Linking Tables/Dealscan_Lender_Link_Schwert_2020.xlsx`
- `Databases/input/Linking Tables/dealscan_linking_table/dealscan_worldscope_linking_table.dta`
- `Databases/input/Linking Tables/Jan Keil/rssd_lenderid.csv`
- `Databases/input/Linking Tables/Jan Keil/rssd_ultimateparentid.csv`

## Included Derived Outputs

- `Databases/output/Dealscan_tcst_cpst Tables/Borrowers_linkingtable_matches.xlsx`
- `Databases/output/Dealscan_tcst_cpst Tables/Identifiers - Final.dta`
- `Databases/output/Dealscan_tcst_cpst Tables/Identifiers - Final.xlsx`
- `Databases/output/Dealscan_tcst_cpst Tables/output_ds(new)/temp/matches_chava_new.dta`
- `Databases/output/Dealscan_tcst_cpst Tables/output_ds(new)/temp/matches_schwert.dta`
- `Databases/output/Dealscan_tcst_cpst Tables/output_ds(new)/temp/ds_lender_link_schwert_compustat_bankscope_1.dta`

## Why These Files

The included files are the safe part of the workflow that adds the most value for a public repository:

- public or broadly shareable linking tables used as matching inputs,
- the authored borrower-side linking table used throughout the curated scripts,
- and selected final matching outputs that show the end product of the pipeline.

The repo still excludes licensed raw vendor datasets, broad intermediate dumps, notes, emails, and historical duplicate workspaces.

## Citation And Reuse

If you reuse the public external linking tables, cite the original source papers or data releases rather than this repository alone. This repo includes them because they are important inputs to the matching logic and help make the workflow interpretable.

## Source Notes

- `Chava_roberts_ds_cs_link_April_2018_post.xlsx` corresponds to the DealScan-Compustat borrower link associated with Chava and Roberts, "How Does Financing Impact Investment? The Role of Debt Covenants," *Journal of Finance* (2008), and distributed through WRDS as the Roberts DealScan-Compustat Linking Database.
- `Dealscan_Lender_Link_Schwert_2020.xlsx` is the lender-side DealScan link commonly cited in the literature as the Schwert link table, described in Michael Schwert, "Bank Capital and Lending Relationships."
- `dealscan_worldscope_linking_table.dta` belongs to the DealScan-Worldscope borrower-link workflow documented by WRDS, which recommends citing the related Beyhaghi, Dai, Saunders, and Wald work on international lending.
- `rssd_lenderid.csv` and `rssd_ultimateparentid.csv` come from Jan Keil's RSSD-DealScan Database Linking Table, posted on his data page and referenced there as first presented in "Do Relationship Lenders Manage Loans Differently?"

## What Is Still Missing For Full Reproduction

The included assets make the repository much more concrete, but they do not make the entire pipeline runnable from scratch on their own. A full rerun still depends on:

- licensed DealScan extracts,
- licensed Trucost emissions data,
- some vendor translation tables,
- and a few review files that were produced during manual matching steps.
