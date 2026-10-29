# PayFlex: SQL vs NoSQL vs NewSQL Comparison
Student: Ifeoluwa Daniel | 301856443

## SQL (MySQL) - Used in Portfolio 1-3
- Best for: Customers, Accounts, Transactions (structured, relationships, ACID)
- Schema: Fixed, 6 tables, PK/FK enforced
- Advantage: ACID for fund transfer, JOIN for reports
- Limitation: Rigid for feedback, logs, device info

## NoSQL (MongoDB) - Portfolio 4
- Best for: Customer feedback, transaction logs, device metadata, unstructured
- Schema: Flexible, nested documents, arrays allowed
- Advantage: Store accounts array inside customer (no JOIN), store error logs with varying fields, scale horizontally for high volume transactions
- Query: db.customers.find({"accounts.balance": {$gt: 100000}})
- Use case in PayFlex: 1) Customer 360 view with all accounts nested 2) Store failed transaction error details with different fields 3) Customer feedback with sentiment

## NewSQL (CockroachDB/Google Spanner) - Future for PayFlex
- Best for: Distributed ACID across branches (Ikeja, VI, Abuja branches)
- Combines: SQL ACID + NoSQL scalability
- For PayFlex: When expanding to 10 branches, need transactions across regions with ACID and scalability
- CAP: CP system - Consistency + Partition tolerance

## Conclusion
PayFlex uses hybrid: MySQL for core banking (ACID), MongoDB for logs/feedback (flexibility), NewSQL for future distributed expansion.
