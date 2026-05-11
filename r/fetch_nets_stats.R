# ============================================================
# Brooklyn Nets Milestone & Streak Tracker — Data Fetch
# All career totals verified from Basketball Reference, May 2026
# ============================================================

suppressPackageStartupMessages({
  library(jsonlite)
  library(cli)
  library(tibble)
  library(dplyr)
})

OFFSEASON_MODE <- TRUE  # Set FALSE in October when 2026-27 season starts

cli_h1("Nets Milestone Tracker — Data Fetch")
cli_alert_info("Run time: {Sys.time()}")
cli_alert_info("Mode: {ifelse(OFFSEASON_MODE, 'OFFSEASON (verified 2025-26 final stats)', 'LIVE (hoopR API)')}")

OUTPUT_DIR <- "public/data"
if (!dir.exists(OUTPUT_DIR)) OUTPUT_DIR <- "../public/data"
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)
cli_alert_info("Output directory: {normalizePath(OUTPUT_DIR)}")

# ── VERIFIED CAREER TOTALS (Basketball Reference, May 11 2026) ─
# Source: basketball-reference.com/players/*/[playerid].html
# All numbers are career totals through end of 2025-26 season

CAREER_TOTALS <- list(

  claxton = list(
    # 7 seasons, all BRK | BBRef: claxtni01
    GP=380L, PTS=4024L, TRB=2875L, AST=788L, STL=266L, BLK=611L, FG3M=11L,
    GP_season=69L, season_PTS=810L, season_TRB=478L, season_AST=253L,
    season_BLK=77L, season_FG3M=3L,
    PPG=11.7, RPG=6.9, APG=3.7, BPG=1.1
  ),

  clowney = list(
    # 3 seasons, all BRK | BBRef: clownno01
    GP=135L, PTS=1362L, TRB=535L, AST=166L, STL=82L, BLK=82L, FG3M=228L,
    GP_season=66L, season_PTS=809L, season_TRB=273L, season_AST=108L,
    season_BLK=45L, season_FG3M=129L,
    PPG=12.3, RPG=4.1, APG=1.6, BPG=0.7
  ),

  mann = list(
    # 7 seasons (LAC x6, ATL, BRK) | BBRef: mannte01
    GP=475L, PTS=3786L, TRB=1651L, AST=980L, STL=268L, BLK=106L, FG3M=385L,
    GP_season=63L, season_PTS=455L, season_TRB=200L, season_AST=190L,
    season_BLK=15L, season_FG3M=56L,
    PPG=7.2, RPG=3.2, APG=3.0, BPG=0.2
  ),

  powell = list(
    # 1 season (rookie) | BBRef: poweldr01
    GP=63L, PTS=408L, TRB=111L, AST=91L, STL=36L, BLK=14L, FG3M=51L,
    GP_season=63L, season_PTS=408L, season_TRB=111L, season_AST=91L,
    season_BLK=14L, season_FG3M=51L,
    PPG=6.5, RPG=1.8, APG=1.4, BPG=0.2
  ),

  sharpe = list(
    # 5 seasons, all BRK | BBRef: sharpda01
    GP=253L, PTS=1777L, TRB=1492L, AST=375L, STL=157L, BLK=159L, FG3M=32L,
    GP_season=62L, season_PTS=540L, season_TRB=413L, season_AST=145L,
    season_BLK=26L, season_FG3M=9L,
    PPG=8.7, RPG=6.7, APG=2.3, BPG=0.4
  ),

  wolf = list(
    # 1 season (rookie) | BBRef: wolfda01
    GP=57L, PTS=508L, TRB=281L, AST=127L, STL=30L, BLK=32L, FG3M=68L,
    GP_season=57L, season_PTS=508L, season_TRB=281L, season_AST=127L,
    season_BLK=32L, season_FG3M=68L,
    PPG=8.9, RPG=4.9, APG=2.2, BPG=0.6
  ),

  williams = list(
    # 5 seasons (MEM x3, BRK x2) | BBRef: willizi02
    GP=269L, PTS=2336L, TRB=809L, AST=319L, STL=223L, BLK=76L, FG3M=348L,
    GP_season=56L, season_PTS=573L, season_TRB=134L, season_AST=60L,
    season_BLK=21L, season_FG3M=86L,
    PPG=10.2, RPG=2.4, APG=1.1, BPG=0.4
  ),

  traore = list(
    # 1 season (rookie) | BBRef: traorno01
    GP=56L, PTS=499L, TRB=99L, AST=213L, STL=45L, BLK=23L, FG3M=61L,
    GP_season=56L, season_PTS=499L, season_TRB=99L, season_AST=213L,
    season_BLK=23L, season_FG3M=61L,
    PPG=8.9, RPG=1.8, APG=3.8, BPG=0.4
  ),

  wilson = list(
    # 3 seasons, all BRK | BBRef: wilsoja03
    GP=176L, PTS=1306L, TRB=515L, AST=240L, STL=73L, BLK=11L, FG3M=200L,
    GP_season=54L, season_PTS=343L, season_TRB=114L, season_AST=50L,
    season_BLK=2L, season_FG3M=54L,
    PPG=6.4, RPG=2.1, APG=0.9, BPG=0.0
  ),

  porter = list(
    # 7 seasons (DEN x6, BRK x1) | BBRef: portemi01
    # Out for season with hamstring
    GP=397L, PTS=6856L, TRB=2576L, AST=643L, STL=261L, BLK=214L, FG3M=1019L,
    GP_season=52L, season_PTS=1259L, season_TRB=367L, season_AST=158L,
    season_BLK=13L, season_FG3M=176L,
    PPG=24.2, RPG=7.1, APG=3.0, BPG=0.3,
    note="Out for season (hamstring)"
  ),

  demin = list(
    # 1 season (rookie) | BBRef: demineg01
    GP=52L, PTS=536L, TRB=165L, AST=173L, STL=42L, BLK=17L, FG3M=124L,
    GP_season=52L, season_PTS=536L, season_TRB=165L, season_AST=173L,
    season_BLK=17L, season_FG3M=124L,
    PPG=10.3, RPG=3.2, APG=3.3, BPG=0.3
  ),

  saraf = list(
    # 1 season (rookie) | BBRef: sarafbe01
    GP=44L, PTS=332L, TRB=92L, AST=145L, STL=38L, BLK=8L, FG3M=19L,
    GP_season=44L, season_PTS=332L, season_TRB=92L, season_AST=145L,
    season_BLK=8L, season_FG3M=19L,
    PPG=7.5, RPG=2.1, APG=3.3, BPG=0.2
  ),

  liddell = list(
    # 3 seasons (NOP, CHI, BRK) | BBRef: liddeej01
    GP=46L, PTS=172L, TRB=83L, AST=28L, STL=9L, BLK=13L, FG3M=21L,
    GP_season=26L, season_PTS=147L, season_TRB=69L, season_AST=24L,
    season_BLK=10L, season_FG3M=18L,
    PPG=5.7, RPG=2.7, APG=0.9, BPG=0.4
  ),

  etienne = list(
    # 2 seasons (BRK) | BBRef: etienty01
    GP=31L, PTS=244L, TRB=36L, AST=52L, STL=14L, BLK=1L, FG3M=56L,
    GP_season=24L, season_PTS=189L, season_TRB=27L, season_AST=40L,
    season_BLK=0L, season_FG3M=43L,
    PPG=7.9, RPG=1.1, APG=1.7, BPG=0.0
  ),

  agbaji = list(
    # 4 seasons (UTA x2, TOR x2, BRK) | BBRef: agbajoc01
    # Spent most of 2025-26 with TOR, joined BRK late
    GP=263L, PTS=1903L, TRB=720L, AST=295L, STL=145L, BLK=106L, FG3M=278L,
    GP_season=20L, season_PTS=133L, season_TRB=46L, season_AST=17L,
    season_BLK=6L, season_FG3M=22L,
    PPG=5.1, RPG=2.3, APG=0.8, BPG=0.2,
    note="Joined BRK late in 2025-26 (20 games with BRK, 42 with TOR)"
  ),

  johnson = list(
    # 1 season (rookie) | BBRef: johnsch06
    GP=17L, PTS=139L, TRB=79L, AST=36L, STL=15L, BLK=9L, FG3M=9L,
    GP_season=17L, season_PTS=139L, season_TRB=79L, season_AST=36L,
    season_BLK=9L, season_FG3M=9L,
    PPG=8.2, RPG=4.6, APG=2.1, BPG=0.5
  ),

  minott = list(
    # 4 seasons (MIN x3, BOS, BRK) | BBRef: minotjo01
    # Spent most of 2025-26 with BOS (33 GP), only 16 GP with BRK
    GP=142L, PTS=579L, TRB=247L, AST=77L, STL=68L, BLK=47L, FG3M=84L,
    GP_season=16L, season_PTS=172L, season_TRB=40L, season_AST=13L,
    season_BLK=12L, season_FG3M=30L,
    PPG=10.8, RPG=2.5, APG=0.8, BPG=0.8,
    note="16 games with BRK in 2025-26 (33 with BOS earlier)"
  ),

  smith = list(
    # 1 season (rookie) | BBRef: smithma02
    GP=15L, PTS=124L, TRB=51L, AST=49L, STL=12L, BLK=4L, FG3M=20L,
    GP_season=15L, season_PTS=124L, season_TRB=51L, season_AST=49L,
    season_BLK=4L, season_FG3M=20L,
    PPG=8.3, RPG=3.4, APG=3.3, BPG=0.3
  )
)

