-- ============================================================
-- Member 3 - Dexter Banoen Garde
-- Goes in shared script 2 (Views and Triggers).
-- Views: v_AnnualPayments, v_ActiveMembers, v_MemberStatus, v_NBAWins, v_SessionEmails
-- Order matters: v_ActiveMembers reads v_AnnualPayments, v_MemberStatus reads v_ActiveMembers,
-- and v_SessionEmails reads Ahmed's v_Assignments, so it must be created after it.
-- ============================================================


-- What each member paid for each membership year, and the fee for that year:
-- $100 for a member under 17 on January 1 of that year (a minor), $200 otherwise (a major).
-- totalPaid - annualFee, when positive, is the donation.
-- A year with no payment at all has no row here.
CREATE VIEW v_AnnualPayments AS
SELECT p.memberID, p.membershipYear, SUM(p.amount) AS totalPaid, 100.00 AS annualFee
FROM Payments p, ClubMembers c
WHERE p.memberID = c.memberID
	AND TIMESTAMPDIFF(YEAR, c.DOB, MAKEDATE(p.membershipYear, 1)) < 17
GROUP BY p.memberID, p.membershipYear
UNION
SELECT p.memberID, p.membershipYear, SUM(p.amount) AS totalPaid, 200.00 AS annualFee
FROM Payments p, ClubMembers c
WHERE p.memberID = c.memberID
	AND TIMESTAMPDIFF(YEAR, c.DOB, MAKEDATE(p.membershipYear, 1)) >= 17
GROUP BY p.memberID, p.membershipYear;

-- Members who are active today. A member is active when the fee of the previous year was fully paid.
-- A member who joined this year has no previous year, so this year's fee is checked instead.
-- KEEP IDENTICAL to the rule written out in trigger 5 (Azmain) and trigger 9 (Ahmed):
-- triggers read the base tables, not this view, so the rule exists in three places.
CREATE VIEW v_ActiveMembers AS
SELECT a.memberID
FROM v_AnnualPayments a
WHERE a.membershipYear = YEAR(CURDATE()) - 1
	AND a.totalPaid >= a.annualFee
UNION
SELECT a.memberID
FROM v_AnnualPayments a, ClubMembers c
WHERE a.memberID = c.memberID
	AND YEAR(c.joinDate) = YEAR(CURDATE())
	AND a.membershipYear = YEAR(CURDATE())
	AND a.totalPaid >= a.annualFee;

-- Status of every club member: 'Active' or 'Inactive'. Every member has exactly one row.
CREATE VIEW v_MemberStatus AS
SELECT memberID, 'Active' AS status
FROM ClubMembers
WHERE memberID IN (SELECT memberID FROM v_ActiveMembers)
UNION
SELECT memberID, 'Inactive' AS status
FROM ClubMembers
WHERE memberID NOT IN (SELECT memberID FROM v_ActiveMembers);

-- NBA games each member won: the team the member played for scored more than the other team.
-- One row per (member, game won).
CREATE VIEW v_NBAWins AS
SELECT p.memberID, p.gameID
FROM GameParticipations p, NBA_Games g
WHERE p.gameID = g.gameID
	AND ((p.teamPlayedFor = g.homeTeam AND g.homeScore > g.awayScore)
		OR (p.teamPlayedFor = g.awayTeam AND g.awayScore > g.homeScore));

-- The email each assigned player receives about a session.
-- sender   = name of the location of the player's team
-- receiver = the player's email address
-- subject  = team name, day, date, time and kind of session, e.g. "Montréal Boys Saturday 21-November-2026 10:00 AM training session"
-- body     = player's name and role, kind of session, head coach's name and email, address
CREATE VIEW v_SessionEmails AS
SELECT a.sessionID, a.sessionDate, l.name AS sender, c.email AS receiver,
	CONCAT(a.teamName, ' ', DATE_FORMAT(a.sessionDate, '%W %e-%M-%Y'), ' ',
		TIME_FORMAT(a.startTime, '%l:%i %p'), ' ', LOWER(a.type), ' session') AS subject,
	CONCAT('Hello ', c.firstName, ' ', c.lastName, ', you play ', a.role,
		' in a ', LOWER(a.type), ' session. Head coach: ', p.firstName, ' ', p.lastName,
		', ', p.email, '. Address: ', a.address, '.') AS body
FROM v_Assignments a, ClubMembers c, Locations l, Personnel p
WHERE c.memberID = a.memberID
	AND l.locationID = a.locationID
	AND p.personnelID = a.headCoachID;
