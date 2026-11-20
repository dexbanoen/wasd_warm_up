-- ============================================================
-- Member 3 - Dexter Banoen Garde
-- Goes in shared script 5 (Queries): queries 11 and 14.
-- The same SQL is in the web site (queries_data.php), so a change here must be copied there.
-- ============================================================


-- Query 11
-- --------
-- Locations that have at least five different club members who played in an NBA game and won it:
-- location name, the member's first-name and last-name, number of NBA games the member won.
-- Sorted by number of games won, descending.
--
-- How it works:
--   v_NBAWins has one row per (member, game won), so COUNT(*) per member = games won.
--   The subquery keeps only the locations where 5 or more different members have a win.
--   A member counts for the location he or she is at now (v_CurrentLocation).
-- Expected on the sample data: 12 rows (7 members of Montréal, 5 members of Laval).
SELECT l.name AS locationName, c.firstName, c.lastName, COUNT(*) AS numGamesWon
FROM ClubMembers c, v_CurrentLocation cl, Locations l, v_NBAWins w
WHERE cl.memberID = c.memberID
	AND l.locationID = cl.locationID
	AND w.memberID = c.memberID
	AND cl.locationID IN (
		SELECT cl2.locationID
		FROM v_CurrentLocation cl2, v_NBAWins w2
		WHERE w2.memberID = cl2.memberID
		GROUP BY cl2.locationID
		HAVING COUNT(DISTINCT cl2.memberID) >= 5
	)
GROUP BY l.name, c.memberID, c.firstName, c.lastName
ORDER BY numGamesWon DESC, locationName ASC, c.lastName ASC;


-- Query 14
-- --------
-- All members who played in at least one NBA game: first-name, last-name, height, age, start date
-- with the club, current location, current status, number of NBA games played, number won.
-- Sorted in descending order by number of NBA games won, then by height, then by location name.
--
-- How it works:
--   The IN subquery keeps the members who have at least one row in GameParticipations.
--   The two counts are separate subqueries, so a member with no win still appears, with 0.
--   Height is the latest measurement, status comes from v_MemberStatus (fee of last year paid or not).
-- Expected on the sample data: 20 rows.
SELECT c.firstName, c.lastName, lm.heightCm AS height,
	TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) AS age,
	c.joinDate AS startDate, l.name AS locationName, st.status,
	(SELECT COUNT(*)
		FROM GameParticipations gp
		WHERE gp.memberID = c.memberID) AS numNBAGames,
	(SELECT COUNT(*)
		FROM v_NBAWins w
		WHERE w.memberID = c.memberID) AS numNBAGamesWon
FROM ClubMembers c, v_CurrentLocation cl, Locations l, v_LatestMeasurement lm, v_MemberStatus st
WHERE cl.memberID = c.memberID
	AND l.locationID = cl.locationID
	AND lm.memberID = c.memberID
	AND st.memberID = c.memberID
	AND c.memberID IN (
		SELECT gp.memberID
		FROM GameParticipations gp
	)
ORDER BY numNBAGamesWon DESC, height DESC, locationName DESC;
