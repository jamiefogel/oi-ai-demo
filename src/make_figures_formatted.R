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

bg_color <- "#ECECEC"
teal_color <- "#25A391"
orange_color <- "#E2912D"
axis_gray <- "#6F6F6F"
text_dark <- "#1F1F1F"

theme_oi_style <- function() {
  theme_minimal(base_size = 12) +
    theme(
      panel.background = element_rect(fill = bg_color, color = NA),
      plot.background = element_rect(fill = bg_color, color = NA),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.line = element_line(color = axis_gray, linewidth = 0.5),
      axis.ticks = element_line(color = axis_gray, linewidth = 0.5),
      axis.text = element_text(color = text_dark, size = 11),
      axis.title = element_text(color = text_dark, face = "bold", size = 12),
      plot.title = element_text(face = "bold", hjust = 0.5, size = 15, margin = margin(b = 8)),
      plot.subtitle = element_text(face = "bold", hjust = 0.5, size = 11, margin = margin(b = 6)),
      plot.margin = margin(14, 14, 14, 14)
    )
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

make_scatter_plot <- function(dt, xcol, ycol, wcol, title, subtitle, xlab, ylab, out_path, series_color, nbins = NULL) {
  x <- dt[[xcol]]
  y <- dt[[ycol]]
  w <- dt[[wcol]]
  corr <- weighted_cor(x, y, w)

  label <- sprintf("Weighted r = %.3f", corr)
  xlim_use <- as.numeric(quantile(x, c(0.005, 0.995), na.rm = TRUE))
  ylim_use <- as.numeric(quantile(y, c(0.005, 0.995), na.rm = TRUE))
  xlim_use <- c(max(0, xlim_use[1]), min(1, xlim_use[2]))
  ylim_use <- c(max(0, ylim_use[1]), min(1, ylim_use[2]))
  x_annot <- xlim_use[1] + 0.02 * (xlim_use[2] - xlim_use[1])
  y_annot <- ylim_use[2] - 0.03 * (ylim_use[2] - ylim_use[1])

  if (is.null(nbins)) {
    p <- ggplot(dt, aes(x = .data[[xcol]], y = .data[[ycol]])) +
      geom_point(alpha = 0.10, size = 0.9, color = series_color) +
      geom_smooth(method = "lm", se = FALSE, color = series_color, linewidth = 1.1) +
      labs(title = title, subtitle = subtitle, x = xlab, y = ylab) +
      annotate("text", x = x_annot, y = y_annot, label = label, hjust = 0, vjust = 1, size = 4.0, fontface = "bold", color = text_dark) +
      theme_oi_style() +
      theme(plot.title = element_text(color = series_color, face = "bold", hjust = 0.5, size = 15)) +
      coord_cartesian(xlim = xlim_use, ylim = ylim_use)
  } else {
    binned <- bin_scatter(dt, xcol, ycol, wcol, nbins = nbins)
    p <- ggplot(binned, aes(x = x, y = y)) +
      geom_line(color = series_color, linewidth = 1.1) +
      geom_point(size = 2.5, color = series_color) +
      labs(title = title, subtitle = subtitle, x = xlab, y = ylab) +
      annotate("text", x = x_annot, y = y_annot, label = label, hjust = 0, vjust = 1, size = 4.0, fontface = "bold", color = text_dark) +
      theme_oi_style() +
      theme(plot.title = element_text(color = series_color, face = "bold", hjust = 0.5, size = 15)) +
      coord_cartesian(xlim = xlim_use, ylim = ylim_use)
  }

  ggsave(out_path, p, width = 7.8, height = 5.1, units = "in", bg = bg_color)
  corr
}

cols <- c(
  "state",
  "kfr_pooled_pooled_p25", "kfr_pooled_pooled_p75",
  "kfr_white_pooled_p25", "kfr_black_pooled_p25",
  "kid_pooled_pooled_blw_p50_n", "kid_white_pooled_blw_p50_n", "kid_black_pooled_blw_p50_n"
)
dt <- fread(input_csv, select = cols, showProgress = FALSE)
# Exclude territories; keep 50 states + DC.
territory_fips <- c(60, 66, 69, 72, 78)
dt <- dt[!state %in% territory_fips]

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
  "Poor vs Rich Mobility",
  "Raw scatter",
  "Mean rank for children from p25 parents", "Mean rank for children from p75 parents",
  file.path(fig_dir, "poor_rich_raw_R.pdf"),
  series_color = teal_color
)
corr_pr_bin <- make_scatter_plot(
  pr, "kfr_pooled_pooled_p25", "kfr_pooled_pooled_p75", "kid_pooled_pooled_blw_p50_n",
  "Poor vs Rich Mobility",
  "Binned scatter (20 weighted quantile bins)",
  "Mean rank for children from p25 parents", "Mean rank for children from p75 parents",
  file.path(fig_dir, "poor_rich_bins_R.pdf"),
  series_color = teal_color,
  nbins = 20
)
corr_wb_raw <- make_scatter_plot(
  wb, "kfr_white_pooled_p25", "kfr_black_pooled_p25", "weight_sum",
  "White vs Black Mobility (p25)",
  "Raw scatter",
  "Mean rank for white children", "Mean rank for Black children",
  file.path(fig_dir, "white_black_raw_R.pdf"),
  series_color = orange_color
)
corr_wb_bin <- make_scatter_plot(
  wb, "kfr_white_pooled_p25", "kfr_black_pooled_p25", "weight_sum",
  "White vs Black Mobility (p25)",
  "Binned scatter (20 weighted quantile bins)",
  "Mean rank for white children", "Mean rank for Black children",
  file.path(fig_dir, "white_black_bins_R.pdf"),
  series_color = orange_color,
  nbins = 20
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
  "\\includegraphics[width=\\linewidth]{../figures/poor_rich_raw_R.pdf}",
  "\\caption*{A. Raw scatter}",
  "\\end{minipage}\\hfill",
  "\\begin{minipage}{0.48\\textwidth}",
  "\\centering",
  "\\includegraphics[width=\\linewidth]{../figures/poor_rich_bins_R.pdf}",
  "\\caption*{B. Binned scatter}",
  "\\end{minipage}",
  sprintf("\\caption{Tract-level mobility (p25 vs p75). Weighted r values: raw %.3f, binned %.3f.}", corr_pr_raw, corr_pr_bin),
  "\\end{figure}",
  "",
  "\\begin{figure}[ht]",
  "\\centering",
  "\\begin{minipage}{0.48\\textwidth}",
  "\\centering",
  "\\includegraphics[width=\\linewidth]{../figures/white_black_raw_R.pdf}",
  "\\caption*{A. Raw scatter}",
  "\\end{minipage}\\hfill",
  "\\begin{minipage}{0.48\\textwidth}",
  "\\centering",
  "\\includegraphics[width=\\linewidth]{../figures/white_black_bins_R.pdf}",
  "\\caption*{B. Binned scatter}",
  "\\end{minipage}",
  sprintf("\\caption{Tract-level mobility (white vs Black, p25). Weighted r values: raw %.3f, binned %.3f.}", corr_wb_raw, corr_wb_bin),
  "\\end{figure}",
  "",
  "\\end{document}"
)
writeLines(latex_lines, latex_path)

cat("Done. Figures in figures/, TeX file in latex/.\n")
