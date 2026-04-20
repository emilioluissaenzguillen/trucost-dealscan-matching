# Carbon Emissions Bank Lending Matching Pipeline

This repository presents the matching component of a research-data workflow linking DealScan, Trucost, Compustat, and Capital IQ identifiers. The public version is intentionally narrow: it focuses on the authored Stata scripts from the `trucost_dealscan_cp_matching` workflow that best showcase identifier reconciliation, entity matching, and merge design.

This repository excludes licensed raw vendor datasets, notes, emails, and supporting literature. It now includes a small set of safe linking tables and selected final matching outputs so the workflow is easier to inspect and reuse.

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
- `Databases/`: selected safe input linking tables and derived matching outputs.
- `templates/`: mock inputs and review-file templates with safe placeholder data.

## Included Scripts

- `01_dealscan_worldscope_gvkey_matching.do`
- `02_dealscan_worldscope_isin_matching.do`
- `03_ds_trucost_compustat_construction.do`
- `04_capital_iq_matching.do`
- `05_merge_new_old_ds.do`

## Included Safe Data

To make the repo more useful, it includes:

- public or shareable linking tables such as the Chava-Roberts, Schwert, and Keil RSSD inputs,
- the authored `dealscan_worldscope_linking_table.dta` used in the borrower-side matching scripts,
- and selected final outputs such as `Identifiers - Final` and the lender-side Schwert match outputs.

That means readers can inspect real matching artifacts instead of only mock schemas, even though the licensed raw vendor inputs are still excluded.

External references for the main public link resources are collected in [docs/public-data.md](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/docs/public-data.md).

## Important Limitations

- The scripts assume the original `Databases/input` and `Databases/output` folder structure is available locally.
- The repo includes selected safe linking tables and matching outputs, but it still excludes licensed DealScan and Trucost raw data.
- Some steps also depend on translation tables and review files that were created during manual matching work.
- Some matching decisions reflect collaboration context and inherited input tables even when the implementation in this repo is authored work.
- This is a workflow and code sample, not a fully reproducible replication package.

More detail is in [docs/workflow.md](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/docs/workflow.md), [docs/data-requirements.md](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/docs/data-requirements.md), [docs/public-data.md](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/docs/public-data.md), and [docs/manual-review.md](/C:/Users/emili/Dropbox/IESE/Carbon%20Emissions%20Bank%20Lending/Carbon%20Emissions%20Bank%20Lending%20-%20github/docs/manual-review.md).
