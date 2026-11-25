<?php
// Item 7: make a payment for a club member, and see the payments against the yearly fee.
// Member 3 - Dexter Banoen Garde. Uses the shared helpers of lib.php.
require 'lib.php';

$error = '';
$memberID = get('memberID', post('memberID'));    // from the member list (GET) or from the payment form (POST)

// ---------- 1. The payment form was submitted: record the payment ----------
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        // The installment number is not typed: it is the highest one already paid for that member
        // and membership year, plus 1. A fifth installment is refused by the CHECK constraint
        // PaymentMaxFourInstallments, and the page shows that as a "Rejected" message.
        $next = row('SELECT COALESCE(MAX(installmentNum), 0) + 1 AS n
                     FROM Payments
                     WHERE memberID = ? AND membershipYear = ?',
            array($memberID, post('membershipYear')));

        q('INSERT INTO Payments (memberID, paymentDate, amount, method, membershipYear, installmentNum)
           VALUES (?, ?, ?, ?, ?, ?)',
            array($memberID, post('paymentDate'), post('amount'), post('method'), post('membershipYear'), $next['n']));

        go('payments.php?memberID=' . $memberID . '&msg='
            . urlencode('Payment recorded as installment ' . $next['n'] . ' of ' . post('membershipYear') . '.'));
    } catch (PDOException $e) {
        $error = ErroMSG($e);
    }
}

// ---------- 2. Show the page ----------
page_start('Payments');
show_error($error);

// The list of members, each with its status. Choosing one reloads the page for that member.
echo '<form method="get" class="box">';
select('Club member', 'memberID',
    array('' => '(choose a member)') + options("SELECT c.memberID, CONCAT(c.memberID, ' ', c.firstName, ' ', c.lastName, ' (', st.status, ')')
        FROM ClubMembers c JOIN v_MemberStatus st ON st.memberID = c.memberID
        ORDER BY c.memberID"),
    $memberID, 'onchange="this.form.submit()"');
echo '</form>';

// The member's name, status and fee of this year. The fee uses the same rule as the view
// v_AnnualPayments: $100 if under 17 on January 1 of the year (a minor), $200 otherwise.
$m = null;
if ($memberID !== '') {
    $m = row("SELECT c.firstName, c.lastName, st.status,
                  IF(TIMESTAMPDIFF(YEAR, c.DOB, MAKEDATE(YEAR(CURDATE()), 1)) < 17, 100, 200) AS feeThisYear
              FROM ClubMembers c JOIN v_MemberStatus st ON st.memberID = c.memberID
              WHERE c.memberID = ?", array($memberID));
}

if ($m) {
    echo '<h2>' . h($m['firstName'] . ' ' . $m['lastName'])
        . ' - ' . ($m['feeThisYear'] == 100 ? 'minor' : 'major') . ', fee of ' . date('Y') . ': $' . h($m['feeThisYear'])
        . ' - status: ' . h($m['status']) . '</h2>';

    // The payment form.
    echo '<form method="post" class="box" action="payments.php">';
    echo '<input type="hidden" name="memberID" value="' . h($memberID) . '">';
    field('Membership year', 'membershipYear', post('membershipYear', date('Y')), 'number', 'required');
    field('Amount ($)', 'amount', post('amount'), 'number', 'required step="0.01"');
    select('Method', 'method', array('Cash' => 'Cash', 'Debit' => 'Debit', 'Credit' => 'Credit'), post('method'));
    field('Payment date', 'paymentDate', post('paymentDate', date('Y-m-d')), 'date', 'required');
    echo '<div><button>Make payment</button></div></form>';

    // Total paid per membership year against the fee of that year.
    echo '<h2>Total per membership year (anything above the fee is a donation)</h2>';
    table(rows('SELECT a.membershipYear, a.totalPaid, a.annualFee,
                    GREATEST(a.annualFee - a.totalPaid, 0) AS stillToPay,
                    GREATEST(a.totalPaid - a.annualFee, 0) AS donation
                FROM v_AnnualPayments a
                WHERE a.memberID = ?
                ORDER BY a.membershipYear', array($memberID)));
    echo '<p>A year with no payment at all is not listed. The member is active when the fee of last year is fully paid.</p>';

    // Every payment of the member.
    echo '<h2>Payments</h2>';
    table(rows('SELECT paymentID, paymentDate, amount, method, membershipYear, installmentNum
                FROM Payments
                WHERE memberID = ?
                ORDER BY membershipYear, installmentNum', array($memberID)));
} elseif ($memberID !== '') {
    show_error('There is no club member number ' . $memberID . '.');
}
page_end();
