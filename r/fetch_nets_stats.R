# ============================================================
# Brooklyn Nets Milestone & Streak Tracker
# Data Fetch Script — powered by hoopR
#
# SETUP:
#   install.packages("pak")
#   pak::pak("sportsdataverse/hoopR")
#   install.packages(c("dplyr", "jsonlite", "purrr", "lubridate", "cli"))
#
# RUN:
#   Rscript fetch_nets_stats.R
#
# OUTPUT:
#   ../public/data/live_stats.json   — consumed by the dashboard
#
# SCHEDULE (Mac/Linux cron — runs 2h after typical game end):
#   0 2 * * * cd /path/to/nets-tracker/r && Rscript fetch_nets_stats.R >> logs/fetch.log 2>&1
# ============================================================

suppressPackageStartupMessages({
  library(hoopR)
  library(dplyr)
  library(jsonlite)
  library(purrr)
  library(lubridate)
  library(cli)
})

cli_h1("Nets Milestone Tracker — Data Fetch")
cli_alert_info("Run time: {Sys.time()}")

# ── CONFIG ────────────────────────────────────────────────────

CURRENT_SEASON <- hoopR::most_recent_nba_season()
NETS_ESPN_ID   <- "17"   # ESPN team ID for Brooklyn Nets

# Output path resolution — works in GitHub Actions, RStudio, and plain Rscript
# GitHub Actions runs from repo root; Rscript r/fetch_nets_stats.R also runs from root
OUTPUT_DIR <- "public/data"
if (!dir.exists(OUTPUT_DIR)) {
  # Running from inside the r/ subdirectory (e.g. RStudio with r/ as working dir)
  OUTPUT_DIR <- "../public/data"
}
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)
cli_alert_info("Output directory: {normalizePath(OUTPUT_DIR)}")

# ── CURRENT NETS ROSTER (2025-26) ─────────────────────────────
# ESPN athlete IDs — used to match hoopR player data
# Source: espn.com/nba/team/roster/_/name/bkn

NETS_ROSTER <- tibble::tibble(
  player_id  = "claxton",
  full_name  = "Nic Claxton",
  number     = "33",
  pos        = "C",
  espn_id    = "4277956"
) |> bind_rows(tibble::tribble(
  ~player_id,    ~full_name,              ~number, ~pos,  ~espn_id,
  "porter",      "Michael Porter Jr.",    "1",     "SF",  "4278104",
  "demin",       "Egor Dëmin",            "8",     "PG",  "4683754",
  "traore",      "Nolan Traoré",          "19",    "PG",  "4683761",
  "sharpe",      "Day'Ron Sharpe",        "20",    "C",   "4432815",
  "williams",    "Ziaire Williams",       "1",     "SF",  "4431985",
  "wilson",      "Jalen Wilson",          "22",    "SF",  "4592905",
  "mann",        "Terance Mann",          "14",    "SG",  "4066420",
  "highsmith",   "Haywood Highsmith",     "24",    "SF",  "3134870",
  "clowney",     "Noah Clowney",          "21",    "PF",  "4683737",
  "powell",      "Drake Powell",          "10",    "SF",  "4683771",
  "saraf",       "Ben Saraf",             "26",    "PG",  "4683778",
  "wolf",        "Danny Wolf",            "27",    "C",   "4683780",
  "agbaji",      "Ochai Agbaji",          "30",    "SG",  "4066611",
  "liddell",     "E.J. Liddell",          "4",     "PF",  "4432168"
))

# ── MILESTONE DEFINITIONS ─────────────────────────────────────
# Each milestone references a player_id and defines:
#   stat_type     : which stat to track
#   career_prior  : career total BEFORE current season (manually verified)
#   target        : the round-number milestone
#   unit          : display unit string

