<?php
// Home page: a few counts and a map of the project items to the pages.
require 'lib.php';
page_start('Home');
$counts = array(
    'Locations' => 'SELECT COUNT(*) FROM Locations', 'Personnel' => 'SELECT COUNT(*) FROM Personnel',
    'Club members' => 'SELECT COUNT(*) FROM ClubMembers',
    'Active members' => "SELECT COUNT(*) FROM v_MemberStatus WHERE status = 'Active'",
    'Family members' => 'SELECT COUNT(*) FROM FamilyMembers', 'Teams' => 'SELECT COUNT(*) FROM Teams',
    'Sessions' => 'SELECT COUNT(*) FROM Sessions', 'Emails logged' => 'SELECT COUNT(*) FROM EmailLog');
echo '<div class="cards">';
foreach ($counts as $label => $sql) echo '<div class="card"><b>' . q($sql)->fetchColumn() . '</b>' . h($label) . '</div>';
echo '</div><h2>Project items</h2><ul class="plain">';
$items = array(
    '1. Create / Delete / Edit / Display a Location' => 'locations.php',
    '2. Create / Delete / Edit / Display a Personnel' => 'personnel.php',
    '3. Create / Delete / Edit / Display a FamilyMember (primary and secondary)' => 'family.php',
    '4. Create / Delete / Edit / Display a ClubMember (major and minor)' => 'members.php',
    '5. Create / Delete / Edit / Display a TeamFormation' => 'sessions.php',
    '6. Assign / Delete / Edit a club member to a team formation' => 'sessions.php',
    '7. Make a payment for a club member' => 'payments.php',
    '8 to 19. Queries' => 'queries.php',
    '20 and 21. Triggers and integrity of the requirements' => 'triggers.php',
    '22. Generation of emails and the email log' => 'emails.php');
foreach ($items as $label => $file) echo '<li><a href="' . $file . '">' . h($label) . '</a></li>';
echo '</ul>';
page_end();
