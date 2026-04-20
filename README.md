# Carbon Emissions Bank Lending Matching Pipeline

This repository presents the matching component of a research-data workflow linking DealScan, Trucost, Compustat, and Capital IQ identifiers. The public version is intentionally narrow: it focuses on the authored Stata scripts from the `trucost_dealscan_cp_matching` workflow that best showcase identifier reconciliation, entity matching, and merge design.

This repository excludes proprietary datasets, generated outputs, notes, emails, and supporting literature.

## What This Repo Shows

The curated scripts in this repo illustrate how the matching workflow:

1. Extends borrower-side links between DealScan and Trucost.
2. Recovers missing identifiers through multiple sources and manual review.
3. Builds a matched DealScan-Trucost-Compustat dataset.
4. Integrates Capital IQ identifiers.
5. Consolidates the new and old matching outputs into a final identifier layer.

## Focus

This repository highlights the part of the project where I did the most original implementation work: the matching pipeline in `trucost_dealscan_cp_matching`. The curated scripts are the ones that best reflect the technical problems I worked on most directly, including identifier reconciliation, multi-source entity matching, and merge consolidation.

More detail is in [docs/provenance.md](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/docs/provenance.md) and [docs/my-contribution.md](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/docs/my-contribution.md).

## Repository Layout

- `stata/`: curated Stata scripts from the matching workflow.
- `docs/`: workflow, provenance, and contribution notes.

## Included Scripts

- `01_dealscan_worldscope_gvkey_matching.do`
- `02_dealscan_worldscope_isin_matching.do`
- `03_ds_trucost_compustat_construction.do`
- `04_capital_iq_matching.do`
- `05_merge_new_old_ds.do`

## Important Limitations

- The scripts still use hard-coded local paths from the original research environment.
- Several steps depend on proprietary vendor data and manually enriched Excel files.
- Some matching decisions reflect collaboration context and inherited input tables even when the implementation in this repo is authored work.
- This is a workflow and code sample, not a fully reproducible replication package.

More detail is in [docs/workflow.md](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/docs/workflow.md).
