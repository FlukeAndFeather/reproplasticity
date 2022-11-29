# Great whale color palette
pal <- function() {
  c("Blue Whale" = "#7DC0EA",
    "Fin Whale" = "#4CA888",
    "Sperm Whale" = "#E3B03C")
}
pal2 <- function() {
  c("Balaenoptera_musculus" = "#7DC0EA",
    "Balaenoptera_physalus" = "#4CA888",
    "Physeter_macrocephalus" = "#E3B03C")
}

# Plot of life history trait against body size
life_history_plot <- function(param_col, param_pretty, dat) {
  lbls_exp <- function(brks) {
    round(exp(brks), 1)
  }
  plot_dat <- dat %>%
    drop_na(adult_body_mass_kg, .data[[param_col]]) %>%
    mutate(log_mass = log(adult_body_mass_kg),
           log_param = log(.data[[param_col]]),
           great_whale = case_when(
             tree_name == "Balaenoptera_musculus" ~ "Blue Whale",
             tree_name == "Balaenoptera_physalus" ~ "Fin Whale",
             tree_name == "Physeter_macrocephalus" ~ "Sperm Whale"
           ))
  ggplot(plot_dat, aes(log_mass, log_param)) +
    geom_point(alpha = 0.5) +
    geom_smooth(method = "lm", formula = y ~ x, se = FALSE) +
    geom_point(aes(color = great_whale), drop_na(plot_dat, great_whale)) +
    scale_color_manual(values = pal()) +
    scale_x_continuous("Adult mass (kg)",
                       labels = lbls_exp) +
    scale_y_continuous(param_pretty,
                       labels = lbls_exp) +
    expand_limits(x = 0, y = 0) +
    theme_classic() +
    theme(legend.position = "none")
}

# Phylogenetic tree with cetaceans highlighted
phylogeny_plot <- function(tr) {
  clade <- MRCA(tr, c("Balaenoptera_musculus",
                      "Balaenoptera_physalus",
                      "Physeter_macrocephalus"))

  ggtree(tr, layout = "circular") +
    geom_hilight(node = clade,
                 fill = "yellow")
}

# PCA biplot of life history trait PCA
biplot <- function(pca) {
  unsigned_range <- function(x) {
    c(-abs(min(x, na.rm = TRUE)),
      abs(max(x, na.rm = TRUE)))
  }

  ratio <- function(pc1_load, pc1_scores, pc2_load, pc2_scores) {
    pc1_ratio <- unsigned_range(pc1_load) / unsigned_range(pc2_scores)
    pc2_ratio <- unsigned_range(pc2_load) / unsigned_range(pc1_scores)
    max(pc1_ratio, pc2_ratio)
  }

  pca_dat <- pca$S %>%
    as.data.frame() %>%
    rownames_to_column("tree_name") %>%
    select(tree_name, pc1 = PC1, pc2 = PC2)

  pca_load0 <- (pca$Evec %*% pca$Eval) %>%
    as.data.frame() %>%
    rownames_to_column("trait") %>%
    select(trait, pc1 = PC1, pc2 = PC2)

  pc_ratio <- ratio(pca_load0$pc1, pca_dat$pc1, pca_load0$pc2, pca_dat$pc2)

  pca_load <- pca_load0 %>%
    mutate(pc1_norm = pc1 / pc_ratio,
           pc2_norm = pc2 / pc_ratio)

  quiet <- function(x) {
    sink(tempfile())
    on.exit(sink())
    invisible(force(x))
  }

  pca_summary <- quiet(summary(pca))
  pc1_import <- pca_summary$importance["Proportion of Variance", "PC1"]
  pc2_import <- pca_summary$importance["Proportion of Variance", "PC2"]
  pc1_title <- sprintf("PC1 (%0.1f%%)", pc1_import * 100)
  pc2_title <- sprintf("PC2 (%0.1f%%)", pc2_import * 100)

  p <- ggplot(pca_dat, aes(pc1, pc2)) +
    geom_point(alpha = 0.25) +
    geom_segment(aes(x = 0, y = 0, xend = pc1_norm, yend = pc2_norm),
                 pca_load,
                 arrow = arrow(angle = 15),
                 color = "red") +
    geom_text_repel(aes(x = pc1_norm, y = pc2_norm, label = trait),
                    pca_load,
                    color = "red") +
    scale_x_continuous(pc1_title, sec.axis = sec_axis(~ . * pc_ratio)) +
    scale_y_continuous(pc2_title, sec.axis = sec_axis(~ . * pc_ratio)) +
    coord_fixed() +
    theme_classic()

  ggMarginal(p, type = "density")
}

# Distribution of PC1 (pace-of-life axis) by order
pol_plot <- function(pca, lht) {
  pol_dat <- pca$S %>%
    as.data.frame() %>%
    rownames_to_column("tree_name") %>%
    select(tree_name, pc1 = PC1, pc2 = PC2) %>%
    left_join(lht, by = "tree_name") %>%
    mutate(order = fct_reorder(order, pc1))

  pol_great_whales <- pol_dat %>%
    filter(tree_name %in% c("Balaenoptera_musculus",
                            "Balaenoptera_physalus",
                            "Physeter_macrocephalus"))

  pol_dat %>%
    ggplot(aes(pc1, order)) +
    geom_boxplot() +
    geom_point(aes(color = tree_name), pol_great_whales, size = 3) +
    scale_color_manual(values = pal2()) +
    theme_classic() +
    theme(axis.title.y = element_blank(),
          legend.position = "none")
}
