
-- 20. The triggers of the system (name, event and table).
SELECT TRIGGER_NAME, ACTION_TIMING, EVENT_MANIPULATION, EVENT_OBJECT_TABLE
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
ORDER BY EVENT_OBJECT_TABLE, TRIGGER_NAME;


-- Rules enforced by triggers
-- --------------------------

-- new game on November 21, 2026 at 12:00 for Montréal Boys (team 1) against Laval Boys (team 4). 
-- Montréal Boys already has a training session that day at 10:00 (session 19).
INSERT INTO Sessions (sessionID, type, sessionDate, startTime, address) VALUES (25, 'Game', '2026-11-21', '12:00:00', '1200 Rue Sainte-Catherine O, Montréal');
INSERT INTO TeamFormations (formationID, sessionID, teamID, headCoachID, score) VALUES (49, 25, 1, 22, NULL), (50, 25, 4, 21, NULL);

-- Test 1 (item 6 and trigger 10). REJECTED: Olivier Roy (member 16) already has the 10:00 training session that day, and 12:00 is only two hours later.
INSERT INTO FormationPlayers (formationID, memberID, role) VALUES
	(49, 16, 'Point Guard');
-- ERROR: Rejected: the player already has a session that day less than 3 hours from this one.

-- Test 2 (trigger 10). Accepted: Marc Tremblay (member 1) has no other session that day.
INSERT INTO FormationPlayers (formationID, memberID, role) VALUES
	(49, 1, 'Center');

-- Test 3 (trigger 7). REJECTED: Léa Tremblay (member 11) is a girl and Montréal Boys is a boys team.
INSERT INTO FormationPlayers (formationID, memberID, role) VALUES
	(49, 11, 'Small Forward');
-- ERROR: Rejected: boys and girls cannot be mixed in a team formation.

-- Test 4 (trigger 8). REJECTED: Mathis Perron (member 26) is a member of Laval, and formation 49 is a team of Montréal.
INSERT INTO FormationPlayers (formationID, memberID, role) VALUES
	(49, 26, 'Power Forward');
-- ERROR: Rejected: the player is not a member of the location of this team on the session date.

-- Test 5 (trigger 9). REJECTED: Daniel Beaulieu (member 27) has not paid his fees for 2025, so he is inactive.
INSERT INTO FormationPlayers (formationID, memberID, role) VALUES
	(49, 27, 'Shooting Guard');
-- ERROR: Rejected: the member is inactive (membership fees not fully paid) and cannot be assigned.

-- Test 6 (trigger 6). REJECTED: session 25 already has its two teams.
INSERT INTO TeamFormations (formationID, sessionID, teamID, headCoachID, score) VALUES
	(51, 25, 6, 15, NULL);
-- ERROR: Rejected: a session has two teams and this session already has two.

-- Test 7 (trigger 11). REJECTED: an assignment cannot be given to another player; only its role can be edited.
UPDATE FormationPlayers
SET memberID = 12
WHERE formationID = 49
	AND memberID = 1;  
-- ERROR: Rejected: only the role can be edited. Delete the assignment and assign the player again.

-- Test 8 (trigger 12). REJECTED: session 24 is a game on December 12, 2026 at 15:00. The Laval Girls players also have a training session that day at 10:00 (session 23), so the game cannot be moved to 12:00.
UPDATE Sessions
SET startTime = '12:00:00'
WHERE sessionID = 24;   
-- ERROR: Rejected: a player of this session would have two sessions less than 3 hours apart.

-- Test 9 (trigger 12). Accepted: 13:00 is three hours after 10:00.
UPDATE Sessions
SET startTime = '13:00:00'
WHERE sessionID = 24;

-- Test 10 (trigger 1). REJECTED: Montréal is already the Head location.
INSERT INTO Locations (locationID, type, name, address, postalCode, webAddress, maxCapacity) VALUES
	(11, 'Head', 'Second Head', '1 Rue Exemple', 'H3G1P1', NULL, 100);
-- ERROR: Rejected: the club already has a Head location.

-- Test 11 (trigger 2). REJECTED: a branch cannot become a second Head.
UPDATE Locations
SET type = 'Head'
WHERE locationID = 2;
-- ERROR: Rejected: the club already has a Head location.

-- Test 12 (trigger 3). REJECTED: James Smith (personnel 1) still works at Montréal, so he cannot start at Laval before that assignment ends.
INSERT INTO PersonnelAssignments (personnelID, locationID, startDate, endDate, role, title, mandate) VALUES
	(1, 2, '2026-11-15', NULL, 'Coach', 'Trainer', 'Salaried');
-- ERROR: Rejected: this personnel member already has an assignment in that period. End it first.

-- Test 13 (trigger 4). REJECTED: Olivier Roy (member 16) is still a member of Montréal, so he cannot be at Laval at the same time.
INSERT INTO MemberLocations (memberID, locationID, startDate, endDate) VALUES
	(16, 2, '2026-11-15', NULL);
