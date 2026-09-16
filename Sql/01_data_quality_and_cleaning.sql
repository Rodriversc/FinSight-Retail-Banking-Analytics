-- ============================================================
-- FinSight Retail Banking Analytics
-- SQL Server 2022
-- 01 - Data Quality & Cleaning
-- ============================================================
 
USE FinSight;
GO
 
 
-- ------------------------------------------------------------
-- 1.1 - row counts van de raw tabellen
-- ------------------------------------------------------------
 
SELECT COUNT(*) AS customers
FROM dbo.customers_raw;
 
SELECT COUNT(*) AS accounts
FROM dbo.accounts_raw;
 
SELECT COUNT(*) AS loans
FROM dbo.loans_raw;
 
SELECT COUNT(*) AS transactions
FROM dbo.transactions_raw;
 
 
-- ------------------------------------------------------------
-- 1.2 - controle op dubbele transaction_id's
-- ------------------------------------------------------------
 
SELECT
    COUNT(*) AS totaal_rijen,
    COUNT(DISTINCT transaction_id) AS unieke_transacties,
    COUNT(*) - COUNT(DISTINCT transaction_id) AS dubbele_transacties
 
FROM dbo.transactions_raw;
 
 
-- ------------------------------------------------------------
-- 1.3 - ontbrekende waarden in transactions_raw
-- ------------------------------------------------------------
 
SELECT
    COUNT(*) AS totaal_rijen,
 
    SUM(
        CASE
            WHEN category IS NULL
                 OR LTRIM(RTRIM(category)) = ''
            THEN 1
            ELSE 0
        END
    ) AS ontbrekende_category,
 
    SUM(
        CASE
            WHEN merchant_country IS NULL
                 OR LTRIM(RTRIM(merchant_country)) = ''
            THEN 1
            ELSE 0
        END
    ) AS ontbrekende_merchant_country
 
FROM dbo.transactions_raw;
 
 
-- ------------------------------------------------------------
-- 1.4 - transacties zonder geldig account controleren
-- ------------------------------------------------------------
 
SELECT
    COUNT(*) AS transacties_zonder_account
 
FROM dbo.transactions_raw AS t
 
LEFT JOIN dbo.accounts_raw AS a
    ON t.account_id = a.account_id
 
WHERE a.account_id IS NULL;
 
 
-- ------------------------------------------------------------
-- 1.5 - accounts zonder geldige klant controleren
-- ------------------------------------------------------------
 
SELECT
    COUNT(*) AS accounts_zonder_customer
 
FROM dbo.accounts_raw AS a
 
LEFT JOIN dbo.customers_raw AS c
    ON a.customer_id = c.customer_id
 
WHERE c.customer_id IS NULL;
 
 
-- ------------------------------------------------------------
-- 1.6 - dubbele transacties zichtbaar maken
-- ------------------------------------------------------------
 
SELECT
    transaction_id,
    COUNT(*) AS aantal
 
FROM dbo.transactions_raw
 
GROUP BY transaction_id
 
HAVING COUNT(*) > 1
 
ORDER BY aantal DESC;
 
 
-- ------------------------------------------------------------
-- 1.7 - duplicaten nummeren met ROW_NUMBER()
-- ------------------------------------------------------------
 
SELECT
    *,
 
    ROW_NUMBER() OVER (
        PARTITION BY transaction_id
        ORDER BY transaction_datetime
    ) AS rij_nummer
 
FROM dbo.transactions_raw;
 
 
-- ------------------------------------------------------------
-- 1.8 - clean transactietabel opnieuw aanmaken
-- ------------------------------------------------------------
 
DROP TABLE IF EXISTS dbo.transactions_clean;
GO
 
 
WITH genummerde_transacties AS
(
    SELECT
        *,
 
        ROW_NUMBER() OVER (
            PARTITION BY transaction_id
            ORDER BY transaction_datetime
        ) AS rij_nummer
 
    FROM dbo.transactions_raw
)
 
SELECT
    transaction_id,
    account_id,
    customer_id,
    transaction_datetime,
    transaction_type,
 
    CASE
        WHEN category IS NULL
             OR LTRIM(RTRIM(category)) = ''
        THEN 'Unknown'
 
        ELSE LTRIM(RTRIM(category))
    END AS category,
 
    amount_eur,
 
    CASE
        WHEN merchant_country IS NULL
             OR LTRIM(RTRIM(merchant_country)) = ''
        THEN 'Unknown'
 
        ELSE LTRIM(RTRIM(merchant_country))
    END AS merchant_country,
 
    channel,
    is_international,
    is_suspicious
 
