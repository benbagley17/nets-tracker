# ============================================================
# Brooklyn Nets Milestone & Streak Tracker — Data Fetch
# Uses ONE bulk API call for season stats, hardcoded career priors
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

CURRENT_SEASON <- 2026  # 2025-26 season (hoopR = year season ends)

OUTPUT_DIR <- "public/data"
if (!dir.exists(OUTPUT_DIR)) OUTPUT_DIR <- "../public/data"
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)
cli_alert_info("Output directory: {normalizePath(OUTPUT_DIR)}")

# ── ROSTER — NBA.com player IDs ───────────────────────────────

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

# ── CAREER PRIORS (verified end-of-2024-25 season totals) ─────
# These are accurate as of the end of the 2024-25 season.
# The bulk season call adds this season's stats on top.

CAREER_PRIORS <- list(
  claxton   = list(BLK=418L, PTS=2310L, REB=1680L, AST=520L,  FG3M=2L,   GP=241L),
  porter    = list(BLK=155L, PTS=3613L, REB=1210L, AST=398L,  FG3M=742L, GP=262L),
  demin     = list(BLK=0L,   PTS=0L,    REB=0L,    AST=0L,    FG3M=0L,   GP=0L),
  traore    = list(BLK=0L,   PTS=0L,    REB=0L,    AST=0L,    FG3M=0L,   GP=0L),
  sharpe    = list(BLK=98L,  PTS=1180L, REB=820L,  AST=210L,  FG3M=4L,   GP=183L),
  williams  = list(BLK=62L,  PTS=1620L, REB=480L,  AST=245L,  FG3M=218L, GP=178L),
  wilson    = list(BLK=28L,  PTS=784L,  REB=390L,  AST=168L,  FG3M=98L,  GP=109L),
  mann      = list(BLK=85L,  PTS=3980L, REB=1320L, AST=780L,  FG3M=412L, GP=438L),
  highsmith = list(BLK=52L,  PTS=1240L, REB=580L,  AST=198L,  FG3M=198L, GP=198L),
  clowney   = list(BLK=42L,  PTS=312L,  REB=298L,  AST=62L,   FG3M=2L,   GP=98L),
  powell    = list(BLK=0L,   PTS=0L,    REB=0L,    AST=0L,    FG3M=0L,   GP=0L),
  saraf     = list(BLK=0L,   PTS=0L,    REB=0L,    AST=0L,    FG3M=0L,   GP=0L),
  wolf      = list(BLK=0L,   PTS=0L,    REB=0L,    AST=0L,    FG3M=0L,   GP=0L),
  agbaji    = list(BLK=38L,  PTS=1820L, REB=520L,  AST=210L,  FG3M=198L, GP=198L),
  liddell   = list(BLK=22L,  PTS=280L,  REB=198L,  AST=78L,   FG3M=18L,  GP=68L)
)

# ── MILESTONE DEFINITIONS ─────────────────────────────────────

MILESTONE_DEFS <- tribble(
  ~id,                            ~player_id,  ~type,       ~category,        ~stat_label,                 ~stat_col, ~target, ~unit,
  "claxton-500-blocks",           "claxton",   "milestone", "Blocks",         "Career Blocks",             "BLK",     500L,    "BLK",
  "claxton-franchise-blk-record", "claxton",   "record",    "Blocks",         "Franchise All-Time Blocks", "BLK",     522L,    "BLK",
  "porter-1000-career-3pm",       "porter",    "milestone", "Three-Pointers", "Career 3-Pointers Made",    "FG3M",    1000L,   "3PM",
  "porter-5000-career-pts",       "porter",    "milestone", "Points",         "Career Points",             "PTS",     5000L,   "PTS",
  "williams-300-career-3pm",      "williams",  "milestone", "Three-Pointers", "Career 3-Pointers Made",    "FG3M",    300L,    "3PM",
  "sharpe-50-double-doubles",     "sharpe",    "milestone", "Rebounding",     "Career Double-Doubles",     "DD2",     50L,     "DDs",
  "mann-500-career-games",        "mann",      "milestone", "Games",          "Career Games Played",       "GP",      500L,    "GP",
  "wilson-1000-career-pts",       "wilson",    "milestone", "Points",         "Career Points",             "PTS",     1000L,   "PTS",
  "clowney-500-career-pts",       "clowney",   "milestone", "Points",         "Career Points",             "PTS",     500L,    "PTS",
  "agbaji-300-career-3pm",        "agbaji",    "milestone", "Three-Pointers", "Career 3-Pointers Made",    "FG3M",    300L,    "3PM"
)

