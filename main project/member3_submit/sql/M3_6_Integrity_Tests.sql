-- ============================================================
-- Member 3 - Dexter Banoen Garde
-- Goes in shared script 6 (Integrity Tests), in "Rules enforced by keys, foreign keys and CHECK constraints".
-- Tests 17 and 18 are the two asked in the work split. They are already in the shared script, unchanged.
-- Run ONE STATEMENT AT A TIME (Ctrl+Enter): every statement here is supposed to fail.
-- Nothing is inserted, so there is nothing to clean up.
-- ============================================================

-- Test 17 (CHECK PaymentMaxFourInstallments). REJECTED: Hassan Benali (member 4) already paid 2025 in four installments; a fifth is refused.
INSERT INTO Payments (memberID, paymentDate, amount, method, membershipYear, installmentNum) VALUES
	(4, '2025-09-15', 10.00, 'Cash', 2025, 5);
-- ERROR: Check constraint 'PaymentMaxFourInstallments' is violated.

-- Test 18 (CHECK PaymentMethodValid). REJECTED: the method of payment is cash, debit or credit card.
INSERT INTO Payments (memberID, paymentDate, amount, method, membershipYear, installmentNum) VALUES
	(4, '2026-11-13', 50.00, 'Cheque', 2027, 1);
-- ERROR: Check constraint 'PaymentMethodValid' is violated.
