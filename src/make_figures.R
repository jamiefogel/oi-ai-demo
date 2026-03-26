#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

input_csv <- "data/tract_outcomes/tract_outcomes_early.csv"
fig_dir <- "figures"
latex_dir <- "latex"
latex_path <- file.path(latex_dir, "atlas_mobility_figures.tex")

dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(latex_dir, showWarnings = FALSE, recursive = TRUE)

weighted_mean <- function(x, w) sum(w * x) / sum(w)

weighted_cor <- function(x, y, w) {
  w <- w / sum(w)
  mx <- sum(w * x)
  my <- sum(w * y)
  cov_xy <- sum(w * (x - mx) * (y - my))
  cov_xx <- sum(w * (x - mx) ^ 2)
  cov_yy <- sum(w * (y - my) ^ 2)
  cov_xy / sqrt(cov_xx * cov_yy)
}

weighted_quantile <- function(x, w, probs) {
  o <- order(x)
  x <- x[o]
  w <- w[o]
  cw <- cumsum(w) / sum(w)
  sapply(probs, function(p) x[min(which(cw >= p))])
}

bin_scatter <- function(dt, xcol, ycol, wcol, nbins = 20) {
  x <- dt[[xcol]]
  y <- dt[[ycol]]
  w <- dt[[wcol]]
  breaks <- weighted_quantile(x, w, seq(0, 1, length.out = nbins + 1))
  breaks[1] <- min(x)
  breaks[length(breaks)] <- max(x)
  breaks <- unique(breaks)
  bin <- cut(x, breaks = breaks, include.lowest = TRUE)
  bdt <- data.table(x = x, y = y, w = w, bin = bin)
  bdt <- bdt[!is.na(bin)]
  bdt[, .(x = weighted_mean(x, w), y = weighted_mean(y, w), w = sum(w)), by = bin]
}

make_scatter_plot <- function(dt, xcol, ycol, wcol, title, xlab, ylab, out_path, nbins = NULL) {
  x <- dt[[xcol]]
  y <- dt[[ycol]]
  w <- dt[[wcol]]
  corr <- weighted_cor(x, y, w)

  label <- sprintf("Weighted r = %.3f", corr)
  x_annot <- 0.02
  y_annot <- 0.96

  if (is.null(nbins)) {
    p <- ggplot(dt, aes(x = .data[[xcol]], y = .data[[ycol]])) +
      geom_point(alpha = 0.2, size = 0.5, color = "#1f3b5c") +
      labs(title = title, x = xlab, y = ylab) +
      annotate("text", x = x_annot, y = y_annot, label = label, hjust = 0, vjust = 1, size = 3) +
      theme_minimal(base_size = 11) +
      coord_cartesian(xlim = c(0, 1), ylim = c(0, 1))
  } else {
    binned <- bin_scatter(dt, xcol, ycol, wcol, nbins = nbins)
    p <- ggplot(binned, aes(x = x, y = y)) +
      geom_line(color = "#1f3b5c", linewidth = 0.6) +
      geom_point(size = 1.8, color = "#1f3b5c") +
      labs(title = title, x = xlab, y = ylab) +
      annotate("text", x = x_annot, y = y_annot, label = label, hjust = 0, vjust = 1, size = 3) +
      theme_minimal(base_size = 11) +
      coord_cartesian(xlim = c(0, 1), ylim = c(0, 1))
  }

  ggsave(out_path, p, width = 6.5, height = 5.0, units = "in")
  corr
}

cols <- c(
  "kfr_pooled_pooled_p25", "kfr_pooled_pooled_p75",
  "kfr_white_pooled_p25", "kfr_black_pooled_p25",
  "kid_pooled_pooled_blw_p50_n", "kid_white_pooled_blw_p50_n", "kid_black_pooled_blw_p50_n"
)
dt <- fread(input_csv, select = cols, showProgress = FALSE)

