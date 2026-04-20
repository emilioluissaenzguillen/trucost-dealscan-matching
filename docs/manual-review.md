# Manual Review Layer

Several matching steps in this workflow were semi-automated rather than fully automated.

The typical pattern was:

1. export a candidate-match file from Stata,
2. review ambiguous or missing cases in Excel,
3. enrich the sheet with selected identifiers or notes,
4. import the revised file back into Stata.

## Why Manual Review Was Needed

This project works with real financial entities, so simple exact matching is often not enough. Examples of issues that required human review include:

- multiple GVKEY candidates for one ISIN,
- parent versus subsidiary ambiguity,
- entity renamings after mergers,
- incomplete identifiers in one source but not another,
- and conflicting links returned by different lookup routes.

## Typical Review Outputs

The curated scripts reference review files such as:

- Trucost ISIN-to-GVKEY enrichment sheets
- DealScan-Worldscope ISIN review sheets
- Chava-and-Roberts match review sheets
- DealScan-Trucost-Compustat review sheets
- final identifier sheets

Safe mock versions of these files are provided in `templates/`.

## What A Reviewer Was Usually Deciding

- Which candidate GVKEY best corresponds to the entity in the source file.
- Whether a match refers to the standalone entity or the parent.
- Whether a candidate should be excluded because it reflects an outdated or economically different entity.
- Whether the review should preserve a match, override it, or leave it missing.

## Public-Safe Interpretation

Including this manual layer is important because the engineering value of the workflow is not just in scripted joins. A large part of the work is building a reliable process for surfacing ambiguous cases, reviewing them systematically, and feeding the decisions back into the pipeline.
