

-- FinSight Retail Banking Analytics
-- SQL Server 2022
-- 06 - Account and Product Analysis
-- ============================================================
 
USE FinSight;
GO


-- 3F.1 - aantal accounts per accounttype --
 
SELECT
    account_type,
 
    COUNT(*) AS aantal_accounts
 
FROM dbo.accounts_raw
 
GROUP BY account_type
 
ORDER BY aantal_accounts DESC;
 
 
-- 3F.2 - accountstatus per accounttype --
 
SELECT
    account_type,
    status,
 
    COUNT(*) AS aantal_accounts
 
FROM dbo.accounts_raw
 
GROUP BY
    account_type,
    status
 
ORDER BY
    account_type,
    aantal_accounts DESC;
 
 
-- 3F.3 - gemiddelde en totale balans per accounttype --
 
SELECT
    account_type,
 
    COUNT(*) AS aantal_accounts,
 
    ROUND(
        AVG(opening_balance_eur),
        2
    ) AS gemiddelde_balans_eur,
 
    ROUND(
        SUM(opening_balance_eur),
        2
    ) AS totale_balans_eur
 
FROM dbo.accounts_raw
 
GROUP BY account_type
 
ORDER BY totale_balans_eur DESC;
 
 
-- 3F.4 - gemiddelde rente per accounttype --
 
SELECT
    account_type,
 
    COUNT(*) AS aantal_accounts,
 
    ROUND(
        AVG(interest_rate_pct),
        2
    ) AS gemiddelde_rente_pct,
 
    ROUND(
        MIN(interest_rate_pct),
        2
    ) AS minimum_rente_pct,
 
    ROUND(
        MAX(interest_rate_pct),
        2
    ) AS maximum_rente_pct
 
FROM dbo.accounts_raw
 
WHERE interest_rate_pct > 0
 
GROUP BY account_type
 
ORDER BY gemiddelde_rente_pct DESC;
 
 
-- 3F.5 - gemiddeld aantal accounts per klantsegment --
 
WITH accounts_per_customer AS
(
    SELECT
        customer_id,
        COUNT(*) AS aantal_accounts
 
    FROM dbo.accounts_raw
 
    GROUP BY customer_id
)
 
SELECT
    c.segment,
 
    COUNT(*) AS aantal_klanten,
 
    ROUND(
        AVG(
            CAST(
                ISNULL(a.aantal_accounts, 0)
                AS DECIMAL(10,2)
            )
        ),
        2
    ) AS gemiddeld_accounts_per_klant
 
FROM dbo.customers_raw AS c
 
LEFT JOIN accounts_per_customer AS a
    ON c.customer_id = a.customer_id
 
GROUP BY c.segment
 
ORDER BY gemiddeld_accounts_per_klant DESC;
 
 
-- 3F.6 - productpenetratie per klantsegment --
 
SELECT
    c.segment,
 
    COUNT(DISTINCT c.customer_id) AS aantal_klanten,
 
    COUNT(
        DISTINCT CASE
            WHEN a.account_type = 'Current Account'
            THEN c.customer_id
        END
    ) AS klanten_met_current_account,
 
    COUNT(
        DISTINCT CASE
            WHEN a.account_type = 'Savings Account'
            THEN c.customer_id
        END
    ) AS klanten_met_savings_account,
 
    COUNT(
        DISTINCT CASE
            WHEN a.account_type = 'Credit Card'
            THEN c.customer_id
        END
    ) AS klanten_met_credit_card
 
FROM dbo.customers_raw AS c
 
LEFT JOIN dbo.accounts_raw AS a
    ON c.customer_id = a.customer_id
 
GROUP BY c.segment
 
ORDER BY c.segment;
 
 
-- 3F.7 - productpenetratie als percentage per klantsegment --
 
WITH segment_producten AS
(
    SELECT
        c.segment,
 
        COUNT(DISTINCT c.customer_id) AS aantal_klanten,
 
        COUNT(
            DISTINCT CASE
                WHEN a.account_type = 'Current Account'
                THEN c.customer_id
            END
        ) AS current_customers,
 
        COUNT(
            DISTINCT CASE
                WHEN a.account_type = 'Savings Account'
                THEN c.customer_id
            END
        ) AS savings_customers,
 
        COUNT(
            DISTINCT CASE
                WHEN a.account_type = 'Credit Card'
                THEN c.customer_id
            END
        ) AS credit_card_customers
 
    FROM dbo.customers_raw AS c
 
    LEFT JOIN dbo.accounts_raw AS a
        ON c.customer_id = a.customer_id
 
    GROUP BY c.segment
)
 
