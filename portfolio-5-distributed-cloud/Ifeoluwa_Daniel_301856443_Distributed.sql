-- MIT 8103 Portfolio 5: Distributed Databases
-- Student: Ifeoluwa Daniel | ID: 301856443
-- Case Study: PayFlex Microfinance - Distributed for Scale
-- Scenario: PayFlex expanding to 3 branches: Ikeja (Primary), VI, Abuja

USE payflex_db;

-- ============================================
-- 1. REPLICATION: Master-Slave for Read Scalability
-- ============================================
-- Master: Ikeja branch (Handles all WRITES - fund transfers)
-- Slaves: VI, Abuja branches (Handles READS - balance checks, reports)

-- On Master Server (Ikeja) - my.cnf config:
/*
[mysqld]
server-id=1
log-bin=mysql-bin
binlog-do-db=payflex_db
*/

-- Create replication user on Master:
CREATE USER 'replica_user'@'%' IDENTIFIED BY 'PayFlex2024!';
GRANT REPLICATION SLAVE ON *.* TO 'replica_user'@'%';
FLUSH PRIVILEGES;
SHOW MASTER STATUS; -- Note File and Position

-- On Slave Servers (VI and Abuja) - my.cnf:
/*
[mysqld]
server-id=2  -- server-id=3 for Abuja
relay-log=mysql-relay-bin
*/

-- On Slave, connect to Master:
-- CHANGE MASTER TO MASTER_HOST='ikeja.payflex.local', MASTER_USER='replica_user', MASTER_PASSWORD='PayFlex2024!', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS= 0;
-- START SLAVE;
-- SHOW SLAVE STATUS\G

-- Benefit for PayFlex:
-- 1. Read scalability: 80% queries are balance checks - offload to slaves
-- 2. High Availability: If Master fails, promote Slave to Master
-- 3. Backup: Slaves can be used for backup without locking Master

-- Query routing logic (in application):
-- Writes: USE Master (Ikeja) - INSERT Transactions, UPDATE Accounts
-- Reads: USE Slave (nearest branch) - SELECT balance, transaction history

-- ============================================
-- 2. SHARDING: Horizontal Partitioning for Large Data
-- ============================================
-- Problem: Transactions table has 100M rows, too big for one server
-- Solution: Shard by customer_id or region

-- Sharding Strategy for PayFlex:

-- Strategy A: Range Sharding by Customer ID
-- Shard 1: customer_id 1-1,000,000 (Lagos customers)
-- Shard 2: customer_id 1,000,001-2,000,000 (Abuja customers)
-- Shard 3: customer_id 2,000,001+ (New regions)

-- Example: Create sharded tables
-- On Shard 1:
CREATE TABLE Transactions_Shard1 (
    transaction_id INT PRIMARY KEY,
    customer_id INT CHECK (customer_id BETWEEN 1 AND 1000000),
    amount DECIMAL(15,2),
    trans_date DATETIME,
    INDEX idx_customer (customer_id)
) ENGINE=InnoDB;

-- On Shard 2:
CREATE TABLE Transactions_Shard2 (
    transaction_id INT PRIMARY KEY,
    customer_id INT CHECK (customer_id BETWEEN 1000001 AND 2000000),
    amount DECIMAL(15,2),
    trans_date DATETIME,
    INDEX idx_customer (customer_id)
) ENGINE=InnoDB;

-- Application logic for sharding:
/*
function getShard(customer_id):
  if customer_id <= 1000000: return Shard1
  elif customer_id <= 2000000: return Shard2
  else: return Shard3
*/

-- Strategy B: Hash Sharding for Even Distribution
-- Shard = customer_id % 3
-- Better for load balancing, but range queries harder

-- Strategy C: Geographic Sharding for PayFlex
-- Ikeja Shard: All accounts where branch = 'IKEJA'
-- VI Shard: branch = 'VI'
-- Abuja Shard: branch = 'ABUJA'
-- Benefit: Data locality - Ikeja customers queried from Ikeja shard (low latency)

-- Add branch column for geographic sharding:
ALTER TABLE Accounts ADD COLUMN branch VARCHAR(20) DEFAULT 'IKEJA' CHECK (branch IN ('IKEJA', 'VI', 'ABUJA'));

-- ============================================
-- 3. CAP THEOREM ANALYSIS FOR PAYFLEX
-- ============================================
/*
CAP Theorem: Consistency, Availability, Partition Tolerance - pick 2

For PayFlex Microfinance:

1. Consistency (C): All branches see same balance after transfer
      - Critical for: Fund transfers, balance checks
      - Cannot allow: Customer transfers 50k in Ikeja, still sees old balance in VI

2. Availability (A): System always responds
      - Critical for: Agency banking, customers need to transact anytime
      - Even if one branch network fails, other branches should work

3. Partition Tolerance (P): System works despite network failure between branches
      - Must have: Lagos to Abuja network may fail, system should not crash

PayFlex Choice: CP (Consistency + Partition Tolerance) over AP

Reason:
- Financial data MUST be consistent - can't have double spending
- Better to make user wait/retry (reduce availability slightly) than show wrong balance
- MySQL Master-Slave is CP: If partition, slave may be stale but master remains consistent
- MongoDB for logs can be AP: Feedback can be eventually consistent

Trade-offs:
- If Ikeja-VI link fails (Partition), VI branch will:
  Option CP: Block writes, allow reads of stale data (safe)
  Option AP: Allow writes locally, sync later (risky for banking - not chosen)

- Implementation:
    * Core banking (Accounts, Transactions): CP - Use synchronous replication, wait for ack
    * Logs, Feedback, Analytics: AP - Use async replication, eventual consistency OK

*/

-- ============================================
-- 4. DISTRIBUTED TRANSACTION: 2-Phase Commit (2PC)
-- ============================================
-- Scenario: Transfer from Ikeja account to Abuja account (cross-shard)

-- Phase 1: Prepare
-- Coordinator asks both shards: Can you commit?
-- Shard 1 (Ikeja): Locks sender account, checks balance, replies YES
-- Shard 2 (Abuja): Locks receiver account, replies YES

-- Phase 2: Commit
-- If both YES: Coordinator tells both to COMMIT
-- If any NO: Coordinator tells both to ROLLBACK

-- MySQL XA Transactions for 2PC:
XA START 'payflex_transfer_001';
UPDATE Accounts SET balance = balance - 5000 WHERE account_id = 1 AND branch = 'IKEJA';
XA END 'payflex_transfer_001';
XA PREPARE 'payflex_transfer_001';

-- On Shard 2:
XA START 'payflex_transfer_001';
UPDATE Accounts SET balance = balance + 5000 WHERE account_id = 1001 AND branch = 'ABUJA';
XA END 'payflex_transfer_001';
XA PREPARE 'payflex_transfer_001';

-- Coordinator:
XA COMMIT 'payflex_transfer_001'; -- Or XA ROLLBACK

-- ============================================
-- 5. CONSISTENCY LEVELS
-- ============================================
-- Strong Consistency: After transfer, all branches immediately see new balance (CP, synchronous)
-- Eventual Consistency: VI branch may see old balance for 2 seconds (AP, asynchronous) - OK for reports, NOT for balance

-- For PayFlex:
SET GLOBAL rpl_semi_sync_master_enabled = 1; -- Semi-sync replication for stronger consistency
-- Master waits for at least 1 slave to ack before returning SUCCESS to customer
-- Trade-off: Slightly slower transfer (100ms extra) but safer
