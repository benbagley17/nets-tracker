# ============================================================
# Brooklyn Nets Milestone & Streak Tracker
# Data Fetch Script — powered by hoopR
#
# Uses nba_leaguedashplayerstats() for season totals (one bulk call)
# and nba_playercareerstats() with NBA.com player IDs for career totals.
#
# RUN:   Rscript r/fetch_nets_stats.R   (from repo root)
# ============================================================

suppressPackageStartupMessages({
  library(hoopR)
  library(dplyr)
  library(jsonlite)
  library(cli)
  library(tibble)
})

cli_h1("Nets Milestone Tracker — Data Fetch")
cli_alert_info("Run time: {Sys.time()}")

# ── CONFIG ────────────────────────────────────────────────────

CURRENT_SEASON <- 2026   # hoopR season = year season ENDS (2025-26 = 2026)

OUTPUT_DIR <- "public/data"
if (!dir.exists(OUTPUT_DIR)) OUTPUT_DIR <- "../public/data"
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)
cli_alert_info("Output directory: {normalizePath(OUTPUT_DIR)}")

# ── ROSTER — NBA.com player IDs ───────────────────────────────
# NBA.com IDs (not ESPN IDs) — used by nba_playercareerstats()
# Source: nba.com/stats, basketball-reference.com

NETS_ROSTER <- tribble(
  ~player_id,   ~full_name,             ~number, ~pos,  ~nba_id,
  "claxton",    "Nic Claxton",          "33",    "C",   "1630567",
  "porter",     "Michael Porter Jr.",   "1",     "SF",  "1629008",
  "demin",      "Egor Dëmin",           "8",     "PG",  "1642355",
  "traore",     "Nolan Traoré",         "19",    "PG",  "1642356",
  "sharpe",     "Day'Ron Sharpe",       "20",    "C",   "1630549",
  "williams",   "Ziaire Williams",      "26",    "SF",  "1630533",
  "wilson",     "Jalen Wilson",         "22",    "SF",  "1641706",
  "mann",       "Terance Mann",         "14",    "SG",  "1629611",
  "highsmith",  "Haywood Highsmith",    "24",    "SF",  "1629754",
  "clowney",    "Noah Clowney",         "21",    "PF",  "1641724",
  "powell",     "Drake Powell",         "10",    "SF",  "1642361",
  "saraf",      "Ben Saraf",            "26",    "PG",  "1642362",
  "wolf",       "Danny Wolf",           "27",    "C",   "1642363",
  "agbaji",     "Ochai Agbaji",         "30",    "SG",  "1630534",
  "liddell",    "E.J. Liddell",         "4",     "PF",  "1630551"
)

# ── MILESTONE DEFINITIONS ─────────────────────────────────────
# career_prior = verified career total BEFORE 2025-26 season
# These are the fallback values if the API returns nothing

MILESTONE_DEFS <- tribble(
  ~id,                            ~player_id,  ~type,       ~category,        ~stat_label,                  ~stat_col,   ~career_prior, ~target, ~unit,
  "claxton-500-blocks",           "claxton",   "milestone", "Blocks",         "Career Blocks",              "BLK",       418L,          500L,    "BLK",
  "claxton-franchise-blk-record", "claxton",   "record",    "Blocks",         "Franchise All-Time Blocks",  "BLK",       418L,          522L,    "BLK",
  "porter-1000-career-3pm",       "porter",    "milestone", "Three-Pointers", "Career 3-Pointers Made",     "FG3M",      742L,          1000L,   "3PM",
  "porter-5000-career-pts",       "porter",    "milestone", "Points",         "Career Points",              "PTS",       3613L,         5000L,   "PTS",
  "williams-300-career-3pm",      "williams",  "milestone", "Three-Pointers", "Career 3-Pointers Made",     "FG3M",      218L,          300L,    "3PM",
  "sharpe-50-double-doubles",     "sharpe",    "milestone", "Rebounding",     "Career Double-Doubles",      "DD2",       32L,           50L,     "DDs",
  "mann-500-career-games",        "mann",      "milestone", "Games",          "Career Games Played",        "GP",        438L,          500L,    "GP",
  "wilson-1000-career-pts",       "wilson",    "milestone", "Points",         "Career Points",              "PTS",       784L,          1000L,   "PTS",
  "clowney-500-career-pts",       "clowney",   "milestone", "Points",         "Career Points",              "PTS",       312L,          500L,    "PTS",
  "agbaji-500-career-3pm",        "agbaji",    "milestone", "Three-Pointers", "Career 3-Pointers Made",     "FG3M",      198L,          300L,    "3PM"
)

