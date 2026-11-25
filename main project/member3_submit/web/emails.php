<?php
// Item 22: generate the emails for the sessions of the coming week, and show the email log.
// Member 3 - Dexter Banoen Garde. Uses the shared helpers of lib.php.
// "Today" can be changed in the form, to show what the system does on any Sunday.
require 'lib.php';

$error = '';
$day = get('day', post('day', date('Y-m-d')));    // the day the emails are generated

// ---------- 1. The "Generate" button was pressed: write the emails to the log ----------
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        // The same statement as the weekly event evt_WeeklyEmails, with the chosen day in place of CURDATE().
        // NOT EXISTS skips an email already in the log, so pressing the button twice adds nothing.
        $st = q('INSERT INTO EmailLog (emailDate, sender, receiver, subject, body)
                 SELECT ?, v.sender, v.receiver, v.subject, LEFT(v.body, 100)
                 FROM v_SessionEmails v
                 WHERE v.sessionDate > ? AND v.sessionDate <= DATE_ADD(?, INTERVAL 7 DAY)
                     AND NOT EXISTS (
                         SELECT * FROM EmailLog e
                         WHERE e.receiver = v.receiver
                             AND CAST(e.subject AS BINARY) = CAST(v.subject AS BINARY))',
            array($day, $day, $day));
        go('emails.php?day=' . $day . '&msg=' . urlencode($st->rowCount() . ' email(s) generated and logged.'));
    } catch (PDOException $e) {
        $error = ErroMSG($e);
    }
}

// ---------- 2. Show the page ----------
page_start('Emails');
show_error($error);
echo '<p>Every Sunday the system writes an email to every club member assigned to a game or training session of the following 7 days. Each email is recorded in the log.</p>';

// Choose the day.
echo '<form method="get" class="box">';
field('Day the emails are generated (a Sunday)', 'day', $day, 'date', 'required');
echo '<div><button>Show the emails of the following week</button></div></form>';

// The emails of the 7 days after that day, in full (the log keeps only the first 100 characters of the body).
$dayName = row('SELECT DAYNAME(?) AS d', array($day));
echo '<h2>Emails for the sessions after ' . h($dayName['d'] . ' ' . $day) . ' (next 7 days)</h2>';
if ($dayName['d'] != 'Sunday') echo '<p>Note: this day is a ' . h($dayName['d']) . '. The weekly event runs on Sundays.</p>';
table(rows('SELECT v.sender, v.receiver, v.subject, v.body
            FROM v_SessionEmails v
            WHERE v.sessionDate > ? AND v.sessionDate <= DATE_ADD(?, INTERVAL 7 DAY)
            ORDER BY v.sessionDate, v.sessionID, v.receiver', array($day, $day)));

echo '<form method="post" action="emails.php"><input type="hidden" name="day" value="' . h($day) . '">';
echo '<p><button>Generate these emails and record them in the log</button></p></form>';

// The log.
echo '<h2>Email log (newest first)</h2>';
table(rows('SELECT emailID, emailDate, sender, receiver, subject, body FROM EmailLog ORDER BY emailID DESC'));

// The weekly event that does the same thing automatically (created by script 7).
echo '<h2>Weekly event</h2>';
try {
    table(rows('SELECT EVENT_NAME, INTERVAL_VALUE, INTERVAL_FIELD, STARTS, STATUS
                FROM information_schema.EVENTS
                WHERE EVENT_SCHEMA = DATABASE()'));
    $scheduler = row('SELECT @@event_scheduler AS s');
    echo '<p>Event scheduler of the server: ' . h($scheduler['s']) . '. The event only runs by itself when it is ON.</p>';
} catch (PDOException $e) {
    show_error(ErroMSG($e));
}
page_end();
