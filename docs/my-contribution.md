# My Contribution

This public repo is centered on the part of the project where I did the most original technical work: the `trucost_dealscan_cp_matching` workflow.

The included scripts show work on:

- extending borrower-side links between DealScan and Trucost,
- recovering missing identifiers through multiple matching routes,
- combining old and new DealScan identifier systems,
- integrating Compustat and Capital IQ identifiers,
- and consolidating the resulting matches into a usable final layer.

In practical terms, the skill demonstrated here is not just writing Stata syntax. It is building a workable identifier pipeline in a messy empirical setting where:

- source tables are incomplete,
- multiple external linking tables disagree or only partially overlap,
- some entities need manual review,
- and mergers or parent-child relationships matter for the final mapping.

That matching and merge logic is the main reason these scripts are the focus of the public repo.
