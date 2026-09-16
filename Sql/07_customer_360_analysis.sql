

-- FinSight Retail Banking Analytics
-- SQL Server 2022
-- 07 - Customer 360 Analysis
-- ============================================================
 
USE FinSight;
GO


-- 3G.1 - volledig Customer 360 overzicht per klant --
 
WITH account_metrics AS
(
    SELECT
        customer_id,
        COUNT(*) AS aantal_accounts,
        SUM(opening_balance_eur) AS totaal_opening_balance_eur,
        MAX(credit_limit_eur) AS hoogste_credit_limit_eur
 
    FROM dbo.accounts_raw
 
    GROUP BY customer_id
),
 
loan_metrics AS
(
    SELECT
        customer_id,
        COUNT(*) AS aantal_leningen,
        SUM(outstanding_balance_eur) AS totaal_openstaand_krediet_eur,
        MAX(days_past_due) AS max_days_past_due,
        SUM(CAST(default_flag AS INT)) AS aantal_defaults
 
    FROM dbo.loans_raw
 
    GROUP BY customer_id
),
 
transaction_metrics AS
(
    SELECT
        customer_id,
        COUNT(*) AS aantal_transacties,
 
        SUM(
            CASE
                WHEN flow_direction = 'Inflow'
                THEN amount_eur
                ELSE 0
            END
        ) AS totale_inflow_eur,
 
        ABS(
            SUM(
                CASE
                    WHEN flow_direction = 'Outflow'
                    THEN amount_eur
                    ELSE 0
                END
            )
        ) AS totale_outflow_eur,
 
        SUM(amount_eur) AS netto_cashflow_eur,
 
        SUM(
            CAST(is_suspicious AS INT)
        ) AS suspicious_transacties
 
    FROM dbo.transactions_clean
 
    GROUP BY customer_id
)
 
SELECT TOP 100
    c.customer_id,
    c.country,
    c.age_group,
    c.segment,
    c.annual_income_eur,
    c.risk_score,
    c.digital_active,
 
    ISNULL(a.aantal_accounts, 0) AS aantal_accounts,
    ISNULL(a.totaal_opening_balance_eur, 0) AS totaal_opening_balance_eur,
    ISNULL(a.hoogste_credit_limit_eur, 0) AS hoogste_credit_limit_eur,
 
    ISNULL(l.aantal_leningen, 0) AS aantal_leningen,
    ISNULL(l.totaal_openstaand_krediet_eur, 0) AS totaal_openstaand_krediet_eur,
    ISNULL(l.max_days_past_due, 0) AS max_days_past_due,
    ISNULL(l.aantal_defaults, 0) AS aantal_defaults,
 
    ISNULL(t.aantal_transacties, 0) AS aantal_transacties,
    ISNULL(t.totale_inflow_eur, 0) AS totale_inflow_eur,
    ISNULL(t.totale_outflow_eur, 0) AS totale_outflow_eur,
    ISNULL(t.netto_cashflow_eur, 0) AS netto_cashflow_eur,
    ISNULL(t.suspicious_transacties, 0) AS suspicious_transacties
 
FROM dbo.customers_raw AS c
 
LEFT JOIN account_metrics AS a
    ON c.customer_id = a.customer_id
 
LEFT JOIN loan_metrics AS l
    ON c.customer_id = l.customer_id
 
LEFT JOIN transaction_metrics AS t
    ON c.customer_id = t.customer_id
 
ORDER BY c.customer_id;
 
 
-- 3G.2 - klanten met hoge inkomsten maar hoge kredietrisico's --
 
SELECT TOP 20
    customer_id,
    segment,
    annual_income_eur,
    risk_score,
    country,
    age_group
 
FROM dbo.customers_raw
 
WHERE annual_income_eur >= 60000
  AND risk_score < 600
 
ORDER BY
    risk_score ASC,
    annual_income_eur DESC;
 
 
-- 3G.3 - klanten met lening(en) én suspicious transactions --
 
WITH loan_metrics AS
(
    SELECT
        customer_id,
        COUNT(*) AS aantal_leningen,
        SUM(outstanding_balance_eur) AS openstaand_krediet_eur,
        MAX(days_past_due) AS max_days_past_due,
        SUM(CAST(default_flag AS INT)) AS aantal_defaults
 
    FROM dbo.loans_raw
 
    GROUP BY customer_id
),
 
suspicious_metrics AS
(
    SELECT
        customer_id,
        COUNT(*) AS totaal_transacties,
 
        SUM(
            CAST(is_suspicious AS INT)
        ) AS suspicious_transacties
 
    FROM dbo.transactions_clean
 
    GROUP BY customer_id
)
 
SELECT
    c.customer_id,
    c.segment,
    c.annual_income_eur,
    c.risk_score,
 
    l.aantal_leningen,
    l.openstaand_krediet_eur,
    l.max_days_past_due,
    l.aantal_defaults,
 
    s.totaal_transacties,
    s.suspicious_transacties,
 
    ROUND(
        100.0 * s.suspicious_transacties
        / NULLIF(s.totaal_transacties, 0),
        2
    ) AS suspicious_rate_pct
 
