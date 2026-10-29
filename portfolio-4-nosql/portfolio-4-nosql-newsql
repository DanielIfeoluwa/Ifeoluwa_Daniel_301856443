// MIT 8103 Portfolio 4: NoSQL & NewSQL
// Student: Ifeoluwa Daniel | ID: 301856443
// Case Study: PayFlex Microfinance - Same case study, NoSQL model
// Database: payflex_nosql

// USE DATABASE
use payflex_nosql

// ============================================
// 1. COLLECTION: customers (Flexible schema - unstructured fields)
// ============================================
db.customers.insertMany([
  {
    _id: 1,
    bvn: "12345678901",
    full_name: "Ifeoluwa Daniel",
    email: "ifeoluwa.payflex@example.com",
    phone: "08012345678",
    kyc_status: "VERIFIED",
    // NoSQL advantage: nested document, no need for separate table
    address: {
      street: "12 Allen Avenue",
      city: "Ikeja",
      state: "Lagos",
      country: "Nigeria"
    },
    // Flexible: array of accounts inside customer
    accounts: [
      { account_no: "0123456789", type: "SAVINGS", balance: 150000.00, status: "ACTIVE" },
      { account_no: "9876543210", type: "CURRENT", balance: 500000.00, status: "ACTIVE" }
    ],
    metadata: {
      created_at: new Date(),
      device_info: ["iPhone 14", "Android 13"],
      tags: ["high-value", "verified", "agency-banking"]
    }
  },
  {
    _id: 2,
    bvn: "10987654321",
    full_name: "Adebayo Tunde",
    email: "adebayo@example.com",
    kyc_status: "PENDING",
    address: { city: "Lagos" }, // Flexible: incomplete address allowed
    accounts: [
      { account_no: "1122334455", type: "SAVINGS", balance: 20000.00 }
    ]
  }
]);

// ============================================
// 2. COLLECTION: transactions (High volume, unstructured logs)
// ============================================
db.transactions.insertMany([
  {
    reference_no: "TRF16987654321",
    from_account: "0123456789",
    to_account: "9876543210",
    amount: 5000.00,
    trans_type: "TRANSFER",
    status: "SUCCESS",
    // NoSQL advantage: flexible log field
    log: {
      ip_address: "192.168.1.1",
      device: "iPhone 14",
      location: { lat: 6.5244, long: 3.3792 },
      attempts: 1
    },
    timestamp: new Date()
  },
  {
    reference_no: "BILL16987654322",
    from_account: "0123456789",
    amount: 2000.00,
    trans_type: "BILL_PAYMENT",
    status: "FAILED",
    error: {
      code: "INSUFFICIENT_FUNDS",
      message: "Balance low",
      retries: 2
    },
    timestamp: new Date()
  }
]);

// ============================================
// 3. COLLECTION: customer_feedback (Unstructured - Can't do well in SQL)
// ============================================
db.customer_feedback.insertMany([
  {
    customer_id: 1,
    rating: 5,
    comment: "Fast transfer! Love PayFlex",
    sentiment: "POSITIVE",
    // Flexible fields
    attachments: ["screenshot1.png"],
    response_time_ms: 120,
    tags: ["transfer", "positive"]
  },
  {
    customer_id: 2,
    rating: 2,
    comment: "Transfer failed twice",
    issues: ["transfer", "network"],
    sentiment: "NEGATIVE"
  }
]);

// ============================================
// 4. NoSQL QUERIES - Demonstrate advantage
// ============================================

// Query 1: Find high-value customers with nested query (No JOIN needed!)
db.customers.find({ "accounts.balance": { $gt: 100000 } });

// Query 2: Aggregation - Total balance per customer (NoSQL aggregation pipeline)
db.customers.aggregate([
  { $unwind: "$accounts" },
  { $group: { _id: "$full_name", total_balance: { $sum: "$accounts.balance" } } },
  { $sort: { total_balance: -1 } }
]);

// Query 3: Find failed transactions with error logs
db.transactions.find({ status: "FAILED", "error.code": { $exists: true } });

// Query 4: Full-text search on feedback (NoSQL advantage)
db.customer_feedback.createIndex({ comment: "text" });
db.customer_feedback.find({ $text: { $search: "transfer failed" } });

// Query 5: Geospatial query (if we store location)
db.transactions.createIndex({ "log.location": "2dsphere" });

// ============================================
// 5. NEWSQL: Comparison - CockroachDB / Google Spanner concept
// ============================================
// NewSQL combines ACID of SQL + scalability of NoSQL
// For PayFlex: Use CockroachDB for distributed transactions across Lagos branches
// Example: CREATE TABLE accounts (id INT PRIMARY KEY, balance DECIMAL) -- same SQL but distributed

// Portfolio 4 Summary:
// SQL good for: Structured, ACID transactions, relationships (Accounts, Transactions)
// NoSQL good for: Flexible schema, unstructured logs, feedback, rapid scaling
// NewSQL good for: Distributed ACID for PayFlex multi-branch expansion
