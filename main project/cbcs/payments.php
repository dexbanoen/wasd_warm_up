<?php
// Item 7: make a payment for a club member, and see the payments against the yearly fee.
require "lib.php";
$error = "";
$memberID = get("memberID", post("memberID"));
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    try {
        // the installment number is the next one for that member and membership year (at most 4: CHECK constraint)
        $next = row(
            "SELECT COUNT(*) + 1 AS n FROM Payments WHERE memberID = ? AND membershipYear = ?",
            [$memberID, post("membershipYear")]
        );
        q(
            "INSERT INTO Payments (memberID, paymentDate, amount, method, membershipYear, installmentNum) VALUES (?, ?, ?, ?, ?, ?)",
            [
                $memberID,
                post("paymentDate"),
                post("amount"),
                post("method"),
                post("membershipYear"),
                $next["n"],
            ]
        );
        go(
            "payments.php?memberID=" .
                $memberID .
                "&msg=" .
                urlencode(
                    "Payment recorded as installment " .
                        $next["n"] .
                        " of " .
                        post("membershipYear") .
                        "."
                )
        );
    } catch (PDOException $e) {
        $error = ErroMSG($e);
    }
}
page_start("Payments");
show_error($error);
echo '<form method="get" class="box">';
select(
    "Club member",
    "memberID",
    ["" => "(choose a member)"] +
        options("SELECT c.memberID, CONCAT(c.memberID, ' ', c.firstName, ' ', c.lastName, ' (', st.status, ')')
    FROM ClubMembers c JOIN v_MemberStatus st ON st.memberID = c.memberID ORDER BY c.memberID"),
    $memberID,
    'onchange="this.form.submit()"'
);
echo "</form>";
if ($memberID !== "") {
    $m = row(
        "SELECT c.firstName, c.lastName, TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) AS age, st.status FROM ClubMembers c JOIN v_MemberStatus st ON st.memberID = c.memberID WHERE c.memberID = ?",
        [$memberID]
    );
    echo "<h2>" .
        h($m["firstName"] . " " . $m["lastName"]) .
        " - " .
        ($m["age"] < 17 ? 'minor ($100 a year)' : 'major ($200 a year)') .
        " - status: " .
        h($m["status"]) .
        "</h2>";
    echo '<form method="post" class="box" action="payments.php"><input type="hidden" name="memberID" value="' .
        h($memberID) .
        '">';
    field(
        "Membership year",
        "membershipYear",
        post("membershipYear", date("Y")),
        "number",
        "required"
    );
    field(
        'Amount ($)',
        "amount",
        post("amount"),
        "number",
        'required step="0.01"'
    );
    select(
        "Method",
        "method",
        ["Cash" => "Cash", "Debit" => "Debit", "Credit" => "Credit"],
        post("method")
    );
    field(
        "Payment date",
        "paymentDate",
        post("paymentDate", date("Y-m-d")),
        "date",
        "required"
    );
    echo "<div><button>Make payment</button></div></form>";
    echo "<h2>Total per membership year (anything above the fee is a donation)</h2>";
    table(
        rows(
            'SELECT a.membershipYear, a.totalPaid, a.annualFee, GREATEST(a.totalPaid - a.annualFee, 0) AS donation
                FROM v_AnnualPayments a WHERE a.memberID = ? ORDER BY a.membershipYear',
            [$memberID]
        )
    );
    echo "<h2>Payments</h2>";
    table(
        rows(
            "SELECT paymentID, paymentDate, amount, method, membershipYear, installmentNum FROM Payments WHERE memberID = ? ORDER BY membershipYear, installmentNum",
            [$memberID]
        )
    );
}
page_end();
