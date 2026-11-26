-- Item 1. Create / Display / Edit / Delete a Location
-- ---------------------------------------------------
-- 1a. Create. The postal code is added first when it is a new one.
INSERT INTO PostalCodes (postalCode, city, province) VALUES
	('J2C2B2', 'Drummondville', 'QC');
INSERT INTO Locations (locationID, type, name, address, postalCode, webAddress, maxCapacity) VALUES
	(11, 'Branch', 'Drummondville', '455 Boulevard Saint-Joseph', 'J2C2B2', 'https://cbcs.example.org/location/11', 110);
INSERT INTO LocationPhones (locationID, phone) VALUES
	(11, '819-555-2011');

-- 1b. Display.
SELECT l.locationID, l.type, l.name, l.address, pc.city, pc.province, l.postalCode,
	l.webAddress, l.maxCapacity, lp.phone
FROM Locations l
	JOIN PostalCodes pc ON pc.postalCode = l.postalCode
	LEFT OUTER JOIN LocationPhones lp ON lp.locationID = l.locationID
WHERE l.locationID = 11;

-- 1c. Edit: a larger capacity and a second phone number.
UPDATE Locations
SET maxCapacity = 125
WHERE locationID = 11;
INSERT INTO LocationPhones (locationID, phone) VALUES
	(11, '819-555-2911');

SELECT l.locationID, l.name, l.maxCapacity, lp.phone
FROM Locations l
	LEFT OUTER JOIN LocationPhones lp ON lp.locationID = l.locationID
WHERE l.locationID = 11;

-- 1d. Delete. The phone numbers of the location are deleted with it (ON DELETE CASCADE). A location that still has members, personnel or teams cannot be deleted (see CBCS_Main_6_Integrity_Tests.sql).
DELETE FROM Locations
WHERE locationID = 11;
DELETE FROM PostalCodes
WHERE postalCode = 'J2C2B2';

SELECT COUNT(*) AS numLocation11
FROM Locations
WHERE locationID = 11;


-- Item 2. Create / Display / Edit / Delete a Personnel
-- ----------------------------------------------------
-- 2a. Create: the person, then the assignment that gives the location, the role and the mandate.
INSERT INTO Personnel (personnelID, firstName, lastName, DOB, SSN, medicareNum, phone, address, postalCode, email) VALUES
	(25, 'Olivia', 'Bélanger', '1994-03-22', '400000025', 'PER000000025', '819-555-3025', '25 Rue Exemple', 'J1H1P1', 'olivia.belanger@example.org');
INSERT INTO PersonnelAssignments (personnelID, locationID, startDate, endDate, role, title, mandate) VALUES
	(25, 6, '2026-11-01', NULL, 'Coach', 'Coach', 'Volunteer');

-- 2b. Display, with the current assignment.
SELECT p.personnelID, p.firstName, p.lastName, p.DOB, p.SSN, p.medicareNum, p.phone,
	p.address, pc.city, pc.province, p.postalCode, p.email,
	l.name AS locationName, pa.role, pa.title, pa.mandate, pa.startDate, pa.endDate
FROM Personnel p
	JOIN PostalCodes pc ON pc.postalCode = p.postalCode
	LEFT OUTER JOIN PersonnelAssignments pa ON pa.personnelID = p.personnelID AND pa.endDate IS NULL
	LEFT OUTER JOIN Locations l ON l.locationID = pa.locationID
WHERE p.personnelID = 25;

-- 2c. Edit: a new phone number, then a move to another location with another role. The current assignment is ended first, because a personnel member has one location and one role at a time.
UPDATE Personnel
SET phone = '819-555-3999'
WHERE personnelID = 25;
UPDATE PersonnelAssignments
SET endDate = '2026-11-30'
WHERE personnelID = 25
	AND endDate IS NULL;
INSERT INTO PersonnelAssignments (personnelID, locationID, startDate, endDate, role, title, mandate) VALUES
	(25, 7, '2026-12-01', NULL, 'Assistant Coach', 'Trainer', 'Volunteer');

SELECT p.personnelID, p.firstName, p.lastName, p.phone, l.name AS locationName,
	pa.startDate, pa.endDate, pa.role, pa.title, pa.mandate
FROM Personnel p, PersonnelAssignments pa, Locations l
WHERE pa.personnelID = p.personnelID
	AND l.locationID = pa.locationID
	AND p.personnelID = 25
ORDER BY pa.startDate;

