-- ============================================================
-- Member 3 - Dexter Banoen Garde
-- Goes in shared script 3 (Data): sections 5, 6 and 8.
-- Needs the ClubMembers rows first (and, for the email log, the sessions, formations and players).
-- The cases are chosen so every rule shows up: exact fee, donation, installments (2, 3 and the
-- maximum 4), a year paid in advance, a partly paid year and an unpaid year (both -> inactive).
-- ============================================================

-- 5. Payments
-- -----------
INSERT INTO Payments (memberID, paymentDate, amount, method, membershipYear, installmentNum) VALUES
	-- 1 Marc Tremblay (major): exact fee every year; 2025 paid in two parts, one in Dec. 2024
	(1, '2023-03-10', 200.00, 'Debit', 2023, 1),
	(1, '2024-01-03', 200.00, 'Credit', 2024, 1),
	(1, '2024-12-18', 100.00, 'Cash', 2025, 1),
	(1, '2025-01-20', 100.00, 'Debit', 2025, 2),
	(1, '2026-01-03', 200.00, 'Credit', 2026, 1),
	-- 2 Sophie Gagnon (major): $250 for 2025 = $50 donation
	(2, '2023-04-12', 200.00, 'Cash', 2023, 1),
	(2, '2024-01-04', 200.00, 'Debit', 2024, 1),
	(2, '2025-01-12', 250.00, 'Credit', 2025, 1),
	(2, '2026-01-04', 200.00, 'Cash', 2026, 1),
	-- 3 Karim Haddad (major): only $150 of $200 for 2025 -> inactive
	(3, '2023-06-08', 200.00, 'Debit', 2023, 1),
	(3, '2024-01-05', 200.00, 'Credit', 2024, 1),
	(3, '2025-02-03', 150.00, 'Cash', 2025, 1),
	(3, '2026-01-05', 200.00, 'Debit', 2026, 1),
	-- 4 Hassan Benali (major): 2025 paid in the maximum 4 installments
	(4, '2023-05-19', 200.00, 'Credit', 2023, 1),
	(4, '2024-01-06', 200.00, 'Cash', 2024, 1),
	(4, '2025-01-15', 50.00, 'Debit', 2025, 1),
	(4, '2025-03-15', 50.00, 'Credit', 2025, 2),
	(4, '2025-05-15', 50.00, 'Cash', 2025, 3),
	(4, '2025-07-15', 50.00, 'Debit', 2025, 4),
	(4, '2026-01-06', 200.00, 'Credit', 2026, 1),
	-- 5 Nadia Rahman (major): exact fee (volunteer coach, must stay active)
	(5, '2024-03-08', 200.00, 'Cash', 2024, 1),
	(5, '2025-01-09', 200.00, 'Debit', 2025, 1),
	(5, '2026-01-07', 200.00, 'Credit', 2026, 1),
	-- 6 Omar Khan (major): $250 for 2025 = $50 donation (volunteer coach)
	(6, '2024-04-07', 200.00, 'Cash', 2024, 1),
	(6, '2025-01-10', 250.00, 'Debit', 2025, 1),
	(6, '2026-01-08', 200.00, 'Credit', 2026, 1),
	-- 7 Amelia Chen (major): paid 2023, 2024 and 2026 but nothing for 2025 -> inactive
	(7, '2023-05-14', 200.00, 'Cash', 2023, 1),
	(7, '2024-01-09', 200.00, 'Debit', 2024, 1),
	(7, '2026-01-09', 200.00, 'Credit', 2026, 1),
	-- 8 Antoine Gagnon (major): $300 for 2024 = $100 donation, exact fee since
	(8, '2023-02-04', 200.00, 'Cash', 2023, 1),
	(8, '2024-01-10', 300.00, 'Debit', 2024, 1),
	(8, '2025-01-22', 200.00, 'Credit', 2025, 1),
	(8, '2026-01-10', 200.00, 'Cash', 2026, 1),
	-- 9 Sarah Wilson (major): only $120 of $200 for 2025 -> inactive
	(9, '2024-01-16', 200.00, 'Debit', 2024, 1),
	(9, '2025-02-14', 120.00, 'Credit', 2025, 1),
	(9, '2026-01-11', 200.00, 'Cash', 2026, 1),
	-- 10 Victor Morin (major): exact fee (volunteer coach, must stay active)
	(10, '2023-06-07', 200.00, 'Debit', 2023, 1),
	(10, '2024-01-12', 200.00, 'Credit', 2024, 1),
	(10, '2025-01-04', 200.00, 'Cash', 2025, 1),
	(10, '2026-01-12', 200.00, 'Debit', 2026, 1),
	-- 11 Léa Tremblay (minor): $130 for 2025 = $30 donation; paid partly in Dec. 2024
	(11, '2023-08-20', 100.00, 'Credit', 2023, 1),
	(11, '2024-01-13', 100.00, 'Cash', 2024, 1),
	(11, '2024-12-15', 60.00, 'Debit', 2025, 1),
	(11, '2025-02-10', 70.00, 'Credit', 2025, 2),
	(11, '2026-01-13', 100.00, 'Cash', 2026, 1),
	-- 12 Noah Tremblay (minor): exact fee
	(12, '2024-03-24', 100.00, 'Debit', 2024, 1),
	(12, '2025-01-25', 100.00, 'Credit', 2025, 1),
	(12, '2026-01-14', 100.00, 'Cash', 2026, 1),
	-- 13 Emma Gagnon (minor): $125 for 2025 in 3 installments = $25 donation
	(13, '2024-06-30', 100.00, 'Debit', 2024, 1),
	(13, '2025-01-17', 50.00, 'Credit', 2025, 1),
	(13, '2025-04-17', 50.00, 'Cash', 2025, 2),
	(13, '2025-09-17', 25.00, 'Debit', 2025, 3),
	(13, '2026-01-15', 100.00, 'Credit', 2026, 1),
	-- 14 Yasmine Haddad (minor): exact fee
	(14, '2024-01-17', 100.00, 'Cash', 2024, 1),
	(14, '2025-01-30', 100.00, 'Debit', 2025, 1),
	(14, '2026-01-16', 100.00, 'Credit', 2026, 1),
	-- 15 Adam Benali (minor): only $80 of $100 for 2025 -> inactive
	(15, '2024-09-24', 100.00, 'Cash', 2024, 1),
	(15, '2025-03-03', 80.00, 'Debit', 2025, 1),
	(15, '2026-01-17', 100.00, 'Credit', 2026, 1),
	-- 16 Olivier Roy (minor): exact fee
	(16, '2023-04-10', 100.00, 'Cash', 2023, 1),
	(16, '2024-01-18', 100.00, 'Debit', 2024, 1),
	(16, '2025-01-08', 100.00, 'Credit', 2025, 1),
	(16, '2026-01-18', 100.00, 'Cash', 2026, 1),
	-- 17 Chloé Lavoie (minor): exact fee
	(17, '2024-07-01', 100.00, 'Debit', 2024, 1),
	(17, '2025-02-01', 100.00, 'Credit', 2025, 1),
	(17, '2026-01-19', 100.00, 'Cash', 2026, 1),
	-- 18 Thomas Bouchard (minor): $150 for 2025 = $50 donation
	(18, '2023-10-06', 100.00, 'Debit', 2023, 1),
	(18, '2024-01-20', 100.00, 'Credit', 2024, 1),
	(18, '2025-01-11', 150.00, 'Cash', 2025, 1),
	(18, '2026-01-20', 100.00, 'Debit', 2026, 1),
	-- 19 Liam Nguyen (minor): exact fee
	(19, '2024-05-06', 100.00, 'Credit', 2024, 1),
	(19, '2025-01-19', 100.00, 'Cash', 2025, 1),
	(19, '2026-01-21', 100.00, 'Debit', 2026, 1),
	-- 20 Zoé Côté (minor): $120 for 2025 = $20 donation
	(20, '2024-03-20', 100.00, 'Credit', 2024, 1),
	(20, '2025-01-28', 120.00, 'Cash', 2025, 1),
	(20, '2026-01-22', 100.00, 'Debit', 2026, 1),
	-- 21 Sarah Pelletier (minor): nothing for 2025 -> inactive
	(21, '2024-03-01', 100.00, 'Credit', 2024, 1),
	-- 22 Gabriel Morin (minor): joined May 2025, paid on joining
	(22, '2025-05-20', 100.00, 'Cash', 2025, 1),
	(22, '2026-01-24', 100.00, 'Debit', 2026, 1),
	-- 23 Elena Morin (major): exact fee
	(23, '2024-03-01', 200.00, 'Credit', 2024, 1),
	(23, '2025-01-06', 200.00, 'Cash', 2025, 1),
	(23, '2026-01-25', 200.00, 'Debit', 2026, 1),
	-- 24 Clara Bouchard (major): exact fee
	(24, '2024-08-18', 200.00, 'Credit', 2024, 1),
	(24, '2025-01-13', 200.00, 'Cash', 2025, 1),
	(24, '2026-01-26', 200.00, 'Debit', 2026, 1),
	-- 25 Élodie Mercier (major): $300 for 2025 = $100 donation
	(25, '2024-06-04', 200.00, 'Credit', 2024, 1),
	(25, '2025-01-21', 300.00, 'Cash', 2025, 1),
	(25, '2026-01-27', 200.00, 'Debit', 2026, 1),
	-- 26 Mathis Perron (major): exact fee
	(26, '2023-04-21', 200.00, 'Credit', 2023, 1),
	(26, '2024-01-28', 200.00, 'Cash', 2024, 1),
	(26, '2025-01-07', 200.00, 'Debit', 2025, 1),
	(26, '2026-01-28', 200.00, 'Credit', 2026, 1),
	-- 27 Daniel Beaulieu (major): joined 2024, stopped paying -> inactive
	(27, '2024-07-11', 200.00, 'Cash', 2024, 1),
	-- 28 Ethan Lefebvre (minor): exact fee every year
	(28, '2024-09-07', 100.00, 'Cash', 2024, 1),
	(28, '2025-01-13', 100.00, 'Debit', 2025, 1),
	(28, '2026-01-13', 100.00, 'Credit', 2026, 1),
	-- 29 Lucas Girard (minor): $150 for 2024 = $50 donation
	(29, '2021-09-04', 100.00, 'Debit', 2021, 1),
	(29, '2022-01-14', 100.00, 'Credit', 2022, 1),
	(29, '2023-01-14', 100.00, 'Cash', 2023, 1),
	(29, '2024-01-14', 150.00, 'Debit', 2024, 1),
	(29, '2025-01-14', 100.00, 'Credit', 2025, 1),
	(29, '2026-01-14', 100.00, 'Cash', 2026, 1),
	-- 30 Nathan Poirier (minor): exact fee every year
	(30, '2024-09-07', 100.00, 'Credit', 2024, 1),
	(30, '2025-01-15', 100.00, 'Cash', 2025, 1),
	(30, '2026-01-15', 100.00, 'Debit', 2026, 1),
	-- 31 Jade Lefebvre (minor): exact fee every year
	(31, '2024-09-07', 100.00, 'Cash', 2024, 1),
	(31, '2025-01-16', 100.00, 'Debit', 2025, 1),
	(31, '2026-01-16', 100.00, 'Credit', 2026, 1),
	-- 32 Alice Morel (minor): exact fee every year
	(32, '2025-09-01', 100.00, 'Credit', 2025, 1),
	(32, '2026-01-17', 100.00, 'Cash', 2026, 1),
	-- 33 Rosalie Dubé (minor): exact fee every year
	(33, '2024-09-07', 100.00, 'Credit', 2024, 1),
	(33, '2025-01-18', 100.00, 'Cash', 2025, 1),
	(33, '2026-01-18', 100.00, 'Debit', 2026, 1),
	-- 34 Camille Fortier (minor): 2025 paid in 2 installments
	(34, '2021-09-10', 100.00, 'Cash', 2021, 1),
	(34, '2022-01-19', 100.00, 'Debit', 2022, 1),
	(34, '2023-01-19', 100.00, 'Credit', 2023, 1),
	(34, '2024-01-19', 100.00, 'Cash', 2024, 1),
	(34, '2025-01-19', 50.00, 'Debit', 2025, 1),
	(34, '2025-03-19', 50.00, 'Credit', 2025, 2),
	(34, '2026-01-19', 100.00, 'Credit', 2026, 1),
	-- 35 Maya Bergeron (minor): exact fee every year
	(35, '2024-09-10', 100.00, 'Debit', 2024, 1),
	(35, '2025-01-20', 100.00, 'Credit', 2025, 1),
	(35, '2026-01-20', 100.00, 'Cash', 2026, 1),
	-- 36 Inès Caron (minor): exact fee every year
	(36, '2024-09-10', 100.00, 'Credit', 2024, 1),
	(36, '2025-01-21', 100.00, 'Cash', 2025, 1),
	(36, '2026-01-21', 100.00, 'Debit', 2026, 1),
	-- 37 Florence Gauthier (minor): exact fee every year
	(37, '2023-09-12', 100.00, 'Credit', 2023, 1),
	(37, '2024-01-22', 100.00, 'Cash', 2024, 1),
	(37, '2025-01-22', 100.00, 'Debit', 2025, 1),
	(37, '2026-01-22', 100.00, 'Credit', 2026, 1),
	-- 38 William Bergeron (minor): 2026 paid in 2 installments
	(38, '2024-09-10', 100.00, 'Debit', 2024, 1),
	(38, '2025-01-23', 100.00, 'Credit', 2025, 1),
	(38, '2026-01-23', 60.00, 'Cash', 2026, 1),
	(38, '2026-03-23', 40.00, 'Debit', 2026, 2),
	-- 39 Samuel Caron (minor): exact fee every year
	(39, '2024-09-10', 100.00, 'Credit', 2024, 1),
	(39, '2025-01-24', 100.00, 'Cash', 2025, 1),
	(39, '2026-01-24', 100.00, 'Debit', 2026, 1),
	-- 40 Juliette Lambert (major): $220 for 2025 = $20 donation
	(40, '2023-09-15', 200.00, 'Credit', 2023, 1),
	(40, '2024-01-05', 200.00, 'Cash', 2024, 1),
	(40, '2025-01-05', 220.00, 'Debit', 2025, 1),
	(40, '2026-01-05', 200.00, 'Credit', 2026, 1),
	-- 41 Océane Simard (major): exact fee every year
	(41, '2024-02-01', 200.00, 'Debit', 2024, 1),
	(41, '2025-01-06', 200.00, 'Credit', 2025, 1),
	(41, '2026-01-06', 200.00, 'Cash', 2026, 1),
	-- 42 Béatrice Lévesque (major): exact fee every year
	(42, '2025-01-15', 200.00, 'Cash', 2025, 1),
	(42, '2026-01-07', 200.00, 'Debit', 2026, 1),
	-- 43 Laurence Pelletier (major): 2025 paid in the maximum 4 installments
	(43, '2025-02-01', 50.00, 'Debit', 2025, 1),
	(43, '2025-04-02', 50.00, 'Credit', 2025, 2),
	(43, '2025-06-01', 50.00, 'Cash', 2025, 3),
	(43, '2025-07-31', 50.00, 'Debit', 2025, 4),
	(43, '2026-01-08', 200.00, 'Credit', 2026, 1),
	-- 44 Mégane Cloutier (minor): exact fee every year
	(44, '2025-02-01', 100.00, 'Credit', 2025, 1),
	(44, '2026-01-09', 100.00, 'Cash', 2026, 1),
	-- 45 Xavier Cloutier (minor): only $60 of $100 for 2025 -> inactive
	(45, '2025-02-01', 60.00, 'Cash', 2025, 1),
	(45, '2026-01-10', 100.00, 'Debit', 2026, 1),
	-- 46 Sandrine Hébert (major): $250 for 2026 = $50 donation
	(46, '2025-03-01', 200.00, 'Debit', 2025, 1),
	(46, '2026-01-11', 250.00, 'Credit', 2026, 1),
	-- 47 Anaïs Leclerc (major): nothing yet for 2026
	(47, '2025-03-01', 200.00, 'Credit', 2025, 1);