# ── ROSTER ────────────────────────────────────────────────────

NETS_ROSTER <- tribble(
  ~player_id,  ~full_name,             ~number, ~pos,
  "claxton",   "Nic Claxton",          "33",    "C",
  "clowney",   "Noah Clowney",         "21",    "PF",
  "mann",      "Terance Mann",         "14",    "SG",
  "powell",    "Drake Powell",         "4",     "SG",
  "sharpe",    "Day'Ron Sharpe",       "20",    "C",
  "wolf",      "Danny Wolf",           "2",     "PF",
  "williams",  "Ziaire Williams",      "1",     "SF",
  "traore",    "Nolan Traoré",         "88",    "PG",
  "wilson",    "Jalen Wilson",         "22",    "PF",
  "porter",    "Michael Porter Jr.",   "17",    "SF",
  "demin",     "Egor Dëmin",           "8",     "PG",
  "saraf",     "Ben Saraf",            "77",    "SG",
  "liddell",   "E.J. Liddell",         "9",     "PF",
  "etienne",   "Tyson Etienne",        "10",    "PG",
  "agbaji",    "Ochai Agbaji",         "30",    "SG",
  "johnson",   "Chaney Johnson",       "31",    "SF",
  "minott",    "Josh Minott",          "00",    "SF",
  "smith",     "Malachi Smith",        "18",    "SG"
)

