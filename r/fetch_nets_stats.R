# ============================================================
# Brooklyn Nets Milestone & Streak Tracker — Data Fetch
# Career totals verified from Basketball Reference, May 11 2026
# ============================================================

suppressPackageStartupMessages({
  library(jsonlite)
  library(cli)
  library(tibble)
  library(dplyr)
  library(rvest)
})

`%||%` <- function(a, b) if (!is.null(a)) a else b

# ── CONFIGURATION ─────────────────────────────────────────────
# Set FALSE on opening night of 2026-27 season to activate live scraping
OFFSEASON_MODE <- TRUE

# BBRef player path suffixes for live scraping
BBREF_IDS <- c(
  claxton  = "c/claxtni01",
  clowney  = "c/clownno01",
  mann     = "m/mannte01",
  powell   = "p/poweldr01",
  sharpe   = "s/sharpda01",
  wolf     = "w/wolfda01",
  williams = "w/willizi02",
  traore   = "t/traorno01",
  wilson   = "w/wilsoja03",
  porter   = "p/portemi01",
  demin    = "d/demineg01",
  saraf    = "s/sarafbe01",
  liddell  = "l/liddeej01",
  etienne  = "e/etienty01",
  agbaji   = "a/agbajoc01",
  johnson  = "j/johnsch06",
  minott   = "m/minotjo01",
  smith    = "s/smithma02"
)

cli_h1("Nets Milestone Tracker — Data Fetch")
cli_alert_info("Run time: {Sys.time()}")
cli_alert_info("Mode: {ifelse(OFFSEASON_MODE, 'OFFSEASON (hardcoded 2025-26 stats)', 'LIVE (BBRef scrape)')}")

OUTPUT_DIR <- "public/data"
if (!dir.exists(OUTPUT_DIR)) OUTPUT_DIR <- "../public/data"
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)
cli_alert_info("Output: {normalizePath(OUTPUT_DIR)}")

