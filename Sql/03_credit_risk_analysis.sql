-- ============================================================
-- FinSight Retail Banking Analytics
-- SQL Server 2022
-- 03 - Credit Risk Analysis
-- ============================================================
 
USE FinSight;
GO

-- 3C.1 - aantal leningen per loan status --
 
SELECT
    loan_status,
    COUNT(*) AS aantal_leningen
 
FROM dbo.loans_raw
 
GROUP BY loan_status
 
ORDER BY aantal_leningen DESC;
 
 
-- 3C.2 - totale default rate --
 
SELECT
    COUNT(*) AS totaal_leningen,
 
    SUM(
        CAST(default_flag AS INT)
    ) AS aantal_defaults,
 
    ROUND(
        100.0 * SUM(CAST(default_flag AS INT))
        / COUNT(*),
        2
    ) AS default_rate_pct
 
FROM dbo.loans_raw;
 
 
-- 3C.3 - default rate per risicogroep --
 
SELECT
    CASE
        WHEN customer_risk_score < 600 THEN 'High Risk'
        WHEN customer_risk_score < 700 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_group,
 
    COUNT(*) AS aantal_leningen,
 
    SUM(
        CAST(default_flag AS INT)
    ) AS aantal_defaults,
 
    ROUND(
        100.0 * SUM(CAST(default_flag AS INT))
        / COUNT(*),
        2
    ) AS default_rate_pct
 
FROM dbo.loans_raw
 
GROUP BY
    CASE
        WHEN customer_risk_score < 600 THEN 'High Risk'
        WHEN customer_risk_score < 700 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END
 
ORDER BY default_rate_pct DESC;
 
 
-- 3C.4 - achterstallige leningen per aantal dagen past due --
 
SELECT
    days_past_due,
 
    COUNT(*) AS aantal_leningen,
 
    ROUND(
        SUM(outstanding_balance_eur),
        2
    ) AS openstaand_saldo_eur
 
FROM dbo.loans_raw
 
GROUP BY days_past_due
 
ORDER BY days_past_due;
 
 
-- 3C.5 - managementoverzicht per loan status --
 
SELECT
    loan_status,
 
    COUNT(*) AS aantal_leningen,
 
    ROUND(
        SUM(original_principal_eur),
        2
    ) AS oorspronkelijk_krediet_eur,
 
    ROUND(
        SUM(outstanding_balance_eur),
        2
    ) AS openstaand_saldo_eur,
 
    ROUND(
        AVG(interest_rate_pct),
        2
    ) AS gemiddelde_rente_pct,
 
    ROUND(
        AVG(
            CAST(customer_risk_score AS DECIMAL(10,2))
        ),
        1
    ) AS gemiddelde_risicoscore
 
FROM dbo.loans_raw
 
GROUP BY loan_status
 
ORDER BY openstaand_saldo_eur DESC;
 
 
-- 3C.6 - kredietrisico per klantsegment --
 
SELECT
    c.segment,
 
    COUNT(l.loan_id) AS aantal_leningen,
 
    ROUND(
        AVG(l.original_principal_eur),
        2
    ) AS gemiddelde_lening_eur,
 
    ROUND(
        AVG(l.interest_rate_pct),
        2
    ) AS gemiddelde_rente_pct,
 
    ROUND(
        100.0 * SUM(CAST(l.default_flag AS INT))
        / COUNT(l.loan_id),
        2
    ) AS default_rate_pct
 
FROM dbo.loans_raw AS l
 
INNER JOIN dbo.customers_raw AS c
    ON l.customer_id = c.customer_id
 
GROUP BY c.segment
 
ORDER BY default_rate_pct DESC;
 
 
-- 3C.7 - top 10 meest problematische leningen --
 
SELECT TOP 10
    l.loan_id,
    l.customer_id,
    c.segment,
    c.annual_income_eur,
    l.original_principal_eur,
    l.outstanding_balance_eur,
    l.days_past_due,
    l.loan_status,
    l.customer_risk_score
 
FROM dbo.loans_raw AS l
 
INNER JOIN dbo.customers_raw AS c
    ON l.customer_id = c.customer_id
 
WHERE l.days_past_due > 0
 
ORDER BY
    l.days_past_due DESC,
    l.outstanding_balance_eur DESC;