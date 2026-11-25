<?php
// Shared helpers used by every page: database access, HTML output, error messages.
require __DIR__ . "/config.php";

// One PDO connection per request. Errors are thrown as exceptions.
function db()
{
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(
            "mysql:host=" .
                DB_HOST .
                ";port=" .
                DB_PORT .
                ";dbname=" .
                DB_NAME .
                ";charset=utf8mb4",
            DB_USER,
            DB_PASS,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ]
        );
        // Text comparisons need the same collation on both sides. The views remember the collation
        // they were created with, so this connection uses that one too.
        $c = $pdo
            ->query(
                "SELECT COLLATION_CONNECTION FROM information_schema.VIEWS
                          WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'v_MemberStatus'"
            )
            ->fetchColumn();
        if ($c) {
            $pdo->exec("SET collation_connection = '" . $c . "'");
        }
    }
    return $pdo;
}
// Run a statement with parameters (prepared statement: values are never pasted into the SQL).
function q($sql, $params = [])
{
    $st = db()->prepare($sql);
    $st->execute($params);
    return $st;
}
function rows($sql, $params = [])
{
    return q($sql, $params)->fetchAll();
}
function row($sql, $params = [])
{
    $r = q($sql, $params)->fetch();
    return $r ? $r : null;
}

function h($s)
{
    return htmlspecialchars((string) $s, ENT_QUOTES, "UTF-8");
}
function post($name, $default = "")
{
    return isset($_POST[$name]) ? trim($_POST[$name]) : $default;
}
function get($name, $default = "")
{
    return isset($_GET[$name]) ? trim($_GET[$name]) : $default;
}
function nul($v)
{
    return $v === "" ? null : $v;
}
function go($url)
{
    header("Location: " . $url);
    exit();
}

// Turn a database error into a message a user can read.
function ErroMSG($e)
{
    return $e->getMessage();
}

// A postal code determines its city and province: insert it, or update it if it is already known.
function save_postal($postalCode, $city, $province)
{
    $postalCode = strtoupper(str_replace(" ", "", $postalCode));
    if (
        row("SELECT postalCode FROM PostalCodes WHERE postalCode = ?", [
            $postalCode,
        ])
    ) {
        q(
            "UPDATE PostalCodes SET city = ?, province = ? WHERE postalCode = ?",
            [$city, strtoupper($province), $postalCode]
        );
    } else {
        q(
            "INSERT INTO PostalCodes (postalCode, city, province) VALUES (?, ?, ?)",
            [$postalCode, $city, strtoupper($province)]
        );
    }
    return $postalCode;
}

// ---------- page layout ----------
function page_start($title)
{
    $menu = [
        "index.php" => "Home",
        "locations.php" => "Locations",
        "personnel.php" => "Personnel",
        "family.php" => "Family members",
        "members.php" => "Club members",
        "teams.php" => "Teams",
        "sessions.php" => "Team formations",
        "payments.php" => "Payments",
        "queries.php" => "Queries",
        "triggers.php" => "Triggers",
        "emails.php" => "Emails",
    ];
    $here = basename($_SERVER["PHP_SELF"]);
    echo '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">';
    echo "<title>" .
        h($title) .
        ' - CBCS</title><link rel="stylesheet" href="style.css"></head><body>';
    echo '<header><div class="brand">CBCS <span>Country Basketball Club System</span></div><nav>';
    foreach ($menu as $file => $label) {
        echo '<a href="' .
            $file .
            '"' .
            ($file == $here ? ' class="on"' : "") .
            ">" .
            $label .
            "</a>";
    }
    echo "</nav></header><main><h1>" . h($title) . "</h1>";
    if (get("msg") !== "") {
        echo '<p class="ok">' . h(get("msg")) . "</p>";
    }
}
function page_end()
{
    echo "</main><footer>COMP 353 Main Project, Fall 2026 - group xpc353_2</footer></body></html>";
}
function show_error($error)
{
    if ($error) {
        echo '<p class="err">' . h($error) . "</p>";
    }
}

// Print a list of rows as an HTML table. $actions($row) returns the HTML of the last column.
function table($rows, $actions = null)
{
    if (!$rows) {
        echo '<p class="none">No rows.</p>';
        return;
    }
    echo '<div class="scroll"><table><tr>';
    foreach (array_keys($rows[0]) as $col) {
        echo "<th>" . h($col) . "</th>";
    }
    if ($actions) {
        echo "<th></th>";
    }
    echo "</tr>";
    foreach ($rows as $r) {
        echo "<tr>";
        foreach ($r as $v) {
            echo "<td>" .
                ($v === null ? '<span class="null">NULL</span>' : h($v)) .
                "</td>";
        }
        if ($actions) {
            echo '<td class="act">' . $actions($r) . "</td>";
        }
        echo "</tr>";
    }
    echo '</table></div><p class="count">' . count($rows) . " row(s)</p>";
}

// Helper Functions
function field($label, $name, $value = "", $type = "text", $extra = "")
{
    echo "<label>" .
        h($label) .
        '<input type="' .
        $type .
        '" name="' .
        $name .
        '" value="' .
        h($value) .
        '" ' .
        $extra .
        "></label>";
}


function select($label, $name, $options, $selected = "", $extra = "")
{
    echo "<label>" . h($label) . '<select name="' . $name . '" ' . $extra . ">";
    foreach ($options as $value => $text) {
        echo '<option value="' .
            h($value) .
            '"' .
            ((string) $value === (string) $selected ? " selected" : "") .
            ">" .
            h($text) .
            "</option>";
    }
    echo "</select></label>";
}


function options($sql)
{
    // first column = value, second column = text
    $out = [];
    foreach (q($sql)->fetchAll(PDO::FETCH_NUM) as $r) {
        $out[$r[0]] = $r[1];
    }
    return $out;
}

function delete_button($page, $id, $what)
{
    return '<form method="post" action="' .
        $page .
        '?a=delete" class="inline" onsubmit="return confirm(\'Delete ' .
        h($what) .
        '?\')">' .
        '<input type="hidden" name="id" value="' .
        h($id) .
        '"><button class="danger">Delete</button></form>';
}
$RELATIONSHIPS = [
    "Father" => "Father",
    "Mother" => "Mother",
    "Grandfather" => "Grandfather",
    "Grandmother" => "Grandmother",
    "Tutor" => "Tutor",
    "Partner" => "Partner",
    "Friend" => "Friend",
    "Other" => "Other",
];
$ROLES = [
    "Point Guard" => "Point Guard",
    "Shooting Guard" => "Shooting Guard",
    "Small Forward" => "Small Forward",
    "Power Forward" => "Power Forward",
    "Center" => "Center",
];