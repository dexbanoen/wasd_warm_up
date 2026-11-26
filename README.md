# CBCS Main Project — Work Split

The technical work of the main project, split five ways; the report is not in this split. Each member owns one part of the system from start to finish, and everyone starts from the same starting kit on day one, so nobody waits for anyone else.

## At a glance

Item and query numbers are those of the project description; trigger numbers follow `CBCS_Main_2_Views_Triggers.sql`. Report due **November 30, 2026 at 23:55**; demos **December 3–4**, and every member must be at the demo.

| Member | Part | Tables | Views | Triggers | Items | Queries | Web pages |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 — Said El-Sherbiny | Locations, personnel, site base | PostalCodes, Locations, LocationPhones, Personnel, PersonnelAssignments | — | 1, 2, 3 | 1, 2 | 10, 15 | locations, personnel, triggers, index, check |
| 2 — MD Azmain Jashim | Club members | ClubMembers, MemberLocations, Hobbies, MemberHobbies, MemberMeasurements | v_LatestMeasurement, v_CurrentLocation | 4, 5 | 4 | 8, 9, 13 | members |
| 3 — Dexter Banoen Garde | Payments, status, NBA, emails | Payments, NBA_Games, GameParticipations, EmailLog | v_AnnualPayments, v_ActiveMembers, v_MemberStatus, v_NBAWins, v_SessionEmails | weekly email event | 7, 22 | 11, 14 | payments, emails, queries |
| 4 — Nicholas Vitsentzatos | E/R diagram, family members | FamilyMembers, SecondaryFamilyMembers, MinorGuardians | — | — | design 1–2, item 3 | 12, 17 | family |
| 5 — Ahmed Khanji | Teams, sessions, formations | Teams, Sessions, TeamFormations, FormationPlayers | v_Formations, v_Assignments | 6–12 | 5, 6 | 16, 18, 19 | teams, sessions |

Every member also does three things for their own tables only: the sample data, the functional dependencies and BCNF check (design items 3–5), and the integrity tests of their own rules (items 20–21).

## Starting kit (day one)

Everyone gets the same three things on day one. Any query, trigger or page can then be built and tested right away, even one that reads another member's tables.

- **The agreed schema:** all 21 tables with their columns, keys and foreign keys (`CBCS_Main_1_Tables.sql`). It is the contract between the parts.
- **The baseline views, triggers and sample data** (`CBCS_Main_2_Views_Triggers.sql`, `CBCS_Main_3_Data.sql`), so there are real rows to test against.
- **The site base:** `config.php`, `lib.php` and `style.css`, which every page uses.

Each member then builds a **private copy on their own laptop**, so nobody's tests touch anyone else's data:

1. Install XAMPP and start **Apache** and **MySQL Database** (XAMPP's MySQL is MariaDB; the scripts run on it unchanged).
2. In DBeaver, connect to `localhost`, port 3306, user `root`, no password, and create a database named `cbcs`.
3. Run scripts 1, 2 and 3 in it. Running them again resets your copy at any time.
4. Copy the web folder to XAMPP's `htdocs/cbcs`, and in its `config.php` use host `localhost`, database `cbcs`, user `root` and an empty password. The site is at `http://localhost/cbcs/`.

## Member 1 — Said: locations, personnel and the site base

Said owns where the club operates and who works there, the site base every page uses, and putting the finished site on AITS.

- [ ] **Tables:** PostalCodes, Locations, LocationPhones, Personnel, PersonnelAssignments, with their keys, foreign keys and CHECKs (Head/Branch, role, mandate, end date after start date, a general manager is an Administrator).
- [ ] **Sample data** for these tables, with past assignments (an end date) as well as current ones.
- [ ] **Triggers 1 and 2:** only one Head location, on insert and on update.
- [ ] **Trigger 3:** a personnel member has one location and one role at a time (no overlapping assignments).
- [ ] **Item 1:** create, display, edit and delete a location, with its phone numbers.
- [ ] **Item 2:** create, display, edit and delete a personnel member; moving someone ends the current assignment and starts a new one.
- [ ] **Queries 10 and 15**, each returning at least 5 rows.
- [ ] **Web pages:** `locations.php`, `personnel.php`, `triggers.php`, `index.php` and `check.php`. Said also keeps the site base (`config.php`, `lib.php`, `style.css`) working for everyone.
- [ ] **Normal forms:** the functional dependencies of these 5 tables and the BCNF check.
- [ ] **Integrity tests** for triggers 1–3, the general-manager CHECK, and deleting a location still in use.
- [ ] **Final deploy:** copy the site to `/www/groups/x/xp_comp353_2` on AITS and confirm `check.php` reports 21 tables and 12 triggers.

## Member 2 — Azmain: club members

Azmain owns the people who play for the club: who they are, where they belong over time, their hobbies and their measurements.

- [ ] **Tables:** ClubMembers (with gender), MemberLocations (one row per period at a location), Hobbies, MemberHobbies, MemberMeasurements, with their keys, foreign keys and CHECKs (at least 6 years old when joining, gender F or M).
- [ ] **Sample data:** majors and minors, boys and girls, at several locations, some who changed location; hobbies; measurements over time.
- [ ] **Views:** `v_LatestMeasurement` (latest height and weight) and `v_CurrentLocation` (the period with no end date).
- [ ] **Trigger 4:** a member is at one location at a time (no overlapping periods).
- [ ] **Trigger 5:** a location cannot take more active members than its maximum capacity.
- [ ] **Item 4:** create, display, edit and delete a club member, major and minor (a minor must get a family member; moving a member ends the current period and starts a new one).
- [ ] **Queries 8, 9 and 13**, each returning at least 5 rows.
- [ ] **Web page:** `members.php`.
- [ ] **Normal forms:** the functional dependencies of these 5 tables and the BCNF check.
- [ ] **Integrity tests** for triggers 4 and 5, the joining age, a duplicate SSN and an unknown hobby.

## Member 3 — Dexter: payments, member status, NBA games and emails

Dexter owns the money side (fees, donations, active or inactive), the NBA games, and the weekly emails.

- [ ] **Tables:** Payments, NBA_Games, GameParticipations, EmailLog, with their keys, foreign keys and CHECKs (amount above 0, Cash/Debit/Credit, at most 4 installments per year).
- [ ] **Sample data:** payments over several years (exact fees, donations, installments, unpaid years), NBA games and who played in them, and one past week of emails in the log.
- [ ] **Views:** `v_AnnualPayments` (paid per year against the $100 minor / $200 major fee), `v_ActiveMembers` and `v_MemberStatus` (active when last year's fee is paid), `v_NBAWins` (games a member won), `v_SessionEmails` (the text of each email).
- [ ] **Item 7:** make a payment for a club member (next installment number, total against the fee, donation).
- [ ] **Item 22:** generate the emails of the coming week into EmailLog without duplicates, show the log, and the weekly event `evt_WeeklyEmails`.
- [ ] **Queries 11 and 14**, each returning at least 5 rows.
- [ ] **Web pages:** `payments.php`, `emails.php`, and `queries.php` (runs any of queries 8–19 with its parameters).
- [ ] **Normal forms:** the functional dependencies of these 4 tables and the BCNF check.
- [ ] **Integrity tests** for a fifth installment and a payment method outside the list.

## Member 4 — Nicholas: E/R diagram and family members

Nicholas owns the E/R diagram of the whole database, and the family members linked to the minors. The diagram is drawn from the agreed schema, so it doesn't hold anyone up and nothing waits for it.

- [ ] **E/R diagram (design item 1)** in draw.io: all entity sets, weak entity sets, relationships and attributes, in the notation of the course slides (DB02).
- [ ] **Constraints (design item 2):** keys underlined, arrows for many-one and exactly-one, and the list of rules the diagram cannot show (one Head location, two teams per session, 3 hours between sessions, and the others).
- [ ] **Schema refinement (design item 3):** moving city and province into PostalCodes, which the four address tables share.
- [ ] **Tables:** FamilyMembers, SecondaryFamilyMembers, MinorGuardians, with their keys, foreign keys and CHECKs (the relationship list).
- [ ] **Sample data:** primary family members (some also club members, some with no child), secondary family members, and the family member of every minor.
- [ ] **Item 3:** create, display, edit and delete a family member, primary and secondary.
- [ ] **Queries 12 and 17**, each returning at least 5 rows.
- [ ] **Web page:** `family.php`.
- [ ] **Normal forms:** the functional dependencies of these 3 tables and the BCNF check.
- [ ] **Integrity tests** for deleting a family member who still has a minor, and registering a minor without one.

## Member 5 — Ahmed: teams, sessions and team formations

Ahmed owns the games and training sessions, who plays in them, and most of the triggers.

- [ ] **Tables:** Teams (a location, boys or girls), Sessions (game or training, date, start time, address), TeamFormations (team, head coach, score), FormationPlayers (player and role), with their keys, foreign keys and CHECKs.
- [ ] **Sample data:** teams at several locations, past and upcoming sessions, two formations per session, and players in every role.
- [ ] **Views:** `v_Formations` (a formation with its session and team) and `v_Assignments` (a player with the formation details).
- [ ] **Trigger 6:** a session has two teams.
- [ ] **Triggers 7, 8 and 9:** a player has the team's gender, belongs to the team's location on the session date, and has paid the fees.
- [ ] **Triggers 10, 11 and 12:** 3 hours between a player's sessions on the same day, only the role of an assignment can be edited, and the 3-hour rule when a session is moved.
- [ ] **Item 5:** create, display, edit and delete a team formation.
- [ ] **Item 6:** assign, edit and delete a player in a team formation, including the conflicting assignment the description asks to show.
- [ ] **Queries 16, 18 and 19**, each returning at least 5 rows.
- [ ] **Web pages:** `teams.php` and `sessions.php`.
- [ ] **Normal forms:** the functional dependencies of these 4 tables and the BCNF check.
- [ ] **Integrity tests** for triggers 6–12 and a player role outside the list.

## Rules everyone follows

**Working on your own:**

- Build and test on your private copy. Edit only your own tables, your sections of the shared scripts, and your own pages.
- The agreed schema is the contract. You may add CHECKs and constraints to your own tables; a change to a column, a key or the columns of a view is posted in the group chat first, because other parts read it.
- The fee rule ($100 for a minor, $200 for a major, last year's fee paid) appears in Dexter's `v_ActiveMembers` and in Ahmed's trigger 9: keep the two identical.
- If you need more rows in someone else's table to test a query, add them to your own copy and post them in the chat for the shared data script.

**Where the work goes.** The seven shared scripts, run in this order: `1_Tables`, `2_Views_Triggers`, `3_Data`, `4_Transactions` (items 1–7), `5_Queries` (8–19), `6_Integrity_Tests` (20–21), `7_Emails` (22). Add your part under your own name in each script.

**Conventions:**

- Tables in PascalCase; attributes in camelCase, except SSN and DOB; `Num`, not `No` (medicareNum).
- Scripts indented with tabs.
- Triggers read the base tables, never the views: the AITS server dropped the connection when our triggers read views. Write them between `DELIMITER //` and `DELIMITER ;`.
- Every query returns at least 5 rows on the sample data.
- The AITS server is the reference: if something behaves differently on your XAMPP copy, what AITS does counts.

**Final build (last week before November 30):**

1. Run scripts 1 to 7 on the group database `xpc353_2` in DBeaver, over the Concordia VPN.
2. Said copies the site to AITS.
3. Each member checks their own part there and takes the screenshots of their queries and pages.

Run the integrity tests one statement at a time (Ctrl+Enter): the rejected ones are supposed to fail.