SELECT
    segment,
 
    aantal_klanten,
 
    ROUND(
        100.0 * current_customers
        / NULLIF(aantal_klanten, 0),
        2
    ) AS current_account_pct,
 
    ROUND(
        100.0 * savings_customers
        / NULLIF(aantal_klanten, 0),
        2
    ) AS savings_account_pct,
 
    ROUND(
        100.0 * credit_card_customers
        / NULLIF(aantal_klanten, 0),
        2
    ) AS credit_card_pct
 
FROM segment_producten
 
ORDER BY credit_card_pct DESC;
 
 
-- 3F.8 - klanten met meerdere accountproducten --
 
WITH customer_products AS
(
    SELECT
        customer_id,
 
        COUNT(*) AS aantal_accounts,
 
        COUNT(
            DISTINCT account_type
        ) AS aantal_producttypes
 
    FROM dbo.accounts_raw
 
    GROUP BY customer_id
)
 
SELECT TOP 100
    c.customer_id,
    c.segment,
    c.annual_income_eur,
    c.risk_score,
 
    p.aantal_accounts,
    p.aantal_producttypes
 
FROM customer_products AS p
 
INNER JOIN dbo.customers_raw AS c
    ON p.customer_id = c.customer_id
 
WHERE p.aantal_producttypes >= 2
 
ORDER BY
    p.aantal_producttypes DESC,
    p.aantal_accounts DESC,
    c.customer_id;
 
 
-- 3F.9 - analyse kredietkaartlimieten per klantsegment --
 
SELECT
    c.segment,
 
    COUNT(a.account_id) AS aantal_credit_cards,
 
    ROUND(
        AVG(a.credit_limit_eur),
        2
    ) AS gemiddelde_credit_limit_eur,
 
    ROUND(
        MIN(a.credit_limit_eur),
        2
    ) AS minimum_credit_limit_eur,
 
    ROUND(
        MAX(a.credit_limit_eur),
        2
    ) AS maximum_credit_limit_eur
 
FROM dbo.accounts_raw AS a
 
INNER JOIN dbo.customers_raw AS c
    ON a.customer_id = c.customer_id
 
WHERE a.account_type = 'Credit Card'
 
GROUP BY c.segment
 
ORDER BY gemiddelde_credit_limit_eur DESC;
 
 
-- 3F.10 - credit card utilization per klant --
 
SELECT TOP 50
    a.customer_id,
    c.segment,
    c.annual_income_eur,
    c.risk_score,
 
    a.credit_limit_eur,
 
    ABS(a.opening_balance_eur) AS gebruikt_krediet_eur,
 
    ROUND(
        100.0 * ABS(a.opening_balance_eur)
        / NULLIF(a.credit_limit_eur, 0),
        2
    ) AS credit_utilization_pct
 
FROM dbo.accounts_raw AS a
 
INNER JOIN dbo.customers_raw AS c
    ON a.customer_id = c.customer_id
 
WHERE a.account_type = 'Credit Card'
  AND a.credit_limit_eur > 0
 
ORDER BY credit_utilization_pct DESC;
 
 
-- 3F.11 - percentage active, dormant en closed accounts --
 
SELECT
    status,
 
    COUNT(*) AS aantal_accounts,
 
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_accounts
 
FROM dbo.accounts_raw
 
GROUP BY status
 
ORDER BY percentage_accounts DESC;
 
 
-- 3F.12 - accountstatus per klantsegment --
 
SELECT
    c.segment,
 
    COUNT(a.account_id) AS totaal_accounts,
 
    SUM(
        CASE
            WHEN a.status = 'Active'
            THEN 1
            ELSE 0
        END
    ) AS active_accounts,
 
    SUM(
        CASE
            WHEN a.status = 'Dormant'
            THEN 1
            ELSE 0
        END
    ) AS dormant_accounts,
 
    SUM(
        CASE
            WHEN a.status = 'Closed'
            THEN 1
            ELSE 0
        END
    ) AS closed_accounts,
 
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN a.status = 'Dormant'
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(a.account_id), 0),
        2
    ) AS dormant_rate_pct
 
FROM dbo.customers_raw AS c
 
INNER JOIN dbo.accounts_raw AS a
    ON c.customer_id = a.customer_id
 
GROUP BY c.segment
 
ORDER BY dormant_rate_pct DESC;