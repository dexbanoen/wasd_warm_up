-- ============================================================
-- Member 3 - Dexter Banoen Garde
-- This is shared script 7 (Emails), item 22, in full.
-- Steps 1 to 4 are the demonstration; steps 5 and 6 create and show the weekly event.
-- ============================================================

-- 1. The emails of the coming week, in full, before they are logged.
-- "Coming week" = the 7 days after today: run on a Sunday, that is Monday to the next Sunday.
SELECT v.sender, v.receiver, v.subject, v.body
FROM v_SessionEmails v
WHERE v.sessionDate > CURDATE()
	AND v.sessionDate <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
ORDER BY v.sessionDate, v.sessionID, v.receiver;

-- 2. Generate the emails: one row in EmailLog per email, with the first 100 characters of the body.
-- The NOT EXISTS condition skips an email that is already in the log (same receiver and same subject;
-- the subject holds the team, the date and the time, so it identifies the session).
-- Running the statement twice therefore does not log the same email twice.
-- CAST(... AS BINARY) compares the two subjects byte by byte, which avoids a collation error between
-- the view and the table.
INSERT INTO EmailLog (emailDate, sender, receiver, subject, body)
SELECT CURDATE(), v.sender, v.receiver, v.subject, LEFT(v.body, 100)
FROM v_SessionEmails v
WHERE v.sessionDate > CURDATE()
	AND v.sessionDate <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
	AND NOT EXISTS (
		SELECT *
		FROM EmailLog e
		WHERE e.receiver = v.receiver
			AND CAST(e.subject AS BINARY) = CAST(v.subject AS BINARY)
	);

-- 3. The log of the emails produced by the system, newest first.
SELECT emailID, emailDate, sender, receiver, subject, body
FROM EmailLog
ORDER BY emailID DESC;

-- 4. The number of emails generated on each date. Run statement 2 again and then this one:
-- the numbers do not change, which shows there are no duplicates.
SELECT emailDate, COUNT(*) AS numEmails
FROM EmailLog
GROUP BY emailDate
ORDER BY emailDate;

-- 5. Automation: the event below makes MySQL run statement 2 by itself every week,
-- counted from Sunday November 15, 2026 at 8:00, so it always runs on a Sunday.
DROP EVENT IF EXISTS evt_WeeklyEmails;

CREATE EVENT evt_WeeklyEmails
ON SCHEDULE EVERY 1 WEEK STARTS '2026-11-15 08:00:00'
DO
	INSERT INTO EmailLog (emailDate, sender, receiver, subject, body)
	SELECT CURDATE(), v.sender, v.receiver, v.subject, LEFT(v.body, 100)
	FROM v_SessionEmails v
	WHERE v.sessionDate > CURDATE()
		AND v.sessionDate <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
		AND NOT EXISTS (
			SELECT *
			FROM EmailLog e
			WHERE e.receiver = v.receiver
				AND CAST(e.subject AS BINARY) = CAST(v.subject AS BINARY)
		);

-- 6. The event, and whether the scheduler that runs events is on.
SELECT EVENT_NAME, INTERVAL_VALUE, INTERVAL_FIELD, STARTS, STATUS
FROM information_schema.EVENTS
WHERE EVENT_SCHEMA = DATABASE();

SELECT @@event_scheduler AS eventScheduler;
