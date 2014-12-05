# http://robjhyndman.com/hyndsight/makefiles/
# https://www.cs.umd.edu/class/fall2002/cmsc214/Tutorial/makefile.html

# List the R files used
# RFILES := data_prep.R data_analysis.R optimize.R optimization_analysis.R

# Rout indicator files to show R file has run
# R CMD BATCH will generate .Rout files after running
# OUT_FILES:= $(RFILES:.R=.Rout)


all: index

index: index.Rmd
	Rscript -e "library(methods); library(slidify); slidify('index.Rmd')"

clean:
	rm -f index.md
	rm -f *.html
	
