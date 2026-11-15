DROP EVENT IF EXISTS evt_WeeklyEmails;

DROP VIEW IF EXISTS v_SessionEmails;
DROP VIEW IF EXISTS v_Assignments;
DROP VIEW IF EXISTS v_Formations;
DROP VIEW IF EXISTS v_NBAWins;
DROP VIEW IF EXISTS v_CurrentLocation;
DROP VIEW IF EXISTS v_MemberStatus;
DROP VIEW IF EXISTS v_ActiveMembers;
DROP VIEW IF EXISTS v_AnnualPayments;
DROP VIEW IF EXISTS v_LatestMeasurement;

DROP TABLE IF EXISTS EmailLog;
DROP TABLE IF EXISTS FormationPlayers;
DROP TABLE IF EXISTS TeamFormations;
DROP TABLE IF EXISTS Sessions;
DROP TABLE IF EXISTS Teams;
DROP TABLE IF EXISTS GameParticipations;
DROP TABLE IF EXISTS NBA_Games;
DROP TABLE IF EXISTS Payments;
DROP TABLE IF EXISTS MinorGuardians;
DROP TABLE IF EXISTS SecondaryFamilyMembers;
DROP TABLE IF EXISTS FamilyMembers;
DROP TABLE IF EXISTS MemberMeasurements;
DROP TABLE IF EXISTS MemberHobbies;
DROP TABLE IF EXISTS Hobbies;
DROP TABLE IF EXISTS MemberLocations;
DROP TABLE IF EXISTS ClubMembers;
DROP TABLE IF EXISTS PersonnelAssignments;
DROP TABLE IF EXISTS Personnel;
DROP TABLE IF EXISTS LocationPhones;
DROP TABLE IF EXISTS Locations;
DROP TABLE IF EXISTS PostalCodes;


-- 1. Postal codes
-- ---------------
-- A postal code determines its city and province, so they are stored once here and not repeated in every address (this keeps Locations, Personnel, ClubMembers and FamilyMembers in BCNF).
CREATE TABLE PostalCodes (
	postalCode CHAR(6) NOT NULL PRIMARY KEY,
	city VARCHAR(50) NOT NULL,
	province CHAR(2) NOT NULL
);


-- 2. Locations and personnel
-- --------------------------
CREATE TABLE Locations (
	locationID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	type VARCHAR(6) NOT NULL CHECK (type IN ('Head', 'Branch')),
	name VARCHAR(80) NOT NULL UNIQUE,
	address VARCHAR(100) NOT NULL,
	postalCode CHAR(6) NOT NULL,
	webAddress VARCHAR(150),
	maxCapacity INT NOT NULL,
	FOREIGN KEY (postalCode) REFERENCES PostalCodes(postalCode) ON UPDATE CASCADE,
	CONSTRAINT ck_loc_capacity CHECK (maxCapacity > 0)
);