-- 6. NBA games
-- ------------
INSERT INTO NBA_Games (gameID, gameDate, gameLocation, homeTeam, awayTeam, homeScore, awayScore) VALUES
	(1, '2025-11-15', 'Montréal', 'Raptors', 'Celtics', 101, 99),
	(2, '2025-12-03', 'Laval', 'Celtics', 'Knicks', 95, 110),
	(3, '2026-01-20', 'Longueuil', 'Lakers', 'Warriors', 120, 115),
	(4, '2026-02-10', 'Québec', 'Raptors', 'Heat', 88, 92),
	(5, '2026-03-05', 'Gatineau', 'Nets', 'Bucks', 105, 100),
	(6, '2026-03-22', 'Montréal', 'Raptors', 'Lakers', 112, 108),
	(7, '2026-04-02', 'Montréal', 'Raptors', 'Nets', 98, 102),
	(8, '2026-04-15', 'Laval', 'Knicks', 'Bucks', 110, 107),
	(9, '2026-04-28', 'Québec', 'Heat', 'Warriors', 99, 105),
	(10, '2026-05-10', 'Longueuil', 'Lakers', 'Celtics', 115, 111),
	(11, '2026-05-20', 'Gatineau', 'Nets', 'Raptors', 100, 96),
	(12, '2026-06-06', 'Montréal', 'Raptors', 'Bucks', 108, 99),
	(13, '2026-06-20', 'Laval', 'Knicks', 'Heat', 97, 103),
	(14, '2026-09-19', 'Laval', 'Celtics', 'Nets', 111, 104),
	(15, '2026-10-03', 'Montréal', 'Lakers', 'Raptors', 99, 105);

