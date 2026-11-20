-- ============================================================
-- Member 3 - Dexter Banoen Garde
-- Goes in shared script 4 (Transactions): replaces steps 7a and 7b of item 7.
-- Step 7c of the shared script (deleting members 48 and 49 and family member 28) is the clean-up
-- of items 3 and 4: leave it where it is, after this block.
-- Member 48 (Félix Rivard, a major who joined in 2026) is created by item 4 earlier in the script.
-- ============================================================


-- Item 7. Make a payment for a club member
-- ----------------------------------------

-- 7a. Before paying: member 48 joined this year and has paid nothing, so he is inactive.
SELECT memberID, status
FROM v_MemberStatus
WHERE memberID = 48;

-- He pays the $200 fee of 2026 in two installments.
-- paymentID is not given: AUTO_INCREMENT gives the next number.
-- installmentNum is not typed either: it is the highest installment already paid for that member
-- and year, plus 1 (so 1 for a first payment). This is what the web page payments.php does.
INSERT INTO Payments (memberID, paymentDate, amount, method, membershipYear, installmentNum)
SELECT 48, '2026-11-13', 120.00, 'Debit', 2026, COALESCE(MAX(installmentNum), 0) + 1
FROM Payments
WHERE memberID = 48
	AND membershipYear = 2026;

INSERT INTO Payments (memberID, paymentDate, amount, method, membershipYear, installmentNum)
SELECT 48, '2026-11-20', 110.00, 'Credit', 2026, COALESCE(MAX(installmentNum), 0) + 1
FROM Payments
WHERE memberID = 48
	AND membershipYear = 2026;

-- 7b. The payments of the member: installments 1 and 2.
SELECT paymentID, memberID, paymentDate, amount, method, membershipYear, installmentNum
FROM Payments
WHERE memberID = 48
ORDER BY membershipYear, installmentNum;

-- Then the total against the fee: $230 paid for a $200 fee, so $30 is a donation, and he is now active.
SELECT a.memberID, a.membershipYear, a.totalPaid, a.annualFee,
	a.totalPaid - a.annualFee AS donation, st.status
FROM v_AnnualPayments a, v_MemberStatus st
WHERE st.memberID = a.memberID
	AND a.memberID = 48;
