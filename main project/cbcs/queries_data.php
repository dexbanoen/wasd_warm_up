<?php
// Queries 8 to 19. Generated from sql/CBCS_Main_5_Queries.sql: the same SQL, with the values
// a user can choose replaced by named parameters (:member, :location, :dateFrom, :dateTo).
$QUERIES = array();
$QUERIES[8] = array('text' => 'For every location, its tallest minor club member: location name, first-name, last-name, height and age. Two or more members with the same height can be the tallest of a location (Montréal has two). Sorted by age.',
    'params' => array(),
    'sql' => 'SELECT l.name AS locationName, c.firstName, c.lastName, lm.heightCm AS height,
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
ORDER BY age ASC;');
$QUERIES[9] = array('text' => 'All club members who do not have basketball as a hobby: first-name, last-name and location name. Sorted by location name, then first-name, then last-name.',
    'params' => array(),
    'sql' => 'SELECT c.firstName, c.lastName, l.name AS locationName
FROM ClubMembers c, v_CurrentLocation cl, Locations l
WHERE cl.memberID = c.memberID
    AND l.locationID = cl.locationID
    AND c.memberID NOT IN (
        SELECT mh.memberID
        FROM MemberHobbies mh, Hobbies h
        WHERE h.hobbyID = mh.hobbyID
            AND h.name = \'Basketball\'
    )
ORDER BY locationName ASC, c.firstName ASC, c.lastName ASC;');
$QUERIES[10] = array('text' => 'Locations that have more girls than boys as members: location name, number of girls and number of boys. Sorted by number of girls, then location name.',
    'params' => array(),
    'sql' => 'SELECT t.locationName, t.numGirls, t.numBoys
FROM (
    SELECT l.name AS locationName,
        (SELECT COUNT(*)
         FROM ClubMembers c, v_CurrentLocation cl
         WHERE cl.memberID = c.memberID
             AND cl.locationID = l.locationID
             AND c.gender = \'F\') AS numGirls,
        (SELECT COUNT(*)
         FROM ClubMembers c, v_CurrentLocation cl
         WHERE cl.memberID = c.memberID
             AND cl.locationID = l.locationID
             AND c.gender = \'M\') AS numBoys
    FROM Locations l
) AS t
WHERE t.numGirls > t.numBoys
ORDER BY t.numGirls ASC, t.locationName ASC;');
$QUERIES[11] = array('text' => 'Locations that have at least five different club members who participated in an NBA game and won it: location name, the member\'s first-name and last-name, and the number of NBA games the member participated in and won. Sorted by number of games won, descending.',
    'params' => array(),
    'sql' => 'SELECT l.name AS locationName, c.firstName, c.lastName, COUNT(*) AS numGamesWon
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
ORDER BY numGamesWon DESC, locationName ASC, c.lastName ASC;');
$QUERIES[12] = array('text' => 'Family members who are not associated with any club member: first-name, last-name, telephone-number and location name. Sorted by location name, then first-name, then last-name.',
    'params' => array(),
    'sql' => 'SELECT f.firstName, f.lastName, f.phone, l.name AS locationName
FROM FamilyMembers f, Locations l
WHERE l.locationID = f.locationID
    AND f.familyMemberID NOT IN (
        SELECT g.familyMemberID
        FROM MinorGuardians g
    )
ORDER BY locationName ASC, f.firstName ASC, f.lastName ASC;');
$QUERIES[13] = array('text' => 'History of one club member, given by club member number',
    'params' => array(array('member', 'Club member number', 'number', '29')),
    'sql' => 'SELECT c.firstName, c.lastName, l.name AS locationName, ml.startDate, ml.endDate,
    (SELECT COUNT(*)
     FROM v_Assignments a
     WHERE a.memberID = c.memberID
         AND a.type = \'Game\'
         AND a.sessionDate >= ml.startDate
         AND (ml.endDate IS NULL OR a.sessionDate <= ml.endDate)
         AND a.sessionDate <= CURDATE()) AS numGames,
    (SELECT COUNT(*)
     FROM v_Assignments a
     WHERE a.memberID = c.memberID
         AND a.type = \'Training\'
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
    AND c.memberID = :member
ORDER BY ml.startDate ASC;');
$QUERIES[14] = array('text' => 'All members who participated in at least one NBA game: first-name, last-name, height, age, start date with the club, current location name, current status, number of NBA games participated in and number of NBA games won. Sorted in descending order by number of NBA games won, then by height, then by location name.',
    'params' => array(),
    'sql' => 'SELECT c.firstName, c.lastName, lm.heightCm AS height,
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
ORDER BY numNBAGamesWon DESC, height DESC, locationName DESC;');
$QUERIES[15] = array('text' => 'Report on the club, one row per location: location name, type, city, province, maximum capacity, first-name and last-name of the current general manager (the manager of the location for a branch), current number of salaried personnel and of volunteer personnel, number of active minor, active major, inactive minor and inactive major club members, number of members who participated in NBA games, and number of members who participated in NBA games and won. Sorted by location name.',
    'params' => array(),
    'sql' => 'SELECT l.name AS locationName, l.type, pc.city, pc.province, l.maxCapacity,
    m.firstName AS managerFirstName, m.lastName AS managerLastName,
    (SELECT COUNT(*)
     FROM PersonnelAssignments pa
     WHERE pa.locationID = l.locationID
         AND pa.endDate IS NULL
         AND pa.mandate = \'Salaried\') AS numSalaried,
    (SELECT COUNT(*)
     FROM PersonnelAssignments pa
     WHERE pa.locationID = l.locationID
         AND pa.endDate IS NULL
         AND pa.mandate = \'Volunteer\') AS numVolunteers,
    (SELECT COUNT(*)
     FROM ClubMembers c, v_CurrentLocation cl, v_MemberStatus st
     WHERE cl.memberID = c.memberID
         AND st.memberID = c.memberID
         AND cl.locationID = l.locationID
         AND st.status = \'Active\'
         AND TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) < 17) AS numActiveMinors,
    (SELECT COUNT(*)
     FROM ClubMembers c, v_CurrentLocation cl, v_MemberStatus st
     WHERE cl.memberID = c.memberID
         AND st.memberID = c.memberID
         AND cl.locationID = l.locationID
         AND st.status = \'Active\'
         AND TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) >= 17) AS numActiveMajors,
    (SELECT COUNT(*)
     FROM ClubMembers c, v_CurrentLocation cl, v_MemberStatus st
     WHERE cl.memberID = c.memberID
         AND st.memberID = c.memberID
         AND cl.locationID = l.locationID
         AND st.status = \'Inactive\'
         AND TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) < 17) AS numInactiveMinors,
    (SELECT COUNT(*)
     FROM ClubMembers c, v_CurrentLocation cl, v_MemberStatus st
     WHERE cl.memberID = c.memberID
         AND st.memberID = c.memberID
         AND cl.locationID = l.locationID
         AND st.status = \'Inactive\'
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
            AND pa.title IN (\'General Manager\', \'Manager\')
    ) AS m
        ON m.locationID = l.locationID
ORDER BY l.name ASC;');
$QUERIES[16] = array('text' => 'For a period of time and a location, the club members who were assigned to at least two games on the same day: first-name, last-name, and the date, start time and address of each of those games. The period is July 21 to July 31, 2026 and the location is number 1 (Montréal) here; change the two dates and the 1 to look up another period or location.',
    'params' => array(array('location', 'Location', 'location', '1'), array('dateFrom', 'From', 'date', '2026-07-21'), array('dateTo', 'To', 'date', '2026-07-31')),
    'sql' => 'SELECT c.firstName, c.lastName, a.sessionDate, a.startTime, a.address
FROM ClubMembers c, v_Assignments a
WHERE a.memberID = c.memberID
    AND a.type = \'Game\'
    AND a.locationID = :location
    AND a.sessionDate >= :dateFrom
    AND a.sessionDate <= :dateTo
    AND 2 <= (
        SELECT COUNT(*)
        FROM v_Assignments a2
        WHERE a2.memberID = a.memberID
            AND a2.type = \'Game\'
            AND a2.sessionDate = a.sessionDate
    )
ORDER BY c.lastName ASC, c.firstName ASC, a.sessionDate ASC, a.startTime ASC;');
$QUERIES[17] = array('text' => 'Primary family members who have at least one associated club member who participated in NBA games and won at least one: first-name and last-name of the family member and, for every associated club member who participated in NBA games, the club membership number, first-name, last-name, date of birth, height, number of NBA games participated in, number of NBA games won, and the relationship with the family member. Sorted by number of NBA games won, descending.',
    'params' => array(),
    'sql' => 'SELECT f.firstName AS familyFirstName, f.lastName AS familyLastName,
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
ORDER BY numNBAGamesWon DESC, familyLastName ASC, c.memberID ASC;');
$QUERIES[18] = array('text' => 'Club members who have never been assigned to a training session and have been assigned to at least one game: location name, first-name, last-name, club member number, age, height and number of games assigned to. Sorted by location name, then number of games.',
    'params' => array(),
    'sql' => 'SELECT l.name AS locationName, c.firstName, c.lastName, c.memberID,
    TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) AS age,
    lm.heightCm AS height, COUNT(*) AS numGames
FROM ClubMembers c, v_CurrentLocation cl, Locations l, v_LatestMeasurement lm, v_Assignments a
WHERE cl.memberID = c.memberID
    AND l.locationID = cl.locationID
    AND lm.memberID = c.memberID
    AND a.memberID = c.memberID
    AND a.type = \'Game\'
    AND c.memberID NOT IN (
        SELECT a2.memberID
        FROM v_Assignments a2
        WHERE a2.type = \'Training\'
    )
GROUP BY l.name, c.memberID, c.firstName, c.lastName, c.DOB, lm.heightCm
ORDER BY locationName ASC, numGames ASC;');
$QUERIES[19] = array('text' => 'Club members who were assigned to a training session or a game at least once in every role (Point Guard, Shooting Guard, Small Forward, Power Forward and Center) during a period of time: location name, first-name, last-name, club member number, age, height and total number of sessions assigned to in the period. The period is July 1 to September 30, 2026 here; change the two dates for another period. Sorted by location name, then club member number.',
    'params' => array(array('dateFrom', 'From', 'date', '2026-07-01'), array('dateTo', 'To', 'date', '2026-09-30')),
    'sql' => 'SELECT l.name AS locationName, c.firstName, c.lastName, c.memberID,
    TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) AS age,
    lm.heightCm AS height, COUNT(*) AS numSessions
FROM ClubMembers c, v_CurrentLocation cl, Locations l, v_LatestMeasurement lm, v_Assignments a
WHERE cl.memberID = c.memberID
    AND l.locationID = cl.locationID
    AND lm.memberID = c.memberID
    AND a.memberID = c.memberID
    AND a.sessionDate >= :dateFrom
    AND a.sessionDate <= :dateTo
GROUP BY l.name, c.memberID, c.firstName, c.lastName, c.DOB, lm.heightCm
HAVING COUNT(DISTINCT a.role) = 5
ORDER BY locationName ASC, c.memberID ASC;');