# ── MILESTONE DEFINITIONS ─────────────────────────────────────
# next_season_pace = projected season total for 2026-27 (for games-away calc)

MILESTONE_DEFS <- tribble(
  ~id,                             ~player_id,  ~type,       ~category,        ~stat_label,                  ~stat_col, ~target, ~unit,  ~next_season_pace,
  # CLAXTON
  "claxton-700-blocks",            "claxton",   "milestone", "Blocks",         "Career Blocks",              "BLK",     700L,    "BLK",  75.0,
  "claxton-5000-pts",              "claxton",   "milestone", "Points",         "Career Points",              "PTS",     5000L,   "PTS",  870.0,
  "claxton-3000-reb",              "claxton",   "milestone", "Rebounding",     "Career Rebounds",            "TRB",     3000L,   "TRB",  478.0,
  # PORTER
  "porter-7000-pts",               "porter",    "milestone", "Points",         "Career Points",              "PTS",     7000L,   "PTS",  1500.0,
  "porter-1000-3pm",               "porter",    "milestone", "Three-Pointers", "Career 3-Pointers Made",     "FG3M",    1000L,   "3PM",  200.0,
  # MANN
  "mann-500-gp",                   "mann",      "milestone", "Games",          "Career Games Played",        "GP",      500L,    "GP",   70.0,
  "mann-4000-pts",                 "mann",      "milestone", "Points",         "Career Points",              "PTS",     4000L,   "PTS",  455.0,
  "mann-1000-ast",                 "mann",      "milestone", "Assists",        "Career Assists",             "AST",     1000L,   "AST",  190.0,
  # CLOWNEY
  "clowney-1500-pts",              "clowney",   "milestone", "Points",         "Career Points",              "PTS",     1500L,   "PTS",  800.0,
  "clowney-300-3pm",               "clowney",   "milestone", "Three-Pointers", "Career 3-Pointers Made",     "FG3M",    300L,    "3PM",  130.0,
  # WILLIAMS
  "williams-400-3pm",              "williams",  "milestone", "Three-Pointers", "Career 3-Pointers Made",     "FG3M",    400L,    "3PM",  100.0,
  "williams-2500-pts",             "williams",  "milestone", "Points",         "Career Points",              "PTS",     2500L,   "PTS",  600.0,
  # WILSON
  "wilson-1500-pts",               "wilson",    "milestone", "Points",         "Career Points",              "PTS",     1500L,   "PTS",  400.0,
  # AGBAJI
  "agbaji-2000-pts",               "agbaji",    "milestone", "Points",         "Career Points",              "PTS",     2000L,   "PTS",  500.0,
  "agbaji-300-3pm",                "agbaji",    "milestone", "Three-Pointers", "Career 3-Pointers Made",     "FG3M",    300L,    "3PM",  80.0,
  # SHARPE
  "sharpe-2000-pts",               "sharpe",    "milestone", "Points",         "Career Points",              "PTS",     2000L,   "PTS",  540.0,
  "sharpe-200-blk",                "sharpe",    "milestone", "Blocks",         "Career Blocks",              "BLK",     200L,    "BLK",  30.0,
)

