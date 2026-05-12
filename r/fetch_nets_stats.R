# ============================================================
# Brooklyn Nets Milestone & Streak Tracker — Data Fetch
# Career totals verified from Basketball Reference, May 11 2026
# Milestone ladders auto-advance — no manual updates needed
# ============================================================

suppressPackageStartupMessages({
  library(jsonlite)
  library(cli)
  library(tibble)
  library(dplyr)
  library(rvest)
})

`%||%` <- function(a, b) if (!is.null(a)) a else b

# ── CONFIG ────────────────────────────────────────────────────
# Set FALSE on opening night of 2026-27 season
OFFSEASON_MODE <- TRUE

BBREF_IDS <- c(
  claxton  = "c/claxtni01",  clowney  = "c/clownno01",
  mann     = "m/mannte01",   powell   = "p/poweldr01",
  sharpe   = "s/sharpda01",  wolf     = "w/wolfda01",
  williams = "w/willizi02",  traore   = "t/traorno01",
  wilson   = "w/wilsoja03",  porter   = "p/portemi01",
  demin    = "d/demineg01",  saraf    = "s/sarafbe01",
  liddell  = "l/liddeej01",  etienne  = "e/etienty01",
  agbaji   = "a/agbajoc01",  johnson  = "j/johnsch06",
  minott   = "m/minotjo01",  smith    = "s/smithma02"
)

cli_h1("Nets Milestone Tracker — Data Fetch")
cli_alert_info("Run time: {Sys.time()}")
cli_alert_info("Mode: {ifelse(OFFSEASON_MODE, 'OFFSEASON (hardcoded 2025-26)', 'LIVE (BBRef scrape)')}")

OUTPUT_DIR <- "public/data"
if (!dir.exists(OUTPUT_DIR)) OUTPUT_DIR <- "../public/data"
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

# ── MILESTONE LADDERS ─────────────────────────────────────────
LADDERS <- list(
  PTS  = c(200, 500, 1000, 1500, 2000, 2500, 3000, 4000, 5000, 7500, 10000, 15000, 20000),
  TRB  = c(100, 250, 500, 1000, 2000, 3000, 4000, 5000, 7500, 10000),
  ORB  = c(50, 100, 200, 300, 500, 750, 1000, 1500, 2000),
  AST  = c(100, 250, 500, 1000, 1500, 2000, 2500, 3000, 5000),
  BLK  = c(50, 100, 200, 300, 500, 700, 1000),
  STL  = c(50, 100, 200, 300, 500, 700, 1000),
  FG3M = c(50, 100, 200, 300, 400, 500, 600, 700, 750, 1000, 1500),
  FTM  = c(50, 100, 200, 300, 500, 700, 1000, 1500, 2000),
  GP   = c(100, 200, 300, 400, 500, 600, 700, 800, 900, 1000)
)

STAT_LABELS <- list(
  PTS  = "Career Points",
  TRB  = "Career Rebounds",
  ORB  = "Career Offensive Rebounds",
  AST  = "Career Assists",
  BLK  = "Career Blocks",
  STL  = "Career Steals",
  FG3M = "Career 3-Pointers Made",
  FTM  = "Career Free Throws Made",
  GP   = "Career Games Played"
)

STAT_CATEGORIES <- list(
  PTS  = "Points",
  TRB  = "Rebounding",
  ORB  = "Rebounding",
  AST  = "Assists",
  BLK  = "Blocks",
  STL  = "Steals",
  FG3M = "Three-Pointers",
  FTM  = "Free Throws",
  GP   = "Games"
)