-- ERROR: Rejected: the member is already at a location in that period. End that period first.

-- Test 14 (trigger 5). Trois-Rivières (location 7) has two active
-- members. setup: its capacity is set to 2 and a new member is created.
UPDATE Locations
SET maxCapacity = 2
WHERE locationID = 7;
INSERT INTO ClubMembers (memberID, firstName, lastName, DOB, gender, joinDate, SSN, medicareNum, phone, address, postalCode, email) VALUES
	(48, 'Test', 'Member', '2000-01-01', 'F', '2026-11-13', '300000048', 'MEM000000048', '819-555-1048', '1 Rue Exemple', 'G8Z4H3', 'test.member@example.org');
-- REJECTED: the location is full.
INSERT INTO MemberLocations (memberID, locationID, startDate, endDate) VALUES
	(48, 7, '2026-11-13', NULL);
-- ERROR: Rejected: the location already has its maximum number of active members.

-- cleanup
DELETE FROM ClubMembers
WHERE memberID = 48;
UPDATE Locations
SET maxCapacity = 140
WHERE locationID = 7;
UPDATE Sessions
SET startTime = '15:00:00'
WHERE sessionID = 24;
DELETE FROM Sessions
WHERE sessionID = 25;


-- Rules enforced by keys, foreign keys and CHECK constraints
-- ----------------------------------------------------------
-- Test 15 (CHECK ck_join_age). REJECTED: a new club member must be at
-- least 6 years old; this child is 4 on the joining date.
INSERT INTO ClubMembers (memberID, firstName, lastName, DOB, gender, joinDate, SSN, medicareNum, phone, address, postalCode, email) VALUES
	(48, 'Too', 'Young', '2022-05-01', 'M', '2026-11-13', '300000048', 'MEM000000048', '514-555-1048', '1 Rue Exemple', 'H3G1P1', 'too.young@example.org');
-- ERROR: Check constraint 'ck_join_age' is violated.

-- Test 16 (UNIQUE on SSN). REJECTED: no two club members can have the same Social Security Number (this is the SSN of member 1).
INSERT INTO ClubMembers (memberID, firstName, lastName, DOB, gender, joinDate, SSN, medicareNum, phone, address, postalCode, email) VALUES
	(48, 'Same', 'Number', '2000-01-01', 'M', '2026-11-13', '100000001', 'MEM000000048', '514-555-1048', '1 Rue Exemple', 'H3G1P1', 'same.number@example.org');
-- ERROR: Duplicate entry '100000001' for key 'ClubMembers.uq_club_ssn'

-- Test 17 (CHECK PaymentMaxFourInstallments). REJECTED: Hassan Benali (member 4) already paid 2025 in four installments; a fifth is refused.
INSERT INTO Payments (memberID, paymentDate, amount, method, membershipYear, installmentNum) VALUES
	(4, '2025-09-15', 10.00, 'Cash', 2025, 5);
-- ERROR: Check constraint 'PaymentMaxFourInstallments' is violated.

-- Test 18 (CHECK PaymentMethodValid). REJECTED: the method of payment is cash, debit or credit card.
INSERT INTO Payments (memberID, paymentDate, amount, method, membershipYear, installmentNum) VALUES
	(4, '2026-11-13', 50.00, 'Cheque', 2027, 1);
-- ERROR: Check constraint 'PaymentMethodValid' is violated.

-- Test 19 (foreign key). REJECTED: a hobby must be in the list of hobbies; there is no hobby 99.
INSERT INTO MemberHobbies (memberID, hobbyID) VALUES
	(1, 99);
-- ERROR: Cannot add or update a child row: a foreign key constraint fails

-- Test 20 (CHECK on role). REJECTED: 'Goalkeeper' is not one of the five roles of a team formation.
INSERT INTO FormationPlayers (formationID, memberID, role) VALUES
	(37, 1, 'Goalkeeper');
-- ERROR: Check constraint 'ck_player_role' is violated.

-- Test 21 (CHECK ck_general_manager). REJECTED: a general manager is an administrative personnel member.
INSERT INTO PersonnelAssignments (personnelID, locationID, startDate, endDate, role, title, mandate) VALUES
	(2, 1, '2020-01-01', '2020-12-31', 'Coach', 'General Manager', 'Salaried');
-- ERROR: Check constraint 'ck_general_manager' is violated.

-- Test 22 (foreign key). REJECTED: Marc Tremblay (family member 1) still has two minors associated with him, and every minor must keep a family member.
DELETE FROM FamilyMembers
WHERE familyMemberID = 1;
-- ERROR: Cannot delete or update a parent row: a foreign key constraint fails

-- Test 23 (foreign key). REJECTED: Laval (location 2) still has members, personnel and teams.
DELETE FROM Locations
WHERE locationID = 2;
-- ERROR: Cannot delete or update a parent row: a foreign key constraint fails