-- Who played in which game. Montréal ends up with 7 members who won a game and Laval with 5,
-- so query 11 (locations with at least five winners) returns both.
INSERT INTO GameParticipations (memberID, gameID, teamPlayedFor, points, details) VALUES
	-- member 1 (major, Montréal)
	(1, 1, 'Raptors', 22, '22 pts, 6 reb'),
	(1, 4, 'Raptors', 18, '18 pts, 4 ast'),
	(1, 6, 'Raptors', 25, '25 pts, 5 reb, 7 ast'),
	-- member 2 (major, Laval)
	(2, 1, 'Celtics', 14, '14 pts, 8 reb'),
	(2, 2, 'Celtics', 20, '20 pts, 3 stl'),
	-- member 4 (major, Gatineau)
	(4, 5, 'Nets', 16, '16 pts, 10 reb'),
	(4, 1, 'Celtics', 9, '9 pts, 5 ast'),
	-- member 5 (major, Montréal)
	(5, 1, 'Celtics', 11, '11 pts, 4 reb'),
	(5, 6, 'Lakers', 13, '13 pts, 6 ast'),
	-- member 6 (major, Laval)
	(6, 2, 'Knicks', 24, '24 pts, 2 blk'),
	(6, 3, 'Warriors', 19, '19 pts, 7 ast'),
	-- member 10 (major, Longueuil)
	(10, 3, 'Lakers', 30, '30 pts, 8 reb'),
	(10, 4, 'Heat', 15, '15 pts, 9 reb'),
	(10, 6, 'Lakers', 21, '21 pts, 5 ast'),
	-- member 7 (major, Québec)
	(7, 4, 'Heat', 12, '12 pts, 3 stl'),
	-- two minors
	(16, 6, 'Lakers', 8, '8 pts, 2 reb'),
	(18, 4, 'Heat', 6, '6 pts, 4 reb'),
	-- games 7 to 11 (so no game is empty)
	(1, 7, 'Raptors', 20, '20 pts, 5 ast'),
	(6, 7, 'Nets', 10, '10 pts, 5 ast'),
	(2, 8, 'Knicks', 17, '17 pts, 6 reb'),
	(10, 9, 'Warriors', 23, '23 pts, 4 ast'),
	(7, 9, 'Heat', 9, '9 pts, 2 stl'),
	(5, 10, 'Lakers', 12, '12 pts, 3 reb'),
	(4, 11, 'Nets', 14, '14 pts, 7 reb'),
	-- games 12 to 15
	(16, 12, 'Raptors', 10, '10 pts, 3 reb'),
	(29, 12, 'Raptors', 14, '14 pts, 4 ast'),
	(28, 12, 'Raptors', 6, '6 pts, 2 stl'),
	(32, 12, 'Bucks', 6, '6 pts, 1 reb'),
	(31, 12, 'Bucks', 4, '4 pts, 2 ast'),
	(11, 13, 'Heat', 8, '8 pts, 3 ast'),
	(35, 13, 'Heat', 12, '12 pts, 5 reb'),
	(13, 13, 'Knicks', 5, '5 pts, 2 reb'),
	(8, 14, 'Celtics', 18, '18 pts, 7 reb'),
	(26, 14, 'Celtics', 4, '4 pts, 1 ast'),
	(4, 14, 'Nets', 11, '11 pts, 6 reb'),
	(34, 15, 'Raptors', 9, '9 pts, 4 reb'),
	(1, 15, 'Raptors', 16, '16 pts, 5 ast'),
	(29, 15, 'Raptors', 7, '7 pts, 2 reb'),
	(27, 15, 'Lakers', 13, '13 pts, 3 reb');

-- 8. Email log
-- ------------
-- One past week of emails: what the system generated on Sunday July 19, 2026 for the sessions of
-- July 20 to July 26, 2026. It is the statement the weekly event runs, with that Sunday in place of today.
-- This must run AFTER the sessions, formations and players are inserted (it reads them through the view).
INSERT INTO EmailLog (emailDate, sender, receiver, subject, body)
SELECT '2026-07-19', v.sender, v.receiver, v.subject, LEFT(v.body, 100)
FROM v_SessionEmails v
WHERE v.sessionDate > '2026-07-19'
	AND v.sessionDate <= DATE_ADD('2026-07-19', INTERVAL 7 DAY)
ORDER BY v.sessionDate, v.sessionID, v.receiver;
