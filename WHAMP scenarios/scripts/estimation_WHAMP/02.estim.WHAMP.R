# WHAMP network estimation

suppressMessages(library("EpiModelHIV"))
rm(list = ls())

load("/homes/dpwhite/R/GitHub Repos/WHAMP/WHAMP scenarios/est/nwstats.whamp.rda")


# 1. Main Model -----------------------------------------------------------

# Initialize network
nw.main <- base_nw_msm_whamp(st)

# Assign degree
nw.main <- assign_degree_whamp(nw.main, deg.type = "pers", nwstats = st)

# Formulas
formation.m <- ~edges +
                nodefactor("deg.pers") +
                nodefactor("race..wa", base=3) + 
                nodefactor("region", base=2) +
                nodematch("race..wa", diff=TRUE) +
                absdiff("sqrt.age") +
                offset(nodematch("role.class", diff = TRUE, keep = 1:2)) +
                offset(nodemix("region", base = c(1,3,6)))

# Fit model
fit.m <- netest(nw.main,
                formation = formation.m,
                target.stats = st$stats.m,
                coef.form = c(-Inf, -Inf, -Inf, -Inf, -Inf),
                coef.diss = st$coef.diss.m,
                constraints = ~bd(maxout = 1),
                set.control.ergm = control.ergm(MPLE.max.dyad.types = 1e10,
                                                init.method = "zeros",
                                                MCMLE.maxit = 250))


# 2. Casual Model ---------------------------------------------------------

# Initialize network
nw.pers <- nw.main

# Assign degree
nw.pers <- assign_degree_whamp(nw.pers, deg.type = "main", nwstats = st)

# Formulas
formation.p <- ~edges +
                nodefactor("deg.main") +
                concurrent +
                nodematch("race..wa", diff=TRUE) +
                nodematch("region", diff=FALSE) +
                absdiff("sqrt.age") +
                offset(nodematch("role.class", diff = TRUE, keep = 1:2))

# Fit model
fit.p <- netest(nw.pers,
                formation = formation.p,
                target.stats = st$stats.p,
                coef.form = c(-Inf, -Inf),
                coef.diss = st$coef.diss.p,
                constraints = ~bd(maxout = 2), 
                edapprox = FALSE,
                set.control.ergm = control.ergm(MPLE.max.dyad.types = 1e9,
                                                init.method = "zeros",
                                                MCMLE.maxit = 250))


# Fit inst model ----------------------------------------------------------

# Initialize network
nw.inst <- nw.main

# Assign degree
nw.inst <- set.vertex.attribute(nw.inst, "deg.main", nw.pers %v% "deg.main")
nw.inst <- set.vertex.attribute(nw.inst, "deg.pers", nw.main %v% "deg.pers")
table(nw.inst %v% "deg.main", nw.inst %v% "deg.pers")

# Formulas
formation.i <- ~edges +
                nodefactor(c("deg.main", "deg.pers")) +
                nodefactor("riskg") +
                nodematch("race..wa", diff=TRUE) +
                nodematch("region", diff=FALSE) +
                absdiff("sqrt.age") +
                offset(nodematch("role.class", diff = TRUE, keep = 1:2)) 

# Fit model
fit.i <- netest(nw.inst,
                formation = formation.i,
                target.stats = st$stats.i,
                coef.diss = dissolution_coefs(~offset(edges), 1),
                set.control.ergm = control.ergm(MPLE.max.dyad.types = 1e9,
                                                MCMLE.maxit = 250))

# Save data
est <- list(fit.m, fit.p, fit.i)
save(est, file = "/homes/dpwhite/R/GitHub Repos/WHAMP/WHAMP scenarios/est/fit.whamp.rda")


# Diagnostics -------------------------------------------------------------

## See file "WHAMP scenarios/fit tests/test_model_fit.Rmd
