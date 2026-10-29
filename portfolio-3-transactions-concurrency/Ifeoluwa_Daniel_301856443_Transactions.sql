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

-- ============================================
-- 2. TRANSACTION: Bill Payment with ROLLBACK scenario
-- ============================================
START TRANSACTION;

-- Attempt to pay bill
UPDATE Accounts SET balance = balance - 2000 WHERE account_id = 1;
UPDATE Bills SET status = 'PAID', paid_date = NOW() WHERE bill_id = 1;

-- Check if balance went negative (business rule)
SET @new_balance = (SELECT balance FROM Accounts WHERE account_id = 1);

-- If balance < 0, rollback
-- For demo: We use a manual check, in procedure use IF
-- IF @new_balance < 0 THEN ROLLBACK; ELSE COMMIT;

COMMIT;

-- ============================================
-- 3. STORED PROCEDURE: Safe Transfer with Concurrency Handling
-- ============================================
DELIMITER //

CREATE PROCEDURE sp_transfer_funds(
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(15,2),
    IN p_reference VARCHAR(20)
)
BEGIN
    DECLARE v_sender_balance DECIMAL(15,2);
    DECLARE v_error INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_error = 1;

    START TRANSACTION;

    -- Lock sender row
    SELECT balance INTO v_sender_balance 
    FROM Accounts WHERE account_id = p_from_account FOR UPDATE;

    -- Validate balance
    IF v_sender_balance < p_amount THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds';
    ELSE
        -- Perform transfer
        UPDATE Accounts SET balance = balance - p_amount WHERE account_id = p_from_account;
        UPDATE Accounts SET balance = balance + p_amount WHERE account_id = p_to_account;

        INSERT INTO Transactions (reference_no, from_account_id, to_account_id, amount, trans_type, status)
        VALUES (p_reference, p_from_account, p_to_account, p_amount, 'TRANSFER', 'SUCCESS');

        IF v_error = 1 THEN
            ROLLBACK;
        ELSE
            COMMIT;
        END IF;
    END IF;
END //

DELIMITER ;

-- How to call: CALL sp_transfer_funds(1, 2, 1000.00, 'REF123456');

-- ============================================
-- 4. TRIGGER: Auto Audit Log on Account Update
-- ============================================
DELIMITER //

CREATE TRIGGER trg_accounts_audit
AFTER UPDATE ON Accounts
FOR EACH ROW
BEGIN
    INSERT INTO AuditLogs (user_id, action, table_name, record_id, old_value, new_value, created_at)
    VALUES (1, 'UPDATE_BALANCE', 'Accounts', NEW.account_id, OLD.balance, NEW.balance, NOW());
END //

DELIMITER ;

-- ============================================
-- 5. TRIGGER: Prevent Negative Balance
-- ============================================
DELIMITER //

CREATE TRIGGER trg_prevent_negative_balance
BEFORE UPDATE ON Accounts
FOR EACH ROW
BEGIN
    IF NEW.balance < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Balance cannot be negative';
    END IF;
END //

DELIMITER ;

-- ============================================
-- 6. CONCURRENCY DEMO: Isolation Level
-- ============================================
-- Show Dirty Read, Non-Repeatable Read protection

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- Or: SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; -- MySQL default

-- Transaction A
START TRANSACTION;
SELECT * FROM Accounts WHERE account_id = 1;
-- Transaction B tries to update same account - will wait due to FOR UPDATE lock
-- This demonstrates row-level locking

-- ============================================
-- 7. DEADLOCK HANDLING EXAMPLE
-- ============================================
-- Transaction 1 locks Account 1 then tries Account 2
-- Transaction 2 locks Account 2 then tries Account 1
-- MySQL automatically detects deadlock and rolls back one
-- Application should retry

-- Example retry logic (in application):
-- Retry 3 times on deadlock error 1213
