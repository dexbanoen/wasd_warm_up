-- Query 8
-- -------
SELECT l.name AS locationName, c.firstName, c.lastName, lm.heightCm AS height,
	TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) AS age
FROM ClubMembers c, v_CurrentLocation cl, Locations l, v_LatestMeasurement lm
WHERE cl.memberID = c.memberID
	AND l.locationID = cl.locationID
	AND lm.memberID = c.memberID
	AND TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) < 17
	AND lm.heightCm >= ALL (
		SELECT lm2.heightCm
		FROM ClubMembers c2, v_CurrentLocation cl2, v_LatestMeasurement lm2
		WHERE cl2.memberID = c2.memberID
			AND lm2.memberID = c2.memberID
			AND cl2.locationID = cl.locationID
			AND TIMESTAMPDIFF(YEAR, c2.DOB, CURDATE()) < 17
	)
ORDER BY age ASC;


-- Query 9
-- -------
SELECT c.firstName, c.lastName, l.name AS locationName
FROM ClubMembers c, v_CurrentLocation cl, Locations l
WHERE cl.memberID = c.memberID
	AND l.locationID = cl.locationID
	AND c.memberID NOT IN (
		SELECT mh.memberID
		FROM MemberHobbies mh, Hobbies h
		WHERE h.hobbyID = mh.hobbyID
			AND h.name = 'Basketball'
	)
ORDER BY locationName ASC, c.firstName ASC, c.lastName ASC;


-- Query 10
-- --------
SELECT t.locationName, t.numGirls, t.numBoys
FROM (
	SELECT l.name AS locationName,
		(SELECT COUNT(*)
			FROM ClubMembers c, v_CurrentLocation cl
			WHERE cl.memberID = c.memberID
				AND cl.locationID = l.locationID
				AND c.gender = 'F') AS numGirls,
		(SELECT COUNT(*)
			FROM ClubMembers c, v_CurrentLocation cl
			WHERE cl.memberID = c.memberID
				AND cl.locationID = l.locationID
				AND c.gender = 'M') AS numBoys
	FROM Locations l
) AS t
WHERE t.numGirls > t.numBoys
ORDER BY t.numGirls ASC, t.locationName ASC;


-- Query 11
-- --------
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


-- Query 12
-- --------
SELECT f.firstName, f.lastName, f.phone, l.name AS locationName
FROM FamilyMembers f, Locations l
WHERE l.locationID = f.locationID
	AND f.familyMemberID NOT IN (
		SELECT g.familyMemberID
		FROM MinorGuardians g
	)
ORDER BY locationName ASC, f.firstName ASC, f.lastName ASC;


-- Query 13
-- --------
SELECT c.firstName, c.lastName, l.name AS locationName, ml.startDate, ml.endDate,
	(SELECT COUNT(*)
		FROM v_Assignments a
		WHERE a.memberID = c.memberID
			AND a.type = 'Game'
			AND a.sessionDate >= ml.startDate
			AND (ml.endDate IS NULL OR a.sessionDate <= ml.endDate)
			AND a.sessionDate <= CURDATE()) AS numGames,
	(SELECT COUNT(*)
		FROM v_Assignments a
		WHERE a.memberID = c.memberID
			AND a.type = 'Training'
			AND a.sessionDate >= ml.startDate
			AND (ml.endDate IS NULL OR a.sessionDate <= ml.endDate)
			AND a.sessionDate <= CURDATE()) AS numTrainingSessions,
	(SELECT COUNT(*)
		FROM GameParticipations gp
		WHERE gp.memberID = c.memberID) AS numNBAGames,
	(SELECT COUNT(*)
		FROM v_NBAWins w
		WHERE w.memberID = c.memberID) AS numNBAGamesWon,
	st.status
FROM ClubMembers c, MemberLocations ml, Locations l, v_MemberStatus st
WHERE ml.memberID = c.memberID
	AND l.locationID = ml.locationID
	AND st.memberID = c.memberID
	AND c.memberID = 29
ORDER BY ml.startDate ASC;


-- Query 14
-- --------
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


