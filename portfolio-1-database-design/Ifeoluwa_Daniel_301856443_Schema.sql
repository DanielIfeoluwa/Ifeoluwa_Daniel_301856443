-- PayFlex Fintech Platform - Advanced Database Portfolio
-- Student: [Ifeoluwa Daniel | ID: 301856443]
-- Case Study: Consistent for all 5 portfolios

CREATE DATABASE IF NOT EXISTS payflex_db;
USE payflex_db;

-- 1. Customers Table
CREATE TABLE Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    bvn VARCHAR(11) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15) NOT NULL,
    kyc_status ENUM('PENDING','VERIFIED','REJECTED') DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (LENGTH(bvn) = 11)
);

-- 2. Accounts Table
CREATE TABLE Accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    account_no VARCHAR(10) UNIQUE NOT NULL,
    customer_id INT NOT NULL,
    account_type ENUM('SAVINGS','CURRENT','WALLET') NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0.00,
    status ENUM('ACTIVE','FROZEN','CLOSED') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE CASCADE,
    CHECK (balance >= 0),
    CHECK (LENGTH(account_no) = 10)
);

-- 3. Transactions Table
CREATE TABLE Transactions (
    transaction_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    reference_no VARCHAR(20) UNIQUE NOT NULL,
    from_account_id INT,
    to_account_id INT,
    amount DECIMAL(15,2) NOT NULL,
    trans_type ENUM('TRANSFER','DEPOSIT','WITHDRAWAL','BILL_PAY') NOT NULL,
    status ENUM('PENDING','SUCCESS','FAILED','REVERSED') DEFAULT 'PENDING',
    trans_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_account_id) REFERENCES Accounts(account_id),
    FOREIGN KEY (to_account_id) REFERENCES Accounts(account_id),
    CHECK (amount > 0)
);

-- 4. Bills Table
CREATE TABLE Bills (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    biller_name VARCHAR(50) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('PAID','FAILED') DEFAULT 'PAID',
    paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- 5. SupportTickets Table
CREATE TABLE SupportTickets (
    ticket_id VARCHAR(15) PRIMARY KEY,
    customer_id INT NOT NULL,
    account_id INT,
    issue_category ENUM('TRANSFER_FAILED','LOGIN','BILL_PAY','KYC','OTHER') NOT NULL,
    priority ENUM('P1','P2','P3') NOT NULL,
    description TEXT,
    status ENUM('OPEN','IN_PROGRESS','CLOSED','ESCALATED') DEFAULT 'OPEN',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (account_id) REFERENCES Accounts(account_id)
);

-- 6. AuditLogs Table
CREATE TABLE AuditLogs (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    account_id INT,
    action_type VARCHAR(50) NOT NULL,
    old_balance DECIMAL(15,2),
    new_balance DECIMAL(15,2),
    performed_by VARCHAR(50),
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES Accounts(account_id)
);

-- Sample Data for Testing
INSERT INTO Customers (bvn, full_name, email, phone, kyc_status) VALUES
('12345678901','Aisha Bello','aisha.bello@email.com','08030000001','VERIFIED'),
('12345678902','Chinedu Okoro','chinedu.o@email.com','08030000002','VERIFIED');

INSERT INTO Accounts (account_no, customer_id, account_type, balance) VALUES
('0123456789',1,'SAVINGS', 500000.00),
('0123456790',2,'SAVINGS', 250000.00);

INSERT INTO Transactions (reference_no, from_account_id, to_account_id, amount, trans_type, status) VALUES
('REF0012026',1,2,50000.00,'TRANSFER','SUCCESS');
