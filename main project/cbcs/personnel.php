<?php
require 'lib.php';
$a = get('a', 'list'); $error = '';
$PROLES = array('Administrator' => 'Administrator', 'Captain' => 'Captain', 'Coach' => 'Coach', 'Assistant Coach' => 'Assistant Coach', 'Other' => 'Other');
$MANDATES = array('Salaried' => 'Salaried', 'Volunteer' => 'Volunteer');
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        if ($a == 'delete') {
            q('DELETE FROM Personnel WHERE personnelID = ?', array(post('id')));
            go('personnel.php?msg=' . urlencode('Personnel member deleted.'));
        }
        db()->beginTransaction();
        if ($a == 'assign') {
            // end the current assignment the day before, then start the new one
            $id = post('id');
            q('UPDATE PersonnelAssignments SET endDate = DATE_SUB(?, INTERVAL 1 DAY) WHERE personnelID = ? AND endDate IS NULL',
                array(post('startDate'), $id));
            q('INSERT INTO PersonnelAssignments (personnelID, locationID, startDate, endDate, role, title, mandate) VALUES (?, ?, ?, NULL, ?, ?, ?)',
                array($id, post('locationID'), post('startDate'), post('role'), post('title'), post('mandate')));
        } else {
            $pc = save_postal(post('postalCode'), post('city'), post('province'));
            $values = array(post('firstName'), post('lastName'), post('DOB'), post('SSN'), post('medicareNum'), post('phone'), post('address'), $pc, post('email'));
            if (post('id') === '') {
                q('INSERT INTO Personnel (firstName, lastName, DOB, SSN, medicareNum, phone, address, postalCode, email) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', $values);
                $id = db()->lastInsertId();
                q('INSERT INTO PersonnelAssignments (personnelID, locationID, startDate, endDate, role, title, mandate) VALUES (?, ?, ?, NULL, ?, ?, ?)',
                    array($id, post('locationID'), post('startDate'), post('role'), post('title'), post('mandate')));
            } else {
                $id = post('id');
                q('UPDATE Personnel SET firstName = ?, lastName = ?, DOB = ?, SSN = ?, medicareNum = ?, phone = ?, address = ?, postalCode = ?, email = ? WHERE personnelID = ?',
                    array_merge($values, array($id)));
            }
        }
        db()->commit();
        go('personnel.php?a=view&id=' . $id . '&msg=' . urlencode('Saved.'));
    } catch (PDOException $e) {
        if (db()->inTransaction()) db()->rollBack();
        $error = friendly($e);
        if ($a == 'delete') $a = 'list';
        if ($a == 'assign') { $a = 'view'; $_GET['id'] = post('id'); }
    }
}
page_start('Personnel');
show_error($error);
function assignment_fields($PROLES, $MANDATES) {
    select('Location', 'locationID', options('SELECT locationID, name FROM Locations ORDER BY name'), post('locationID'));
    select('Role', 'role', $PROLES, post('role', 'Coach'));
    field('Title (for example General Manager, Manager, Coach)', 'title', post('title'), 'text', 'required');
    select('Mandate', 'mandate', $MANDATES, post('mandate', 'Salaried'));
    field('Start date', 'startDate', post('startDate', date('Y-m-d')), 'date', 'required');
}
if ($a == 'new' || $a == 'edit') {
    $r = array('personnelID' => '', 'firstName' => '', 'lastName' => '', 'DOB' => '', 'SSN' => '', 'medicareNum' => '', 'phone' => '',
        'address' => '', 'city' => '', 'province' => 'QC', 'postalCode' => '', 'email' => '');
    if ($a == 'edit') $r = row('SELECT p.*, pc.city, pc.province FROM Personnel p JOIN PostalCodes pc ON pc.postalCode = p.postalCode WHERE p.personnelID = ?', array(get('id')));
    if ($_POST) $r = array_merge($r, $_POST);
    echo '<form method="post" class="box" action="personnel.php?a=' . $a . '&id=' . h($r['personnelID']) . '"><input type="hidden" name="id" value="' . h($r['personnelID']) . '">';
    field('First name', 'firstName', $r['firstName'], 'text', 'required');
    field('Last name', 'lastName', $r['lastName'], 'text', 'required');
    field('Date of birth', 'DOB', $r['DOB'], 'date', 'required');
    field('Social Security Number (9 digits)', 'SSN', $r['SSN'], 'text', 'required maxlength="9"');
    field('Medicare card number', 'medicareNum', $r['medicareNum'], 'text', 'required maxlength="12"');
    field('Phone', 'phone', $r['phone'], 'text', 'required');
    field('Address', 'address', $r['address'], 'text', 'required');
    field('City', 'city', $r['city'], 'text', 'required');
    field('Province', 'province', $r['province'], 'text', 'required maxlength="2"');
    field('Postal code', 'postalCode', $r['postalCode'], 'text', 'required maxlength="7"');
    field('Email', 'email', $r['email'], 'email', 'required');
    if ($a == 'new') assignment_fields($PROLES, $MANDATES);
    echo '<div class="wide"><button>Save</button> <a class="btn" href="personnel.php">Cancel</a></div></form>';
} elseif ($a == 'view') {
    $id = get('id');
    $r = row('SELECT p.personnelID, p.firstName, p.lastName, p.DOB, p.SSN, p.medicareNum, p.phone, p.address, pc.city, pc.province, p.postalCode, p.email
              FROM Personnel p JOIN PostalCodes pc ON pc.postalCode = p.postalCode WHERE p.personnelID = ?', array($id));
    echo '<p class="bar"><a class="btn" href="personnel.php">Back to the list</a> <a class="btn" href="personnel.php?a=edit&id=' . h($id) . '">Edit</a></p><dl>';
    foreach ($r as $k => $v) echo '<dt>' . h($k) . '</dt><dd>' . h($v) . '</dd>';
    echo '</dl><h2>Assignments (the one with no end date is the current one)</h2>';
    table(rows('SELECT l.name AS location, pa.role, pa.title, pa.mandate, pa.startDate, pa.endDate
                FROM PersonnelAssignments pa JOIN Locations l ON l.locationID = pa.locationID WHERE pa.personnelID = ? ORDER BY pa.startDate', array($id)));
    echo '<h2>New assignment (ends the current one the day before the start date)</h2>';
    echo '<form method="post" class="box" action="personnel.php?a=assign"><input type="hidden" name="id" value="' . h($id) . '">';
    assignment_fields($PROLES, $MANDATES);
    echo '<div class="wide"><button>Start new assignment</button></div></form>';
} else {
    echo '<p class="bar"><a class="btn" href="personnel.php?a=new">New personnel member</a></p>';
    table(rows('SELECT p.personnelID, p.firstName, p.lastName, p.phone, p.email, l.name AS location, pa.role, pa.title, pa.mandate, pa.startDate
                FROM Personnel p
                    LEFT OUTER JOIN PersonnelAssignments pa ON pa.personnelID = p.personnelID AND pa.endDate IS NULL
                    LEFT OUTER JOIN Locations l ON l.locationID = pa.locationID
                ORDER BY p.personnelID'),
        function ($r) {
            return '<a class="btn small" href="personnel.php?a=view&id=' . $r['personnelID'] . '">Display</a> '
                . '<a class="btn small" href="personnel.php?a=edit&id=' . $r['personnelID'] . '">Edit</a> '
                . delete_button('personnel.php', $r['personnelID'], $r['firstName'] . ' ' . $r['lastName']);
        });
}
