#!/usr/bin/env Rscript
# Parse outputs for benchmark of viral inference tools
# tool: geNomad

# load packages
suppressPackageStartupMessages({
  library(optparse)
  library(readr)
  library(dplyr)})

# argument list
option_list <- list(
  make_option(c("-i", "--input"), type = "character",
              help = "geNomad *_virus_summary.tsv"),
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
  select(contig = seq_name, score = virus_score)

# save output
write_tsv(parsed_inf, opt$output)