MILESTONE_DEFS <- tibble::tribble(
  ~id,                              ~player_id,   ~type,       ~category,       ~stat_label,                   ~stat_col,           ~career_prior, ~target, ~unit,
  "claxton-500-blocks",             "claxton",    "milestone", "Blocks",        "Career Blocks",               "blocks",            418L,          500L,    "BLK",
  "claxton-franchise-blk-record",   "claxton",    "record",    "Blocks",        "Franchise All-Time Blocks",   "blocks",            418L,          522L,    "BLK",
  "claxton-1000-pts-season",        "claxton",    "milestone", "Points",        "1,000 Points This Season",    "points_season",     0L,            1000L,   "PTS",
  "porter-1000-career-3pm",         "porter",     "milestone", "Three-Pointers","Career 3-Pointers Made",      "three_point_field_goals_made", 742L, 1000L, "3PM",
  "porter-5000-career-pts",         "porter",     "milestone", "Points",        "Career Points",               "points",            3613L,         5000L,   "PTS",
  "demin-rookie-ast-record",        "demin",      "record",    "Assists",       "Nets Rookie Season Assists",  "assists_season",    0L,            350L,    "AST",
  "williams-300-career-3pm",        "williams",   "milestone", "Three-Pointers","Career 3-Pointers Made",      "three_point_field_goals_made", 218L, 300L, "3PM",
  "sharpe-50-double-doubles",       "sharpe",     "milestone", "Rebounding",    "Career Double-Doubles",       "double_doubles",    32L,           50L,     "DDs",
  "mann-500-career-games",          "mann",       "milestone", "Games",         "Career Games Played",         "games_played",      438L,          500L,    "GP",
  "wilson-1000-career-pts",         "wilson",     "milestone", "Points",        "Career Points",               "points",            784L,          1000L,   "PTS"
)

# Streak definitions — these require game log analysis
STREAK_DEFS <- tibble::tribble(
  ~id,                           ~player_id,  ~type,    ~category,  ~streak_label,                    ~threshold, ~stat_col,  ~franchise_record, ~franchise_holder,
  "claxton-10reb-streak",        "claxton",   "streak", "Rebounding","Consec. Games 10+ Rebounds",    10,         "rebounds", 9,                 "Brook Lopez (2015)",
  "porter-20pt-streak",          "porter",    "streak", "Scoring",   "Consec. Games 20+ Points",     20,         "points",   11,                 "Vince Carter (2008)",
  "demin-5ast-streak",           "demin",     "streak", "Assists",   "Consec. Games 5+ Assists",     5,          "assists",  NA,                 NA
)

# ── MEDIA ALERT TEXT ──────────────────────────────────────────
# Stored separately so data.js in the frontend can stay authoritative
# for display copy while this script drives the numbers.

MEDIA_ALERTS <- list(
  "claxton-500-blocks"           = "Prepare a 'the 500-block club' historical comparison feature — Mourning, Mutombo, and elite rim protectors. Claxton is one of the youngest to reach this as a Net.",
  "claxton-franchise-blk-record" = "FRANCHISE ALL-TIME RECORD. Coordinate with Nets PR. Reach out to Brook Lopez's representation for a potential tribute. Pull Lopez footage for B-roll.",
  "claxton-1000-pts-season"      = "Good peg for a Claxton evolution feature — career-high 3.7 APG and two triple-doubles this season. His passing growth is the bigger story.",
  "porter-1000-career-3pm"       = "Only ~200 NBA players have ever made 1,000 career threes. Porter averaged 3.4 per game this season before his hamstring ended his year. Pre-write the feature for 2026-27.",
  "porter-5000-career-pts"       = "5,000 career points is a benchmark of star-level output. MPJ averaged a career-high 24.2 ppg this season. Feature angle: his evolution from Denver role player to Brooklyn's franchise cornerstone.",
  "demin-rookie-ast-record"      = "FRANCHISE ROOKIE RECORD. Dëmin is the 8th overall pick rewriting Nets rookie history. Compare his court vision to Jason Kidd's early Nets years.",
  "williams-300-career-3pm"      = "Quiet redemption narrative — drafted 10th overall by Memphis, now a reliable wing shooter for the Nets. 300 career threes marks his establishment as a floor spacer.",
  "sharpe-50-double-doubles"     = "Sharpe's 50th career double-double is a durability milestone for the 24-year-old. His role grew significantly this season (career-high 2.3 APG).",
  "mann-500-career-games"        = "500 NBA games is a longevity milestone. Mann went from a 2019 Clippers role player to a key two-way veteran. Great human interest retrospective.",
  "wilson-1000-career-pts"       = "Wilson appeared in a league-high 79 games. His 1,000th career point marks establishment in the league — good blue-collar Nets feature angle.",
  "claxton-10reb-streak"         = "FRANCHISE RECORD WATCH: Brook Lopez's 9-game streak of 10+ rebound games (2015) is within reach. Alert beat writers immediately if streak hits 7+.",
  "porter-20pt-streak"           = "FRANCHISE RECORD WATCH: Vince Carter's 11-game 20+ point streak (2008). Porter averaged 24.2 ppg this season. Track carefully when healthy next year.",
  "demin-5ast-streak"            = "Dëmin's playmaking consistency is a key development metric. Track his 5+ assist streaks as a barometer of his NBA growth curve."
)

# ── FETCH FUNCTIONS ───────────────────────────────────────────

