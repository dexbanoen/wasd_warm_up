-- Latest height and weight of each member.
CREATE VIEW v_LatestMeasurement AS
SELECT m.memberID, m.heightCm, m.weightKg
FROM MemberMeasurements m
	JOIN (
		SELECT memberID, MAX(measureDate) AS lastDate
		FROM MemberMeasurements
		GROUP BY memberID
	) AS recent
		ON recent.memberID = m.memberID AND recent.lastDate = m.measureDate;

-- What each member paid for each membership year, and the fee for that year: $100 for a member under 17 on January 1 of that year (a minor), $200 otherwise.
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

-- Members who are active today. A member is active when the fee of the previous year was fully paid. A member who joined this year has no previous year, so this year's fee is checked instead.
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

-- Status of every club member: 'Active' or 'Inactive'.
CREATE VIEW v_MemberStatus AS
SELECT memberID, 'Active' AS status
FROM ClubMembers
WHERE memberID IN (SELECT memberID FROM v_ActiveMembers)
UNION
SELECT memberID, 'Inactive' AS status
FROM ClubMembers
WHERE memberID NOT IN (SELECT memberID FROM v_ActiveMembers);

-- Current location of each member (the period that has no end date).
CREATE VIEW v_CurrentLocation AS
SELECT memberID, locationID, startDate
FROM MemberLocations
WHERE endDate IS NULL;

-- NBA games each member won: the team the member played for scored
-- more than the other team.
CREATE VIEW v_NBAWins AS
SELECT p.memberID, p.gameID
FROM GameParticipations p, NBA_Games g
WHERE p.gameID = g.gameID
	AND ((p.teamPlayedFor = g.homeTeam AND g.homeScore > g.awayScore)
		OR (p.teamPlayedFor = g.awayTeam AND g.awayScore > g.homeScore));

-- One row per team formation, with its session and its team.
CREATE VIEW v_Formations AS
SELECT tf.formationID, tf.sessionID, tf.teamID, tf.headCoachID, tf.score,
	s.type, s.sessionDate, s.startTime, s.address,
	t.name AS teamName, t.locationID, t.gender
FROM TeamFormations tf, Sessions s, Teams t
WHERE s.sessionID = tf.sessionID
	AND t.teamID = tf.teamID;

-- One row per player assigned to a team formation, with the details of
-- the formation.
CREATE VIEW v_Assignments AS
SELECT fp.memberID, fp.role, f.formationID, f.sessionID, f.teamID, f.headCoachID,
	f.type, f.sessionDate, f.startTime, f.address, f.teamName, f.locationID
FROM FormationPlayers fp, v_Formations f
WHERE f.formationID = fp.formationID;

-- The email each assigned player receives about a session. Sender: the location of the team. Receiver is the player's email.
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


-- TRIGGERS
-- DELIMITER // lets a trigger body contain ";" characters.
-- --------------------------------------------------------
DELIMITER //

-- Trigger 1 and 2. The club has only one Head location.
CREATE TRIGGER trg_Locations_OneHead_Insert
BEFORE INSERT ON Locations
FOR EACH ROW
BEGIN
	IF NEW.type = 'Head'
		AND EXISTS (SELECT * FROM Locations WHERE type = 'Head') THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Rejected: the club already has a Head location.';
	END IF;
END//

CREATE TRIGGER trg_Locations_OneHead_Update
BEFORE UPDATE ON Locations
FOR EACH ROW
BEGIN
	IF NEW.type = 'Head'
		AND EXISTS (SELECT * FROM Locations WHERE type = 'Head' AND locationID <> OLD.locationID) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Rejected: the club already has a Head location.';
	END IF;
END//

-- Trigger 3. A personnel member works at only one location, with one  role, at any time: a new assignment cannot overlap an existing one.
CREATE TRIGGER trg_PersonnelAssignments_NoOverlap
BEFORE INSERT ON PersonnelAssignments
FOR EACH ROW
BEGIN
	IF EXISTS (
		SELECT *
		FROM PersonnelAssignments a
		WHERE a.personnelID = NEW.personnelID
			AND (a.endDate IS NULL OR a.endDate >= NEW.startDate)
			AND (NEW.endDate IS NULL OR a.startDate <= NEW.endDate)
	) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Rejected: this personnel member already has an assignment in that period. End it first.';
	END IF;
