# Workflow Map

## Matching Workflow In Plain Language

This repo focuses on the matching-heavy part of the larger project. The core problem is to connect DealScan borrowers and lenders to emissions, Compustat, and Capital IQ identifiers when there is no single clean key and when names, parents, and identifiers change over time.

## Main Steps

### 1. Borrower-side GVKEY recovery

Script:

- `stata/01_dealscan_worldscope_gvkey_matching.do`

What it does:

- Starts from a pre-existing `dealscan_worldscope_linking_table`.
- Fills missing ISIN and GVKEY information with supplementary matching inputs.
- Uses Capital IQ lookups, dictionaries, and manual review to recover more borrower-side GVKEYs.
- Produces an enriched borrower-side linking layer.

### 2. Borrower-side ISIN-based matching

Script:

- `stata/02_dealscan_worldscope_isin_matching.do`

What it does:

- Complements the GVKEY matching by working through ISIN-based links.
- Adds extra Trucost matches that are easier to capture through security identifiers than direct GVKEY mapping.

### 3. DealScan-Trucost-Compustat construction

Script:

- `stata/03_ds_trucost_compustat_construction.do`

What it does:

- Combines DealScan extracts.
- Translates between old and new DealScan identifiers.
- Merges the enriched Trucost linking table into the DealScan sample.
- Adds lender-side and parent-level identifiers needed for downstream use.

### 4. Capital IQ identifier integration

Script:

- `stata/04_capital_iq_matching.do`

What it does:

- Adds Capital IQ-related identifiers and matching logic on top of the DealScan-Trucost-Compustat layer.
- Extends the linked dataset toward the bank ownership side of the broader project.

### 5. Consolidation of new and old matching outputs

Script:

- `stata/05_merge_new_old_ds.do`

What it does:

- Consolidates identifiers across old and new matching branches.
- Produces a cleaner final identifier layer used by the wider project.

## Manual Components

The source scripts make clear that some steps were not fully automated:

- Excel add-in lookups for identifiers.
- By-hand resolution of ambiguous multiple matches.
- Entity-level corrections around mergers, parent-child structures, and renamed entities.

Those manual components are part of what makes this workflow representative of real research-data engineering rather than a toy matching example.

## What Is Intentionally Out Of Scope

This public repo does not include:

- licensed raw vendor inputs,
- ownership-construction scripts from the wider project,
- most generated intermediate `.dta` and spreadsheet outputs,
- archival or duplicate historical versions of the matching pipeline.

It does include a small set of safe linking tables and final matching outputs under `Databases/` so the matching logic is easier to inspect.