fetch_season_player_stats <- function(season) {
  cli_alert("Fetching {season} season player stats...")
  tryCatch({
    # nba_player_stats returns all players for the season
    stats <- hoopR::nba_leaguedashplayerstats(
      season = hoopR::most_recent_nba_season(),
      season_type = "Regular Season",
      per_mode = "Totals"
    )
    stats$PlayerStats
  }, error = function(e) {
    cli_alert_danger("Season stats fetch failed: {e$message}")
    NULL
  })
}

fetch_player_career_stats <- function(player_id_espn) {
  cli_alert("  Fetching career stats for ESPN ID {player_id_espn}...")
  tryCatch({
    hoopR::nba_playercareerstats(
      player_id = player_id_espn,
      per_mode = "Totals"
    )
  }, error = function(e) {
    cli_alert_warning("  Career stats failed for {player_id_espn}: {e$message}")
    NULL
  })
}

fetch_player_game_log <- function(player_id_espn, season) {
  cli_alert("  Fetching game log for ESPN ID {player_id_espn}...")
  tryCatch({
    hoopR::nba_playergamelog(
      player_id   = player_id_espn,
      season      = hoopR::most_recent_nba_season(),
      season_type = "Regular Season"
    )$PlayerGameLog
  }, error = function(e) {
    cli_alert_warning("  Game log failed for {player_id_espn}: {e$message}")
    NULL
  })
}

# ── STAT EXTRACTION ───────────────────────────────────────────

extract_career_total <- function(career_data, stat_col) {
  if (is.null(career_data)) return(NA_integer_)
  totals <- career_data$CareerTotalsRegularSeason
  if (is.null(totals) || nrow(totals) == 0) return(NA_integer_)
  col <- toupper(stat_col)
  if (!col %in% names(totals)) {
    # Try alternate column name patterns
    col_map <- c(
      "points"                         = "PTS",
      "blocks"                         = "BLK",
      "assists"                         = "AST",
      "rebounds"                        = "REB",
      "three_point_field_goals_made"   = "FG3M",
      "games_played"                   = "GP",
      "steals"                         = "STL"
    )
    col <- col_map[[stat_col]] %||% toupper(stat_col)
  }
  if (!col %in% names(totals)) {
    cli_alert_warning("    Column {col} not found in career totals")
    return(NA_integer_)
  }
  as.integer(totals[[col]][1])
}

extract_season_total <- function(season_stats, espn_id, stat_col) {
  if (is.null(season_stats)) return(NA_integer_)
  row <- season_stats |> filter(PLAYER_ID == espn_id)
  if (nrow(row) == 0) return(NA_integer_)
  col_map <- c(
    "points"                       = "PTS",
    "blocks"                       = "BLK",
    "assists"                      = "AST",
    "rebounds"                     = "REB",
    "three_point_field_goals_made" = "FG3M",
    "games_played"                 = "GP",
    "steals"                       = "STL",
    "points_season"                = "PTS",  # same as points but means season-only
    "assists_season"               = "AST"
  )
  col <- col_map[[stat_col]] %||% toupper(stat_col)
  if (!col %in% names(row)) return(NA_integer_)
  as.integer(row[[col]][1])
}

# ── STREAK CALCULATION ────────────────────────────────────────

calc_current_streak <- function(game_log, stat_col, threshold) {
  if (is.null(game_log) || nrow(game_log) == 0) return(0L)

  col_map <- c(
    "points"   = "PTS",
    "rebounds" = "REB",
    "assists"  = "AST",
    "blocks"   = "BLK",
    "steals"   = "STL"
  )
  col <- col_map[[stat_col]] %||% toupper(stat_col)
  if (!col %in% names(game_log)) return(0L)

  # Game log is newest-first from NBA API
  vals <- as.numeric(game_log[[col]])

  streak <- 0L
  for (v in vals) {
    if (is.na(v)) break
    if (v >= threshold) streak <- streak + 1L
    else break
  }
  streak
}

calc_season_best_streak <- function(game_log, stat_col, threshold) {
  if (is.null(game_log) || nrow(game_log) == 0) return(0L)
  col_map <- c(
    "points"   = "PTS",
    "rebounds" = "REB",
    "assists"  = "AST",
    "blocks"   = "BLK"
  )
  col <- col_map[[stat_col]] %||% toupper(stat_col)
  if (!col %in% names(game_log)) return(0L)

  vals <- rev(as.numeric(game_log[[col]]))  # chronological order
  best <- 0L
  current <- 0L
  for (v in vals) {
    if (!is.na(v) && v >= threshold) {
      current <- current + 1L
      if (current > best) best <- current
    } else {
      current <- 0L
    }
  }
  best
}