END//

-- Trigger 4. A club member is associated with only one location at any time: a new period cannot overlap an existing one.
CREATE TRIGGER trg_MemberLocations_NoOverlap
BEFORE INSERT ON MemberLocations
FOR EACH ROW
BEGIN
	IF EXISTS (
		SELECT *
		FROM MemberLocations ml
		WHERE ml.memberID = NEW.memberID
			AND (ml.endDate IS NULL OR ml.endDate >= NEW.startDate)
			AND (NEW.endDate IS NULL OR ml.startDate <= NEW.endDate)
	) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Rejected: the member is already at a location in that period. End that period first.';
	END IF;
END//

-- Trigger 5. A location cannot take a new member when its number of active members has reached its maximum capacity. 
-- A member is active when the fee of the previous year is fully paid ($100 for a minor, $200 otherwise), or, for a member who joined this year, when this year's fee is fully paid (the same rule as the view v_ActiveMembers).
CREATE TRIGGER trg_MemberLocations_Capacity
BEFORE INSERT ON MemberLocations
FOR EACH ROW
BEGIN
	IF NEW.endDate IS NULL
		AND (SELECT COUNT(*)
			FROM MemberLocations ml, ClubMembers c
			WHERE ml.locationID = NEW.locationID
				AND ml.endDate IS NULL
				AND c.memberID = ml.memberID
				AND (
					(SELECT COALESCE(SUM(p.amount), 0)
						FROM Payments p
						WHERE p.memberID = c.memberID
							AND p.membershipYear = YEAR(CURDATE()) - 1)
					>= IF(TIMESTAMPDIFF(YEAR, c.DOB, MAKEDATE(YEAR(CURDATE()) - 1, 1)) < 17, 100, 200)
					OR (YEAR(c.joinDate) = YEAR(CURDATE())
						AND (SELECT COALESCE(SUM(p.amount), 0)
							FROM Payments p
							WHERE p.memberID = c.memberID
								AND p.membershipYear = YEAR(CURDATE()))
						>= IF(TIMESTAMPDIFF(YEAR, c.DOB, MAKEDATE(YEAR(CURDATE()), 1)) < 17, 100, 200))
				))
		>= (SELECT maxCapacity FROM Locations WHERE locationID = NEW.locationID) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Rejected: the location already has its maximum number of active members.';
	END IF;
END//

-- Trigger 6. Every game or training session consists of two teams.
CREATE TRIGGER trg_TeamFormations_TwoTeams
BEFORE INSERT ON TeamFormations
FOR EACH ROW
BEGIN
	IF (SELECT COUNT(*) FROM TeamFormations WHERE sessionID = NEW.sessionID) >= 2 THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Rejected: a session has two teams and this session already has two.';
	END IF;
END//

-- Trigger 7. All players of a team formation are boys or all are girls: the player's gender must be the gender of the team.
CREATE TRIGGER trg_Player_SameGender
BEFORE INSERT ON FormationPlayers
FOR EACH ROW
BEGIN
	IF EXISTS (
		SELECT *
		FROM TeamFormations tf, Teams t, ClubMembers c
		WHERE tf.formationID = NEW.formationID
			AND t.teamID = tf.teamID
			AND c.memberID = NEW.memberID
			AND c.gender <> t.gender
	) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Rejected: boys and girls cannot be mixed in a team formation.';
	END IF;
END//

-- Trigger 8. All players of a team are club members of the team's location: on the day of the session the player must be associated with the location of the team.
CREATE TRIGGER trg_Player_SameLocation
BEFORE INSERT ON FormationPlayers
FOR EACH ROW
BEGIN
	IF NOT EXISTS (
		SELECT *
		FROM TeamFormations tf, Teams t, Sessions s, MemberLocations ml
		WHERE tf.formationID = NEW.formationID
			AND t.teamID = tf.teamID
			AND s.sessionID = tf.sessionID
			AND ml.memberID = NEW.memberID
			AND ml.locationID = t.locationID
			AND ml.startDate <= s.sessionDate
			AND (ml.endDate IS NULL OR ml.endDate >= s.sessionDate)
	) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Rejected: the player is not a member of the location of this team on the session date.';
	END IF;
END//

