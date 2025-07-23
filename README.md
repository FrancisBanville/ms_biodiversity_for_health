# Monitoring biodiversity for human, animal, and environmental health

This manuscript was made with Quarto using an adaptation of the [Quarto template for PLOS](https://github.com/quarto-journals/plos). Follow [this tutorial](https://quarto.org/docs/manuscripts/authoring/vscode.html) to learn how to use Quarto with VS Code. 

## Folder organization 

This repository contains the following files and folders: 

### Writing the manuscript 

- `figures/`: contains all figures in the manuscript
- `index.qmd`: includes the content of the manuscript
- `references.bib`: contains the references of the manuscript in BibTeX format

### Formatting and compiling the manuscript

- `.github/workflows/`: contains the GitHub Actions workflow used to produce the manuscript 
- `_extensions/quarto-journals/plos/`: contains formatting files provided by the Quarto template for PLOS
- `site_libs/`: contains formatting files used for the manuscript website
- `_quarto.yml`: specifies the project's type and outputs
- `plos2015.bst`: contains instructions to correctly compile the bibliography according to PLOS guidelines

### Miscellaneous

- `.gitignore`: specifies which files and folders are ignored when committing changes
- `LICENSE.txt`: specifies the license of the manuscript


## Data and code

All data and code used to produce the figures and results of this manuscript can be found in [this repository](https://github.com/FrancisBanville/BiodiversityForHealth/blob/main/).