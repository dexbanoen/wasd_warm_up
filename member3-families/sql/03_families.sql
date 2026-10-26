-- =====================================================================
-- CBCS  |  03_families.sql  |  Owner: Member 3 (Families)
-- Tables: FamilyMembers, MinorGuardians
-- Runs after 01_locations_personnel.sql and 02_club_members.sql,
-- because it references Locations(locationID) and ClubMembers(memberID).
-- Target: MySQL 8.0.16+ (CHECK constraints are enforced from 8.0.16;
-- older servers parse and ignore them, so the script still runs).
-- =====================================================================

-- ---------------------------------------------------------------------
-- FamilyMembers
-- A registered family member who signs up one or more minor club
-- members. locationID is the location they are associated with now;
-- a move updates the row (schema contract, decision 6).
-- SSN is NOT NULL and UNIQUE: it is also how query vi recognises a
-- family member who is the same person as a major club member
-- (schema contract, decision 2, option A).
-- ---------------------------------------------------------------------
CREATE TABLE FamilyMembers (
    familyMemberID  INT           NOT NULL AUTO_INCREMENT,
    firstName       VARCHAR(50)   NOT NULL,
    lastName        VARCHAR(50)   NOT NULL,
    DOB             DATE          NOT NULL,
    SSN             CHAR(9)       NOT NULL,
    medicareNum     CHAR(12)      NOT NULL,
    phone           VARCHAR(15)   NOT NULL,
    address         VARCHAR(100)  NOT NULL,
    city            VARCHAR(50)   NOT NULL,
    province        CHAR(2)       NOT NULL,
    postalCode      CHAR(6)       NOT NULL,
    email           VARCHAR(100),
    locationID      INT           NOT NULL,
    CONSTRAINT pk_familymembers   PRIMARY KEY (familyMemberID),
    CONSTRAINT uq_family_ssn      UNIQUE (SSN),
    CONSTRAINT uq_family_medicare UNIQUE (medicareNum),
    CONSTRAINT fk_family_location FOREIGN KEY (locationID)
        REFERENCES Locations (locationID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_family_ssn      CHECK (SSN REGEXP '^[0-9]{9}$'),
    CONSTRAINT ck_family_postal   CHECK (postalCode REGEXP '^[A-Z][0-9][A-Z][0-9][A-Z][0-9]$')
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- ---------------------------------------------------------------------
-- MinorGuardians
-- Links each minor club member to the one family member they are
-- associated with now, and records the relationship.
-- PK = memberID, so a minor has exactly one guardian at a time;
-- switching guardians updates the row (schema contract).
-- ON DELETE RESTRICT on the family member: a family member cannot be
-- removed while a minor still depends on them, which protects the rule
-- that every minor needs a registered family member.
-- ---------------------------------------------------------------------
CREATE TABLE MinorGuardians (
    memberID        INT  NOT NULL,
    familyMemberID  INT  NOT NULL,
    relationship    ENUM('Father','Mother','Grandfather','Grandmother',
                         'Tutor','Partner','Friend','Other') NOT NULL,
    CONSTRAINT pk_minorguardians  PRIMARY KEY (memberID),
    CONSTRAINT fk_guardian_member FOREIGN KEY (memberID)
        REFERENCES ClubMembers (memberID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_guardian_family FOREIGN KEY (familyMemberID)
        REFERENCES FamilyMembers (familyMemberID)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- =====================================================================
-- Data
-- >>> CHECK AGAINST THE CAST LIST BEFORE RUNNING <<<
-- Rows marked [CAST] must match Member 1's cast list / Member 2's rows:
--   * FamilyMembers 1-4 are also major club members. Their SSN must be
--     IDENTICAL to their ClubMembers.SSN, or query vi returns nothing.
--   * MinorGuardians.memberID values must be the MemberIDs of MINOR
--     club members (age 6-16) in 02_club_members.sql.
-- Placeholder mapping used here (replace with the real cast IDs):
--   ClubMembers 1 Marc Tremblay    (major, NBA games, Montreal)
--   ClubMembers 2 Sophie Gagnon    (major, NBA games, Laval)
--   ClubMembers 3 Karim Haddad     (major, NO NBA games)
--   ClubMembers 4 Hassan Benali    (major, NBA games, Gatineau)
--   ClubMembers 11-22               minors, one per guardian row
--   Locations 1-5                   Montreal (Head), Laval, Longueuil,
--                                   Quebec, Gatineau
-- =====================================================================

INSERT INTO FamilyMembers
  (familyMemberID, firstName, lastName, DOB, SSN, medicareNum, phone,
   address, city, province, postalCode, email, locationID) VALUES
  -- [CAST] parents who are also major club members (same SSN)
  (1,  'Marc',     'Tremblay', '1985-03-14', '100000001', 'TREM85031411', '514-555-0101',
       '1200 Rue Sainte-Catherine O', 'Montréal',  'QC', 'H3G1P1', 'marc.tremblay@mail.ca',    1),
  (2,  'Sophie',   'Gagnon',   '1983-07-22', '100000002', 'GAGS83572211', '450-555-0102',
       '45 Boulevard Le Carrefour',   'Laval',     'QC', 'H7T1C7', 'sophie.gagnon@mail.ca',    2),
  (3,  'Karim',    'Haddad',   '1980-11-05', '100000003', 'HADK80110511', '450-555-0103',
       '88 Rue Saint-Charles O',      'Longueuil', 'QC', 'J4H1C9', 'karim.haddad@mail.ca',     3),
  (4,  'Hassan',   'Benali',   '1984-02-27', '100000004', 'BENA84022711', '819-555-0104',
       '25 Rue Laurier',              'Gatineau',  'QC', 'J8X3W9', 'hassan.benali@mail.ca',    5),
  -- family members who are not club members
  (5,  'Nathalie', 'Roy',      '1979-01-30', '200000005', 'ROYN79513011', '514-555-0105',
       '300 Avenue du Parc',          'Montréal',  'QC', 'H2V4G1', 'nathalie.roy@mail.ca',     1),
  (6,  'Pierre',   'Lavoie',   '1952-06-11', '200000006', 'LAVP52061111', '450-555-0106',
       '12 Rue Principale',           'Laval',     'QC', 'H7N2A3', 'pierre.lavoie@mail.ca',    2),
  (7,  'Monique',  'Bouchard', '1955-09-02', '200000007', 'BOUM55590211', '418-555-0107',
       '700 Grande Allée E',          'Québec',    'QC', 'G1R2K5', 'monique.bouchard@mail.ca', 4),
  (8,  'David',    'Chen',     '1990-04-18', '200000008', 'CHED90041811', '418-555-0108',
       '55 Rue Saint-Jean',           'Québec',    'QC', 'G1R1N4', 'david.chen@mail.ca',       4),
  (9,  'Isabelle', 'Côté',     '1987-12-09', '200000009', 'COTI87620911', '819-555-0109',
       '140 Rue Montcalm',            'Gatineau',  'QC', 'J8Y3B5', 'isabelle.cote@mail.ca',    5),
  (10, 'Julie',    'Martin',   '1992-08-15', '200000010', 'MARJ92581511', '450-555-0110',
       '9 Rue Saint-Laurent O',       'Longueuil', 'QC', 'J4H1M4', 'julie.martin@mail.ca',     3),
  (11, 'Lucas',    'Fortin',   '1975-05-05', '200000011', 'FORL75050511', '514-555-0111',
       '2020 Rue Sherbrooke E',       'Montréal',  'QC', 'H2K1B8', 'lucas.fortin@mail.ca',     1),
  (12, 'Chantal',  'Morin',    '1981-10-21', '200000012', 'MORC81602111', '450-555-0112',
       '410 Boulevard Curé-Labelle',  'Laval',     'QC', 'H7V2S4', 'chantal.morin@mail.ca',    2);

INSERT INTO MinorGuardians (memberID, familyMemberID, relationship) VALUES
  -- [CAST] MemberIDs 11-22 must be minors in 02_club_members.sql
  (11, 1,  'Father'),       -- Léa Tremblay      <- Marc Tremblay
  (12, 1,  'Father'),       -- Noah Tremblay     <- Marc Tremblay (2 children)
  (13, 2,  'Mother'),       -- Emma Gagnon       <- Sophie Gagnon
  (14, 3,  'Father'),       -- Yasmine Haddad    <- Karim Haddad
  (15, 4,  'Father'),       -- Adam Benali       <- Hassan Benali
  (16, 5,  'Mother'),       -- Olivier Roy       <- Nathalie Roy
  (17, 6,  'Grandfather'),  -- Chloé Lavoie      <- Pierre Lavoie
  (18, 7,  'Grandmother'),  -- Thomas Bouchard   <- Monique Bouchard
  (19, 8,  'Tutor'),        -- Liam Nguyen       <- David Chen
  (20, 9,  'Mother'),       -- Zoé Côté          <- Isabelle Côté
  (21, 10, 'Friend'),       -- Sarah Pelletier   <- Julie Martin
  (22, 12, 'Mother');       -- Gabriel Morin     <- Chantal Morin
-- Family member 11 (Lucas Fortin) is registered but not yet linked to
-- a minor: a family member must exist before a minor can be registered.
