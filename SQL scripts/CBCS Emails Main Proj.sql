-- 1. The emails of the coming week, in full, before they are logged.
SELECT v.sender, v.receiver, v.subject, v.body
FROM v_SessionEmails v
WHERE v.sessionDate > CURDATE()
	AND v.sessionDate <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
ORDER BY v.sessionDate, v.sessionID, v.receiver;

-- 2. Generate the emails: one row in EmailLog per email. The NOT EXISTS condition skips an email that is already in the log, so running the statement twice does not log the same email twice.
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

-- 4. The number of emails generated on each date.
SELECT emailDate, COUNT(*) AS numEmails
FROM EmailLog
GROUP BY emailDate
ORDER BY emailDate;

-- 5. Automation: the event below makes MySQL run statement 2 by itself every week, starting on Sunday November 15, 2026 at 8:00.
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

-- 6. The event, and when it runs next.
SELECT EVENT_NAME, INTERVAL_VALUE, INTERVAL_FIELD, STARTS, STATUS
FROM information_schema.EVENTS
WHERE EVENT_SCHEMA = DATABASE();
