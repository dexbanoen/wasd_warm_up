# Member 3 — text for the report

Ready-to-paste sections for the parts of the report that concern payments, member status, NBA games and emails. The normal-forms section is in `NORMAL_FORMS.md`.

---

## Assumptions

**Payments and status**

1. A member is a minor for a membership year when he or she is under 17 on January 1 of that year, and a major otherwise. The fee of the year ($100 or $200) follows from that, so a member who turns 17 during a year pays the minor fee for that year.
2. A payment is for one membership year, which is recorded separately from the payment date, because a year can be paid in advance (for example in December 2024 for 2025).
3. A membership year is paid in 1 to 4 installments. The system numbers them; a fifth is refused.
4. Any amount paid above the fee of a year is a donation. It is not carried over to another year.
5. A member is active when the fee of the previous year is fully paid. A member who joined during the current year has no previous year, so the fee of the current year is checked instead.
6. The fee, the donation and the status are never stored. They are calculated from the payments each time they are needed, so they cannot become out of date.

**NBA games**

7. An NBA game has a home team and an away team, which are different, and a final score for each.
8. A club member plays for one of the two teams of the game, and takes part in a game at most once.
9. A member won a game when the team he or she played for scored more than the other team.
10. In the queries, a member counts for the location he or she belongs to today, not the location at the time of the game.

**Emails**

11. An email about a session is sent to every club member assigned to one of the two team formations of that session. A member who is not assigned to any session of the week receives no email.
12. "The coming week" is the 7 days after the Sunday the emails are generated: Monday to the following Sunday.
13. The sender of an email is the location of the member's team; the receiver is the member's email address.
14. The log keeps the first 100 characters of the body, as the description asks. The complete body can be produced again at any time from the view.
15. The same email (same receiver and same subject) is logged only once, even if the generation is run several times.
16. The system records the emails in the log; it does not connect to a mail server.

---

## Functionalities implemented

**Item 7 — make a payment for a club member** (`payments.php`)
The user chooses a member, a membership year, an amount, a method and a date. The system gives the payment the next installment number of that member and year, then shows the total paid for each year against the fee, what is still to pay, the donation, and the member's status. Rejected with a message: a fifth installment, an amount of 0 or less, a method other than Cash, Debit or Credit.

**Queries 8 to 19** (`queries.php`)
One page runs any of the twelve queries. Queries with parameters (a member number, a location, a period) show a small form with default values. The result and the SQL are both displayed. Queries 11 and 14 are part of this section.

**Item 22 — emails** (`emails.php`)
The page shows the complete emails of the 7 days after a chosen Sunday, generates them into the log with one button, and shows the log. Generating twice adds nothing. The event `evt_WeeklyEmails` runs the same statement automatically every Sunday at 8:00.

---

## Views of this section

| View | What it gives | Used by |
|---|---|---|
| v_AnnualPayments | per member and year: total paid and the fee | payments page, item 7 |
| v_ActiveMembers | the members who are active today | v_MemberStatus |
| v_MemberStatus | 'Active' or 'Inactive' for every member | queries 13, 14, 15, member pages |
| v_NBAWins | one row per game a member won | queries 11, 13, 14, 15, 17 |
| v_SessionEmails | sender, receiver, subject and body of each email | item 22, the weekly event |

No trigger belongs to this section. The rule "an inactive member cannot play" is enforced by trigger 9 (Member 5), which repeats the rule of `v_ActiveMembers` on the base tables. The automation of this section is the scheduled event `evt_WeeklyEmails`.

---

## Contributions — Dexter Banoen Garde (Member 3)

- Tables Payments, NBA_Games, GameParticipations and EmailLog, with their keys, foreign keys and CHECK constraints.
- Sample data for these tables: payments over several years (exact fees, donations, installments, unpaid years), NBA games and participations, and one past week of emails.
- Views v_AnnualPayments, v_ActiveMembers, v_MemberStatus, v_NBAWins and v_SessionEmails.
- Item 7 (make a payment) and item 22 (generation and log of emails), with the weekly event evt_WeeklyEmails.
- Queries 11 and 14.
- Web pages payments.php, emails.php and queries.php (runs queries 8 to 19).
- Functional dependencies and BCNF check of the four tables.
- Integrity tests of the payment rules (fifth installment, payment method).

---

## Demo questions to be ready for

- **Why is the status a view and not a column?** It depends on the date and on the payments. A stored value would be wrong on January 1 of every year and after every payment.
- **Why two UNION branches in v_AnnualPayments?** One branch for the members under 17 that year (fee 100), one for the others (fee 200). Each member-year falls in exactly one branch.
- **How do you prevent a fifth installment?** The installment number is the highest existing one plus 1, and a CHECK constraint refuses any number above 4. The UNIQUE constraint refuses the same number twice.
- **How do you avoid duplicate emails?** The INSERT has a NOT EXISTS condition on receiver and subject. The subject contains the team, the date and the time, so it identifies the session.
- **How does the system send emails by itself?** A MySQL scheduled event runs the INSERT every week, counted from a Sunday at 8:00.
- **Why is the rule for "active" written in the triggers too?** On the AITS server a trigger that read a view dropped the connection, so triggers 5 and 9 repeat the rule on the base tables. The three copies must stay identical.
- **How do you know who won an NBA game?** v_NBAWins compares the score of the team the member played for with the score of the other team.