calc_double_doubles <- function(game_log) {
  if (is.null(game_log) || nrow(game_log) == 0) return(0L)
  needed <- c("PTS", "REB", "AST", "BLK", "STL")
  available <- intersect(needed, names(game_log))
  if (length(available) < 2) return(0L)
  dd <- game_log |>
    mutate(across(all_of(available), as.numeric)) |>
    rowwise() |>
    mutate(dd = sum(c_across(all_of(available)) >= 10, na.rm = TRUE) >= 2) |>
    ungroup()
  sum(dd$dd, na.rm = TRUE)
}

# ── MAIN FETCH LOOP ───────────────────────────────────────────

cli_h2("Fetching season-wide stats")
season_stats <- fetch_season_player_stats(CURRENT_SEASON)

cli_h2("Fetching per-player career stats & game logs")

player_data <- list()

for (i in seq_len(nrow(NETS_ROSTER))) {
  p <- NETS_ROSTER[i, ]
  cli_h3("{p$full_name} ({p$espn_id})")

  career   <- fetch_player_career_stats(p$espn_id)
  game_log <- fetch_player_game_log(p$espn_id, CURRENT_SEASON)

  # Season games played (for pace calculation)
  gp_season <- extract_season_total(season_stats, p$espn_id, "games_played")
  gp_season <- if (is.na(gp_season)) 0L else gp_season

  player_data[[p$player_id]] <- list(
    roster    = as.list(p),
    career    = career,
    game_log  = game_log,
    gp_season = gp_season,
    season_stats_row = if (!is.null(season_stats)) {
      season_stats |> filter(PLAYER_ID == p$espn_id) |> as.list()
    } else NULL
  )

  Sys.sleep(0.4)  # be polite to the API
}

# ── COMPUTE MILESTONES ────────────────────────────────────────

cli_h2("Computing milestone proximity")

compute_milestones <- function() {
  results <- vector("list", nrow(MILESTONE_DEFS))

  for (i in seq_len(nrow(MILESTONE_DEFS))) {
    m   <- MILESTONE_DEFS[i, ]
    pd  <- player_data[[m$player_id]]
    ros <- NETS_ROSTER |> filter(player_id == m$player_id)

    if (is.null(pd)) next

    # Determine current value
    stat <- m$stat_col
    current <- NA_integer_

    if (stat == "double_doubles") {
      # Special: sum career prior + this season's DDs from game log
      season_dd <- calc_double_doubles(pd$game_log)
      current   <- m$career_prior + season_dd
    } else if (grepl("_season$", stat)) {
      # Season-only stat
      current <- extract_season_total(season_stats, ros$espn_id, stat)
      if (is.na(current)) current <- 0L
    } else {
      # Career total = prior + this season from career endpoint
      career_total <- extract_career_total(pd$career, stat)
      if (!is.na(career_total)) {
        current <- career_total
      } else {
        # Fallback: prior + season
        season_val <- extract_season_total(season_stats, ros$espn_id, stat)
        current <- m$career_prior + if (is.na(season_val)) 0L else season_val
      }
    }

    if (is.na(current)) {
      cli_alert_warning("  Could not compute current value for {m$id}")
      current <- m$career_prior  # safe fallback
    }

    remaining <- as.integer(m$target) - as.integer(current)
    remaining <- max(0L, remaining)

    # Per-game pace from this season
    gp  <- pd$gp_season
    season_val <- extract_season_total(season_stats, ros$espn_id, m$stat_col)
    pace <- if (!is.na(season_val) && gp > 0) round(season_val / gp, 3) else 0

    games_away <- if (pace > 0 && remaining > 0) ceiling(remaining / pace) else NA_integer_

    # Urgency
    urgency <- dplyr::case_when(
      is.na(games_away) | games_away == 0           ~ "upcoming",
      games_away <= 5                                ~ "urgent",
      games_away <= 15                               ~ "close",
      TRUE                                           ~ "upcoming"
    )

    results[[i]] <- list(
      id          = m$id,
      player      = m$player_id,
      type        = m$type,
      category    = m$category,
      statType    = m$stat_label,
      current     = as.integer(current),
      target      = as.integer(m$target),
      unit        = m$unit,
      remaining   = remaining,
      pace        = pace,
      gamesAway   = if (is.na(games_away)) NULL else as.integer(games_away),
      urgency     = urgency,
      mediaAlert  = MEDIA_ALERTS[[m$id]] %||% "",
      gp_season   = gp
    )

    cli_alert_success("  {m$id}: {current}/{m$target} ({urgency}, {games_away %||% '?'} games away)")
  }

  Filter(Negate(is.null), results)
}

