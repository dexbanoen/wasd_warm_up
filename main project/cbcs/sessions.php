<?php
require 'lib.php';
$a = get('a', 'list'); $error = ''; $sid = get('id');
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        $sid = post('sessionID', $sid);
        if ($a == 'delete') {
            q('DELETE FROM Sessions WHERE sessionID = ?', array(post('id')));
            go('sessions.php?msg=' . urlencode('Session deleted, with its team formations and their players.'));
        } elseif ($a == 'save') {
            if (post('id') === '') {
                q('INSERT INTO Sessions (type, sessionDate, startTime, address) VALUES (?, ?, ?, ?)', array(post('type'), post('sessionDate'), post('startTime'), post('address')));
                $sid = db()->lastInsertId();
            } else {
                $sid = post('id');
                q('UPDATE Sessions SET type = ?, sessionDate = ?, startTime = ?, address = ? WHERE sessionID = ?',
                    array(post('type'), post('sessionDate'), post('startTime'), post('address'), $sid));
            }
        } elseif ($a == 'addformation') {
            q('INSERT INTO TeamFormations (sessionID, teamID, headCoachID, score) VALUES (?, ?, ?, ?)', array($sid, post('teamID'), post('headCoachID'), nul(post('score'))));
        } elseif ($a == 'editformation') {
            q('UPDATE TeamFormations SET headCoachID = ?, score = ? WHERE formationID = ?', array(post('headCoachID'), nul(post('score')), post('formationID')));
        } elseif ($a == 'delformation') {
            q('DELETE FROM TeamFormations WHERE formationID = ?', array(post('formationID')));
        } elseif ($a == 'assign') {
            // triggers 7 to 10 check this INSERT
            q('INSERT INTO FormationPlayers (formationID, memberID, role) VALUES (?, ?, ?)', array(post('formationID'), post('memberID'), post('role')));
        } elseif ($a == 'editplayer') {
            q('UPDATE FormationPlayers SET role = ? WHERE formationID = ? AND memberID = ?', array(post('role'), post('formationID'), post('memberID')));
        } elseif ($a == 'delplayer') {
            q('DELETE FROM FormationPlayers WHERE formationID = ? AND memberID = ?', array(post('formationID'), post('memberID')));
        }
        go('sessions.php?a=view&id=' . $sid . '&msg=' . urlencode('Saved.'));
    } catch (PDOException $e) {
        $error = friendly($e);
        $a = ($a == 'delete') ? 'list' : (($a == 'save') ? (post('id') === '' ? 'new' : 'edit') : 'view');
        if ($a == 'edit') $sid = post('id');
    }
}
page_start('Team formations');
show_error($error);
if ($a == 'new' || $a == 'edit') {
    $r = array('sessionID' => '', 'type' => 'Game', 'sessionDate' => date('Y-m-d'), 'startTime' => '10:00', 'address' => '');
    if ($a == 'edit') $r = row('SELECT * FROM Sessions WHERE sessionID = ?', array($sid));
    if ($_POST) $r = array_merge($r, $_POST);
    echo '<form method="post" class="box" action="sessions.php?a=save"><input type="hidden" name="id" value="' . h($r['sessionID']) . '">';
    select('Type', 'type', array('Game' => 'Game', 'Training' => 'Training'), $r['type']);
    field('Date', 'sessionDate', $r['sessionDate'], 'date', 'required');
    field('Start time', 'startTime', substr($r['startTime'], 0, 5), 'time', 'required');
    field('Address', 'address', $r['address'], 'text', 'required');
    echo '<div class="wide"><button>Save</button> <a class="btn" href="sessions.php">Cancel</a></div></form>';
} elseif ($a == 'view') {
    $s = row('SELECT * FROM Sessions WHERE sessionID = ?', array($sid));
    echo '<p class="bar"><a class="btn" href="sessions.php">Back to the list</a> <a class="btn" href="sessions.php?a=edit&id=' . h($sid) . '">Edit date, time, address</a></p>';
    echo '<dl><dt>session</dt><dd>' . h($s['sessionID']) . '</dd><dt>type</dt><dd>' . h($s['type']) . '</dd><dt>date and time</dt><dd>' . h($s['sessionDate'] . ' at ' . substr($s['startTime'], 0, 5))
        . '</dd><dt>address</dt><dd>' . h($s['address']) . '</dd></dl>';
    $coaches = options("SELECT personnelID, CONCAT(firstName, ' ', lastName) FROM Personnel ORDER BY firstName, lastName");
    $forms = rows('SELECT f.*, l.name AS locationName FROM v_Formations f JOIN Locations l ON l.locationID = f.locationID WHERE f.sessionID = ? ORDER BY f.formationID', array($sid));
    echo '<div class="cols">';
    foreach ($forms as $f) {
        $fid = $f['formationID'];
        echo '<div><h2>' . h($f['teamName']) . ' (' . h($f['locationName']) . ', ' . ($f['gender'] == 'M' ? 'boys' : 'girls') . ') - formation ' . h($fid) . '</h2>';
        echo '<form method="post" class="box" action="sessions.php?a=editformation&id=' . h($sid) . '"><input type="hidden" name="formationID" value="' . h($fid) . '">';
        select('Head coach', 'headCoachID', $coaches, $f['headCoachID']);
        field('Score', 'score', $f['score'], 'number', 'min="0"');
        echo '<div><button>Save</button></div></form>';
        echo '<form method="post" class="inline" action="sessions.php?a=delformation&id=' . h($sid) . '" onsubmit="return confirm(\'Delete this team formation?\')">'
            . '<input type="hidden" name="formationID" value="' . h($fid) . '"><p><button class="danger">Delete this team formation</button></p></form>';
        echo '<h3>Players</h3><div class="scroll"><table><tr><th>number</th><th>player</th><th>role</th><th></th></tr>';
        foreach (rows('SELECT fp.memberID, c.firstName, c.lastName, fp.role FROM FormationPlayers fp JOIN ClubMembers c ON c.memberID = fp.memberID WHERE fp.formationID = ? ORDER BY c.memberID', array($fid)) as $p) {
            echo '<tr><td>' . h($p['memberID']) . '</td><td>' . h($p['firstName'] . ' ' . $p['lastName']) . '</td><td>';
            echo '<form method="post" class="inline" action="sessions.php?a=editplayer&id=' . h($sid) . '"><input type="hidden" name="formationID" value="' . h($fid) . '"><input type="hidden" name="memberID" value="' . h($p['memberID']) . '"><select name="role">';
            foreach ($ROLES as $role) echo '<option' . ($role == $p['role'] ? ' selected' : '') . '>' . h($role) . '</option>';
            echo '</select> <button class="small">Change role</button></form></td><td>';
            echo '<form method="post" class="inline" action="sessions.php?a=delplayer&id=' . h($sid) . '"><input type="hidden" name="formationID" value="' . h($fid) . '"><input type="hidden" name="memberID" value="' . h($p['memberID']) . '"><button class="danger">Remove</button></form></td></tr>';
        }
        echo '</table></div>';
        // every club member can be chosen, so that the rules can be seen being enforced
        echo '<form method="post" class="box" action="sessions.php?a=assign&id=' . h($sid) . '"><input type="hidden" name="formationID" value="' . h($fid) . '">';
        select('Assign club member', 'memberID', options("SELECT c.memberID, CONCAT(c.memberID, ' ', c.firstName, ' ', c.lastName, ' (', c.gender, ', ', l.name, ', ', st.status, ')')
            FROM ClubMembers c JOIN v_MemberStatus st ON st.memberID = c.memberID LEFT OUTER JOIN v_CurrentLocation cl ON cl.memberID = c.memberID
                LEFT OUTER JOIN Locations l ON l.locationID = cl.locationID ORDER BY c.memberID"));
        select('Role', 'role', $ROLES);
        echo '<div><button>Assign</button></div></form></div>';
    }
    echo '</div>';
    if (count($forms) < 2) {
        echo '<h2>Add a team formation (a session has two teams)</h2><form method="post" class="box" action="sessions.php?a=addformation&id=' . h($sid) . '">';
        select('Team', 'teamID', options("SELECT t.teamID, CONCAT(t.name, ' (', l.name, ', ', t.gender, ')') FROM Teams t JOIN Locations l ON l.locationID = t.locationID ORDER BY t.name"));
        select('Head coach', 'headCoachID', $coaches);
        field('Score (empty until played)', 'score', '', 'number', 'min="0"');
        echo '<div><button>Add team formation</button></div></form>';
    }
} else {
    echo '<p class="bar"><a class="btn" href="sessions.php?a=new">New session</a></p>';
    table(rows("SELECT s.sessionID, s.type, s.sessionDate, s.startTime, s.address,
                    (SELECT GROUP_CONCAT(CONCAT(f.teamName, IF(f.score IS NULL, '', CONCAT(' ', f.score))) ORDER BY f.formationID SEPARATOR '  vs  ')
                     FROM v_Formations f WHERE f.sessionID = s.sessionID) AS teamsAndScores,
                    (SELECT COUNT(*) FROM v_Assignments a WHERE a.sessionID = s.sessionID) AS numPlayers
                FROM Sessions s ORDER BY s.sessionDate DESC, s.startTime DESC"),
        function ($r) {
            return '<a class="btn small" href="sessions.php?a=view&id=' . $r['sessionID'] . '">Display / formations</a> '
                . '<a class="btn small" href="sessions.php?a=edit&id=' . $r['sessionID'] . '">Edit</a> '
                . delete_button('sessions.php', $r['sessionID'], 'session ' . $r['sessionID']);
        });
}