INTO dbo.transactions_clean
 
FROM genummerde_transacties
 
WHERE rij_nummer = 1;
GO
 
 
-- ------------------------------------------------------------
-- 1.9 - flow direction toevoegen
-- ------------------------------------------------------------
 
ALTER TABLE dbo.transactions_clean
ADD flow_direction VARCHAR(10);
GO
 
 
UPDATE dbo.transactions_clean
 
SET flow_direction =
    CASE
        WHEN amount_eur >= 0
        THEN 'Inflow'
 
        ELSE 'Outflow'
    END;
GO
 
 
-- ------------------------------------------------------------
-- 1.10 - aantal clean transacties controleren
-- ------------------------------------------------------------
 
SELECT
    COUNT(*) AS aantal_clean
 
FROM dbo.transactions_clean;
 
 
-- ------------------------------------------------------------
-- 1.11 - controleren of duplicaten verwijderd zijn
-- ------------------------------------------------------------
 
SELECT
    COUNT(*) AS totaal_rijen,
    COUNT(DISTINCT transaction_id) AS unieke_transacties,
    COUNT(*) - COUNT(DISTINCT transaction_id) AS dubbele_transacties
 
FROM dbo.transactions_clean;
 
 
-- ------------------------------------------------------------
-- 1.12 - Unknown waarden controleren
-- ------------------------------------------------------------
 
SELECT
 
    SUM(
        CASE
            WHEN category = 'Unknown'
            THEN 1
            ELSE 0
        END
    ) AS unknown_category,
 
    SUM(
        CASE
            WHEN merchant_country = 'Unknown'
            THEN 1
            ELSE 0
        END
    ) AS unknown_merchant_country
 
FROM dbo.transactions_clean;
 
 
-- ------------------------------------------------------------
-- 1.13 - volledige cleaning validation
-- ------------------------------------------------------------
 
WITH controles AS
(
    SELECT
        1 AS volgorde,
        'Rijen in RAW-tabel' AS controle,
        COUNT(*) AS resultaat
    FROM dbo.transactions_raw
 
 
    UNION ALL
 
 
    SELECT
        2,
        'Rijen in CLEAN-tabel',
        COUNT(*)
    FROM dbo.transactions_clean
 
 
    UNION ALL
 
 
    SELECT
        3,
        'Duplicaten in RAW',
        COUNT(*) - COUNT(DISTINCT transaction_id)
    FROM dbo.transactions_raw
 
 
    UNION ALL
 
 
    SELECT
        4,
        'Duplicaten in CLEAN',
        COUNT(*) - COUNT(DISTINCT transaction_id)
    FROM dbo.transactions_clean
 
 
    UNION ALL
 
 
    SELECT
        5,
        'Unknown categories',
        COUNT(*)
    FROM dbo.transactions_clean
    WHERE category = 'Unknown'
 
 
    UNION ALL
 
 
    SELECT
        6,
        'Unknown merchant countries',
        COUNT(*)
    FROM dbo.transactions_clean
    WHERE merchant_country = 'Unknown'
 
 
    UNION ALL
 
 
    SELECT
        7,
        'Inflow transacties',
        COUNT(*)
    FROM dbo.transactions_clean
    WHERE flow_direction = 'Inflow'
 
 
    UNION ALL
 
 
    SELECT
        8,
        'Outflow transacties',
        COUNT(*)
    FROM dbo.transactions_clean
    WHERE flow_direction = 'Outflow'
)
 
SELECT
    controle,
    resultaat
 
FROM controles
 
ORDER BY volgorde;
 
 
-- ------------------------------------------------------------
-- 1.14 - sample van de opgeschoonde dataset
-- ------------------------------------------------------------
 
SELECT TOP 10
    transaction_id,
    transaction_datetime,
    transaction_type,
    category,
    amount_eur,
    merchant_country,
    flow_direction,
    is_suspicious
 
FROM dbo.transactions_clean
 
ORDER BY transaction_datetime DESC;