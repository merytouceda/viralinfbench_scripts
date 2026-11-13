# Merge the results from the different tools


# Load libraries
library(tidyverse)

path_to_repo <- "~/Documents/GitHub/viralinfbench_scripts/"

# load output data from tools

# deepmicroclass2
deepmicroclass2_out <- read_tsv(paste(path_to_repo , "data/deepmicroclass2/classification.tsv", sep = ""))
# take the highest score between the classes, and keep whatever is either eukvir or prokvir, contig, label, confidence

# deepvirfinder
deepvirfinder_out <- read_table (paste(path_to_repo , "data/deepvirfinder/ERR12510640.contigs.fa_gt1500bp_dvfpred.txt", sep = ""))

# genomad
genomad_out <- read_tsv(paste(path_to_repo , "data/genomad/contigs_virus_summary.tsv", sep = ""))

# viralm
viralm_out <- read_csv(paste(path_to_repo , "data/viralm/result_genome_fragments.csv", sep = ""))

# virrep
virrep_out <- read_tsv(paste(path_to_repo , "data/virrep/genome_fragments_score.tsv", sep = ""))

# virsorter2
virsorter2_out <- read_tsv(paste(path_to_repo , "data/virsorter2/final-viral-score.tsv", sep = ""))



# objective = table with cols: contig | score. 


# one per tool of the parsers
# what I want is the list of contigs that are classified as viral with the score, and the ones that are classified as plasmid with the score
# Then have a script that creates a table (cols = tools, rows = contigs in mock dataset, values = V/P/O)

