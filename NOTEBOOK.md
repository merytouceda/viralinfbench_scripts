# Lab Notebook — viralinfbench_scripts

Chronological log of work sessions on this project. Newest entries at the bottom.
Append-only — never edit or reorder past entries.

Entry format:
## YYYY-MM-DD
- What was done / tried
- What happened (concrete results, errors, numbers — not a diff restatement)
- Decision or next step

---

## 2026-11-20
- Question: should the per-tool parsing happen inside the Nextflow workflow
  (`i_mg_viralinfbenchmark` in `bonphyre_pipelines/dev/`) or stay as R scripts?
  Decision: keep it in R scripts that run as processes. Nextflow operators like
  `splitCsv` run on the head job, re-run on every `-resume`, and are hard to test
  outside the pipeline. A process with a script in `bin/` is cached, runs in its
  own container, and can be tested on its own. This is the same pattern as
  `genomad_filterviral.r`.
- Bugs found while reviewing the old per-tool `*_parse.r` scripts:
  - `viralm_parse.r` used `read_tsv` on a CSV, so it would fail.
  - Contig IDs differ between tools, so a merge would silently fail to join:
    VirSorter2 adds `||full`/`||lt2gene`/`||0_partial`, DVF keeps the whole
    header (`k127_x flag=1 multi=… len=…`), VirRep keeps the description, and
    geNomad names proviruses `contig|provirus_…`.
  - The outputs meant different things: viraLM/DMC2 kept only viral calls,
    while VirRep returned every contig. There was no DVF parser.
- Replaced them with one script, `scripts/parse_viral_inference.r --tool <name>`.
  It always writes the same columns: `sampleid | tool | contig | score | call`,
  with call = V/P/O. `--input` can be the file or the tool's output folder, and
  the script finds the file by name pattern. Per-tool choices:
  - DeepMicroClass2: score = eukvir + prokvir (the class probabilities add up
    to 1, so this is P(viral)). Call V if the label is eukvir/prokvir, P if pls.
  - DeepVirFinder has no call of its own: V if score ≥ 0.9 and p < 0.05.
  - VirRep: V if score ≥ 0.5.
  - viraLM: uses its own `prediction`.
  - geNomad and VirSorter2: everything they report is V, plus P from geNomad's
    plasmid summary when it's present.
  - Contig ID = first word before any space or `|`. When one contig has several
    calls (proviruses or partials), keep the best call and then the highest score.
  - Every scored contig is kept, not only the viral ones, so ROC/PR curves are
    still possible later.
- Added `scripts/merge_viral_inference.r`: it writes a long table and a
  contig × tool V/P/O table. With `--contigs`, every contig in the assembly gets
  a row (O when no tool reported it).
- Tested on `data/`: every tool's row count matches its input file (DMC2 10000,
  DVF 26208, geNomad 17158, viraLM 10000, VirRep 10000, VS2 2013). Calls:
  DMC2 7 V / 2 P, DVF 1397 V, viraLM 33 V, VirRep 2313 V. Tested a geNomad
  plasmid file and a small FASTA for `--contigs` with fake files; both worked.
- Problems found in the test data (not in the scripts):
  - DMC2, viraLM and VirRep share only about 110 `frag_*` contigs, so they were
    run on different subsets of the mock data.
  - About 14.6k of geNomad's 17k viral calls are under 1500 bp. The geNomad
    module has no length cutoff, while DVF and VS2 use 1500. Among contigs of
    1500 bp or more, only 205 match DVF IDs, so this geNomad file probably comes
    from a different assembly than the DVF/VS2 files.
- Wired the scripts into the pipeline (`bonphyre_pipelines/dev/i_mg_viralinfbenchmark/pipeline/`):
  - Copied both scripts to `bin/`.
  - New `modules/local/viral_inference_parse.nf` has `parse_viral_inference`
    (once per sample per tool) and `merge_viral_inference` (once per sample).
  - The workflow sends each tool's output folder to the parser, then groups the
    parsed tables by sample and joins them with the contigs.
  - New config settings: `dvf_min_score`, `dvf_max_pvalue`, `virrep_min_score`
    and `container__parse_viralinference`.
  - The workflow passes Nextflow's `--help` check. The processes have not run
    on Hazel yet.
- Next steps:
  - Confirm the path of the R container (set to `microbial_ecology_20261012.sif`).
  - Check that real tool outputs match the file patterns.
  - Decide on a geNomad length cutoff.
  - Rerun the mock data so all tools see the same input.
  - Delete the old `*_parse.r` scripts and `merge_outputs.r`.
  - Remember that the scripts live in this repo and in `pipeline/bin/`: after
    editing one, copy it to the other.
- Later the same day: decided viruses and plasmids get separate pipelines and
  separate script repos. Plasmid parsing moved to `plasmidinfbench_scripts`
  (see its notebook).
- Changed the output format of `parse_viral_inference.r` to
  `sampleid | tool | contig | score | call`, with call = 1 (viral) or 0
  (scored but not called). V/P/O is gone because this parser only looks at
  viruses. Removed the plasmid parts: geNomad `--plasmid` and the DMC2 `pls` → P
  rule. Briefly had a `target` column (virus/plasmid) so both kinds of output
  could be stacked; dropped it once the pipelines were split.
- `merge_viral_inference.r` now writes 1/0 per tool. 0 means not called or
  not reported; the long table tells the two apart.
- Restructured the parser so each tool is one entry (file pattern + parse
  function) in a `tools` list, because more tools will be added. The `--tool`
  choices and help text come from the list. Wrote `scripts/README.md`,
  explaining when adding a tool only needs a new entry and when it needs more
  (results split over several files, or a FASTA of hits only). Tested the
  README's example entry in a copy of the parser: it parses and shows in `--help`.
- VirSorter2 `lt2gene` contigs (fewer than 2 genes but have hallmark genes)
  have `nan` scores: 118 of 2013 calls. They are now read as NA and still
  count as calls. Still to decide: leave them NA or set them to 1 for ROC/PR.
- Re-ran on `data/`: same call counts as before (DMC2 7, DVF 1397, geNomad
  17158, viraLM 33, VirRep 2313, VS2 2013).
- Copied the new scripts into `bonphyre_pipelines`
  (`dev/i_mg_viralinfbenchmark/pipeline/bin/`, branch
  `viralinfbench-parse-outputs`) and updated the module comments. Still passes
  the Nextflow `--help` check.
