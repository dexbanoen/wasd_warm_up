<?php
// Item 1: create, display, edit and delete a location.
require 'lib.php';
$a = get('a', 'list'); $error = '';
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        if ($a == 'delete') {
            q('DELETE FROM Locations WHERE locationID = ?', array(post('id')));
            go('locations.php?msg=' . urlencode('Location deleted.'));
        }
        db()->beginTransaction();
        $pc = save_postal(post('postalCode'), post('city'), post('province'));
        $values = array(post('type'), post('name'), post('address'), $pc, nul(post('webAddress')), post('maxCapacity'));
        if (post('id') === '') {
            q('INSERT INTO Locations (type, name, address, postalCode, webAddress, maxCapacity) VALUES (?, ?, ?, ?, ?, ?)', $values);
            $id = db()->lastInsertId();
        } else {
            $id = post('id');
            q('UPDATE Locations SET type = ?, name = ?, address = ?, postalCode = ?, webAddress = ?, maxCapacity = ? WHERE locationID = ?',
                array_merge($values, array($id)));
            q('DELETE FROM LocationPhones WHERE locationID = ?', array($id));
        }
        foreach (explode(',', post('phones')) as $phone)
            if (trim($phone) !== '') q('INSERT INTO LocationPhones (locationID, phone) VALUES (?, ?)', array($id, trim($phone)));
        db()->commit();
        go('locations.php?msg=' . urlencode('Location saved.'));
    } catch (PDOException $e) {
        if (db()->inTransaction()) db()->rollBack();
        $error = friendly($e);
        if ($a == 'delete') $a = 'list';
    }
}
page_start('Locations');
show_error($error);
if ($a == 'new' || $a == 'edit') {
    $r = array('locationID' => '', 'type' => 'Branch', 'name' => '', 'address' => '', 'city' => '', 'province' => 'QC',
        'postalCode' => '', 'webAddress' => '', 'maxCapacity' => '', 'phones' => '');
    if ($a == 'edit')
        $r = row("SELECT l.*, pc.city, pc.province,
                      (SELECT GROUP_CONCAT(lp.phone ORDER BY lp.phone SEPARATOR ', ') FROM LocationPhones lp WHERE lp.locationID = l.locationID) AS phones
                  FROM Locations l JOIN PostalCodes pc ON pc.postalCode = l.postalCode WHERE l.locationID = ?", array(get('id')));
    if ($_POST) $r = array_merge($r, $_POST);
    echo '<form method="post" class="box" action="locations.php?a=' . $a . '&id=' . h($r['locationID']) . '">';
    echo '<input type="hidden" name="id" value="' . h($r['locationID']) . '">';
    select('Type', 'type', array('Branch' => 'Branch', 'Head' => 'Head'), $r['type']);
    field('Name', 'name', $r['name'], 'text', 'required');
    field('Address', 'address', $r['address'], 'text', 'required');
    field('City', 'city', $r['city'], 'text', 'required');
    field('Province', 'province', $r['province'], 'text', 'required maxlength="2"');
    field('Postal code', 'postalCode', $r['postalCode'], 'text', 'required maxlength="7"');
    field('Web address', 'webAddress', $r['webAddress']);
    field('Maximum capacity', 'maxCapacity', $r['maxCapacity'], 'number', 'required');
    field('Phone numbers (separate with commas)', 'phones', $r['phones']);
    echo '<div class="wide"><button>Save</button> <a class="btn" href="locations.php">Cancel</a></div></form>';
} else {
    echo '<p class="bar"><a class="btn" href="locations.php?a=new">New location</a></p>';
    table(rows("SELECT l.locationID, l.type, l.name, l.address, pc.city, pc.province, l.postalCode,
                    (SELECT GROUP_CONCAT(lp.phone ORDER BY lp.phone SEPARATOR ', ') FROM LocationPhones lp WHERE lp.locationID = l.locationID) AS phones,
                    l.webAddress, l.maxCapacity
                FROM Locations l JOIN PostalCodes pc ON pc.postalCode = l.postalCode ORDER BY l.locationID"),
        function ($r) {
            return '<a class="btn small" href="locations.php?a=edit&id=' . $r['locationID'] . '">Edit</a> '
                . delete_button('locations.php', $r['locationID'], 'location ' . $r['name']);
        });
}
page_end();