milestone_results <- compute_milestones()

# ── COMPUTE STREAKS ───────────────────────────────────────────

cli_h2("Computing streaks")

compute_streaks <- function() {
  results <- vector("list", nrow(STREAK_DEFS))

  for (i in seq_len(nrow(STREAK_DEFS))) {
    s   <- STREAK_DEFS[i, ]
    pd  <- player_data[[s$player_id]]

    if (is.null(pd) || is.null(pd$game_log)) {
      cli_alert_warning("  No game log for streak {s$id}")
      next
    }

    current_streak  <- calc_current_streak(pd$game_log, s$stat_col, s$threshold)
    season_best     <- calc_season_best_streak(pd$game_log, s$stat_col, s$threshold)
    franchise_rec   <- if (!is.na(s$franchise_record)) as.integer(s$franchise_record) else NULL
    games_to_record <- if (!is.null(franchise_rec) && current_streak > 0) {
      max(0L, franchise_rec - current_streak + 1L)
    } else NULL

    urgency <- dplyr::case_when(
      current_streak == 0                                           ~ "upcoming",
      !is.null(games_to_record) && games_to_record <= 2            ~ "urgent",
      !is.null(games_to_record) && games_to_record <= 5            ~ "close",
      current_streak >= 3                                           ~ "close",
      TRUE                                                          ~ "upcoming"
    )

    results[[i]] <- list(
      id               = s$id,
      player           = s$player_id,
      type             = "streak",
      category         = s$category,
      statType         = s$streak_label,
      current          = as.integer(current_streak),
      target           = if (!is.null(franchise_rec)) franchise_rec else as.integer(current_streak + 5L),
      unit             = "games",
      remaining        = if (!is.null(games_to_record)) as.integer(games_to_record) else NULL,
      gamesAway        = games_to_record,
      urgency          = urgency,
      seasonBest       = as.integer(season_best),
      franchiseRecord  = franchise_rec,
      franchiseHolder  = if (!is.na(s$franchise_holder)) s$franchise_holder else NULL,
      threshold        = as.integer(s$threshold),
      mediaAlert       = MEDIA_ALERTS[[s$id]] %||% "",
      isActive         = current_streak > 0
    )

    cli_alert_success("  {s$id}: current streak = {current_streak}, season best = {season_best}")
  }

  Filter(Negate(is.null), results)
}

streak_results <- compute_streaks()

# ── BUILD ROSTER SUMMARY ──────────────────────────────────────

roster_summary <- lapply(seq_len(nrow(NETS_ROSTER)), function(i) {
  p  <- NETS_ROSTER[i, ]
  pd <- player_data[[p$player_id]]
  sr <- if (!is.null(season_stats)) season_stats |> filter(PLAYER_ID == p$espn_id) else NULL

  list(
    id       = p$player_id,
    name     = p$full_name,
    number   = p$number,
    pos      = p$pos,
    espn_id  = p$espn_id,
    gp       = pd$gp_season,
    season_ppg = if (!is.null(sr) && nrow(sr) > 0 && !is.na(sr$PTS) && pd$gp_season > 0)
                   round(as.numeric(sr$PTS[1]) / pd$gp_season, 1) else NULL,
    season_rpg = if (!is.null(sr) && nrow(sr) > 0 && !is.na(sr$REB) && pd$gp_season > 0)
                   round(as.numeric(sr$REB[1]) / pd$gp_season, 1) else NULL,
    season_apg = if (!is.null(sr) && nrow(sr) > 0 && !is.na(sr$AST) && pd$gp_season > 0)
                   round(as.numeric(sr$AST[1]) / pd$gp_season, 1) else NULL
  )
})

# ── WRITE OUTPUT ──────────────────────────────────────────────

cli_h2("Writing output JSON")

output <- list(
  meta = list(
    generated_at   = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    season         = CURRENT_SEASON,
    source         = "hoopR / ESPN NBA API",
    nets_espn_id   = NETS_ESPN_ID,
    total_milestones = length(milestone_results),
    total_streaks    = length(streak_results)
  ),
  roster     = roster_summary,
  milestones = milestone_results,
  streaks    = streak_results
)

out_path <- file.path(OUTPUT_DIR, "live_stats.json")
write(toJSON(output, auto_unbox = TRUE, pretty = TRUE, null = "null"), out_path)

cli_alert_success("Written: {out_path}")
cli_alert_info("  Milestones: {length(milestone_results)}")
cli_alert_info("  Streaks:    {length(streak_results)}")
cli_h1("Done — {format(Sys.time())}")