MEDIA_ALERTS <- list(
  "claxton-700-blocks"   = "Claxton has 611 career blocks — 89 away from 700, a threshold reached by only the most dominant shot-blockers in NBA history. At 1.1 BPG, he hits this roughly midway through 2026-27. Prepare a feature on his place among elite modern rim protectors.",
  "claxton-5000-pts"     = "Claxton finished 2025-26 with 4,024 career points. At his scoring pace he reaches 5,000 in approximately year 9 of his career — a meaningful longevity milestone for a center who was originally regarded as a defensive specialist.",
  "claxton-3000-reb"     = "Claxton has 2,875 career rebounds — 125 away from 3,000. At 6.9 RPG, expect this milestone within the first quarter of 2026-27. Good peg for a feature on his development as a complete center.",
  "porter-7000-pts"      = "Porter finished 2025-26 with 6,856 career points — 144 away from 7,000. At his 24.2 PPG pace, he reaches this within 6 games of 2026-27 if healthy. Major scorer milestone angle.",
  "porter-1000-3pm"      = "Porter has 1,019 career 3-pointers — already past 1,000! This milestone was achieved during 2025-26. Only ~200 players in NBA history have reached this mark. Pre-write a retrospective piece.",
  "mann-500-gp"          = "Mann finished 2025-26 with 475 career games — 25 away from 500. He'll reach this within the first month of 2026-27. Career longevity milestone: from undrafted buzz to 500 NBA games.",
  "mann-4000-pts"        = "Mann has 3,786 career points — 214 away from 4,000, arriving roughly mid-2026-27. Good milestone for a veteran two-way wing who's quietly built a strong career.",
  "mann-1000-ast"        = "Mann has 980 career assists — 20 away from 1,000. He'll reach this within the first few games of 2026-27. Playmaking milestone for a wing player.",
  "clowney-1500-pts"     = "Clowney has 1,362 career points at age 21 — 138 away from 1,500. With career highs across the board in 2025-26, this arrives early in 2026-27. Young-player development feature angle.",
  "clowney-300-3pm"      = "Clowney made 129 threes in 2025-26 alone and now has 228 career makes — 72 away from 300. At 2.0 per game he hits this around game 36 of 2026-27. His floor-spacing development is the story.",
  "williams-400-3pm"     = "Williams has 348 career threes — 52 away from 400, arriving roughly game 42 of 2026-27. Quietly becoming one of the better floor spacers on the roster.",
  "williams-2500-pts"    = "Williams has 2,336 career points — 164 away from 2,500. Good mid-career scoring milestone for a player who has reinvented himself since Memphis.",
  "wilson-1500-pts"      = "Wilson has 1,306 career points — 194 away from 1,500. At his pace this arrives mid-2026-27. Establishment-in-the-league milestone.",
  "agbaji-2000-pts"      = "Agbaji has 1,903 career points — 97 away from 2,000. At his pace this arrives within 20 games of 2026-27. He joined BRK late this season; feature on his fresh start in Brooklyn.",
  "agbaji-300-3pm"       = "Agbaji has 278 career threes — 22 away from 300, arriving within his first few weeks as a full-time Net in 2026-27. Shooter's milestone.",
  "sharpe-2000-pts"      = "Sharpe has 1,777 career points — 223 away from 2,000. At 8.7 PPG this arrives around game 26 of 2026-27. His progression as a scoring threat is worth tracking.",
  "sharpe-200-blk"       = "Sharpe has 159 career blocks — 41 away from 200. At just 24 years old reaching 200 career blocks marks his emergence as a legitimate two-way center. Arrives ~mid-2026-27."
)

