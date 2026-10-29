-- MIT 8103 Portfolio 3: Transactions & Concurrency Control
-- Student: Ifeoluwa Daniel | ID: 301856443
-- Case Study: PayFlex Microfinance - Consistent
-- Database: payflex_db

USE payflex_db;

-- ============================================
-- 1. ACID TRANSACTION: Fund Transfer Between Accounts
-- ============================================
-- Scenario: Transfer 5000 from Account 1 to Account 2

START TRANSACTION;

-- Lock rows to prevent concurrent modification
SELECT balance FROM Accounts WHERE account_id = 1 FOR UPDATE;
SELECT balance FROM Accounts WHERE account_id = 2 FOR UPDATE;

-- Check if sender has enough balance
SET @sender_balance = (SELECT balance FROM Accounts WHERE account_id = 1);
SET @transfer_amount = 5000.00;

-- If condition (in application logic, but shown here)
-- In real stored procedure, use IF @sender_balance >= @transfer_amount

-- Deduct from sender
UPDATE Accounts 
SET balance = balance - @transfer_amount 
WHERE account_id = 1;

-- Add to receiver
UPDATE Accounts 
SET balance = balance + @transfer_amount 
WHERE account_id = 2;

-- Log transaction
INSERT INTO Transactions (reference_no, from_account_id, to_account_id, amount, trans_type, status, trans_date)
VALUES (CONCAT('TRF', UNIX_TIMESTAMP()), 1, 2, @transfer_amount, 'TRANSFER', 'SUCCESS', NOW());

-- Log audit
INSERT INTO AuditLogs (user_id, action, table_name, record_id, old_value, new_value, created_at)
VALUES (1, 'TRANSFER', 'Accounts', 1, @sender_balance, @sender_balance - @transfer_amount, NOW());

COMMIT;
-- ROLLBACK if any error
