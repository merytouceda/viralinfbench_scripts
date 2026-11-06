# Merge the results from the different tools


# Load libraries
library(tidyverse)

path_to_repo <- "~/Documents/GitHub/viralinfbench_scripts/"

# load output data from tools

# genomad
genomad_out <- read_tsv(paste(path_to_repo , "data/genomad/contigs_virus_summary.tsv", sep = ""))

# deepvirfinder