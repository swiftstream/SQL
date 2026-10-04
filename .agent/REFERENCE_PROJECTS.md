# External Evidence and Reference Projects

SQL currently has no package dependencies in `Package.swift`. Do not invent dependency or reference-project entries for the package.

External repositories may be supplied transiently for research, comparison, API inspection, or style extraction. Stable documentation must not preserve machine-local checkout paths, sibling-layout assumptions, branch or commit provenance, sampled evidence inventories, or instructions to follow another project merely as provenance. Concrete provenance belongs in `.artifacts/**`.

Any rule promoted into stable documentation must be self-contained and remain understandable on another machine without the external checkout.

Generated, vendor, framework-forced, or unreviewed examples are not automatic maintainer-style authority. Current external database or dialect facts should be checked against authoritative current sources when they may have changed.