-- Trigger 9. A club member whose membership fees are not paid cannot take part in a game or a training session (same rule as trigger 5).
CREATE TRIGGER trg_Player_FeesPaid
BEFORE INSERT ON FormationPlayers
FOR EACH ROW
BEGIN
	DECLARE vDOB DATE;
	DECLARE vJoinDate DATE;
	DECLARE vYear INT;
	DECLARE vPaidLastYear DECIMAL(9,2);
	DECLARE vPaidThisYear DECIMAL(9,2);
	SET vYear = YEAR(CURDATE());
	SELECT c.DOB, c.joinDate INTO vDOB, vJoinDate
	FROM ClubMembers c
	WHERE c.memberID = NEW.memberID;
	SELECT COALESCE(SUM(p.amount), 0) INTO vPaidLastYear
	FROM Payments p
	WHERE p.memberID = NEW.memberID
		AND p.membershipYear = vYear - 1;
	SELECT COALESCE(SUM(p.amount), 0) INTO vPaidThisYear
	FROM Payments p
	WHERE p.memberID = NEW.memberID
		AND p.membershipYear = vYear;
	IF NOT (vPaidLastYear >= IF(TIMESTAMPDIFF(YEAR, vDOB, MAKEDATE(vYear - 1, 1)) < 17, 100, 200)
			OR (YEAR(vJoinDate) = vYear
				AND vPaidThisYear >= IF(TIMESTAMPDIFF(YEAR, vDOB, MAKEDATE(vYear, 1)) < 17, 100, 200))) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Rejected: the member is inactive (membership fees not fully paid) and cannot be assigned.';
	END IF;
END//

-- Trigger 10. A player assigned to two team formations on the same day needs at least three hours between the two start times.
CREATE TRIGGER trg_Player_ThreeHours
BEFORE INSERT ON FormationPlayers
FOR EACH ROW
BEGIN
	IF EXISTS (
		SELECT *
		FROM TeamFormations tf, Sessions s,
			FormationPlayers fp, TeamFormations tf2, Sessions s2
		WHERE tf.formationID = NEW.formationID
			AND s.sessionID = tf.sessionID
			AND fp.memberID = NEW.memberID
			AND tf2.formationID = fp.formationID
			AND s2.sessionID = tf2.sessionID
			AND s2.sessionDate = s.sessionDate
			AND s2.startTime > SUBTIME(s.startTime, '03:00:00')
			AND s2.startTime < ADDTIME(s.startTime, '03:00:00')
	) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Rejected: the player already has a session that day less than 3 hours from this one.';
	END IF;
END//

-- Trigger 11. An assignment can only have its role edited. To move a player to another team formation, the assignment is deleted and a new one is inserted, so triggers 7 to 10 check it again.
CREATE TRIGGER trg_Player_OnlyRoleEdit
BEFORE UPDATE ON FormationPlayers
FOR EACH ROW
BEGIN
	IF NEW.formationID <> OLD.formationID OR NEW.memberID <> OLD.memberID THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Rejected: only the role can be edited. Delete the assignment and assign the player again.';
	END IF;
END//

-- Trigger 12. The same three-hour rule when the date or the start time of a session is changed after players have been assigned.
CREATE TRIGGER trg_Sessions_ThreeHours
BEFORE UPDATE ON Sessions
FOR EACH ROW
BEGIN
	IF (NEW.sessionDate <> OLD.sessionDate OR NEW.startTime <> OLD.startTime)
		AND EXISTS (
			SELECT *
			FROM TeamFormations tf, FormationPlayers fp,
				FormationPlayers fp2, TeamFormations tf2, Sessions s2
			WHERE tf.sessionID = OLD.sessionID
				AND fp.formationID = tf.formationID
				AND fp2.memberID = fp.memberID
				AND tf2.formationID = fp2.formationID
				AND tf2.sessionID <> OLD.sessionID
				AND s2.sessionID = tf2.sessionID
				AND s2.sessionDate = NEW.sessionDate
				AND s2.startTime > SUBTIME(NEW.startTime, '03:00:00')
				AND s2.startTime < ADDTIME(NEW.startTime, '03:00:00')
		) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Rejected: a player of this session would have two sessions less than 3 hours apart.';
	END IF;
END//

DELIMITER ;