<?php
require 'lib.php';
$a = get('a', 'list');
$error = '';
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        if ($a == 'delete') {
            q('DELETE FROM ClubMembers WHERE memberID = ?', array(post('id')));
            go('members.php?msg=' . urlencode('Club member deleted, with everything that belonged to the member.'));
        }
        $id = post('id');
        db()->beginTransaction();
        if ($a == 'measure') {
            q('INSERT INTO MemberMeasurements (memberID, measureDate, heightCm, weightKg) VALUES (?, ?, ?, ?)',
                array($id, post('measureDate'), post('heightCm'), post('weightKg')));
        } elseif ($a == 'move') {
            // end the current period the day before, then start the new one
            q('UPDATE MemberLocations SET endDate = DATE_SUB(?, INTERVAL 1 DAY) WHERE memberID = ? AND endDate IS NULL',
                array(post('startDate'), $id));
            q('INSERT INTO MemberLocations (memberID, locationID, startDate, endDate) VALUES (?, ?, ?, NULL)',
                array($id, post('locationID'), post('startDate')));
        } else {
            // a minor (under 17 on the joining date) must have a family member
            $age = row('SELECT TIMESTAMPDIFF(YEAR, ?, ?) AS age', array(post('DOB'), post('joinDate')));
            if ($age['age'] < 17 && post('familyMemberID') === '')
                throw new Exception('Rejected: a minor club member must be associated with a family member.');
            $pc = save_postal(post('postalCode'), post('city'), post('province'));
            $values = array(post('firstName'), post('lastName'), post('DOB'), post('gender'), post('joinDate'),
                post('SSN'), post('medicareNum'), post('phone'), post('address'), $pc, post('email'));
            if ($id === '') {
                // memberID is not given: AUTO_INCREMENT assigns the club member number
                q('INSERT INTO ClubMembers (firstName, lastName, DOB, gender, joinDate, SSN, medicareNum, phone, address, postalCode, email)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', $values);
                $id = db()->lastInsertId();
                q('INSERT INTO MemberLocations (memberID, locationID, startDate, endDate) VALUES (?, ?, ?, NULL)',
                    array($id, post('locationID'), post('joinDate')));
                q('INSERT INTO MemberMeasurements (memberID, measureDate, heightCm, weightKg) VALUES (?, ?, ?, ?)',
                    array($id, post('joinDate'), post('heightCm'), post('weightKg')));
            } else {
                q('UPDATE ClubMembers SET firstName = ?, lastName = ?, DOB = ?, gender = ?, joinDate = ?, SSN = ?, medicareNum = ?, phone = ?,
                       address = ?, postalCode = ?, email = ? WHERE memberID = ?', array_merge($values, array($id)));
            }
            q('DELETE FROM MemberHobbies WHERE memberID = ?', array($id));
            if (isset($_POST['hobbies']))
                foreach ($_POST['hobbies'] as $hobbyID)
                    q('INSERT INTO MemberHobbies (memberID, hobbyID) VALUES (?, ?)', array($id, $hobbyID));
            q('DELETE FROM MinorGuardians WHERE memberID = ?', array($id));
            if (post('familyMemberID') !== '')
                q('INSERT INTO MinorGuardians (memberID, familyMemberID, relationship) VALUES (?, ?, ?)',
                    array($id, post('familyMemberID'), post('relationship')));
        }
        db()->commit();
        go('members.php?a=view&id=' . $id . '&msg=' . urlencode('Saved.'));
    } catch (Exception $e) {
        if (db()->inTransaction())
            db()->rollBack();
        $error = ($e instanceof PDOException) ? friendly($e) : $e->getMessage();
        if ($a == 'delete')
            $a = 'list';
        if ($a == 'measure' || $a == 'move') {
            $a = 'view';
            $_GET['id'] = post('id');
        }
    }
}
page_start('Club members');
show_error($error);
if ($a == 'new' || $a == 'edit') {
    $r = array('memberID' => '', 'firstName' => '', 'lastName' => '', 'DOB' => '', 'gender' => 'M', 'joinDate' => date('Y-m-d'), 'SSN' => '',
        'medicareNum' => '', 'phone' => '', 'address' => '', 'city' => '', 'province' => 'QC', 'postalCode' => '', 'email' => '',
        'locationID' => '', 'heightCm' => '', 'weightKg' => '', 'familyMemberID' => '', 'relationship' => 'Father');
    $hobbies = array();
    if ($a == 'edit') {
        $r = array_merge($r, row('SELECT c.*, pc.city, pc.province FROM ClubMembers c JOIN PostalCodes pc ON pc.postalCode = c.postalCode WHERE c.memberID = ?',
            array(get('id'))));
        $g = row('SELECT familyMemberID, relationship FROM MinorGuardians WHERE memberID = ?', array(get('id')));
        if ($g)
            $r = array_merge($r, $g);
        foreach (rows('SELECT hobbyID FROM MemberHobbies WHERE memberID = ?', array(get('id'))) as $x)
            $hobbies[] = $x['hobbyID'];
    }
    if ($_POST) {
        $r = array_merge($r, $_POST);
        $hobbies = isset($_POST['hobbies']) ? $_POST['hobbies'] : array();
    }
    echo '<form method="post" class="box" action="members.php?a=' . $a . '&id=' . h($r['memberID'])
        . '"><input type="hidden" name="id" value="' . h($r['memberID']) . '">';
    field('First name', 'firstName', $r['firstName'], 'text', 'required');
    field('Last name', 'lastName', $r['lastName'], 'text', 'required');
    field('Date of birth', 'DOB', $r['DOB'], 'date', 'required');
    select('Gender', 'gender', array('M' => 'Boy (M)', 'F' => 'Girl (F)'), $r['gender']);
    field('Joining date', 'joinDate', $r['joinDate'], 'date', 'required');
    field('Social Security Number (9 digits)', 'SSN', $r['SSN'], 'text', 'required maxlength="9"');
    field('Medicare card number', 'medicareNum', $r['medicareNum'], 'text', 'required maxlength="12"');
    field('Phone', 'phone', $r['phone'], 'text', 'required');
    field('Address', 'address', $r['address'], 'text', 'required');
    field('City', 'city', $r['city'], 'text', 'required');
    field('Province', 'province', $r['province'], 'text', 'required maxlength="2"');
    field('Postal code', 'postalCode', $r['postalCode'], 'text', 'required maxlength="7"');
    field('Email', 'email', $r['email'], 'email', 'required');
    if ($a == 'new') {
        select('Location', 'locationID', options('SELECT locationID, name FROM Locations ORDER BY name'), $r['locationID']);
        field('Height (cm)', 'heightCm', $r['heightCm'], 'number', 'required step="0.1"');
        field('Weight (kg)', 'weightKg', $r['weightKg'], 'number', 'required step="0.1"');
    }
    echo '<div class="wide"><b>Hobbies</b><br>';
    foreach (rows('SELECT hobbyID, name FROM Hobbies ORDER BY name') as $hb)
        echo '<label class="check"><input type="checkbox" name="hobbies[]" value="' . $hb['hobbyID'] . '"'
            . (in_array($hb['hobbyID'], $hobbies) ? ' checked' : '') . '>' . h($hb['name']) . '</label>';
    echo '</div><h2 class="wide">Family member (required for a minor, who is under 17)</h2>';
    select('Family member', 'familyMemberID',
        array('' => '(none)') + options("SELECT familyMemberID, CONCAT(firstName, ' ', lastName) FROM FamilyMembers ORDER BY firstName, lastName"),
        $r['familyMemberID']);
    select('Relationship', 'relationship', $RELATIONSHIPS, $r['relationship']);
    echo '<div class="wide"><button>Save</button> <a class="btn" href="members.php">Cancel</a></div></form>';
} elseif ($a == 'view') {
    $id = get('id');
    $r = row("SELECT c.memberID AS clubMemberNumber, c.firstName, c.lastName, c.DOB, TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) AS age, c.gender, c.joinDate,
                  c.SSN, c.medicareNum, c.phone, c.address, pc.city, pc.province, c.postalCode, c.email, l.name AS currentLocation, st.status,
                  lm.heightCm, lm.weightKg, CONCAT(f.firstName, ' ', f.lastName, ' (', g.relationship, ')') AS familyMember
              FROM ClubMembers c
                  JOIN PostalCodes pc ON pc.postalCode = c.postalCode
                  JOIN v_MemberStatus st ON st.memberID = c.memberID
                  LEFT OUTER JOIN v_CurrentLocation cl ON cl.memberID = c.memberID
                  LEFT OUTER JOIN Locations l ON l.locationID = cl.locationID
                  LEFT OUTER JOIN v_LatestMeasurement lm ON lm.memberID = c.memberID
                  LEFT OUTER JOIN MinorGuardians g ON g.memberID = c.memberID
                  LEFT OUTER JOIN FamilyMembers f ON f.familyMemberID = g.familyMemberID
              WHERE c.memberID = ?", array($id));
    echo '<p class="bar"><a class="btn" href="members.php">Back to the list</a> <a class="btn" href="members.php?a=edit&id=' . h($id) . '">Edit</a> '
        . '<a class="btn" href="payments.php?memberID=' . h($id) . '">Payments</a></p><dl>';
    foreach ($r as $k => $v)
        echo '<dt>' . h($k) . '</dt><dd>' . h($v) . '</dd>';
    echo '<dt>minor or major</dt><dd>' . ($r['age'] < 17 ? 'Minor' : 'Major') . '</dd>';
    $hb = rows('SELECT h.name FROM MemberHobbies mh JOIN Hobbies h ON h.hobbyID = mh.hobbyID WHERE mh.memberID = ? ORDER BY h.name',
        array($id));
    $names = array();
    foreach ($hb as $x)
        $names[] = $x['name'];
    echo '<dt>hobbies</dt><dd>' . h($names ? implode(', ', $names) : 'none') . '</dd></dl><div class="cols"><div>';
    echo '<h2>Locations (history)</h2>';
    table(rows('SELECT l.name AS location, ml.startDate, ml.endDate FROM MemberLocations ml JOIN Locations l ON l.locationID = ml.locationID WHERE ml.memberID = ? ORDER BY ml.startDate',
        array($id)));
    echo '<form method="post" class="box" action="members.php?a=move"><input type="hidden" name="id" value="' . h($id) . '">';
    select('Move to location', 'locationID', options('SELECT locationID, name FROM Locations ORDER BY name'));
    field('Starting on', 'startDate', date('Y-m-d'), 'date', 'required');
    echo '<div><button>Move</button></div></form></div><div><h2>Height and weight (history)</h2>';
    table(rows('SELECT measureDate, heightCm, weightKg FROM MemberMeasurements WHERE memberID = ? ORDER BY measureDate',
        array($id)));
    echo '<form method="post" class="box" action="members.php?a=measure"><input type="hidden" name="id" value="' . h($id) . '">';
    field('Date', 'measureDate', date('Y-m-d'), 'date', 'required');
    field('Height (cm)', 'heightCm', '', 'number', 'required step="0.1"');
    field('Weight (kg)', 'weightKg', '', 'number', 'required step="0.1"');
    echo '<div><button>Add measurement</button></div></form></div></div>';
    echo '<h2>Team formations the member is assigned to</h2>';
    table(rows('SELECT a.sessionDate, a.startTime, a.type, a.teamName, a.role, a.address FROM v_Assignments a WHERE a.memberID = ? ORDER BY a.sessionDate, a.startTime',
        array($id)));
} else {
    echo '<p class="bar"><a class="btn" href="members.php?a=new">New club member</a></p>';
    table(rows("SELECT c.memberID, c.firstName, c.lastName, c.gender, TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) AS age, l.name AS location, st.status, c.phone, c.email
                FROM ClubMembers c
                    JOIN v_MemberStatus st ON st.memberID = c.memberID
                    LEFT OUTER JOIN v_CurrentLocation cl ON cl.memberID = c.memberID
                    LEFT OUTER JOIN Locations l ON l.locationID = cl.locationID
                ORDER BY c.memberID"),
        function ($r) {
            return '<a class="btn small" href="members.php?a=view&id=' . $r['memberID'] . '">Display</a> '
                . '<a class="btn small" href="members.php?a=edit&id=' . $r['memberID'] . '">Edit</a> '
                . delete_button('members.php', $r['memberID'], 'member ' . $r['memberID'] . ' ' . $r['firstName'] . ' ' . $r['lastName']);
        });
}