-- 2d. Delete. The assignments of the person are deleted with the person.
DELETE FROM Personnel
WHERE personnelID = 25;

SELECT COUNT(*) AS numPersonnel25
FROM Personnel
WHERE personnelID = 25;


-- Item 3. Create / Display / Edit / Delete a FamilyMember (primary and secondary)
-- -------------------------------------------------------------------------------
-- 3a. Create a primary family member, then the secondary family member this person names as a second contact.
INSERT INTO FamilyMembers (familyMemberID, firstName, lastName, DOB, SSN, medicareNum, phone, address, postalCode, email, locationID) VALUES
	(28, 'Chantal', 'Rivard', '1984-06-18', '200000028', 'FAM000000028', '450-555-0128', '77 Rue Saint-Charles O', 'J4H1C9', 'chantal.rivard@mail.ca', 3);
INSERT INTO SecondaryFamilyMembers (familyMemberID, firstName, lastName, phone, relationship) VALUES
	(28, 'Denis', 'Rivard', '450-555-0228', 'Father');

-- 3b. Display both.
SELECT f.familyMemberID, f.firstName, f.lastName, f.DOB, f.SSN, f.medicareNum, f.phone,
	f.address, pc.city, pc.province, f.postalCode, f.email, l.name AS locationName,
	s.firstName AS secondaryFirstName, s.lastName AS secondaryLastName,
	s.phone AS secondaryPhone, s.relationship AS secondaryRelationship
FROM FamilyMembers f
	JOIN PostalCodes pc ON pc.postalCode = f.postalCode
	JOIN Locations l ON l.locationID = f.locationID
	LEFT OUTER JOIN SecondaryFamilyMembers s ON s.familyMemberID = f.familyMemberID
WHERE f.familyMemberID = 28;

-- 3c. Edit: the primary family member moves to another location, and the secondary family member has a new phone number.
UPDATE FamilyMembers
SET locationID = 8,
	address = '120 Boulevard Leduc',
	postalCode = 'J4Y0E6'
WHERE familyMemberID = 28;
UPDATE SecondaryFamilyMembers
SET phone = '450-555-0999'
WHERE familyMemberID = 28;

SELECT f.familyMemberID, f.firstName, f.lastName, f.address, pc.city, l.name AS locationName,
	s.firstName AS secondaryFirstName, s.phone AS secondaryPhone
FROM FamilyMembers f
	JOIN PostalCodes pc ON pc.postalCode = f.postalCode
	JOIN Locations l ON l.locationID = f.locationID
	LEFT OUTER JOIN SecondaryFamilyMembers s ON s.familyMemberID = f.familyMemberID
WHERE f.familyMemberID = 28;

-- 3d. Delete: the secondary family member alone. The primary family member is deleted at the end of item 4, after the minor registered under her in item 4.
DELETE FROM SecondaryFamilyMembers
WHERE familyMemberID = 28;

SELECT COUNT(*) AS numSecondary28
FROM SecondaryFamilyMembers
WHERE familyMemberID = 28;


-- Item 4. Create / Display / Edit / Delete a ClubMember (major and minor)
-- -----------------------------------------------------------------------
-- 4a. Create a major member: the person, the location, the first height and weight, and the hobbies. In the web interface the club member number is not typed: AUTO_INCREMENT gives the next number.
INSERT INTO ClubMembers (memberID, firstName, lastName, DOB, gender, joinDate, SSN, medicareNum, phone, address, postalCode, email) VALUES
	(48, 'Félix', 'Rivard', '2004-02-10', 'M', '2026-11-13', '300000048', 'MEM000000048', '450-555-1048', '77 Rue Saint-Charles O', 'J4H1C9', 'felix.rivard@example.org');
INSERT INTO MemberLocations (memberID, locationID, startDate, endDate) VALUES
	(48, 3, '2026-11-13', NULL);
INSERT INTO MemberMeasurements (memberID, measureDate, heightCm, weightKg) VALUES
	(48, '2026-11-13', 181.0, 76.5);
INSERT INTO MemberHobbies (memberID, hobbyID) VALUES
	(48, 11),
	(48, 6);

-- 4b. Create a minor member: the same steps, plus the family member the minor is associated with (family member 28, created in item 3).
INSERT INTO ClubMembers (memberID, firstName, lastName, DOB, gender, joinDate, SSN, medicareNum, phone, address, postalCode, email) VALUES
	(49, 'Livia', 'Rivard', '2015-08-30', 'F', '2026-11-13', '300000049', 'MEM000000049', '450-555-1049', '120 Boulevard Leduc', 'J4Y0E6', 'livia.rivard@example.org');
