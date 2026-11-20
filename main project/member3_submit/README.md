# Member 3 — Dexter Banoen Garde

Payments, member status, NBA games and emails. The agreed schema is unchanged: no column, key or view column differs from the starting kit.

## Where each file goes

| File | Goes in | Change to the shared file |
|---|---|---|
| `sql/M3_1_Tables.sql` | script 1, Tables (sections 5, 6, 8) | none, comments only |
| `sql/M3_2_Views.sql` | script 2, Views and Triggers | none, comments only |
| `sql/M3_3_Data.sql` | script 3, Data (sections 5, 6, 8) | none, comments only |
| `sql/M3_4_Transactions.sql` | script 4, Transactions, item 7 | **replaces steps 7a–7b; step 7c stays** |
| `sql/M3_5_Queries.sql` | script 5, Queries 11 and 14 | none, comments only |
| `sql/M3_6_Integrity_Tests.sql` | script 6, tests 17 and 18 | none |
| `sql/M3_7_Emails.sql` | script 7, Emails (whole script) | none, comments only |
| `web/payments.php` | site folder | **replaces the file** |
| `web/emails.php` | site folder | **replaces the file** |
| `report/NORMAL_FORMS.md` | report: functional dependencies and BCNF of the 4 tables | new |
| `report/REPORT_MEMBER3.md` | report: assumptions, functionalities, contributions | new |

`queries.php` and `queries_data.php` are unchanged.

## What changed in behaviour

- Item 7: the installment number is calculated (highest of that member and year, plus 1).
- `payments.php`: the fee shown uses the same rule as `v_AnnualPayments`; a `stillToPay` column was added.
- `emails.php`: shows the event `evt_WeeklyEmails` and the state of the event scheduler.

## Notes for the team

- The fee rule is written three times: `v_ActiveMembers`, trigger 5 and trigger 9. Keep them identical.
- In script 3, payments must be inserted before the formation players (trigger 9 checks them), and the email log after them.
- The event needs the server's event scheduler ON. If AITS refuses `CREATE EVENT`, the Generate button on `emails.php` runs the same statement.