# ── VERIFIED CAREER TOTALS (Basketball Reference, May 11 2026) ─
CAREER_TOTALS <- list(

  claxton = list(
    GP=380L, PTS=4024L, TRB=2875L, AST=788L, STL=266L, BLK=611L, FG3M=11L,
    GP_season=69L, season_PTS=810L, season_TRB=478L, season_AST=253L,
    season_BLK=77L, season_FG3M=3L,
    PPG=11.7, RPG=6.9, APG=3.7, BPG=1.1
  ),

  clowney = list(
    GP=135L, PTS=1362L, TRB=535L, AST=166L, STL=82L, BLK=82L, FG3M=228L,
    GP_season=66L, season_PTS=809L, season_TRB=273L, season_AST=108L,
    season_BLK=45L, season_FG3M=129L,
    PPG=12.3, RPG=4.1, APG=1.6, BPG=0.7
  ),

  mann = list(
    GP=475L, PTS=3786L, TRB=1651L, AST=980L, STL=268L, BLK=106L, FG3M=385L,
    GP_season=63L, season_PTS=455L, season_TRB=200L, season_AST=190L,
    season_BLK=15L, season_FG3M=56L,
    PPG=7.2, RPG=3.2, APG=3.0, BPG=0.2
  ),

  powell = list(
    GP=63L, PTS=408L, TRB=111L, AST=91L, STL=36L, BLK=14L, FG3M=51L,
    GP_season=63L, season_PTS=408L, season_TRB=111L, season_AST=91L,
    season_BLK=14L, season_FG3M=51L,
    PPG=6.5, RPG=1.8, APG=1.4, BPG=0.2
  ),

  sharpe = list(
    GP=253L, PTS=1777L, TRB=1492L, AST=375L, STL=157L, BLK=159L, FG3M=32L,
    GP_season=62L, season_PTS=540L, season_TRB=413L, season_AST=145L,
    season_BLK=26L, season_FG3M=9L,
    PPG=8.7, RPG=6.7, APG=2.3, BPG=0.4
  ),

  wolf = list(
    GP=57L, PTS=508L, TRB=281L, AST=127L, STL=30L, BLK=32L, FG3M=68L,
    GP_season=57L, season_PTS=508L, season_TRB=281L, season_AST=127L,
    season_BLK=32L, season_FG3M=68L,
    PPG=8.9, RPG=4.9, APG=2.2, BPG=0.6
  ),

  williams = list(
    GP=269L, PTS=2336L, TRB=809L, AST=319L, STL=223L, BLK=76L, FG3M=348L,
    GP_season=56L, season_PTS=573L, season_TRB=134L, season_AST=60L,
    season_BLK=21L, season_FG3M=86L,
    PPG=10.2, RPG=2.4, APG=1.1, BPG=0.4
  ),

  traore = list(
    GP=56L, PTS=499L, TRB=99L, AST=213L, STL=45L, BLK=23L, FG3M=61L,
    GP_season=56L, season_PTS=499L, season_TRB=99L, season_AST=213L,
    season_BLK=23L, season_FG3M=61L,
    PPG=8.9, RPG=1.8, APG=3.8, BPG=0.4
  ),

  wilson = list(
    GP=176L, PTS=1306L, TRB=515L, AST=240L, STL=73L, BLK=11L, FG3M=200L,
    GP_season=54L, season_PTS=343L, season_TRB=114L, season_AST=50L,
    season_BLK=2L, season_FG3M=54L,
    PPG=6.4, RPG=2.1, APG=0.9, BPG=0.0
  ),

  porter = list(
    GP=397L, PTS=6856L, TRB=2576L, AST=643L, STL=261L, BLK=214L, FG3M=1019L,
    GP_season=52L, season_PTS=1259L, season_TRB=367L, season_AST=158L,
    season_BLK=13L, season_FG3M=176L,
    PPG=24.2, RPG=7.1, APG=3.0, BPG=0.3,
    note="Out for season (hamstring)"
  ),

  demin = list(
    GP=52L, PTS=536L, TRB=165L, AST=173L, STL=42L, BLK=17L, FG3M=124L,
    GP_season=52L, season_PTS=536L, season_TRB=165L, season_AST=173L,
    season_BLK=17L, season_FG3M=124L,
    PPG=10.3, RPG=3.2, APG=3.3, BPG=0.3
  ),

  saraf = list(
    GP=44L, PTS=332L, TRB=92L, AST=145L, STL=38L, BLK=8L, FG3M=19L,
    GP_season=44L, season_PTS=332L, season_TRB=92L, season_AST=145L,
    season_BLK=8L, season_FG3M=19L,
    PPG=7.5, RPG=2.1, APG=3.3, BPG=0.2
  ),

  liddell = list(
    GP=46L, PTS=172L, TRB=83L, AST=28L, STL=9L, BLK=13L, FG3M=21L,
    GP_season=26L, season_PTS=147L, season_TRB=69L, season_AST=24L,
    season_BLK=10L, season_FG3M=18L,
    PPG=5.7, RPG=2.7, APG=0.9, BPG=0.4
  ),

  etienne = list(
    GP=31L, PTS=244L, TRB=36L, AST=52L, STL=14L, BLK=1L, FG3M=56L,
    GP_season=24L, season_PTS=189L, season_TRB=27L, season_AST=40L,
    season_BLK=0L, season_FG3M=43L,
    PPG=7.9, RPG=1.1, APG=1.7, BPG=0.0
  ),

  agbaji = list(
    GP=263L, PTS=1903L, TRB=720L, AST=295L, STL=145L, BLK=106L, FG3M=278L,
    GP_season=20L, season_PTS=133L, season_TRB=46L, season_AST=17L,
    season_BLK=6L, season_FG3M=22L,
    PPG=5.1, RPG=2.3, APG=0.8, BPG=0.2,
    note="Joined BRK late (20 GP with BRK, 42 with TOR)"
  ),

  johnson = list(
    GP=17L, PTS=139L, TRB=79L, AST=36L, STL=15L, BLK=9L, FG3M=9L,
    GP_season=17L, season_PTS=139L, season_TRB=79L, season_AST=36L,
    season_BLK=9L, season_FG3M=9L,
    PPG=8.2, RPG=4.6, APG=2.1, BPG=0.5
  ),

  minott = list(
    GP=142L, PTS=579L, TRB=247L, AST=77L, STL=68L, BLK=47L, FG3M=84L,
    GP_season=16L, season_PTS=172L, season_TRB=40L, season_AST=13L,
    season_BLK=12L, season_FG3M=30L,
    PPG=10.8, RPG=2.5, APG=0.8, BPG=0.8,
    note="16 GP with BRK in 2025-26 (33 with BOS earlier)"
  ),

  smith = list(
    GP=15L, PTS=124L, TRB=51L, AST=49L, STL=12L, BLK=4L, FG3M=20L,
    GP_season=15L, season_PTS=124L, season_TRB=51L, season_AST=49L,
    season_BLK=4L, season_FG3M=20L,
    PPG=8.3, RPG=3.4, APG=3.3, BPG=0.3
  )
)