INSERT INTO MemberLocations (memberID, locationID, startDate, endDate) VALUES
	(49, 8, '2026-11-13', NULL);
INSERT INTO MemberMeasurements (memberID, measureDate, heightCm, weightKg) VALUES
	(49, '2026-11-13', 142.0, 36.0);
INSERT INTO MinorGuardians (memberID, familyMemberID, relationship) VALUES
	(49, 28, 'Mother');

-- 4c. Display both members: age, current location, status, latest height and weight, and the family member of the minor.
SELECT c.memberID, c.firstName, c.lastName, c.DOB,
	TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) AS age,
	c.gender, c.joinDate, c.SSN, c.medicareNum, c.phone, c.address, pc.city, pc.province,
	c.postalCode, c.email, l.name AS locationName, st.status, lm.heightCm, lm.weightKg,
	f.firstName AS familyFirstName, f.lastName AS familyLastName, g.relationship
FROM ClubMembers c
	JOIN PostalCodes pc ON pc.postalCode = c.postalCode
	JOIN v_MemberStatus st ON st.memberID = c.memberID
	LEFT OUTER JOIN v_CurrentLocation cl ON cl.memberID = c.memberID
	LEFT OUTER JOIN Locations l ON l.locationID = cl.locationID
	LEFT OUTER JOIN v_LatestMeasurement lm ON lm.memberID = c.memberID
	LEFT OUTER JOIN MinorGuardians g ON g.memberID = c.memberID
	LEFT OUTER JOIN FamilyMembers f ON f.familyMemberID = g.familyMemberID
WHERE c.memberID IN (48, 49);

SELECT mh.memberID, h.name AS hobby
FROM MemberHobbies mh, Hobbies h
WHERE h.hobbyID = mh.hobbyID
	AND mh.memberID IN (48, 49);

-- 4d. Edit: a new phone number; a new height and weight (the old row stays, so the history is kept); a move to another branch (the current period is ended, then the new one starts).
UPDATE ClubMembers
SET phone = '450-555-1999'
WHERE memberID = 48;
INSERT INTO MemberMeasurements (memberID, measureDate, heightCm, weightKg) VALUES
	(48, '2026-11-20', 181.2, 77.0);
UPDATE MemberLocations
SET endDate = '2026-11-30'
WHERE memberID = 48
	AND endDate IS NULL;
INSERT INTO MemberLocations (memberID, locationID, startDate, endDate) VALUES
	(48, 1, '2026-12-01', NULL);

SELECT c.memberID, c.firstName, c.phone, l.name AS locationName, ml.startDate, ml.endDate
FROM ClubMembers c, MemberLocations ml, Locations l
WHERE ml.memberID = c.memberID
	AND l.locationID = ml.locationID
	AND c.memberID = 48
ORDER BY ml.startDate;

SELECT memberID, measureDate, heightCm, weightKg
FROM MemberMeasurements
WHERE memberID = 48
ORDER BY measureDate;


-- Item 5. Create / Display / Edit / Delete a TeamFormation
-- --------------------------------------------------------
-- 5a. Create a game session and its two team formations: Montréal Boys (team 1, head coach 1) against Laval Boys (team 4, head coach 21).
INSERT INTO Sessions (sessionID, type, sessionDate, startTime, address) VALUES
	(25, 'Game', '2026-12-19', '10:00:00', '1200 Rue Sainte-Catherine O, Montréal');
INSERT INTO TeamFormations (formationID, sessionID, teamID, headCoachID, score) VALUES
	(49, 25, 1, 1, NULL),
	(50, 25, 4, 21, NULL);

-- 5b. Display the two formations of the session.
SELECT f.formationID, f.type, f.sessionDate, f.startTime, f.address, f.teamName,
	l.name AS locationName, f.gender, p.firstName AS coachFirstName, p.lastName AS coachLastName, f.score
FROM v_Formations f, Locations l, Personnel p
WHERE l.locationID = f.locationID
	AND p.personnelID = f.headCoachID
	AND f.sessionID = 25;

-- 5c. Edit: the game starts one hour later, and Montréal Boys gets
--     another head coach (personnel 22).
UPDATE Sessions
SET startTime = '11:00:00'
WHERE sessionID = 25;
UPDATE TeamFormations
SET headCoachID = 22
WHERE formationID = 49;

