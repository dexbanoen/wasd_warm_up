<?php
require 'lib.php';
require 'queries_data.php';
$n = (int)get('q', 0);
page_start('Queries');
echo '<p class="bar">';
foreach ($QUERIES as $num => $qr) echo '<a class="btn small" href="queries.php?q=' . $num . '">Query ' . $num . '</a> ';
echo '</p>';
if (isset($QUERIES[$n])) {
    $qr = $QUERIES[$n];
    echo '<h2>Query ' . $n . '</h2><p>' . h($qr['text']) . '</p>';
    $values = array();
    if ($qr['params']) {
        echo '<form method="get" class="box"><input type="hidden" name="q" value="' . $n . '">';
        // $p = name, label, type, default value
        foreach ($qr['params'] as $p) {
            $values[$p[0]] = get($p[0], $p[3]);
            if ($p[2] == 'location') select($p[1], $p[0], options('SELECT locationID, name FROM Locations ORDER BY name'), $values[$p[0]]);
            else field($p[1], $p[0], $values[$p[0]], $p[2], 'required');
        }
        echo '<div><button>Run</button></div></form>';
    }
    try { table(rows($qr['sql'], $values)); } catch (PDOException $e) { show_error(friendly($e)); }
    echo '<h2>SQL</h2><pre>' . h($qr['sql']) . '</pre>';
} else {
    $list = array();
    foreach ($QUERIES as $num => $qr) $list[] = array('Query' => $num, 'What it returns' => $qr['text']);
    table($list);
}
