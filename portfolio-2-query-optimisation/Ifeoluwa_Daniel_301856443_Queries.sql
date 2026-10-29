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