CREATE TABLE LocationPhones (
	locationID INT NOT NULL,
	phone VARCHAR(15) NOT NULL,
	PRIMARY KEY (locationID, phone),
	FOREIGN KEY (locationID) REFERENCES Locations(locationID) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Personnel (
	personnelID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	firstName VARCHAR(50) NOT NULL,
	lastName VARCHAR(50) NOT NULL,
	DOB DATE NOT NULL,
	SSN CHAR(9) NOT NULL UNIQUE,
	medicareNum CHAR(12) NOT NULL UNIQUE,
	phone VARCHAR(15) NOT NULL,
	address VARCHAR(100) NOT NULL,
	postalCode CHAR(6) NOT NULL,
	email VARCHAR(100) NOT NULL,
	FOREIGN KEY (postalCode) REFERENCES PostalCodes(postalCode) ON UPDATE CASCADE
);

-- One row per period a personnel member works at a location. endDate NULL means the assignment is still active.
CREATE TABLE PersonnelAssignments (
	personnelID INT NOT NULL,
	locationID INT NOT NULL,
	startDate DATE NOT NULL,
	endDate DATE,
	role VARCHAR(15) NOT NULL
		CHECK (role IN ('Administrator', 'Captain', 'Coach', 'Assistant Coach', 'Other')),
	title VARCHAR(60) NOT NULL,
	mandate VARCHAR(9) NOT NULL CHECK (mandate IN ('Volunteer', 'Salaried')),
	PRIMARY KEY (personnelID, startDate),
	FOREIGN KEY (personnelID) REFERENCES Personnel(personnelID) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (locationID) REFERENCES Locations(locationID) ON UPDATE CASCADE,
	CONSTRAINT ck_assignment_dates CHECK (endDate IS NULL OR endDate >= startDate),
	CONSTRAINT ck_general_manager CHECK (title <> 'General Manager' OR role = 'Administrator')
);


-- 3. Club members, their locations, hobbies and measurements
-- ----------------------------------------------------------
CREATE TABLE ClubMembers (
	memberID INT NOT NULL AUTO_INCREMENT,
	firstName VARCHAR(50) NOT NULL,
	lastName VARCHAR(50) NOT NULL,
	DOB DATE NOT NULL,
	gender CHAR(1) NOT NULL,
	joinDate DATE NOT NULL,
	SSN CHAR(9) NOT NULL,
	medicareNum CHAR(12) NOT NULL,
	phone VARCHAR(15) NOT NULL,
	address VARCHAR(100) NOT NULL,
	postalCode CHAR(6) NOT NULL,
	email VARCHAR(100) NOT NULL,
	CONSTRAINT pk_clubmembers PRIMARY KEY (memberID),
	CONSTRAINT uq_club_ssn UNIQUE (SSN),
	CONSTRAINT uq_club_medicare UNIQUE (medicareNum),
	CONSTRAINT fk_club_postal FOREIGN KEY (postalCode)
		REFERENCES PostalCodes(postalCode) ON UPDATE CASCADE,
	CONSTRAINT ck_club_gender CHECK (gender IN ('F', 'M')),
	CONSTRAINT ck_join_age CHECK (joinDate >= DATE_ADD(DOB, INTERVAL 6 YEAR))
);

-- One row per period a member is associated with a location. endDate NULL means it is the member's current location.
CREATE TABLE MemberLocations (
	memberID INT NOT NULL,
	locationID INT NOT NULL,
	startDate DATE NOT NULL,
	endDate DATE,
	CONSTRAINT pk_memberlocations PRIMARY KEY (memberID, startDate),
	CONSTRAINT fk_memberlocation_member FOREIGN KEY (memberID)
		REFERENCES ClubMembers(memberID) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_memberlocation_location FOREIGN KEY (locationID)
		REFERENCES Locations(locationID) ON UPDATE CASCADE,
	CONSTRAINT ck_memberlocation_dates CHECK (endDate IS NULL OR endDate >= startDate)
);

CREATE TABLE Hobbies (
	hobbyID INT NOT NULL AUTO_INCREMENT,
	name VARCHAR(60) NOT NULL,
	CONSTRAINT pk_hobbies PRIMARY KEY (hobbyID),
	CONSTRAINT uq_hobby_name UNIQUE (name)
);

CREATE TABLE MemberHobbies (
	memberID INT NOT NULL,
	hobbyID INT NOT NULL,
	CONSTRAINT pk_memberhobbies PRIMARY KEY (memberID, hobbyID),
	CONSTRAINT fk_memberhobby_member FOREIGN KEY (memberID)
		REFERENCES ClubMembers(memberID) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_memberhobby_hobby FOREIGN KEY (hobbyID)
		REFERENCES Hobbies(hobbyID) ON UPDATE CASCADE
);

CREATE TABLE MemberMeasurements (
	memberID INT NOT NULL,
	measureDate DATE NOT NULL,
	heightCm DECIMAL(5,1) NOT NULL,
	weightKg DECIMAL(5,1) NOT NULL,
	CONSTRAINT pk_membermeasurements PRIMARY KEY (memberID, measureDate),
	CONSTRAINT fk_measure_member FOREIGN KEY (memberID)
		REFERENCES ClubMembers(memberID) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT ck_height CHECK (heightCm > 0),
	CONSTRAINT ck_weight CHECK (weightKg > 0)
);


-- 4. Family members
-- -----------------
-- FamilyMembers holds the primary family members (the person who registers a child). A primary family member can name one secondary family member as a second contact.
CREATE TABLE FamilyMembers (
	familyMemberID INT NOT NULL AUTO_INCREMENT,
	firstName VARCHAR(50) NOT NULL,
	lastName VARCHAR(50) NOT NULL,
	DOB DATE NOT NULL,
	SSN CHAR(9) NOT NULL,
	medicareNum CHAR(12) NOT NULL,
	phone VARCHAR(15) NOT NULL,
	address VARCHAR(100) NOT NULL,
	postalCode CHAR(6) NOT NULL,
	email VARCHAR(100),
	locationID INT NOT NULL,
	CONSTRAINT pk_familymembers PRIMARY KEY (familyMemberID),
	CONSTRAINT uq_family_ssn UNIQUE (SSN),
	CONSTRAINT uq_family_medicare UNIQUE (medicareNum),
	CONSTRAINT fk_family_postal FOREIGN KEY (postalCode)
		REFERENCES PostalCodes(postalCode) ON UPDATE CASCADE,
	CONSTRAINT fk_family_location FOREIGN KEY (locationID)
		REFERENCES Locations(locationID) ON UPDATE CASCADE
);

CREATE TABLE SecondaryFamilyMembers (
	familyMemberID INT NOT NULL,
	firstName VARCHAR(50) NOT NULL,
	lastName VARCHAR(50) NOT NULL,
	phone VARCHAR(15) NOT NULL,
	relationship VARCHAR(11) NOT NULL
		CHECK (relationship IN ('Father', 'Mother', 'Grandfather', 'Grandmother', 'Tutor', 'Partner', 'Friend', 'Other')),
	CONSTRAINT pk_secondaryfamily PRIMARY KEY (familyMemberID),
	CONSTRAINT fk_secondary_primary FOREIGN KEY (familyMemberID)
		REFERENCES FamilyMembers(familyMemberID) ON UPDATE CASCADE ON DELETE CASCADE
);

-- The family member each minor is associated with (one per minor).
CREATE TABLE MinorGuardians (
	memberID INT NOT NULL,
	familyMemberID INT NOT NULL,
	relationship VARCHAR(11) NOT NULL
		CHECK (relationship IN ('Father', 'Mother', 'Grandfather', 'Grandmother', 'Tutor', 'Partner', 'Friend', 'Other')),
	CONSTRAINT pk_minorguardians PRIMARY KEY (memberID),
	CONSTRAINT fk_guardian_member FOREIGN KEY (memberID)
		REFERENCES ClubMembers(memberID) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_guardian_family FOREIGN KEY (familyMemberID)
		REFERENCES FamilyMembers(familyMemberID) ON UPDATE CASCADE
);


-- 5. Payments
-- -----------
CREATE TABLE Payments (
	paymentID INT NOT NULL AUTO_INCREMENT,
	memberID INT NOT NULL,
	paymentDate DATE NOT NULL,
	amount DECIMAL(7,2) NOT NULL,
	method VARCHAR(6) NOT NULL,
	membershipYear INT NOT NULL,
	installmentNum INT NOT NULL,
	PRIMARY KEY (paymentID),
	UNIQUE (memberID, membershipYear, installmentNum),
	FOREIGN KEY (memberID) REFERENCES ClubMembers(memberID) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT PaymentAmountPositive CHECK (amount > 0),
	CONSTRAINT PaymentMethodValid CHECK (method IN ('Cash', 'Debit', 'Credit')),
	CONSTRAINT PaymentYearValid CHECK (membershipYear >= 2000 AND membershipYear <= 2100),
	CONSTRAINT PaymentMaxFourInstallments CHECK (installmentNum >= 1 AND installmentNum <= 4)
);


-- 6. NBA games
-- ------------
CREATE TABLE NBA_Games (
	gameID INT NOT NULL AUTO_INCREMENT,
	gameDate DATE NOT NULL,
	gameLocation VARCHAR(100) NOT NULL,
	homeTeam VARCHAR(50) NOT NULL,
	awayTeam VARCHAR(50) NOT NULL,
	homeScore INT NOT NULL,
	awayScore INT NOT NULL,
	CONSTRAINT pk_nbagames PRIMARY KEY (gameID),
	CONSTRAINT ck_nba_homescore CHECK (homeScore >= 0),
	CONSTRAINT ck_nba_awayscore CHECK (awayScore >= 0),
	CONSTRAINT ck_nba_teams CHECK (homeTeam <> awayTeam)
);

CREATE TABLE GameParticipations (
	memberID INT NOT NULL,
	gameID INT NOT NULL,
	teamPlayedFor VARCHAR(50) NOT NULL,
	points INT NOT NULL,
	details VARCHAR(255),
	CONSTRAINT pk_gameparticipations PRIMARY KEY (memberID, gameID),
	CONSTRAINT fk_gp_member FOREIGN KEY (memberID)
		REFERENCES ClubMembers(memberID) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_gp_game FOREIGN KEY (gameID)
		REFERENCES NBA_Games(gameID) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT ck_gp_points CHECK (points >= 0)
);


-- 7. Teams, sessions and team formations
-- --------------------------------------
-- A team belongs to one location and is a boys team (M) or a girls
-- team (F).
CREATE TABLE Teams (
	teamID INT NOT NULL AUTO_INCREMENT,
	name VARCHAR(60) NOT NULL,
	locationID INT NOT NULL,
	gender CHAR(1) NOT NULL,
	CONSTRAINT pk_teams PRIMARY KEY (teamID),
	CONSTRAINT uq_team_name UNIQUE (name),
	CONSTRAINT fk_team_location FOREIGN KEY (locationID)
		REFERENCES Locations(locationID) ON UPDATE CASCADE,
	CONSTRAINT ck_team_gender CHECK (gender IN ('F', 'M'))
);

-- A session is one game or one training session.
CREATE TABLE Sessions (
	sessionID INT NOT NULL AUTO_INCREMENT,
	type VARCHAR(8) NOT NULL,
	sessionDate DATE NOT NULL,
	startTime TIME NOT NULL,
	address VARCHAR(150) NOT NULL,
	CONSTRAINT pk_sessions PRIMARY KEY (sessionID),
	CONSTRAINT ck_session_type CHECK (type IN ('Game', 'Training'))
);

-- A team formation is one team taking part in one session, with its
-- head coach and its score (NULL until the session has been played).
CREATE TABLE TeamFormations (
	formationID INT NOT NULL AUTO_INCREMENT,
	sessionID INT NOT NULL,
	teamID INT NOT NULL,
	headCoachID INT NOT NULL,
	score INT,
	CONSTRAINT pk_teamformations PRIMARY KEY (formationID),
	CONSTRAINT uq_formation_session_team UNIQUE (sessionID, teamID),
	CONSTRAINT fk_formation_session FOREIGN KEY (sessionID)
		REFERENCES Sessions(sessionID) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_formation_team FOREIGN KEY (teamID)
		REFERENCES Teams(teamID) ON UPDATE CASCADE,
	CONSTRAINT fk_formation_coach FOREIGN KEY (headCoachID)
		REFERENCES Personnel(personnelID) ON UPDATE CASCADE,
	CONSTRAINT ck_formation_score CHECK (score IS NULL OR score >= 0)
);

-- The players of a team formation and the role each one plays.
CREATE TABLE FormationPlayers (
	formationID INT NOT NULL,
	memberID INT NOT NULL,
	role VARCHAR(14) NOT NULL,
	CONSTRAINT pk_formationplayers PRIMARY KEY (formationID, memberID),
	CONSTRAINT fk_player_formation FOREIGN KEY (formationID)
		REFERENCES TeamFormations(formationID) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_player_member FOREIGN KEY (memberID)
		REFERENCES ClubMembers(memberID) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT ck_player_role CHECK (role IN ('Point Guard', 'Shooting Guard', 'Small Forward', 'Power Forward', 'Center'))
);


-- 8. Email log
-- ------------
-- One row per email generated by the system. body keeps the first 100 characters of the email body.
CREATE TABLE EmailLog (
	emailID INT NOT NULL AUTO_INCREMENT,
	emailDate DATE NOT NULL,
	sender VARCHAR(80) NOT NULL,
	receiver VARCHAR(100) NOT NULL,
	subject VARCHAR(200) NOT NULL,
	body VARCHAR(100) NOT NULL,
	CONSTRAINT pk_emaillog PRIMARY KEY (emailID)
);