# ── VERIFIED CAREER TOTALS (Basketball Reference, May 11 2026) ─
CAREER_TOTALS <- list(

  claxton = list(
    GP=380L, PTS=4024L, TRB=2875L, ORB=855L, AST=788L, STL=266L, BLK=611L, FG3M=11L, FTM=557L,
    GP_season=69L, season_PTS=810L, season_TRB=478L, season_ORB=168L, season_AST=253L,
    season_STL=62L, season_BLK=77L, season_FG3M=3L, season_FTM=141L,
    PPG=11.7, RPG=6.9, APG=3.7, BPG=1.1
  ),

  clowney = list(
    GP=135L, PTS=1362L, TRB=535L, ORB=121L, AST=166L, STL=82L, BLK=82L, FG3M=228L, FTM=268L,
    GP_season=66L, season_PTS=809L, season_TRB=273L, season_ORB=52L, season_AST=108L,
    season_STL=50L, season_BLK=45L, season_FG3M=129L, season_FTM=180L,
    PPG=12.3, RPG=4.1, APG=1.6, BPG=0.7
  ),

  mann = list(
    GP=475L, PTS=3786L, TRB=1651L, ORB=472L, AST=980L, STL=268L, BLK=106L, FG3M=385L, FTM=505L,
    GP_season=63L, season_PTS=455L, season_TRB=200L, season_ORB=70L, season_AST=190L,
    season_STL=41L, season_BLK=15L, season_FG3M=56L, season_FTM=63L,
    PPG=7.2, RPG=3.2, APG=3.0, BPG=0.2
  ),

  powell = list(
    GP=63L, PTS=408L, TRB=111L, ORB=21L, AST=91L, STL=36L, BLK=14L, FG3M=51L, FTM=69L,
    GP_season=63L, season_PTS=408L, season_TRB=111L, season_ORB=21L, season_AST=91L,
    season_STL=36L, season_BLK=14L, season_FG3M=51L, season_FTM=69L,
    PPG=6.5, RPG=1.8, APG=1.4, BPG=0.2
  ),

  sharpe = list(
    GP=253L, PTS=1777L, TRB=1492L, ORB=661L, AST=375L, STL=157L, BLK=159L, FG3M=32L, FTM=293L,
    GP_season=62L, season_PTS=540L, season_TRB=413L, season_ORB=171L, season_AST=145L,
    season_STL=67L, season_BLK=26L, season_FG3M=9L, season_FTM=103L,
    PPG=8.7, RPG=6.7, APG=2.3, BPG=0.4
  ),

  wolf = list(
    GP=57L, PTS=508L, TRB=281L, ORB=57L, AST=127L, STL=30L, BLK=32L, FG3M=68L, FTM=84L,
    GP_season=57L, season_PTS=508L, season_TRB=281L, season_ORB=57L, season_AST=127L,
    season_STL=30L, season_BLK=32L, season_FG3M=68L, season_FTM=84L,
    PPG=8.9, RPG=4.9, APG=2.2, BPG=0.6
  ),

  williams = list(
    GP=269L, PTS=2336L, TRB=809L, ORB=168L, AST=319L, STL=223L, BLK=76L, FG3M=348L, FTM=342L,
    GP_season=56L, season_PTS=573L, season_TRB=134L, season_ORB=30L, season_AST=60L,
    season_STL=76L, season_BLK=21L, season_FG3M=86L, season_FTM=119L,
    PPG=10.2, RPG=2.4, APG=1.1, BPG=0.4
  ),

  traore = list(
    GP=56L, PTS=499L, TRB=99L, ORB=14L, AST=213L, STL=45L, BLK=23L, FG3M=61L, FTM=74L,
    GP_season=56L, season_PTS=499L, season_TRB=99L, season_ORB=14L, season_AST=213L,
    season_STL=45L, season_BLK=23L, season_FG3M=61L, season_FTM=74L,
    PPG=8.9, RPG=1.8, APG=3.8, BPG=0.4
  ),

  wilson = list(
    GP=176L, PTS=1306L, TRB=515L, ORB=139L, AST=240L, STL=73L, BLK=11L, FG3M=200L, FTM=242L,
    GP_season=54L, season_PTS=343L, season_TRB=114L, season_ORB=17L, season_AST=50L,
    season_STL=22L, season_BLK=2L, season_FG3M=54L, season_FTM=69L,
    PPG=6.4, RPG=2.1, APG=0.9, BPG=0.0
  ),

  porter = list(
    GP=397L, PTS=6856L, TRB=2576L, ORB=543L, AST=643L, STL=261L, BLK=214L, FG3M=1019L, FTM=703L,
    GP_season=52L, season_PTS=1259L, season_TRB=367L, season_ORB=69L, season_AST=158L,
    season_STL=55L, season_BLK=13L, season_FG3M=176L, season_FTM=195L,
    PPG=24.2, RPG=7.1, APG=3.0, BPG=0.3,
    note="Out for season (hamstring)"
  ),

  demin = list(
    GP=52L, PTS=536L, TRB=165L, ORB=21L, AST=173L, STL=42L, BLK=17L, FG3M=124L, FTM=54L,
    GP_season=52L, season_PTS=536L, season_TRB=165L, season_ORB=21L, season_AST=173L,
    season_STL=42L, season_BLK=17L, season_FG3M=124L, season_FTM=54L,
    PPG=10.3, RPG=3.2, APG=3.3, BPG=0.3
  ),

  saraf = list(
    GP=44L, PTS=332L, TRB=92L, ORB=20L, AST=145L, STL=38L, BLK=8L, FG3M=19L, FTM=73L,
    GP_season=44L, season_PTS=332L, season_TRB=92L, season_ORB=20L, season_AST=145L,
    season_STL=38L, season_BLK=8L, season_FG3M=19L, season_FTM=73L,
    PPG=7.5, RPG=2.1, APG=3.3, BPG=0.2
  ),

  liddell = list(
    GP=46L, PTS=172L, TRB=83L, ORB=17L, AST=28L, STL=9L, BLK=13L, FG3M=21L, FTM=25L,
    GP_season=26L, season_PTS=147L, season_TRB=69L, season_ORB=14L, season_AST=24L,
    season_STL=6L, season_BLK=10L, season_FG3M=18L, season_FTM=21L,
    PPG=5.7, RPG=2.7, APG=0.9, BPG=0.4
  ),

  etienne = list(
    GP=31L, PTS=244L, TRB=36L, ORB=8L, AST=52L, STL=14L, BLK=1L, FG3M=56L, FTM=38L,
    GP_season=24L, season_PTS=189L, season_TRB=27L, season_ORB=5L, season_AST=40L,
    season_STL=11L, season_BLK=0L, season_FG3M=43L, season_FTM=30L,
    PPG=7.9, RPG=1.1, APG=1.7, BPG=0.0
  ),

  agbaji = list(
    GP=263L, PTS=1903L, TRB=720L, ORB=224L, AST=295L, STL=145L, BLK=106L, FG3M=278L, FTM=163L,
    GP_season=20L, season_PTS=133L, season_TRB=46L, season_ORB=13L, season_AST=17L,
    season_STL=7L, season_BLK=6L, season_FG3M=22L, season_FTM=11L,
    PPG=5.1, RPG=2.3, APG=0.8, BPG=0.2,
    note="Joined BRK late (20 GP with BRK, 42 with TOR)"
  ),

  johnson = list(
    GP=17L, PTS=139L, TRB=79L, ORB=33L, AST=36L, STL=15L, BLK=9L, FG3M=9L, FTM=28L,
    GP_season=17L, season_PTS=139L, season_TRB=79L, season_ORB=33L, season_AST=36L,
    season_STL=15L, season_BLK=9L, season_FG3M=9L, season_FTM=28L,
    PPG=8.2, RPG=4.6, APG=2.1, BPG=0.5
  ),

  minott = list(
    GP=142L, PTS=579L, TRB=247L, ORB=69L, AST=77L, STL=68L, BLK=47L, FG3M=84L, FTM=85L,
    GP_season=16L, season_PTS=172L, season_TRB=40L, season_ORB=8L, season_AST=13L,
    season_STL=20L, season_BLK=12L, season_FG3M=30L, season_FTM=28L,
    PPG=10.8, RPG=2.5, APG=0.8, BPG=0.8,
    note="16 GP with BRK in 2025-26 (33 with BOS earlier)"
  ),

  smith = list(
    GP=15L, PTS=124L, TRB=51L, ORB=12L, AST=49L, STL=12L, BLK=4L, FG3M=20L, FTM=8L,
    GP_season=15L, season_PTS=124L, season_TRB=51L, season_ORB=12L, season_AST=49L,
    season_STL=12L, season_BLK=4L, season_FG3M=20L, season_FTM=8L,
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

# ── LIVE BBRef SCRAPER ────────────────────────────────────────
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
      ORB  = career[["orb"]] %||% NA_integer_,
      AST  = career[["ast"]] %||% NA_integer_,
      STL  = career[["stl"]] %||% NA_integer_,
      BLK  = career[["blk"]] %||% NA_integer_,
      FG3M = career[["fg3"]] %||% NA_integer_,
      FTM  = career[["ft"]]  %||% NA_integer_
    )
    tbody_rows <- rvest::html_elements(page, "#totals_stats tbody tr:not(.thead)")
    if (length(tbody_rows) > 0) {
      szn  <- extract_row(tbody_rows[[length(tbody_rows)]])
      gp_s <- szn[["g"]] %||% 0L
      result$GP_season   <- gp_s
      result$season_PTS  <- szn[["pts"]] %||% 0L
      result$season_TRB  <- szn[["trb"]] %||% 0L
      result$season_ORB  <- szn[["orb"]] %||% 0L
      result$season_AST  <- szn[["ast"]] %||% 0L
      result$season_STL  <- szn[["stl"]] %||% 0L
      result$season_BLK  <- szn[["blk"]] %||% 0L
      result$season_FG3M <- szn[["fg3"]] %||% 0L
      result$season_FTM  <- szn[["ft"]]  %||% 0L
      if (!is.na(gp_s) && gp_s > 0) {
        result$PPG <- round(result$season_PTS / gp_s, 1)
        result$RPG <- round(result$season_TRB / gp_s, 1)
        result$APG <- round(result$season_AST / gp_s, 1)
        result$BPG <- round(result$season_BLK / gp_s, 1)
      }
    }
    cli_alert_success("  {pid}: GP={result$GP} PTS={result$PTS} BLK={result$BLK}")
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

# ── COMPUTE MILESTONES (LADDER SYSTEM) ───────────────────────
cli_h2("Computing milestones from ladders")

next_rung <- function(current, ladder) {
  above <- ladder[ladder > current]
  if (length(above) == 0) return(NULL)
  min(above)
}

milestone_results <- list()

for (pid in names(CAREER_TOTALS)) {
  totals <- CAREER_TOTALS[[pid]]
  name   <- NETS_ROSTER$full_name[NETS_ROSTER$player_id == pid]
  if (length(name) == 0) name <- pid

  for (stat in names(LADDERS)) {
    current <- totals[[stat]]
    if (is.null(current) || is.na(current)) next

    target <- next_rung(as.integer(current), LADDERS[[stat]])
    if (is.null(target)) next

    remaining   <- as.integer(target) - as.integer(current)
    season_stat <- totals[[paste0("season_", stat)]] %||% 0L
    gp_s        <- totals$GP_season %||% 0L
    pace        <- if (gp_s > 0 && season_stat > 0) season_stat / gp_s else NA_real_

    games_away <- if (!is.na(pace) && pace > 0 && remaining > 0) {
      as.integer(ceiling(remaining / pace))
    } else NA_integer_

    urgency <- if (remaining == 0L) {
      "achieved"
    } else if (!is.na(games_away) && games_away <= 10) {
      "urgent"
    } else if (!is.na(games_away) && games_away <= 30) {
      "close"
    } else {
      "upcoming"
    }

    mid <- paste0(pid, "-", tolower(stat), "-", target)

    milestone_results[[length(milestone_results) + 1]] <- list(
      id         = mid,
      player     = pid,
      playerName = name,
      category   = STAT_CATEGORIES[[stat]],
      statType   = STAT_LABELS[[stat]],
      statKey    = stat,
      current    = as.integer(current),
      target     = as.integer(target),
      remaining  = remaining,
      pace       = if (is.na(pace)) NULL else round(pace, 2),
      gamesAway  = if (is.na(games_away)) NULL else games_away,
      urgency    = urgency,
      gp_season  = gp_s,
      data_source = ifelse(OFFSEASON_MODE, "verified_bbref_2025_26", "live_bbref_scrape")
    )
  }
}

cli_alert_success("Generated {length(milestone_results)} milestones across {length(CAREER_TOTALS)} players")

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
    career_gp  = t$GP %||% NULL,
    season_ppg = t$PPG %||% NULL,
    season_rpg = t$RPG %||% NULL,
    season_apg = t$APG %||% NULL,
    note       = t$note %||% NULL,
    stats = list(
      GP   = t$GP   %||% 0L,
      PTS  = t$PTS  %||% 0L,
      TRB  = t$TRB  %||% 0L,
      ORB  = t$ORB  %||% 0L,
      AST  = t$AST  %||% 0L,
      STL  = t$STL  %||% 0L,
      BLK  = t$BLK  %||% 0L,
      FG3M = t$FG3M %||% 0L,
      FTM  = t$FTM  %||% 0L
    )
  )
})

# ── WRITE JSON ────────────────────────────────────────────────
cli_h2("Writing JSON")

output <- list(
  meta = list(
    generated_at     = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    season           = 2027L,
    source           = ifelse(OFFSEASON_MODE,
      "Verified career totals — Basketball Reference (May 11, 2026)",
      paste0("Live BBRef scrape — ", format(Sys.time(), "%Y-%m-%d"))),
    offseason_mode   = OFFSEASON_MODE,
    total_milestones = length(milestone_results),
    total_streaks    = 0L
  ),
  ladders    = LADDERS,
  roster     = roster_out,
  milestones = milestone_results,
  streaks    = list()
)

out_path <- file.path(OUTPUT_DIR, "live_stats.json")
writeLines(toJSON(output, auto_unbox = TRUE, pretty = TRUE, null = "null"), out_path)

cli_alert_success("Written: {out_path}")
cli_alert_info("Total milestones: {length(milestone_results)}")
cli_h1("Done — {format(Sys.time())}")