# ── ROSTER ────────────────────────────────────────────────────
NETS_ROSTER <- tribble(
  ~player_id,  ~full_name,            ~number, ~pos,
  "claxton",   "Nic Claxton",         "33",    "C",
  "clowney",   "Noah Clowney",        "21",    "PF",
  "mann",      "Terance Mann",        "14",    "SG",
  "powell",    "Drake Powell",        "4",     "SG",
  "sharpe",    "Day'Ron Sharpe",      "20",    "C",
  "wolf",      "Danny Wolf",          "2",     "PF",
  "williams",  "Ziaire Williams",     "1",     "SF",
  "traore",    "Nolan Traore",        "88",    "PG",
  "wilson",    "Jalen Wilson",        "22",    "PF",
  "porter",    "Michael Porter Jr.",  "17",    "SF",
  "demin",     "Egor Demin",          "8",     "PG",
  "saraf",     "Ben Saraf",           "77",    "SG",
  "liddell",   "E.J. Liddell",        "9",     "PF",
  "etienne",   "Tyson Etienne",       "10",    "PG",
  "agbaji",    "Ochai Agbaji",        "30",    "SG",
  "johnson",   "Chaney Johnson",      "31",    "SF",
  "minott",    "Josh Minott",         "00",    "SF",
  "smith",     "Malachi Smith",       "18",    "SG"
)

# ── MILESTONE DEFINITIONS ─────────────────────────────────────
# next_season_pace = projected full-season total for games-away calc
MILESTONE_DEFS <- tribble(
  ~id,                    ~player_id,  ~category,        ~stat_label,               ~stat_col, ~target, ~next_season_pace,
  "claxton-700-blk",      "claxton",   "Blocks",         "Career Blocks",            "BLK",     700L,    75.0,
  "claxton-5000-pts",     "claxton",   "Points",         "Career Points",            "PTS",     5000L,   870.0,
  "claxton-3000-reb",     "claxton",   "Rebounding",     "Career Rebounds",          "TRB",     3000L,   478.0,
  "porter-7000-pts",      "porter",    "Points",         "Career Points",            "PTS",     7000L,   1500.0,
  "porter-1000-3pm",      "porter",    "Three-Pointers", "Career 3-Pointers Made",   "FG3M",    1000L,   200.0,
  "mann-500-gp",          "mann",      "Games",          "Career Games Played",      "GP",      500L,    70.0,
  "mann-4000-pts",        "mann",      "Points",         "Career Points",            "PTS",     4000L,   455.0,
  "mann-1000-ast",        "mann",      "Assists",        "Career Assists",           "AST",     1000L,   190.0,
  "clowney-1500-pts",     "clowney",   "Points",         "Career Points",            "PTS",     1500L,   800.0,
  "clowney-300-3pm",      "clowney",   "Three-Pointers", "Career 3-Pointers Made",   "FG3M",    300L,    130.0,
  "williams-400-3pm",     "williams",  "Three-Pointers", "Career 3-Pointers Made",   "FG3M",    400L,    100.0,
  "williams-2500-pts",    "williams",  "Points",         "Career Points",            "PTS",     2500L,   600.0,
  "wilson-1500-pts",      "wilson",    "Points",         "Career Points",            "PTS",     1500L,   400.0,
  "agbaji-2000-pts",      "agbaji",    "Points",         "Career Points",            "PTS",     2000L,   500.0,
  "agbaji-300-3pm",       "agbaji",    "Three-Pointers", "Career 3-Pointers Made",   "FG3M",    300L,    80.0,
  "sharpe-2000-pts",      "sharpe",    "Points",         "Career Points",            "PTS",     2000L,   540.0,
  "sharpe-200-blk",       "sharpe",    "Blocks",         "Career Blocks",            "BLK",     200L,    30.0
)

