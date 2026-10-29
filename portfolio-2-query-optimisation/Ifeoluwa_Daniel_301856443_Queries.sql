-- MIT 8103 Portfolio 2: Query Optimisation
-- Student: Ifeoluwa Daniel | ID: 301856443
-- Case Study: PayFlex Microfinance - Consistent for all 5 portfolios
-- Database: payflex_db

USE payflex_db;

-- 1. INDEXES FOR OPTIMISATION
CREATE INDEX idx_transactions_from_account ON Transactions(from_account_id);
CREATE INDEX idx_transactions_date ON Transactions(trans_date);
CREATE INDEX idx_transactions_status ON Transactions(status);
CREATE INDEX idx_accounts_customer ON Accounts(customer_id);
CREATE INDEX idx_accounts_no ON Accounts(account_no);
CREATE INDEX idx_customers_bvn ON Customers(bvn);

-- 2. QUERY 1: Customer Transaction History with JOIN (Optimised)
-- Get all transactions for a specific customer with account details
EXPLAIN SELECT 
    c.full_name, a.account_no, t.reference_no, t.amount, t.trans_type, t.status, t.trans_date
FROM Customers c
JOIN Accounts a ON c.customer_id = a.customer_id
JOIN Transactions t ON a.account_id = t.from_account_id
WHERE c.customer_id = 1
ORDER BY t.trans_date DESC;

-- Actual Query
SELECT 
    c.full_name, a.account_no, t.reference_no, t.amount, t.trans_type, t.status, t.trans_date
FROM Customers c
JOIN Accounts a ON c.customer_id = a.customer_id
JOIN Transactions t ON a.account_id = t.from_account_id
WHERE c.customer_id = 1
ORDER BY t.trans_date DESC;

-- 3. QUERY 2: Monthly Transaction Summary - GROUP BY with Aggregation
SELECT 
    DATE_FORMAT(trans_date, '%Y-%m') AS month,
    trans_type,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount
FROM Transactions
WHERE status = 'SUCCESS'
GROUP BY DATE_FORMAT(trans_date, '%Y-%m'), trans_type
ORDER BY month DESC;

-- 4. QUERY 3: Failed Transactions for Audit - Subquery
SELECT 
    c.full_name, c.email, a.account_no, t.reference_no, t.amount, t.trans_date
FROM Customers c
JOIN Accounts a ON c.customer_id = a.customer_id
JOIN Transactions t ON a.account_id = t.from_account_id
WHERE t.transaction_id IN (
    SELECT transaction_id FROM Transactions WHERE status = 'FAILED'
)
ORDER BY t.trans_date DESC;
