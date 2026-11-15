<?php
// Item 22: generate the emails for the sessions of the coming week, and show the email log.
// "Today" can be changed in the form to show what the system does on any Sunday.
require 'lib.php';
$error = ''; $day = get('day', post('day', date('Y-m-d')));
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        // the same statement as the weekly event evt_WeeklyEmails, with the chosen day in place of CURDATE()
        $st = q('INSERT INTO EmailLog (emailDate, sender, receiver, subject, body)
                 SELECT ?, v.sender, v.receiver, v.subject, LEFT(v.body, 100)
                 FROM v_SessionEmails v
                 WHERE v.sessionDate > ? AND v.sessionDate <= DATE_ADD(?, INTERVAL 7 DAY)
                     AND NOT EXISTS (SELECT * FROM EmailLog e WHERE e.receiver = v.receiver AND CAST(e.subject AS BINARY) = CAST(v.subject AS BINARY))',
            array($day, $day, $day));
        go('emails.php?day=' . $day . '&msg=' . urlencode($st->rowCount() . ' email(s) generated and logged.'));
    } catch (PDOException $e) { $error = friendly($e); }
}
page_start('Emails');
show_error($error);
echo '<p>Every Sunday the system writes an email to every club member assigned to a game or training session of the following 7 days. Each email is recorded in the log.</p>';
echo '<form method="get" class="box">';
field('Day the emails are generated (a Sunday)', 'day', $day, 'date', 'required');
echo '<div><button>Show the emails of the following week</button></div></form>';
$dayName = row('SELECT DAYNAME(?) AS d', array($day));
echo '<h2>Emails for the sessions after ' . h($dayName['d'] . ' ' . $day) . ' (next 7 days)</h2>';
table(rows('SELECT v.sender, v.receiver, v.subject, v.body FROM v_SessionEmails v
            WHERE v.sessionDate > ? AND v.sessionDate <= DATE_ADD(?, INTERVAL 7 DAY) ORDER BY v.sessionDate, v.sessionID, v.receiver', array($day, $day)));
echo '<form method="post" action="emails.php"><input type="hidden" name="day" value="' . h($day) . '"><p><button>Generate these emails and record them in the log</button></p></form>';
echo '<h2>Email log (newest first)</h2>';
table(rows('SELECT emailID, emailDate, sender, receiver, subject, body FROM EmailLog ORDER BY emailID DESC'));
page_end();
