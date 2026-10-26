-- =====================================================================
-- CBCS  |  05_nba.sql  |  Owner: Member 5 (NBA / DarkNight)
-- Tables: NBA_Games, GameParticipations
-- Runs after 01_locations_personnel.sql and 02_club_members.sql,
-- because GameParticipations references ClubMembers(memberID).
-- Target: MySQL 8.0.16+ (CHECK constraints are enforced from 8.0.16;
-- older servers parse and ignore them, so the script still runs).
--
-- NOTE: teamPlayedFor must equal the homeTeam or awayTeam of that game;
-- this can't be a CHECK across tables, so it's enforced by the data.
-- =====================================================================

-- ---------------------------------------------------------------------
-- NBA_Games
-- One NBA game: the two teams, where/when it was played and the final
-- score. Table name is NBA_Games exactly, as required by the assignment.
-- Scores are non-negative and the two teams must differ.
-- ---------------------------------------------------------------------
CREATE TABLE NBA_Games (
    gameID        INT           NOT NULL AUTO_INCREMENT,
    gameDate      DATE          NOT NULL,
    gameLocation  VARCHAR(100)  NOT NULL,
    homeTeam      VARCHAR(50)   NOT NULL,
    awayTeam      VARCHAR(50)   NOT NULL,
    homeScore     INT           NOT NULL,
    awayScore     INT           NOT NULL,
    CONSTRAINT pk_nbagames        PRIMARY KEY (gameID),
    CONSTRAINT ck_nba_homescore   CHECK (homeScore >= 0),
    CONSTRAINT ck_nba_awayscore   CHECK (awayScore >= 0),
    CONSTRAINT ck_nba_teams       CHECK (homeTeam <> awayTeam)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- ---------------------------------------------------------------------
-- GameParticipations
-- The PlayedIn M-N relationship between club members and NBA games:
-- one row per (member, game) pair, so PK = (memberID, gameID).
-- A member can play many games and a game has many members.
-- teamPlayedFor records which side of that game the member played for
-- (see the cross-table note in the file header).
-- ON DELETE CASCADE on both sides: if a member or a game is removed,
-- their participation rows go with it.
-- ---------------------------------------------------------------------
CREATE TABLE GameParticipations (
    memberID       INT           NOT NULL,
    gameID         INT           NOT NULL,
    teamPlayedFor  VARCHAR(50)   NOT NULL,
    points         INT           NOT NULL,
    details        VARCHAR(255),
    CONSTRAINT pk_gameparticipations PRIMARY KEY (memberID, gameID),
    CONSTRAINT fk_gp_member FOREIGN KEY (memberID)
        REFERENCES ClubMembers (memberID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_gp_game   FOREIGN KEY (gameID)
        REFERENCES NBA_Games (gameID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_gp_points CHECK (points >= 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =====================================================================
-- Data
-- Rows reference ClubMembers by memberID only (see 02_club_members.sql).
-- The roster is chosen so every dependent query returns at least 2 rows:
--   * ii / v (mine): majors (17+) with >= 1 game -> members 1,2,4,5,6,7,10
--   * vi  (Member 3): adults with games who are parents -> members 1,2,4
--     (Marc, Sophie, member 4) all have games.
--   * vii (Member 1): volunteer personnel who are active members with a
--     game -> members 5,6,10 (they match Personnel by SSN, are volunteer
--     coaches, and are active in Member 4's payments).
--   * i   (Member 1): games are spread over locations 1-5.
-- teamPlayedFor is always the homeTeam or awayTeam of that game; this
-- can't be a CHECK across tables, so it is enforced here by the data.
-- Minors (16, 18) play too, for realism; ii and v exclude them by age.
-- =====================================================================

INSERT INTO NBA_Games
  (gameID, gameDate, gameLocation, homeTeam, awayTeam, homeScore, awayScore) VALUES
  (1, '2025-11-15', 'Montréal',  'Raptors', 'Celtics',  101,  99),
  (2, '2025-12-03', 'Laval',     'Celtics', 'Knicks',    95, 110),
  (3, '2026-01-20', 'Longueuil', 'Lakers',  'Warriors', 120, 115),
  (4, '2026-02-10', 'Québec',    'Raptors', 'Heat',      88,  92),
  (5, '2026-03-05', 'Gatineau',  'Nets',    'Bucks',    105, 100),
  (6, '2026-03-22', 'Montréal',  'Raptors', 'Lakers',   112, 108),
  (7, '2026-04-02', 'Montréal',  'Raptors', 'Nets',      98, 102),
  (8, '2026-04-15', 'Laval',     'Knicks',  'Bucks',    110, 107),
  (9, '2026-04-28', 'Québec',    'Heat',    'Warriors',  99, 105),
  (10,'2026-05-10', 'Longueuil', 'Lakers',  'Celtics',  115, 111),
  (11,'2026-05-20', 'Gatineau',  'Nets',    'Raptors',  100,  96);

INSERT INTO GameParticipations
  (memberID, gameID, teamPlayedFor, points, details) VALUES
  -- member 1 (major, parent, loc 1): 3 games
  (1,  1, 'Raptors',  22, '22 pts, 6 reb'),
  (1,  4, 'Raptors',  18, '18 pts, 4 ast'),
  (1,  6, 'Raptors',  25, '25 pts, 5 reb, 7 ast'),
  -- member 2 (major, parent, loc 2): 2 games
  (2,  1, 'Celtics',  14, '14 pts, 8 reb'),
  (2,  2, 'Celtics',  20, '20 pts, 3 stl'),
  -- member 4 (major, parent, loc 5): 2 games
  (4,  5, 'Nets',     16, '16 pts, 10 reb'),
  (4,  1, 'Celtics',   9, '9 pts, 5 ast'),
  -- member 5 (major, volunteer, active, loc 1): 2 games
  (5,  1, 'Celtics',  11, '11 pts, 4 reb'),
  (5,  6, 'Lakers',   13, '13 pts, 6 ast'),
  -- member 6 (major, volunteer, active, loc 2): 2 games
  (6,  2, 'Knicks',   24, '24 pts, 2 blk'),
  (6,  3, 'Warriors', 19, '19 pts, 7 ast'),
  -- member 10 (major, volunteer, active, loc 3): 3 games
  (10, 3, 'Lakers',   30, '30 pts, 8 reb'),
  (10, 4, 'Heat',     15, '15 pts, 9 reb'),
  (10, 6, 'Lakers',   21, '21 pts, 5 ast'),
  -- member 7 (major, loc 4): 1 game
  (7,  4, 'Heat',     12, '12 pts, 3 stl'),
  -- minors (excluded from ii / v by age), for realism
  (16, 6, 'Lakers',    8, '8 pts, 2 reb'),
  (18, 4, 'Heat',      6, '6 pts, 4 reb'),
  -- participations in the added games 7-11 (so no game is empty)
  (1,  7, 'Raptors',  20, '20 pts, 5 ast'),
  (6,  7, 'Nets',     10, '10 pts, 5 ast'),
  (2,  8, 'Knicks',   17, '17 pts, 6 reb'),
  (10, 9, 'Warriors', 23, '23 pts, 4 ast'),
  (7,  9, 'Heat',      9, '9 pts, 2 stl'),
  (5, 10, 'Lakers',   12, '12 pts, 3 reb'),
  (4, 11, 'Nets',     14, '14 pts, 7 reb');
