# Member 3 — Functional dependencies and BCNF check

Tables: Payments, NBA_Games, GameParticipations, EmailLog (design items 3 to 5).

**The test used.** A relation is in BCNF when, for every non-trivial functional dependency X → Y that holds in it, X is a superkey. So for each table: list the dependencies, find the keys, and check that every left side is a key.

**Result.** All four tables are in BCNF, so they are also in 3NF and nothing has to be decomposed.

---

## 1. Payments

`Payments(paymentID, memberID, paymentDate, amount, method, membershipYear, installmentNum)`

Functional dependencies:

- FD1: paymentID → memberID, paymentDate, amount, method, membershipYear, installmentNum
- FD2: memberID, membershipYear, installmentNum → paymentID, paymentDate, amount, method

Candidate keys: {paymentID} (the primary key) and {memberID, membershipYear, installmentNum} (declared UNIQUE).

BCNF check: the left side of FD1 and the left side of FD2 are both candidate keys. No other dependency holds:

- memberID alone does not determine anything, because a member has many payments.
- paymentDate does not determine membershipYear: a payment made in December 2024 can be for the 2025 membership (members 1 and 11 in the sample data).
- memberID, membershipYear does not determine the amount: the year can be paid in up to 4 installments of different amounts.

**In BCNF.**

Why the fee, the donation and the status are not columns: the fee depends on the member's age in that year, the donation is total paid minus fee, and the status depends on last year's total. All three can be calculated from Payments and ClubMembers, so they are views (`v_AnnualPayments`, `v_ActiveMembers`, `v_MemberStatus`). Storing them would repeat information and let it go out of date.

## 2. NBA_Games

`NBA_Games(gameID, gameDate, gameLocation, homeTeam, awayTeam, homeScore, awayScore)`

Functional dependencies:

- FD1: gameID → gameDate, gameLocation, homeTeam, awayTeam, homeScore, awayScore

Candidate key: {gameID}.

BCNF check: the only left side is the key. gameLocation is not determined by homeTeam (in the sample data the Raptors are the home team in Montréal and in Québec), and two teams can meet more than once, so the teams do not determine the date or the score.

**In BCNF.**

## 3. GameParticipations

`GameParticipations(memberID, gameID, teamPlayedFor, points, details)`

Functional dependencies:

- FD1: memberID, gameID → teamPlayedFor, points, details

Candidate key: {memberID, gameID}.

BCNF check: the only left side is the key. There is no partial dependency:

- gameID alone does not determine teamPlayedFor: members play on both sides of the same game (game 1: member 1 for the Raptors, member 2 for the Celtics).
- memberID alone does not determine teamPlayedFor: a member plays for different teams in different games (member 5: Celtics in game 1, Lakers in game 6).

**In BCNF.**

Why the opponent, the final score and "won or lost" are not columns: they are facts about the game, already in NBA_Games. The team played against is the other team of the game, and a win is calculated by the view `v_NBAWins`. Storing them here would repeat the score on every participation row.

## 4. EmailLog

`EmailLog(emailID, emailDate, sender, receiver, subject, body)`

Functional dependencies:

- FD1: emailID → emailDate, sender, receiver, subject, body

Candidate key: {emailID}.

BCNF check: the only left side is the key. The system never logs the same receiver and subject twice (the NOT EXISTS condition of the generating statement), so receiver, subject → emailID, emailDate, sender, body also holds in practice; its left side would then be a second candidate key, which still satisfies BCNF.

**In BCNF.**

Why sender and receiver are text and not foreign keys: the log records what was sent at that moment. It must stay the same if a location is renamed, a member changes email address or a member is deleted later.

---

## Constraints of these tables (for design item 3)

| Table | Primary key | Foreign keys | Other constraints |
|---|---|---|---|
| Payments | paymentID | memberID → ClubMembers | UNIQUE (memberID, membershipYear, installmentNum); amount > 0; method in Cash, Debit, Credit; installmentNum 1 to 4; membershipYear 2000 to 2100 |
| NBA_Games | gameID | — | scores ≥ 0; homeTeam ≠ awayTeam |
| GameParticipations | (memberID, gameID) | memberID → ClubMembers, gameID → NBA_Games | points ≥ 0 |
| EmailLog | emailID | — | all columns NOT NULL |

Rules that a table constraint cannot express, and where they are enforced instead:

- "Total above the fee is a donation" and "inactive when last year's fee is not fully paid": calculated by the views.
- "An inactive member cannot play": trigger 9 (Ahmed), which repeats the rule of `v_ActiveMembers` on the base tables.
- "No email is logged twice": the NOT EXISTS condition of the generating statement and of the event.