# ── MEDIA ALERT COPY ──────────────────────────────────────────
MEDIA_ALERTS <- list(
  "claxton-700-blk"    = "Claxton has 611 career blocks — 89 away from 700, a threshold reached by only the most dominant shot-blockers in NBA history. At 1.1 BPG, he hits this roughly midway through 2026-27.",
  "claxton-5000-pts"   = "Claxton finished 2025-26 with 4,024 career points. At his scoring pace he reaches 5,000 in approximately year 9 of his career — meaningful for a player originally regarded as a defensive specialist.",
  "claxton-3000-reb"   = "Claxton has 2,875 career rebounds — 125 away from 3,000. At 6.9 RPG, expect this milestone within the first quarter of 2026-27.",
  "porter-7000-pts"    = "Porter finished 2025-26 with 6,856 career points — 144 away from 7,000. At his 24.2 PPG pace, he reaches this within 6 games of 2026-27 if healthy.",
  "porter-1000-3pm"    = "Porter has 1,019 career 3-pointers — already past 1,000! This milestone was achieved during 2025-26. Only ~200 players in NBA history have reached this mark.",
  "mann-500-gp"        = "Mann finished 2025-26 with 475 career games — 25 away from 500. He'll reach this within the first month of 2026-27.",
  "mann-4000-pts"      = "Mann has 3,786 career points — 214 away from 4,000, arriving roughly mid-2026-27.",
  "mann-1000-ast"      = "Mann has 980 career assists — 20 away from 1,000. He'll reach this within the first few games of 2026-27.",
  "clowney-1500-pts"   = "Clowney has 1,362 career points at age 21 — 138 away from 1,500. With career highs across the board in 2025-26, this arrives early in 2026-27.",
  "clowney-300-3pm"    = "Clowney made 129 threes in 2025-26 alone and now has 228 career makes — 72 away from 300. His floor-spacing development is the story.",
  "williams-400-3pm"   = "Williams has 348 career threes — 52 away from 400, arriving roughly game 42 of 2026-27.",
  "williams-2500-pts"  = "Williams has 2,336 career points — 164 away from 2,500.",
  "wilson-1500-pts"    = "Wilson has 1,306 career points — 194 away from 1,500. At his pace this arrives mid-2026-27.",
  "agbaji-2000-pts"    = "Agbaji has 1,903 career points — 97 away from 2,000. He joined BRK late this season; feature on his fresh start in Brooklyn.",
  "agbaji-300-3pm"     = "Agbaji has 278 career threes — 22 away from 300, arriving within his first few weeks as a full-time Net in 2026-27.",
  "sharpe-2000-pts"    = "Sharpe has 1,777 career points — 223 away from 2,000. At 8.7 PPG this arrives around game 26 of 2026-27.",
  "sharpe-200-blk"     = "Sharpe has 159 career blocks — 41 away from 200. At just 24 years old reaching 200 career blocks marks his emergence as a two-way center."
)

# ── LIVE BBRef SCRAPER ────────────────────────────────────────
# Only runs when OFFSEASON_MODE = FALSE
scrape_bbref_player <- function(pid, bbref_path) {
  url <- paste0("https://www.basketball-reference.com/players/", bbref_path, ".html")
  cli_alert("  Scraping {pid}...")
  tryCatch({
    page <- rvest::read_html(url)
    extract_row <- function(row) {
      cells <- rvest::html_elements(row, "td[data-stat]")
      vals  <- suppressWarnings(as.integer(gsub(",", "", rvest::html_text(cells))))
      setNames(vals, rvest::html_attr(cells, "data-stat"))
    }
    tfoot_row <- rvest::html_element(page, "#totals_stats tfoot tr:first-child")
    if (is.na(tfoot_row)) { cli_alert_warning("  No tfoot for {pid}"); return(NULL) }
    career <- extract_row(tfoot_row)
    result <- list(
      GP   = career[["g"]]   %||% NA_integer_,
      PTS  = career[["pts"]] %||% NA_integer_,
      TRB  = career[["trb"]] %||% NA_integer_,
      AST  = career[["ast"]] %||% NA_integer_,
      STL  = career[["stl"]] %||% NA_integer_,
      BLK  = career[["blk"]] %||% NA_integer_,
      FG3M = career[["fg3"]] %||% NA_integer_
    )
    tbody_rows <- rvest::html_elements(page, "#totals_stats tbody tr:not(.thead)")
    if (length(tbody_rows) > 0) {
      szn  <- extract_row(tbody_rows[[length(tbody_rows)]])
      gp_s <- szn[["g"]] %||% 0L
      result$GP_season   <- gp_s
      result$season_PTS  <- szn[["pts"]] %||% 0L
      result$season_TRB  <- szn[["trb"]] %||% 0L
      result$season_AST  <- szn[["ast"]] %||% 0L
      result$season_BLK  <- szn[["blk"]] %||% 0L
      result$season_FG3M <- szn[["fg3"]] %||% 0L
      if (!is.na(gp_s) && gp_s > 0) {
        result$PPG <- round(result$season_PTS / gp_s, 1)
        result$RPG <- round(result$season_TRB / gp_s, 1)
        result$APG <- round(result$season_AST / gp_s, 1)
        result$BPG <- round(result$season_BLK / gp_s, 1)
      }
    }
    cli_alert_success("  {pid}: GP={result$GP} PTS={result$PTS} BLK={result$BLK} 3PM={result$FG3M}")
    Sys.sleep(3.5)
    result
  }, error = function(e) {
    cli_alert_warning("  {pid} failed: {conditionMessage(e)}")
    NULL
  })
}