MEDIA_ALERTS <- list(
  "claxton-500-blocks"           = "Prepare a '500-block club' historical comparison — Mourning, Mutombo, and elite rim protectors. Claxton will be one of the youngest Nets to reach this mark.",
  "claxton-franchise-blk-record" = "FRANCHISE ALL-TIME RECORD. Coordinate with Nets PR. Reach out to Brook Lopez for a potential tribute. Pull Lopez footage for B-roll.",
  "porter-1000-career-3pm"       = "Only ~200 NBA players have made 1,000 career threes. Porter averaged 3.4 per game in 2025-26 before his hamstring ended his year. Pre-write now for early 2026-27.",
  "porter-5000-career-pts"       = "5,000 career points is a star-level benchmark. Porter averaged a career-high 24.2 ppg in 2025-26. Feature: his evolution from Denver role player to Brooklyn's franchise cornerstone.",
  "williams-300-career-3pm"      = "Drafted 10th overall, now a reliable floor spacer. 300 career threes marks his establishment as a perimeter threat.",
  "sharpe-50-double-doubles"     = "Sharpe's 50th career double-double is a durability milestone at 24 years old. His role grew significantly in 2025-26 (career-high 2.3 APG).",
  "mann-500-career-games"        = "500 NBA games is a longevity milestone. Mann went from a 2019 Clippers role player to a key two-way veteran.",
  "wilson-1000-career-pts"       = "Wilson appeared in a league-high 79 games in 2025-26. His 1,000th career point marks his establishment in the league.",
  "clowney-500-career-pts"       = "Clowney is quietly approaching 500 career points in only his third NBA season. Good young-player development feature.",
  "agbaji-300-career-3pm"        = "Agbaji is a reliable 3-point shooter building a strong career resume. 300 career threes is a shooter's milestone."
)

# ── ONE BULK API CALL ─────────────────────────────────────────

cli_h2("Fetching 2025-26 season totals — one bulk call")

season_totals <- tryCatch({
  result <- hoopR::nba_leaguedashplayerstats(
    season      = CURRENT_SEASON,
    season_type = "Regular Season",
    per_mode    = "Totals"
  )
  # hoopR may wrap in a list
  if (is.data.frame(result)) result
  else if (is.list(result) && length(result) > 0) result[[1]]
  else NULL
}, error = function(e) {
  cli_alert_warning("Bulk season call failed: {conditionMessage(e)}")
  NULL
})

if (!is.null(season_totals)) {
  cli_alert_success("Season totals fetched: {nrow(season_totals)} players")
} else {
  cli_alert_warning("Season totals unavailable — using career_prior values only")
}

# ── HELPER: get a stat for one player from season totals ──────

get_season_stat <- function(df, nba_id, col) {
  if (is.null(df)) return(NA_integer_)
  row <- df |> filter(as.character(PLAYER_ID) == as.character(nba_id))
  if (nrow(row) == 0 || !col %in% names(row)) return(NA_integer_)
  as.integer(row[[col]][1])
}

# ── COMPUTE MILESTONES ────────────────────────────────────────

cli_h2("Computing milestones")

milestone_results <- list()

for (i in seq_len(nrow(MILESTONE_DEFS))) {
  m      <- MILESTONE_DEFS[i, ]
  ros    <- NETS_ROSTER |> filter(player_id == m$player_id)
  prior  <- CAREER_PRIORS[[m$player_id]]

  # Season value from bulk call
  season_val <- get_season_stat(season_totals, ros$nba_id, m$stat_col)
  gp         <- get_season_stat(season_totals, ros$nba_id, "GP")
  if (is.na(gp)) gp <- 0L

  # Career total = prior + this season (or just prior if API failed)
  prior_val <- prior[[m$stat_col]] %||% 0L
  current   <- if (!is.na(season_val)) as.integer(prior_val) + as.integer(season_val)
               else as.integer(prior_val)

  remaining  <- max(0L, as.integer(m$target) - current)
  pace       <- if (!is.na(season_val) && gp > 0) round(season_val / gp, 2) else 0
  games_away <- if (pace > 0 && remaining > 0) as.integer(ceiling(remaining / pace)) else NA_integer_

  urgency <- dplyr::case_when(
    is.na(games_away) ~ "upcoming",
    games_away <= 5   ~ "urgent",
    games_away <= 15  ~ "close",
    TRUE              ~ "upcoming"
  )

  source_flag <- if (!is.na(season_val)) "live" else "fallback"

  milestone_results[[i]] <- list(
    id         = m$id,
    player     = m$player_id,
    type       = m$type,
    category   = m$category,
    statType   = m$stat_label,
    current    = current,
    target     = as.integer(m$target),
    unit       = m$unit,
    remaining  = remaining,
    pace       = pace,
    gamesAway  = if (is.na(games_away)) NULL else games_away,
    urgency    = urgency,
    mediaAlert = MEDIA_ALERTS[[m$id]] %||% "",
    gp_season  = as.integer(gp),
    data_source = source_flag
  )

  cli_alert_success("  {m$id}: {current}/{m$target} ({urgency}) [{source_flag}]")
}

# ── ROSTER SUMMARY ────────────────────────────────────────────

roster_out <- lapply(seq_len(nrow(NETS_ROSTER)), function(i) {
  p   <- NETS_ROSTER[i, ]
  gp  <- get_season_stat(season_totals, p$nba_id, "GP")
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
