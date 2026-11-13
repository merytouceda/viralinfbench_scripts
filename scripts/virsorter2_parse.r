#!/usr/bin/env Rscript
# Parse outputs for benchmark of viral inference tools
# tool: VirSorter2

# load packages
suppressPackageStartupMessages({
  library(optparse)
  library(readr)
  library(dplyr)})

# argument list
option_list <- list(
  make_option(c("-i", "--input"), type = "character",
              help = "VirSorter2 final-viral-score.tsv"),
  make_option(c("-o", "--output"), type = "character",
              help = "Output TSV (contig, score)"))

opt <- parse_args(OptionParser(option_list = option_list))

# missing input error
if (is.null(opt$input) || is.null(opt$output)) {
  stop("Both --input and --output are required. Run with --help for usage.")
}

# import data
raw_inf <- read_tsv(opt$input, show_col_types = FALSE)


# parse
parsed_inf <- raw_inf %>%
  select(contig = seqname, score = max_score)

# save output
write_tsv(parsed_inf, opt$output)