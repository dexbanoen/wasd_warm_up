<?php
require 'lib.php';
page_start('Triggers and integrity');
echo '<p>Every rule below is enforced by the database itself. To see one at work, try the action in the page named in the last column: the database rejects it and the page shows the message.</p>';
$tests = array(
    array('A player needs at least 3 hours between two sessions on the same day', 'trigger trg_Player_ThreeHours', 'Team formations: assign a player who already has a session that day'),
    array('Boys and girls are not mixed in a team formation', 'trigger trg_Player_SameGender', 'Team formations: assign a girl to a boys team'),
    array('All players of a team are members of the team\'s location', 'trigger trg_Player_SameLocation', 'Team formations: assign a member of another location'),
    array('A member whose fees are not paid cannot play', 'trigger trg_Player_FeesPaid', 'Team formations: assign an inactive member'),
    array('A session has two teams', 'trigger trg_TeamFormations_TwoTeams', 'Team formations: the form to add a team disappears after two'),
    array('Changing a session time keeps the 3-hour rule', 'trigger trg_Sessions_ThreeHours', 'Team formations: edit the time of a session'),
    array('The club has only one Head location', 'triggers trg_Locations_OneHead_*', 'Locations: create a second Head'),
    array('Personnel: one location and one role at a time', 'trigger trg_PersonnelAssignments_NoOverlap', 'Personnel: the new assignment form ends the current one first'),
    array('A member is at one location at a time', 'trigger trg_MemberLocations_NoOverlap', 'Club members: the move form ends the current period first'),
    array('A location cannot exceed its capacity of active members', 'trigger trg_MemberLocations_Capacity', 'Club members: register at a full location'),
    array('A new member is at least 6 years old', 'CHECK ck_join_age', 'Club members: create a member younger than 6'),
    array('At most 4 installments per membership year', 'CHECK PaymentMaxFourInstallments', 'Payments: make a fifth payment for the same year'),
    array('Unique SSN and medicare card number', 'UNIQUE', 'Create a person with an SSN already used in the same table'),
    array('A minor keeps a family member', 'FOREIGN KEY', 'Family members: delete one who still has a minor'));
$out = array();
foreach ($tests as $t) $out[] = array('Rule' => $t[0], 'Enforced by' => $t[1], 'How to see it' => $t[2]);
table($out);
echo '<h2>Triggers defined in the database</h2>';
foreach (rows('SELECT TRIGGER_NAME, ACTION_TIMING, EVENT_MANIPULATION, EVENT_OBJECT_TABLE, ACTION_STATEMENT
               FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = DATABASE() ORDER BY EVENT_OBJECT_TABLE, TRIGGER_NAME') as $t) {
    echo '<h3>' . h($t['TRIGGER_NAME']) . '</h3>';
    echo '<pre>CREATE TRIGGER ' . h($t['TRIGGER_NAME']) . "\n" . h($t['ACTION_TIMING'] . ' ' . $t['EVENT_MANIPULATION'] . ' ON ' . $t['EVENT_OBJECT_TABLE'])
        . "\nFOR EACH ROW\n" . h($t['ACTION_STATEMENT']) . '</pre>';
}
