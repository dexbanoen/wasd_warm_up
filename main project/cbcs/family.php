<?php
// Item 3: create, display, edit and delete a family member.
// The primary family member is in FamilyMembers; the secondary family member (a second
// contact named by the primary one) is in SecondaryFamilyMembers.
require "lib.php";
$a = get("a", "list");
$error = "";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    try {
        if ($a == "delete") {
            q("DELETE FROM FamilyMembers WHERE familyMemberID = ?", [
                post("id"),
            ]);
            go("family.php?msg=" . urlencode("Family member deleted."));
        }
        if ($a == "delsecondary") {
            q("DELETE FROM SecondaryFamilyMembers WHERE familyMemberID = ?", [
                post("id"),
            ]);
            go(
                "family.php?msg=" .
                    urlencode("Secondary family member deleted.")
            );
        }
        db()->beginTransaction();
        $pc = save_postal(post("postalCode"), post("city"), post("province"));
        $values = [
            post("firstName"),
            post("lastName"),
            post("DOB"),
            post("SSN"),
            post("medicareNum"),
            post("phone"),
            post("address"),
            $pc,
            nul(post("email")),
            post("locationID"),
        ];
        if (post("id") === "") {
            q(
                "INSERT INTO FamilyMembers (firstName, lastName, DOB, SSN, medicareNum, phone, address, postalCode, email, locationID) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                $values
            );
            $id = db()->lastInsertId();
        } else {
            $id = post("id");
            q(
                "UPDATE FamilyMembers SET firstName = ?, lastName = ?, DOB = ?, SSN = ?, medicareNum = ?, phone = ?, address = ?, postalCode = ?, email = ?, locationID = ? WHERE familyMemberID = ?",
                array_merge($values, [$id])
            );
        }
        // secondary family member: saved when a first name is typed
        if (post("sFirstName") !== "") {
            $sec = [
                post("sFirstName"),
                post("sLastName"),
                post("sPhone"),
                post("sRelationship"),
            ];
            if (
                row(
                    "SELECT familyMemberID FROM SecondaryFamilyMembers WHERE familyMemberID = ?",
                    [$id]
                )
            ) {
                q(
                    "UPDATE SecondaryFamilyMembers SET firstName = ?, lastName = ?, phone = ?, relationship = ? WHERE familyMemberID = ?",
                    array_merge($sec, [$id])
                );
            } else {
                q(
                    "INSERT INTO SecondaryFamilyMembers (firstName, lastName, phone, relationship, familyMemberID) VALUES (?, ?, ?, ?, ?)",
                    array_merge($sec, [$id])
                );
            }
        }
        db()->commit();
        go("family.php?msg=" . urlencode("Family member saved."));
    } catch (PDOException $e) {
        if (db()->inTransaction()) {
            db()->rollBack();
        }
        $error = ErroMSG($e);
        if ($a == "delete" || $a == "delsecondary") {
            $a = "list";
        }
    }
}
page_start("Family members");
show_error($error);
if ($a == "new" || $a == "edit") {
    $r = [
        "familyMemberID" => "",
        "firstName" => "",
        "lastName" => "",
        "DOB" => "",
        "SSN" => "",
        "medicareNum" => "",
        "phone" => "",
        "address" => "",
        "city" => "",
        "province" => "QC",
        "postalCode" => "",
        "email" => "",
        "locationID" => "",
        "sFirstName" => "",
        "sLastName" => "",
        "sPhone" => "",
        "sRelationship" => "Other",
    ];
    if ($a == "edit") {
        $r = array_merge(
            $r,
            row(
                "SELECT f.*, pc.city, pc.province FROM FamilyMembers f JOIN PostalCodes pc ON pc.postalCode = f.postalCode WHERE f.familyMemberID = ?",
                [get("id")]
            )
        );
        $s = row(
            "SELECT firstName AS sFirstName, lastName AS sLastName, phone AS sPhone, relationship AS sRelationship FROM SecondaryFamilyMembers WHERE familyMemberID = ?",
            [get("id")]
        );
        if ($s) {
            $r = array_merge($r, $s);
        }
    }
    if ($_POST) {
        $r = array_merge($r, $_POST);
    }
    echo '<form method="post" class="box" action="family.php?a=' .
        $a .
        "&id=" .
        h($r["familyMemberID"]) .
        '"><input type="hidden" name="id" value="' .
        h($r["familyMemberID"]) .
        '">';
    echo '<h2 class="wide">Primary family member</h2>';
    field("First name", "firstName", $r["firstName"], "text", "required");
    field("Last name", "lastName", $r["lastName"], "text", "required");
    field("Date of birth", "DOB", $r["DOB"], "date", "required");
    field(
        "Social Security Number (9 digits)",
        "SSN",
        $r["SSN"],
        "text",
        'required maxlength="9"'
    );
    field(
        "Medicare card number",
        "medicareNum",
        $r["medicareNum"],
        "text",
        'required maxlength="12"'
    );
    field("Phone", "phone", $r["phone"], "text", "required");
    field("Address", "address", $r["address"], "text", "required");
    field("City", "city", $r["city"], "text", "required");
    field(
        "Province",
        "province",
        $r["province"],
        "text",
        'required maxlength="2"'
    );
    field(
        "Postal code",
        "postalCode",
        $r["postalCode"],
        "text",
        'required maxlength="7"'
    );
    field("Email", "email", $r["email"], "email");
    select(
        "Location",
        "locationID",
        options("SELECT locationID, name FROM Locations ORDER BY name"),
        $r["locationID"]
    );
    echo '<h2 class="wide">Secondary family member (optional: leave the first name empty for none)</h2>';
    field("First name", "sFirstName", $r["sFirstName"]);
    field("Last name", "sLastName", $r["sLastName"]);
    field("Phone", "sPhone", $r["sPhone"]);
    select(
        "Relationship with the club member",
        "sRelationship",
        $RELATIONSHIPS,
        $r["sRelationship"]
    );
    echo '<div class="wide"><button>Save</button> <a class="btn" href="family.php">Cancel</a></div></form>';
} else {
    echo '<p class="bar"><a class="btn" href="family.php?a=new">New family member</a></p>';
    table(
        rows("SELECT f.familyMemberID, f.firstName, f.lastName, f.DOB, f.SSN, f.medicareNum, f.phone, f.address, pc.city, pc.province, f.postalCode,
                    f.email, l.name AS location,
                    (SELECT COUNT(*) FROM MinorGuardians g WHERE g.familyMemberID = f.familyMemberID) AS numChildren,
                    CONCAT(s.firstName, ' ', s.lastName, ', ', s.phone, ' (', s.relationship, ')') AS secondaryFamilyMember
                FROM FamilyMembers f
                    JOIN PostalCodes pc ON pc.postalCode = f.postalCode
                    JOIN Locations l ON l.locationID = f.locationID
                    LEFT OUTER JOIN SecondaryFamilyMembers s ON s.familyMemberID = f.familyMemberID
                ORDER BY f.familyMemberID"),
        function ($r) {
            $out =
                '<a class="btn small" href="family.php?a=edit&id=' .
                $r["familyMemberID"] .
                '">Edit</a> ' .
                delete_button(
                    "family.php",
                    $r["familyMemberID"],
                    $r["firstName"] . " " . $r["lastName"]
                );
            if ($r["secondaryFamilyMember"] !== null) {
                $out .=
                    ' <form method="post" action="family.php?a=delsecondary" class="inline"><input type="hidden" name="id" value="' .
                    $r["familyMemberID"] .
                    '"><button class="danger">Delete secondary</button></form>';
            }
            return $out;
        }
    );
}
page_end();
