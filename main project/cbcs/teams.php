<?php
// Teams: each team belongs to one location and is a boys (M) or a girls (F) team.
require "lib.php";
$a = get("a", "list");
$error = "";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    try {
        if ($a == "delete") {
            q("DELETE FROM Teams WHERE teamID = ?", [post("id")]);
            go("teams.php?msg=" . urlencode("Team deleted."));
        }
        if (post("id") === "") {
            q("INSERT INTO Teams (name, locationID, gender) VALUES (?, ?, ?)", [
                post("name"),
                post("locationID"),
                post("gender"),
            ]);
        } else {
            q(
                "UPDATE Teams SET name = ?, locationID = ?, gender = ? WHERE teamID = ?",
                [post("name"), post("locationID"), post("gender"), post("id")]
            );
        }
        go("teams.php?msg=" . urlencode("Team saved."));
    } catch (PDOException $e) {
        $error = ErroMSG($e);
        if ($a == "delete") {
            $a = "list";
        }
    }
}
page_start("Teams");
show_error($error);
if ($a == "new" || $a == "edit") {
    $r = ["teamID" => "", "name" => "", "locationID" => "", "gender" => "M"];
    if ($a == "edit") {
        $r = row("SELECT * FROM Teams WHERE teamID = ?", [get("id")]);
    }
    if ($_POST) {
        $r = array_merge($r, $_POST);
    }

    echo '<form method="post" class="box" action="teams.php?a=' .
        $a .
        "&id=" .
        h($r["teamID"]) .
        '"><input type="hidden" name="id" value="' .
        h($r["teamID"]) .
        '">';
    field("Team name", "name", $r["name"], "text", "required");
    select(
        "Location",
        "locationID",
        options("SELECT locationID, name FROM Locations ORDER BY name"),
        $r["locationID"]
    );
    select(
        "Boys or girls",
        "gender",
        ["M" => "Boys (M)", "F" => "Girls (F)"],
        $r["gender"]
    );
    echo '<div class="wide"><button>Save</button> <a class="btn" href="teams.php">Cancel</a></div></form>';

} else {
    echo '<p class="bar"><a class="btn" href="teams.php?a=new">New team</a></p>';
    table(
        rows('SELECT t.teamID, t.name, l.name AS location, t.gender,
                    (SELECT COUNT(*) FROM TeamFormations tf WHERE tf.teamID = t.teamID) AS numFormations
                FROM Teams t JOIN Locations l ON l.locationID = t.locationID ORDER BY t.teamID'),
        function ($r) {
            return '<a class="btn small" href="teams.php?a=edit&id=' .
                $r["teamID"] .
                '">Edit</a> ' .
                delete_button("teams.php", $r["teamID"], "team " . $r["name"]);
        }
    );
}
page_end();