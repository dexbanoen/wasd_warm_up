<?php
// Home page: a few counts of what is in the database; each card links to its page.
require 'lib.php';
page_start('Home');
$cards = array(
    'Locations' => array('SELECT COUNT(*) FROM Locations', 'locations.php'),
    'Personnel' => array('SELECT COUNT(*) FROM Personnel', 'personnel.php'),
    'Club members' => array('SELECT COUNT(*) FROM ClubMembers', 'members.php'),
    'Active members' => array("SELECT COUNT(*) FROM v_MemberStatus WHERE status = 'Active'", 'members.php'),
    'Family members' => array('SELECT COUNT(*) FROM FamilyMembers', 'family.php'),
    'Teams' => array('SELECT COUNT(*) FROM Teams', 'teams.php'),
    'Sessions' => array('SELECT COUNT(*) FROM Sessions', 'sessions.php'),
    'Emails logged' => array('SELECT COUNT(*) FROM EmailLog', 'emails.php'));
echo '<div class="cards">';
foreach ($cards as $label => list($sql, $page))
    echo '<a class="card" href="' . $page . '"><b>' . q($sql)->fetchColumn() . '</b>' . h($label) . '</a>';
echo '</div>';