FROM dbo.customers_raw AS c
 
INNER JOIN loan_metrics AS l
    ON c.customer_id = l.customer_id
 
INNER JOIN suspicious_metrics AS s
    ON c.customer_id = s.customer_id
 
WHERE s.suspicious_transacties > 0
 
ORDER BY
    l.aantal_defaults DESC,
    l.max_days_past_due DESC,
    s.suspicious_transacties DESC;
 
 
-- 3G.4 - klanten met betalingsachterstand én suspicious transaction --
 
WITH loan_risk AS
(
    SELECT
        customer_id,
        COUNT(*) AS aantal_leningen,
        MAX(days_past_due) AS max_days_past_due,
        SUM(CAST(default_flag AS INT)) AS aantal_defaults,
        SUM(outstanding_balance_eur) AS openstaand_krediet_eur
 
    FROM dbo.loans_raw
 
    GROUP BY customer_id
),
 
suspicious_customers AS
(
    SELECT
        customer_id,
        COUNT(*) AS aantal_transacties,
 
        SUM(
            CAST(is_suspicious AS INT)
        ) AS suspicious_transacties
 
    FROM dbo.transactions_clean
 
    GROUP BY customer_id
)
 
SELECT
    c.customer_id,
    c.segment,
    c.annual_income_eur,
    c.risk_score,
 
    l.aantal_leningen,
    l.max_days_past_due,
    l.aantal_defaults,
    l.openstaand_krediet_eur,
 
    s.aantal_transacties,
    s.suspicious_transacties
 
FROM dbo.customers_raw AS c
 
INNER JOIN loan_risk AS l
    ON c.customer_id = l.customer_id
 
INNER JOIN suspicious_customers AS s
    ON c.customer_id = s.customer_id
 
WHERE l.max_days_past_due > 0
  AND s.suspicious_transacties > 0
 
ORDER BY
    l.max_days_past_due DESC,
    s.suspicious_transacties DESC,
    l.openstaand_krediet_eur DESC;
 
 
-- 3G.5 - productgebruik per klant --
 
SELECT
    c.customer_id,
    c.segment,
 
    COUNT(a.account_id) AS aantal_accounts,
 
    SUM(
        CASE
            WHEN a.account_type = 'Current Account'
            THEN 1
            ELSE 0
        END
    ) AS current_accounts,
 
    SUM(
        CASE
            WHEN a.account_type = 'Savings Account'
            THEN 1
            ELSE 0
        END
    ) AS savings_accounts,
 
    SUM(
        CASE
            WHEN a.account_type = 'Credit Card'
            THEN 1
            ELSE 0
        END
    ) AS credit_cards
 
FROM dbo.customers_raw AS c
 
LEFT JOIN dbo.accounts_raw AS a
    ON c.customer_id = a.customer_id
 
GROUP BY
    c.customer_id,
    c.segment
 
ORDER BY
    aantal_accounts DESC,
    c.customer_id;
 
 
-- 3G.6 - klanten met meerdere financiële producten --
 
WITH account_metrics AS
(
    SELECT
        customer_id,
        COUNT(*) AS aantal_accounts,
        COUNT(DISTINCT account_type) AS aantal_accounttypes
 
    FROM dbo.accounts_raw
 
    GROUP BY customer_id
),
 
loan_metrics AS
(
    SELECT
        customer_id,
        COUNT(*) AS aantal_leningen
 
    FROM dbo.loans_raw
 
    GROUP BY customer_id
)
 
SELECT
    c.customer_id,
    c.segment,
 
    ISNULL(a.aantal_accounts, 0) AS aantal_accounts,
    ISNULL(a.aantal_accounttypes, 0) AS aantal_accounttypes,
    ISNULL(l.aantal_leningen, 0) AS aantal_leningen,
 
    ISNULL(a.aantal_accounts, 0)
    + ISNULL(l.aantal_leningen, 0) AS totaal_producten
 
FROM dbo.customers_raw AS c
 
LEFT JOIN account_metrics AS a
    ON c.customer_id = a.customer_id
 
LEFT JOIN loan_metrics AS l
    ON c.customer_id = l.customer_id
 
WHERE
    ISNULL(a.aantal_accounts, 0)
    + ISNULL(l.aantal_leningen, 0) >= 3
 
ORDER BY
    totaal_producten DESC,
    c.customer_id;
 
 
-- 3G.7 - klantsegmenten: gecombineerd financieel profiel --
 
WITH account_metrics AS
(
    SELECT
        customer_id,
        COUNT(*) AS aantal_accounts
 
    FROM dbo.accounts_raw
 
    GROUP BY customer_id
),
 
loan_metrics AS
(
    SELECT
        customer_id,
        COUNT(*) AS aantal_leningen,
 
        SUM(
            CAST(default_flag AS INT)
        ) AS aantal_defaults
 
    FROM dbo.loans_raw
 
    GROUP BY customer_id
),
 
