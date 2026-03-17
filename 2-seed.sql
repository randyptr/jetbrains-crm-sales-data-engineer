-- 2-seed.sql — Sample Data

-- Clear tables before inserting (idempotent)
TRUNCATE TABLE crm_dwh.raw_transactions;
TRUNCATE TABLE crm_dwh.raw_subscriptions;
TRUNCATE TABLE crm_dwh.raw_customers;

-- Customers: 10 clean + 3 dirty rows
INSERT INTO crm_dwh.raw_customers VALUES
    (1,  'Acme Corp',         'US',      '2024-01-05'),
    (2,  'Beta Systems',      'UK',      '2024-01-15'),
    (3,  'Gamma Solutions',   'DE',      '2024-02-01'),
    (4,  'Delta Tech',        'FR',      '2024-02-20'),
    (5,  'Epsilon Ltd',       'US',      '2024-03-05'),
    (6,  'Zeta Innovations',  'ES',      '2024-03-18'),
    (7,  'Eta Software',      'NL',      '2024-04-02'),
    (8,  'Theta Cloud',       'US',      '2024-04-15'),
    (9,  'Iota Digital',      'CA',      '2024-05-01'),
    (10, 'Kappa Group',       'AU',      '2024-05-20'),
    (11, NULL,                'US',      '2024-06-01'),  -- missing company name
    (12, NULL,                'UK',      '2024-06-10'),  -- missing company name
    (NULL, 'Ghost Company',   'DE',      '2024-06-15');  -- missing customer_id

-- Subscriptions: 15 clean + 3 dirty rows
INSERT INTO crm_dwh.raw_subscriptions VALUES
    (1,  1,  'Annual',   '2024-01-01', '2024-12-31', 1200.00),
    (2,  2,  'Annual',   '2024-01-15', '2025-01-14', 1200.00),
    (3,  5,  'Annual',   '2024-03-01', '2025-02-28', 1200.00),
    (4,  6,  'Annual',   '2024-03-20', '2025-03-19', 1200.00),
    (5,  3,  'Monthly',  '2024-02-01', '2024-02-29', 100.00),
    (6,  4,  'Monthly',  '2024-02-20', '2024-03-19', 100.00),
    (7,  7,  'Monthly',  '2024-04-01', '2024-04-30', 100.00),
    (8,  8,  'Monthly',  '2024-04-15', '2024-05-14', 100.00),
    (9,  9,  'Monthly',  '2024-05-01', NULL,         100.00),
    (10, 10, 'Annual',   '2024-05-20', NULL,         1200.00),
    (11, 1,  'Monthly',  '2024-06-01', NULL,         100.00),
    (12, 3,  'Annual',   '2024-07-01', NULL,         1200.00),
    (13, 5,  'Monthly',  '2024-07-15', NULL,         100.00),
    (14, 2,  'Annual',   '2024-08-01', NULL,         1200.00),
    (15, 4,  'Monthly',  '2024-09-01', NULL,         100.00),
    (16, 1,  'Weekly',   '2024-09-10', NULL,         25.00),   -- invalid plan type
    (17, 2,  'Lifetime', '2024-09-12', NULL,         5000.00), -- invalid plan type
    (18, NULL, 'Monthly','2024-09-15', NULL,         100.00);  -- missing customer_id

-- Transactions: 20 clean + 3 duplicates + 3 DQ errors + 2 invalid statuses
INSERT INTO crm_dwh.raw_transactions VALUES
    (1,  1,  '2024-01-01', 'Success'),
    (2,  2,  '2024-01-15', 'Success'),
    (3,  3,  '2024-03-01', 'Success'),
    (4,  4,  '2024-03-20', 'Success'),
    (5,  5,  '2024-02-01', 'Success'),
    (6,  6,  '2024-02-20', 'Failed'),
    (7,  6,  '2024-02-25', 'Success'),
    (8,  7,  '2024-04-01', 'Refunded'),
    (9,  8,  '2024-04-15', 'Success'),
    (10, 9,  '2024-05-01', 'Success'),
    (11, 10, '2024-05-20', 'Success'),
    (12, 11, '2024-06-01', 'Success'),
    (13, 12, '2024-07-01', 'Success'),
    (14, 13, '2024-07-15', 'Failed'),
    (15, 13, '2024-07-20', 'Success'),
    (16, 14, '2024-08-01', 'Success'),
    (17, 15, '2024-09-01', 'Success'),
    (18, 1,  '2024-04-01', 'Success'),
    (19, 2,  '2024-04-15', 'Success'),
    (20, 3,  '2024-06-01', 'Success'),
    (21, 1,  '2024-01-01', 'Success'),   -- duplicate of tx_id 1
    (22, 2,  '2024-01-15', 'Success'),   -- duplicate of tx_id 2
    (23, 5,  '2024-02-01', 'Success'),   -- duplicate of tx_id 5
    (24, 9,  '2024-04-10', 'Success'),   -- sub 9 started 2024-05-01
    (25, 10, '2024-05-15', 'Success'),   -- sub 10 started 2024-05-20
    (26, 12, '2024-06-20', 'Success'),   -- sub 12 started 2024-07-01
    (27, 9,  '2024-06-01', 'Pending'),   -- invalid status
    (28, 10, '2024-07-01', 'Processing');-- invalid status