MEDIA_ALERTS <- list(
  "claxton-500-blocks"           = "Prepare a '500-block club' historical comparison — Mourning, Mutombo, and elite rim protectors. Claxton will be one of the youngest Nets to reach this mark.",
  "claxton-franchise-blk-record" = "FRANCHISE ALL-TIME RECORD. Coordinate with Nets PR. Reach out to Brook Lopez for a potential tribute. Pull Lopez footage for B-roll.",
  "porter-1000-career-3pm"       = "Only ~200 NBA players have made 1,000 career threes. Porter averaged 3.4 per game in 2025-26 before his hamstring. Pre-write now for early 2026-27.",
  "porter-5000-career-pts"       = "5,000 career points is a star-level benchmark. Porter averaged a career-high 24.2 ppg in 2025-26. Feature: his evolution from Denver role player to Brooklyn's franchise cornerstone.",
  "williams-300-career-3pm"      = "Drafted 10th overall, now a reliable floor spacer. 300 career threes marks his establishment as a perimeter threat.",
  "sharpe-50-double-doubles"     = "Sharpe's 50th career double-double is a durability milestone at 24 years old. His role grew significantly in 2025-26 (career-high 2.3 APG).",
  "mann-500-career-games"        = "500 NBA games is a longevity milestone. Mann went from a 2019 Clippers role player to a key two-way veteran. Great human interest retrospective.",
  "wilson-1000-career-pts"       = "Wilson appeared in a league-high 79 games in 2025-26. His 1,000th career point marks his establishment in the league.",
  "clowney-500-career-pts"       = "Clowney is quietly approaching 500 career points in only his third NBA season. Good young-player development feature.",
  "agbaji-500-career-3pm"        = "Agbaji is a reliable 3-point shooter who has quietly built a strong career resume. 300 career threes is a shooter's milestone."
)

# ── SAFE FETCH ────────────────────────────────────────────────

safe_fetch <- function(expr, label = "") {
  tryCatch(expr, error = function(e) {
    cli_alert_warning("{label}: {conditionMessage(e)}")
    NULL
  })
}

# ── FETCH ALL SEASON STATS IN ONE CALL ───────────────────────
# nba_leaguedashplayerstats pulls all NBA players for the season at once
# This is far more reliable than per-player calls

cli_h2("Fetching 2025-26 season totals (all NBA players, one call)")

season_totals <- safe_fetch(
  hoopR::nba_leaguedashplayerstats(
    season      = CURRENT_SEASON,
    season_type = "Regular Season",
    per_mode    = "Totals"
  ),
  label = "nba_leaguedashplayerstats"
)

# hoopR wraps results in a list — extract the data frame
if (!is.null(season_totals)) {
  if (is.list(season_totals) && !is.data.frame(season_totals)) {
    season_totals <- season_totals[[1]]
  }
  cli_alert_success("Season totals: {nrow(season_totals)} players fetched")
} else {
  cli_alert_warning("Season totals unavailable — will use career_prior fallbacks")
}

# ── FETCH CAREER TOTALS PER PLAYER ────────────────────────────
# nba_playercareerstats uses NBA.com player IDs

cli_h2("Fetching career stats per player")

career_data <- list()

for (i in seq_len(nrow(NETS_ROSTER))) {
  p <- NETS_ROSTER[i, ]
  cli_alert("  {p$full_name} (NBA ID: {p$nba_id})...")

  result <- safe_fetch(
    hoopR::nba_playercareerstats(
      player_id = p$nba_id,
      per_mode  = "Totals"
    ),
    label = p$full_name
  )

  career_data[[p$player_id]] <- result

  if (!is.null(result)) {
    cli_alert_success("    Got career data")
  } else {
    cli_alert_warning("    No career data — using fallback")
  }

  Sys.sleep(0.3)
}

# ── HELPER: extract a stat from season totals ─────────────────

get_season_stat <- function(season_df, nba_id, col) {
  if (is.null(season_df)) return(NA_integer_)
  row <- season_df |> filter(as.character(PLAYER_ID) == as.character(nba_id))
  if (nrow(row) == 0 || !col %in% names(row)) return(NA_integer_)
  as.integer(row[[col]][1])
}

# ── HELPER: extract career total from career endpoint ─────────

get_career_total <- function(career, col) {
  if (is.null(career)) return(NA_integer_)
  # Career totals live in different list elements depending on hoopR version
  totals <- career$CareerTotalsRegularSeason %||%
            career[[grep("CareerTotals", names(career), value = TRUE)[1]]]
  if (is.null(totals) || nrow(totals) == 0) return(NA_integer_)
  if (!col %in% names(totals)) return(NA_integer_)
  as.integer(totals[[col]][1])
}

