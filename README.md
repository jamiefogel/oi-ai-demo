# oi-ai-demo

This repo was built entirely through a single interactive conversation with Codex, OpenAI's AI coding agent. Codex is very similar to Claude Code from Anthropic and one could likely achieve very similar results with the latter. The goal was to demonstrate how a researcher can use AI to go from a high-level research question to a complete, reproducible analysis — including data acquisition, figure generation in multiple languages, and a compiled LaTeX document — in one sitting.

The full conversation is preserved in [`docs/chat_transcript.md`](docs/chat_transcript.md).

## What happened in the demo

### Starting from a research question

The user began with a broad prompt: explore how correlated neighborhood-level economic mobility estimates are across different groups, using the [Opportunity Atlas](https://opportunityinsights.org/data/) data from Opportunity Insights. Specifically:

1. Are the places where poor kids have high upward mobility the same places where rich kids do well?
2. Are the places where white kids have high upward mobility the same places where Black kids do well?

The user asked Codex to make a plan, create a GitHub repo, and interview them about key analysis decisions along the way.

### Codex set up the project

In its first response, Codex created the GitHub repository, scaffolded the directory structure, and wrote initial drafts of:

- A step-by-step analysis plan ([`docs/analysis_plan.md`](docs/analysis_plan.md))
- A decision log to record analysis choices ([`docs/decision_log.md`](docs/decision_log.md))
- An R script to generate the figures ([`src/make_figures.R`](src/make_figures.R))

It then posed six interview questions about decisions that needed to be made before producing any output: which weights to use, how to handle missing data, how many bins, whether to exclude territories, and how to set axis ranges.

### The user made the decisions

The user answered the six questions in a single message — choosing below-median sample-size weights, dropping rows with zero weight, 20 bins, excluding territories, and fixed [0, 1] axes. Codex locked these into the decision log, checked the data for available weight variables (discovering that p25-specific weights don't exist in the file), and updated the analysis script accordingly.

### End-to-end execution

With decisions locked, Codex ran the full pipeline:

1. Downloaded `tract_outcomes.zip` from the Census Bureau via a shell script it wrote
2. Ran the R analysis script, producing four scatter plots (raw and binned for each comparison)
3. Generated a LaTeX file and compiled it into a two-page PDF

The key results: the correlation between poor and rich kids' mobility is 0.743 (places good for poor kids tend to be good for rich kids too), while the white-Black correlation is much lower at 0.357 (places good for white kids are less predictive of outcomes for Black kids).

### Iterative refinement

The user then made several follow-up requests, each handled by Codex:

- **Format the figures** to match the style of an existing Opportunity Insights publication (the user provided a screenshot as a reference). Codex created a new formatted R script rather than modifying the original.
- **Replicate in Python and Stata** to demonstrate cross-language reproducibility. Codex wrote equivalent scripts in both languages and verified they produced matching output.
- **Clean up naming conventions** — standardize output filenames with language suffixes (`_R`, `_python`, `_stata`) and ensure exactly 12 PDFs in the figures folder.
- **Export the conversation** as a formatted transcript for documentation.

### What this demonstrates

- **Decision-driven workflow**: Analysis choices were separated from code and locked before any figures were generated, making the research process transparent and auditable.
- **Conversational iteration**: The project evolved through natural back-and-forth — the user gave high-level direction and made substantive decisions while Codex handled implementation details.
- **Multi-language reproducibility**: The same analysis was implemented in R, Python, and Stata, producing identical results and serving as a cross-check.
- **End-to-end automation**: From an empty directory to a compiled PDF with publication-quality figures, all within a single conversation.

## Project layout

```
oi-ai-demo/
├── data/                      # Downloaded data (not tracked by git)
│   └── tract_outcomes/
│       └── tract_outcomes_early.csv
├── docs/
│   ├── analysis_plan.md       # Step-by-step methodology
│   ├── decision_log.md        # Locked analysis decisions
│   ├── chat_transcript.md     # Full conversation from the demo
│   └── reference/             # Style reference materials
├── src/
│   ├── download_data.sh       # Downloads data from the Census Bureau
│   ├── make_figures.R         # Basic R implementation
│   ├── make_figures_formatted.R  # Publication-styled R version
│   ├── make_figures_python.py # Python implementation
│   └── make_figures_stata.do  # Stata implementation
├── figures/                   # 12 generated PDFs (4 figures x 3 languages)
└── latex/
    ├── atlas_mobility_figures.tex
    └── atlas_mobility_figures.pdf
```

## Quick start

**Prerequisites:** R (with `data.table` and `ggplot2`), or Python (with `numpy` and `matplotlib`), or Stata 17+. You also need `curl` and `unzip` for data download, and optionally `pdflatex` for the LaTeX compilation.

```bash
# Clone and enter the repo
git clone https://github.com/jamiefogel/oi-ai-demo.git
cd oi-ai-demo

# Download Opportunity Atlas tract-level data (~100 MB)
bash src/download_data.sh

# Generate figures (pick your language)
Rscript src/make_figures_formatted.R   # R (formatted)
python3 src/make_figures_python.py     # Python
# stata-mp -b do src/make_figures_stata.do  # Stata (adjust path to your install)

# Compile the LaTeX PDF (optional)
cd latex && pdflatex atlas_mobility_figures.tex
```

## Setting up Codex or Claude Code in VS Code

If you want to try this workflow yourself, you'll need VS Code and an AI coding extension. Here's how to get set up.

### Install VS Code

1. Go to [https://code.visualstudio.com](https://code.visualstudio.com) and download the installer for your operating system (macOS, Windows, or Linux).
2. Run the installer and follow the prompts.
3. Open VS Code once it's installed.

### Option A: Install Codex (OpenAI)

1. In VS Code, open the Extensions panel by clicking the square icon in the left sidebar or pressing `Ctrl+Shift+X` (Windows/Linux) or `Cmd+Shift+X` (macOS).
2. Search for **"Codex"** and install the extension published by OpenAI.
3. Once installed, open the Codex panel from the sidebar.
4. You'll be prompted to sign in with your OpenAI account. You'll need an OpenAI API key or an active ChatGPT subscription that includes Codex access.

### Option B: Install Claude Code (Anthropic)

1. Open the Extensions panel in VS Code (`Ctrl+Shift+X` / `Cmd+Shift+X`).
2. Search for **"Claude Code"** and install the extension published by Anthropic.
3. Once installed, open the Claude Code panel from the sidebar.
4. You'll be prompted to sign in with your Anthropic account. You'll need either an Anthropic API key or a Claude Pro/Max subscription.

Both tools give you an interactive chat panel inside VS Code where you can give natural-language instructions, and the agent can read files, write code, run terminal commands, and iterate based on your feedback — the same workflow shown in this demo.

## Data source

[Opportunity Atlas](https://opportunityinsights.org/data/) — tract-level estimates of children's long-run outcomes from Chetty, Friedman, Hendren, Jones, and Porter (2018).
