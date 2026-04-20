# Provenance And Attribution

## Purpose Of This Public Repo

This repository is a public-safe reconstruction of a collaborative research workspace. Its purpose is to document the technical workflow and the matching logic without publishing proprietary inputs or overstating individual ownership.

## Origin Of The Material

- The archived scripts in the original workspace include mixed authorship and collaboration markers from the broader IESE RA workflow.
- The code reflects collaborative research-assistant work carried out at IESE.
- The original folder contained both code and non-public materials such as vendor data extracts, manually enriched spreadsheets, emails, notes, and literature files.

## What Was Curated Into This Repo

- A selected set of Stata scripts from `trucost_dealscan_cp_matching`.
- Only the public-facing copies of scripts whose headers identify Emilio Luis Saenz Guillen as author.
- Documentation explaining the pipeline, limits, and attribution.
- No raw vendor data, generated output files, or private notes.

## Collaboration-Sensitive Elements

Several parts of the underlying workflow were clearly collaborative in the source material:

- The borrower-side matching starts from a pre-existing `dealscan_worldscope_linking_table`.
- The scripts reference a supplementary missing-ISIN matching file used to fill missing ISINs and GVKEYs.
- Comments in the archived workspace reflect inherited entity-level judgments and review steps beyond the public sample shown here.
- The lender-side matching also relies on external linking tables such as Schwert (2020), which were then extended through additional CUSIP-based matching and by-hand review.

## Safe Public Interpretation

The fairest public interpretation is:

- This repo demonstrates original authored implementation work on identifier reconciliation, matching-table extension, merge design, and workflow reconstruction.
- It does not claim that every source table or entity-level decision used by the workflow originated with one person alone.
- It preserves enough context to show the engineering problem and the solution approach while remaining honest about collaboration.

## What Is Deliberately Omitted

- DealScan, Trucost, Capital IQ, and other proprietary raw datasets.
- Most intermediate `.dta`, `.xlsx`, `.csv`, and other generated outputs.
- Emails, notes, screenshots, and literature files from the original workspace.
- Some manual working spreadsheets referenced by the scripts.

## How To Read The Repo

Treat the repo as:

- a skills-focused archive of a real matching pipeline,
- a public-facing reconstruction of collaborative research-support work,
- and a documentation layer over a non-public empirical data process.