`%||%` <- function(a, b) if (!is.null(a)) a else b

# ── COMPUTE MILESTONES ────────────────────────────────────────

cli_h2("Computing milestone proximity")

milestone_results <- list()

for (i in seq_len(nrow(MILESTONE_DEFS))) {
  m   <- MILESTONE_DEFS[i, ]
  ros <- NETS_ROSTER |> filter(player_id == m$player_id)
  car <- career_data[[m$player_id]]

  # 1. Try career endpoint for career total
  career_total <- get_career_total(car, m$stat_col)

  # 2. Try season totals endpoint
  season_val <- get_season_stat(season_totals, ros$nba_id, m$stat_col)
  gp         <- get_season_stat(season_totals, ros$nba_id, "GP")
  if (is.na(gp)) gp <- 0L

  # 3. Determine current value
  current <- if (!is.na(career_total)) {
    career_total  # career endpoint is authoritative
  } else if (!is.na(season_val)) {
    m$career_prior + season_val  # prior + this season
  } else {
    m$career_prior  # hardcoded fallback
  }

  # 4. Pace & games away
  pace <- if (!is.na(season_val) && gp > 0) round(season_val / gp, 2) else 0
  remaining  <- max(0L, as.integer(m$target) - as.integer(current))
  games_away <- if (pace > 0 && remaining > 0) ceiling(remaining / pace) else NA_integer_

  urgency <- case_when(
    is.na(games_away)    ~ "upcoming",
    games_away <= 5      ~ "urgent",
    games_away <= 15     ~ "close",
    TRUE                 ~ "upcoming"
  )

  data_source <- case_when(
    !is.na(career_total) ~ "career_endpoint",
    !is.na(season_val)   ~ "season_totals",
    TRUE                 ~ "fallback"
  )

  milestone_results[[i]] <- list(
    id         = m$id,
    player     = m$player_id,
    type       = m$type,
    category   = m$category,
    statType   = m$stat_label,
    current    = as.integer(current),
    target     = as.integer(m$target),
    unit       = m$unit,
    remaining  = remaining,
    pace       = pace,
    gamesAway  = if (is.na(games_away)) NULL else as.integer(games_away),
    urgency    = urgency,
    mediaAlert = MEDIA_ALERTS[[m$id]] %||% "",
    gp_season  = gp,
    data_source = data_source
  )

  cli_alert_success("  {m$id}: {current}/{m$target} ({urgency}) [{data_source}]")
}

milestone_results <- Filter(Negate(is.null), milestone_results)

# ── ROSTER SUMMARY ────────────────────────────────────────────

roster_out <- lapply(seq_len(nrow(NETS_ROSTER)), function(i) {
  p  <- NETS_ROSTER[i, ]
  gp <- get_season_stat(season_totals, p$nba_id, "GP")
  pts <- get_season_stat(season_totals, p$nba_id, "PTS")
  reb <- get_season_stat(season_totals, p$nba_id, "REB")
  ast <- get_season_stat(season_totals, p$nba_id, "AST")
  list(
    id     = p$player_id,
    name   = p$full_name,
    number = p$number,
    pos    = p$pos,
    nba_id = p$nba_id,
    gp     = if (is.na(gp))  NULL else as.integer(gp),
    season_ppg = if (!is.na(pts) && !is.na(gp) && gp > 0) round(pts/gp, 1) else NULL,
    season_rpg = if (!is.na(reb) && !is.na(gp) && gp > 0) round(reb/gp, 1) else NULL,
    season_apg = if (!is.na(ast) && !is.na(gp) && gp > 0) round(ast/gp, 1) else NULL
  )
})

# ── WRITE JSON ────────────────────────────────────────────────

cli_h2("Writing output JSON")

output <- list(
  meta = list(
    generated_at     = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    season           = CURRENT_SEASON,
    source           = "hoopR / NBA.com Stats API",
    total_milestones = length(milestone_results),
    total_streaks    = 0L
  ),
  roster     = roster_out,
  milestones = milestone_results,
  streaks    = list()
)

out_path <- file.path(OUTPUT_DIR, "live_stats.json")
writeLines(toJSON(output, auto_unbox = TRUE, pretty = TRUE, null = "null"), out_path)

cli_alert_success("Written: {out_path}")
cli_alert_info("Milestones: {length(milestone_results)}")
cli_h1("Done — {format(Sys.time())}")