-- Query 15
-- --------
SELECT l.name AS locationName, l.type, pc.city, pc.province, l.maxCapacity,
	m.firstName AS managerFirstName, m.lastName AS managerLastName,
	(SELECT COUNT(*)
		FROM PersonnelAssignments pa
		WHERE pa.locationID = l.locationID
			AND pa.endDate IS NULL
			AND pa.mandate = 'Salaried') AS numSalaried,
	(SELECT COUNT(*)
		FROM PersonnelAssignments pa
		WHERE pa.locationID = l.locationID
			AND pa.endDate IS NULL
			AND pa.mandate = 'Volunteer') AS numVolunteers,
	(SELECT COUNT(*)
		FROM ClubMembers c, v_CurrentLocation cl, v_MemberStatus st
		WHERE cl.memberID = c.memberID
			AND st.memberID = c.memberID
			AND cl.locationID = l.locationID
			AND st.status = 'Active'
			AND TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) < 17) AS numActiveMinors,
	(SELECT COUNT(*)
		FROM ClubMembers c, v_CurrentLocation cl, v_MemberStatus st
		WHERE cl.memberID = c.memberID
			AND st.memberID = c.memberID
			AND cl.locationID = l.locationID
			AND st.status = 'Active'
			AND TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) >= 17) AS numActiveMajors,
	(SELECT COUNT(*)
		FROM ClubMembers c, v_CurrentLocation cl, v_MemberStatus st
		WHERE cl.memberID = c.memberID
			AND st.memberID = c.memberID
			AND cl.locationID = l.locationID
			AND st.status = 'Inactive'
			AND TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) < 17) AS numInactiveMinors,
	(SELECT COUNT(*)
		FROM ClubMembers c, v_CurrentLocation cl, v_MemberStatus st
		WHERE cl.memberID = c.memberID
			AND st.memberID = c.memberID
			AND cl.locationID = l.locationID
			AND st.status = 'Inactive'
			AND TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) >= 17) AS numInactiveMajors,
	(SELECT COUNT(DISTINCT gp.memberID)
		FROM GameParticipations gp, v_CurrentLocation cl
		WHERE cl.memberID = gp.memberID
			AND cl.locationID = l.locationID) AS numNBAPlayers,
	(SELECT COUNT(DISTINCT w.memberID)
		FROM v_NBAWins w, v_CurrentLocation cl
		WHERE cl.memberID = w.memberID
			AND cl.locationID = l.locationID) AS numNBAWinners
FROM Locations l
	JOIN PostalCodes pc ON pc.postalCode = l.postalCode
	LEFT OUTER JOIN (
		SELECT pa.locationID, p.firstName, p.lastName
		FROM PersonnelAssignments pa, Personnel p
		WHERE p.personnelID = pa.personnelID
			AND pa.endDate IS NULL
			AND pa.title IN ('General Manager', 'Manager')
	) AS m
		ON m.locationID = l.locationID
ORDER BY l.name ASC;


-- Query 16
-- --------
SELECT c.firstName, c.lastName, a.sessionDate, a.startTime, a.address
FROM ClubMembers c, v_Assignments a
WHERE a.memberID = c.memberID
	AND a.type = 'Game'
	AND a.locationID = 1
	AND a.sessionDate >= '2026-07-21'
	AND a.sessionDate <= '2026-07-31'
	AND 2 <= (
		SELECT COUNT(*)
		FROM v_Assignments a2
		WHERE a2.memberID = a.memberID
			AND a2.type = 'Game'
			AND a2.sessionDate = a.sessionDate
	)
ORDER BY c.lastName ASC, c.firstName ASC, a.sessionDate ASC, a.startTime ASC;


-- Query 17
-- --------
SELECT f.firstName AS familyFirstName, f.lastName AS familyLastName,
	c.memberID, c.firstName, c.lastName, c.DOB, lm.heightCm AS height,
	(SELECT COUNT(*)
		FROM GameParticipations gp
		WHERE gp.memberID = c.memberID) AS numNBAGames,
	(SELECT COUNT(*)
		FROM v_NBAWins w
		WHERE w.memberID = c.memberID) AS numNBAGamesWon,
	g.relationship
FROM FamilyMembers f, MinorGuardians g, ClubMembers c, v_LatestMeasurement lm
WHERE g.familyMemberID = f.familyMemberID
	AND c.memberID = g.memberID
	AND lm.memberID = c.memberID
	AND c.memberID IN (
		SELECT gp.memberID
		FROM GameParticipations gp
	)
	AND f.familyMemberID IN (
		SELECT g2.familyMemberID
		FROM MinorGuardians g2, v_NBAWins w
		WHERE w.memberID = g2.memberID
	)
ORDER BY numNBAGamesWon DESC, familyLastName ASC, c.memberID ASC;


-- Query 18
-- --------
SELECT l.name AS locationName, c.firstName, c.lastName, c.memberID,
	TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) AS age,
	lm.heightCm AS height, COUNT(*) AS numGames
FROM ClubMembers c, v_CurrentLocation cl, Locations l, v_LatestMeasurement lm, v_Assignments a
WHERE cl.memberID = c.memberID
	AND l.locationID = cl.locationID
	AND lm.memberID = c.memberID
	AND a.memberID = c.memberID
	AND a.type = 'Game'
	AND c.memberID NOT IN (
		SELECT a2.memberID
		FROM v_Assignments a2
		WHERE a2.type = 'Training'
	)
GROUP BY l.name, c.memberID, c.firstName, c.lastName, c.DOB, lm.heightCm
ORDER BY locationName ASC, numGames ASC;


-- Query 19
-- --------
SELECT l.name AS locationName, c.firstName, c.lastName, c.memberID,
	TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) AS age,
	lm.heightCm AS height, COUNT(*) AS numSessions
FROM ClubMembers c, v_CurrentLocation cl, Locations l, v_LatestMeasurement lm, v_Assignments a
WHERE cl.memberID = c.memberID
	AND l.locationID = cl.locationID
	AND lm.memberID = c.memberID
	AND a.memberID = c.memberID
	AND a.sessionDate >= '2026-07-01'
	AND a.sessionDate <= '2026-09-30'
GROUP BY l.name, c.memberID, c.firstName, c.lastName, c.DOB, lm.heightCm
HAVING COUNT(DISTINCT a.role) = 5
ORDER BY locationName ASC, c.memberID ASC;