SELECT f.formationID, f.sessionDate, f.startTime, f.teamName,
	p.firstName AS coachFirstName, p.lastName AS coachLastName, f.score
FROM v_Formations f, Personnel p
WHERE p.personnelID = f.headCoachID
	AND f.sessionID = 25;


-- Item 6. Assign / Edit / Delete a club member to a team formation
-- ----------------------------------------------------------------

-- 6a. Assign three players of Montréal to formation 49 (Montréal Boys) and two players of Laval to formation 50 (Laval Boys). 
-- Triggers 7 to 10 check each row: same gender as the team, member of the team's location, fees paid, and no other session within 3 hours.
INSERT INTO FormationPlayers (formationID, memberID, role) VALUES
	(49, 16, 'Point Guard'),
	(49, 12, 'Shooting Guard'),
	(49, 29, 'Center'),
	(50, 38, 'Point Guard'),
	(50, 39, 'Center');

SELECT a.formationID, a.teamName, c.memberID, c.firstName, c.lastName, a.role
FROM v_Assignments a, ClubMembers c
WHERE c.memberID = a.memberID
	AND a.sessionID = 25
ORDER BY a.formationID, c.memberID;

-- 6b. Edit: member 12 plays Small Forward instead.
UPDATE FormationPlayers
SET role = 'Small Forward'
WHERE formationID = 49
	AND memberID = 12;

-- 6c. Delete: member 29 is taken out of the formation.
DELETE FROM FormationPlayers
WHERE formationID = 49
	AND memberID = 29;

SELECT a.formationID, a.teamName, c.memberID, c.firstName, c.lastName, a.role
FROM v_Assignments a, ClubMembers c
WHERE c.memberID = a.memberID
	AND a.sessionID = 25
ORDER BY a.formationID, c.memberID;

-- 6d. A conflicting assignment (a second formation on the same day, less than three hours later) is rejected by trigger 10. Because a rejected statement stops a script, that attempt is test 1 of CBCS_Main_6_Integrity_Tests.sql.

-- 6e. Delete (item 5): one team formation alone, then the session. The remaining formation and all the players are deleted with the session (ON DELETE CASCADE).
DELETE FROM TeamFormations
WHERE formationID = 50;
DELETE FROM Sessions
WHERE sessionID = 25;

SELECT COUNT(*) AS numFormationsOfSession25
FROM TeamFormations
WHERE sessionID = 25;


-- Item 7. Make a payment for a club member
-- ----------------------------------------
-- 7a. Member 48 joined this year and has paid nothing, so he is inactive. He pays the $200 fee of 2026 in two installments. paymentID is not given: AUTO_INCREMENT gives the next number.
SELECT memberID, status
FROM v_MemberStatus
WHERE memberID = 48;

INSERT INTO Payments (memberID, paymentDate, amount, method, membershipYear, installmentNum) VALUES
	(48, '2026-11-13', 120.00, 'Debit', 2026, 1);
INSERT INTO Payments (memberID, paymentDate, amount, method, membershipYear, installmentNum) VALUES
	(48, '2026-11-20', 110.00, 'Credit', 2026, 2);

-- 7b. The payments of the member, then the total against the fee: $230 paid for a $200 fee, so $30 is a donation and he is now active.
SELECT paymentID, memberID, paymentDate, amount, method, membershipYear, installmentNum
FROM Payments
WHERE memberID = 48
ORDER BY installmentNum;

SELECT a.memberID, a.membershipYear, a.totalPaid, a.annualFee,
	a.totalPaid - a.annualFee AS donation, st.status
FROM v_AnnualPayments a, v_MemberStatus st
WHERE st.memberID = a.memberID
	AND a.memberID = 48;

-- 7c. Delete (items 3 and 4): the two club members, then the primary family member. Everything that belongs to a member (locations, measurements, hobbies, family link, payments) is deleted with the member. 
-- A family member who still has a minor cannot be deleted, so the minor is deleted first.
DELETE FROM ClubMembers
WHERE memberID = 48;
DELETE FROM ClubMembers
WHERE memberID = 49;
DELETE FROM FamilyMembers
WHERE familyMemberID = 28;

SELECT COUNT(*) AS numMembers48And49
FROM ClubMembers
WHERE memberID IN (48, 49);

SELECT COUNT(*) AS numFamilyMember28
FROM FamilyMembers
WHERE familyMemberID = 28;
