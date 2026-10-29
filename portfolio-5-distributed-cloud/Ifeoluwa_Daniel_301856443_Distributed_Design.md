# PayFlex Distributed Database Design
Student: Ifeoluwa Daniel | 301856443

## 1. Current Problem
Single MySQL server in Ikeja handling 10k transactions/day - will not scale to 100k/day when expanding to VI and Abuja. Need distributed design.

## 2. Proposed Architecture
- Master: Ikeja (Write) - All fund transfers, bill payments
- Slave 1: VI (Read Replica) - Balance checks, statements for VI customers
- Slave 2: Abuja (Read Replica) - Balance checks for Abuja customers
- Replication: Semi-synchronous for CP guarantee

## 3. Sharding Strategy Chosen: Geographic Sharding
- Reason: Data locality - 90% of Ikeja customers transact in Ikeja, low latency
- Shard Key: branch column in Accounts (IKEJA, VI, ABUJA)
- Shard 1 (Ikeja): 60% data, Shard 2 (VI): 25%, Shard 3 (Abuja): 15%
- Future: Hash sharding if one branch grows too large

## 4. CAP Theorem Decision: CP System
- For PayFlex core banking, Consistency > Availability
- Justification: Financial transactions cannot afford inconsistency - no double spending
- Implementation: Synchronous replication, 2PC for cross-shard transfers
- Trade-off: If network partition between Ikeja-VI, VI will block writes (customer sees "try again") - acceptable for banking

## 5. Replication vs Sharding
- Replication: For read scalability and HA (same data on multiple servers)
- Sharding: For write scalability and storage (different data on different servers)
- PayFlex uses both: Replicate each shard for HA

## 6. Challenges & Solutions
- Challenge: Cross-shard transfer (Ikeja to Abuja) - Solution: XA 2-Phase Commit
- Challenge: Distributed deadlock - Solution: Timeout and retry logic in app
- Challenge: Replication lag - Solution: Read-your-writes: after customer transfers, read from Master for 5 seconds

## 7. Conclusion
PayFlex distributed design gives scalability to 100k TPS, HA, and maintains ACID for financial safety using CP model.