# ── FETCH LIVE DATA ───────────────────────────────────────────
if (!OFFSEASON_MODE) {
  cli_h2("LIVE MODE — Scraping Basketball Reference")
  for (pid in names(BBREF_IDS)) {
    fresh <- scrape_bbref_player(pid, BBREF_IDS[[pid]])
    if (!is.null(fresh)) {
      existing <- CAREER_TOTALS[[pid]]
      for (field in names(fresh)) {
        if (!is.null(fresh[[field]]) && !is.na(fresh[[field]])) {
          existing[[field]] <- fresh[[field]]
        }
      }
      CAREER_TOTALS[[pid]] <- existing
    }
  }
  cli_alert_success("Scrape complete")
} else {
  cli_alert_info("Offseason — using hardcoded 2025-26 totals")
}

# ── COMPUTE MILESTONES ────────────────────────────────────────
cli_h2("Computing milestones")

milestone_results <- list()

for (i in seq_len(nrow(MILESTONE_DEFS))) {
  m       <- MILESTONE_DEFS[i, ]
  totals  <- CAREER_TOTALS[[m$player_id]]
  current <- totals[[m$stat_col]]

  if (is.null(current) || is.na(current)) {
    cli_alert_warning("  Missing {m$stat_col} for {m$player_id}, skipping")
    next
  }

  remaining  <- max(0L, as.integer(m$target) - as.integer(current))
  pace       <- m$next_season_pace / 82.0

  # In live mode, recalculate pace from actual season stats
  if (!OFFSEASON_MODE) {
    gp_s <- totals$GP_season %||% 0L
    if (gp_s > 0) {
      season_stat <- switch(m$stat_col,
        PTS  = totals$season_PTS,
        TRB  = totals$season_TRB,
        AST  = totals$season_AST,
        BLK  = totals$season_BLK,
        FG3M = totals$season_FG3M,
        GP   = gp_s,
        NULL
      )
      if (!is.null(season_stat) && !is.na(season_stat) && gp_s > 0) {
        pace <- season_stat / gp_s
      }
    }
  }

  games_away <- if (pace > 0 && remaining > 0) as.integer(ceiling(remaining / pace)) else NA_integer_

  urgency <- if (remaining == 0L) {
    "achieved"
  } else if (!is.na(games_away) && games_away <= 10) {
    "urgent"
  } else if (!is.na(games_away) && games_away <= 30) {
    "close"
  } else {
    "upcoming"
  }

  milestone_results[[length(milestone_results) + 1]] <- list(
    id          = m$id,
    player      = m$player_id,
    category    = m$category,
    statType    = m$stat_label,
    current     = as.integer(current),
    target      = as.integer(m$target),
    unit        = m$stat_col,
    remaining   = remaining,
    pace        = round(pace, 2),
    gamesAway   = if (is.na(games_away)) NULL else games_away,
    urgency     = urgency,
    mediaAlert  = MEDIA_ALERTS[[m$id]] %||% "",
    gp_season   = totals$GP_season %||% 0L,
    data_source = ifelse(OFFSEASON_MODE, "verified_bbref_2025_26", "live_bbref_scrape")
  )

  status <- if (remaining == 0L) "ACHIEVED" else paste0(games_away %||% "?", " games away")
  cli_alert_success("  {m$id}: {current}/{m$target} ({urgency}) — {status}")
}

# ── ROSTER OUTPUT ─────────────────────────────────────────────
roster_out <- lapply(seq_len(nrow(NETS_ROSTER)), function(i) {
  p <- NETS_ROSTER[i, ]
  t <- CAREER_TOTALS[[p$player_id]]
  list(
    id         = p$player_id,
    name       = p$full_name,
    number     = p$number,
    pos        = p$pos,
    gp         = t$GP_season %||% NULL,
    season_ppg = t$PPG %||% NULL,
    season_rpg = t$RPG %||% NULL,
    season_apg = t$APG %||% NULL,
    note       = t$note %||% NULL
  )
})

# ── WRITE JSON ────────────────────────────────────────────────
cli_h2("Writing JSON")

data_source_label <- if (OFFSEASON_MODE) {
  "Verified career totals — Basketball Reference (May 11, 2026)"
} else {
  paste0("Live BBRef scrape — ", format(Sys.time(), "%Y-%m-%d"))
}

output <- list(
  meta = list(
    generated_at     = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    season           = 2027L,
    source           = data_source_label,
    offseason_mode   = OFFSEASON_MODE,
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