# ── COMPUTE MILESTONES ────────────────────────────────────────

cli_h2("Computing milestones from verified 2025-26 final stats")

milestone_results <- list()

for (i in seq_len(nrow(MILESTONE_DEFS))) {
  m      <- MILESTONE_DEFS[i, ]
  totals <- CAREER_TOTALS[[m$player_id]]

  current <- totals[[m$stat_col]]
  if (is.null(current)) {
    cli_alert_warning("  No stat {m$stat_col} for {m$player_id}")
    next
  }

  remaining  <- max(0L, as.integer(m$target) - as.integer(current))
  pace       <- m$next_season_pace / 82.0
  games_away <- if (pace > 0 && remaining > 0) as.integer(ceiling(remaining / pace)) else NA_integer_

  # Milestone already achieved?
  if (remaining == 0L) {
    urgency <- "achieved"
  } else if (!is.na(games_away) && games_away <= 10) {
    urgency <- "urgent"
  } else if (!is.na(games_away) && games_away <= 30) {
    urgency <- "close"
  } else {
    urgency <- "upcoming"
  }

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
    pace       = round(pace, 2),
    gamesAway  = if (is.na(games_away)) NULL else games_away,
    urgency    = urgency,
    mediaAlert = MEDIA_ALERTS[[m$id]] %||% "",
    gp_season  = totals$GP_season %||% 0L,
    data_source = "verified_bbref_2025_26"
  )

  status <- if (remaining == 0L) "ACHIEVED" else paste0(games_away %||% "?", " games into 2026-27")
  cli_alert_success("  {m$id}: {current}/{m$target} ({urgency}) — {status}")
}

`%||%` <- function(a, b) if (!is.null(a)) a else b
milestone_results <- Filter(Negate(is.null), milestone_results)

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

cli_h2("Writing output JSON")

output <- list(
  meta = list(
    generated_at     = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    season           = 2026L,
    source           = "Verified career totals — Basketball Reference (May 11, 2026)",
    offseason_mode   = TRUE,
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