transaction_metrics AS
(
    SELECT
        customer_id,
        COUNT(*) AS aantal_transacties,
 
        SUM(
            CAST(is_suspicious AS INT)
        ) AS suspicious_transacties
 
    FROM dbo.transactions_clean
 
    GROUP BY customer_id
)
 
SELECT
    c.segment,
 
    COUNT(*) AS aantal_klanten,
 
    ROUND(
        AVG(
            CAST(c.annual_income_eur AS DECIMAL(12,2))
        ),
        2
    ) AS gemiddeld_inkomen_eur,
 
    ROUND(
        AVG(
            CAST(c.risk_score AS DECIMAL(10,2))
        ),
        1
    ) AS gemiddelde_risicoscore,
 
    ROUND(
        AVG(
            CAST(ISNULL(a.aantal_accounts, 0) AS DECIMAL(10,2))
        ),
        2
    ) AS gem_accounts_per_klant,
 
    ROUND(
        AVG(
            CAST(ISNULL(l.aantal_leningen, 0) AS DECIMAL(10,2))
        ),
        2
    ) AS gem_leningen_per_klant,
 
    SUM(
        ISNULL(l.aantal_defaults, 0)
    ) AS totaal_defaults,
 
    SUM(
        ISNULL(t.suspicious_transacties, 0)
    ) AS totaal_suspicious_transacties
 
FROM dbo.customers_raw AS c
 
LEFT JOIN account_metrics AS a
    ON c.customer_id = a.customer_id
 
LEFT JOIN loan_metrics AS l
    ON c.customer_id = l.customer_id
 
LEFT JOIN transaction_metrics AS t
    ON c.customer_id = t.customer_id
 
GROUP BY c.segment
 
ORDER BY gemiddeld_inkomen_eur DESC;
 
 
-- 3G.8 - high-risk klanten met openstaand krediet --
 
WITH loan_metrics AS
(
    SELECT
        customer_id,
 
        COUNT(*) AS aantal_leningen,
 
        SUM(outstanding_balance_eur) AS openstaand_krediet_eur,
 
        MAX(days_past_due) AS max_days_past_due,
 
        SUM(
            CAST(default_flag AS INT)
        ) AS aantal_defaults
 
    FROM dbo.loans_raw
 
    GROUP BY customer_id
)
 
SELECT TOP 20
    c.customer_id,
    c.segment,
    c.annual_income_eur,
    c.risk_score,
 
    l.aantal_leningen,
    l.openstaand_krediet_eur,
    l.max_days_past_due,
    l.aantal_defaults
 
FROM dbo.customers_raw AS c
 
INNER JOIN loan_metrics AS l
    ON c.customer_id = l.customer_id
 
WHERE c.risk_score < 600
  AND l.openstaand_krediet_eur > 0
 
ORDER BY
    l.aantal_defaults DESC,
    l.max_days_past_due DESC,
    l.openstaand_krediet_eur DESC;
 
 
-- 3G.9 - Customer 360 shortlist voor extra monitoring --
 
WITH loan_metrics AS
(
    SELECT
        customer_id,
 
        SUM(outstanding_balance_eur) AS openstaand_krediet_eur,
 
        MAX(days_past_due) AS max_days_past_due,
 
        SUM(
            CAST(default_flag AS INT)
        ) AS aantal_defaults
 
    FROM dbo.loans_raw
 
    GROUP BY customer_id
),
 
transaction_metrics AS
(
    SELECT
        customer_id,
 
        COUNT(*) AS aantal_transacties,
 
        SUM(
            CAST(is_suspicious AS INT)
        ) AS suspicious_transacties
 
    FROM dbo.transactions_clean
 
    GROUP BY customer_id
)
 
SELECT TOP 25
    c.customer_id,
    c.segment,
    c.annual_income_eur,
    c.risk_score,
 
    ISNULL(l.openstaand_krediet_eur, 0) AS openstaand_krediet_eur,
    ISNULL(l.max_days_past_due, 0) AS max_days_past_due,
    ISNULL(l.aantal_defaults, 0) AS aantal_defaults,
 
    ISNULL(t.aantal_transacties, 0) AS aantal_transacties,
    ISNULL(t.suspicious_transacties, 0) AS suspicious_transacties
 
FROM dbo.customers_raw AS c
 
LEFT JOIN loan_metrics AS l
    ON c.customer_id = l.customer_id
 
LEFT JOIN transaction_metrics AS t
    ON c.customer_id = t.customer_id
 
WHERE
       c.risk_score < 600
    OR ISNULL(l.aantal_defaults, 0) > 0
    OR ISNULL(l.max_days_past_due, 0) >= 30
    OR ISNULL(t.suspicious_transacties, 0) > 0
 
ORDER BY
    ISNULL(l.aantal_defaults, 0) DESC,
    ISNULL(l.max_days_past_due, 0) DESC,
    ISNULL(t.suspicious_transacties, 0) DESC,
    c.risk_score ASC;