pr <- dt[
  !is.na(kfr_pooled_pooled_p25) & !is.na(kfr_pooled_pooled_p75) &
    !is.na(kid_pooled_pooled_blw_p50_n) & kid_pooled_pooled_blw_p50_n > 0
]
wb <- dt[
  !is.na(kfr_white_pooled_p25) & !is.na(kfr_black_pooled_p25) &
    !is.na(kid_white_pooled_blw_p50_n) & !is.na(kid_black_pooled_blw_p50_n)
]
wb[, weight_sum := kid_white_pooled_blw_p50_n + kid_black_pooled_blw_p50_n]
wb <- wb[weight_sum > 0]

corr_pr_raw <- make_scatter_plot(
  pr, "kfr_pooled_pooled_p25", "kfr_pooled_pooled_p75", "kid_pooled_pooled_blw_p50_n",
  "Tract Mobility: p25 vs p75 (Raw)",
  "Mean income rank at age 35 for p25", "Mean income rank at age 35 for p75",
  file.path(fig_dir, "poor_rich_raw.pdf")
)
corr_pr_bin <- make_scatter_plot(
  pr, "kfr_pooled_pooled_p25", "kfr_pooled_pooled_p75", "kid_pooled_pooled_blw_p50_n",
  "Tract Mobility: p25 vs p75 (Binned)",
  "Mean income rank at age 35 for p25", "Mean income rank at age 35 for p75",
  file.path(fig_dir, "poor_rich_bins.pdf"), nbins = 20
)
corr_wb_raw <- make_scatter_plot(
  wb, "kfr_white_pooled_p25", "kfr_black_pooled_p25", "weight_sum",
  "Tract Mobility: White vs Black (Raw)",
  "Mean income rank at age 35 for white p25", "Mean income rank at age 35 for black p25",
  file.path(fig_dir, "white_black_raw.pdf")
)
corr_wb_bin <- make_scatter_plot(
  wb, "kfr_white_pooled_p25", "kfr_black_pooled_p25", "weight_sum",
  "Tract Mobility: White vs Black (Binned)",
  "Mean income rank at age 35 for white p25", "Mean income rank at age 35 for black p25",
  file.path(fig_dir, "white_black_bins.pdf"), nbins = 20
)

latex_lines <- c(
  "\\documentclass{article}",
  "\\usepackage{graphicx}",
  "\\usepackage{caption}",
  "\\usepackage[margin=1in]{geometry}",
  "\\begin{document}",
  "",
  "\\begin{figure}[ht]",
  "\\centering",
  "\\begin{minipage}{0.48\\textwidth}",
  "\\centering",
  "\\includegraphics[width=\\linewidth]{../figures/poor_rich_raw.pdf}",
  "\\caption*{A. Raw scatter}",
  "\\end{minipage}\\hfill",
  "\\begin{minipage}{0.48\\textwidth}",
  "\\centering",
  "\\includegraphics[width=\\linewidth]{../figures/poor_rich_bins.pdf}",
  "\\caption*{B. Binned scatter}",
  "\\end{minipage}",
  sprintf("\\caption{Tract-level mobility (p25 vs p75). Weighted r values: raw %.3f, binned %.3f.}", corr_pr_raw, corr_pr_bin),
  "\\end{figure}",
  "",
  "\\begin{figure}[ht]",
  "\\centering",
  "\\begin{minipage}{0.48\\textwidth}",
  "\\centering",
  "\\includegraphics[width=\\linewidth]{../figures/white_black_raw.pdf}",
  "\\caption*{A. Raw scatter}",
  "\\end{minipage}\\hfill",
  "\\begin{minipage}{0.48\\textwidth}",
  "\\centering",
  "\\includegraphics[width=\\linewidth]{../figures/white_black_bins.pdf}",
  "\\caption*{B. Binned scatter}",
  "\\end{minipage}",
  sprintf("\\caption{Tract-level mobility (white vs Black, p25). Weighted r values: raw %.3f, binned %.3f.}", corr_wb_raw, corr_wb_bin),
  "\\end{figure}",
  "",
  "\\end{document}"
)
writeLines(latex_lines, latex_path)

cat("Done. Figures in figures/, TeX file in latex/.\n")
