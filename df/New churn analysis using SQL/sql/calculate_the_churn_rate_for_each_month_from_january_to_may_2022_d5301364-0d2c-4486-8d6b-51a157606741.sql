WITH "customer_orders" AS (
  SELECT
    "fact_order_table"."customer_id",
    DATE_TRUNC('month', "fact_order_table"."created_at") AS "order_month",
    COUNT(DISTINCT DATE("fact_order_table"."created_at")) AS "n_purchases",
    MAX("fact_order_table"."created_at") AS "last_purchase_date",
    SUM("fact_order_table"."total_price") AS "total_spent"
  FROM "public"."fact_order_table"
  GROUP BY
    "fact_order_table"."customer_id",
    "order_month"
), "customer_recency" AS (
  SELECT
    "dim_customer_table"."id" AS "customer_id",
    DATE_TRUNC('month', MAX("dim_customer_table"."created_at")) AS "last_purchase_month",
    EXTRACT(day FROM AGE('2022-05-31', MAX("dim_customer_table"."created_at"))) AS "diff_date"
  FROM "public"."dim_customer_table"
  GROUP BY
    "customer_id"
), "customer_scores" AS (
  SELECT
    "customer_orders"."customer_id",
    "customer_orders"."order_month",
    "customer_orders"."n_purchases",
    "customer_orders"."total_spent",
    "customer_recency"."diff_date",
    CASE
      WHEN "customer_recency"."diff_date" IS NULL
      THEN 0
      ELSE (
        (
          30 - "customer_recency"."diff_date"
        ) / 30.0
      ) * 100
    END AS "r_score",
    CASE
      WHEN "customer_orders"."n_purchases" IS NULL
      THEN 0
      ELSE (
        "customer_orders"."n_purchases" / 30.0
      ) * 100
    END AS "f_score"
  FROM "customer_orders"
  LEFT JOIN "customer_recency"
    ON "customer_orders"."customer_id" = "customer_recency"."customer_id"
), "customer_loyalty" AS (
  SELECT
    "customer_id",
    "order_month",
    "n_purchases",
    "total_spent",
    "r_score",
    "f_score",
    (
      "r_score" * "f_score"
    ) / 10000.0 AS "loyalty_score"
  FROM "customer_scores"
), "customer_churn" AS (
  SELECT
    "customer_id",
    "order_month",
    "n_purchases",
    "total_spent",
    "r_score",
    "f_score",
    "loyalty_score",
    CASE WHEN "loyalty_score" < 0 THEN 1 WHEN "loyalty_score" > 0.2 THEN 0 ELSE 1 END AS "churn"
  FROM "customer_loyalty"
), "customer_churn_rate" AS (
  SELECT
    "order_month",
    COUNT(DISTINCT "customer_id") AS "total_customers",
    SUM("churn") AS "churned_customers",
    (
      SUM("churn") / CAST(COUNT(DISTINCT "customer_id") AS REAL)
    ) * 100 AS "churn_rate"
  FROM "customer_churn"
  GROUP BY
    "order_month"
)
SELECT
  TO_CHAR("order_month", 'YYYY-MM') AS "month",
  "total_customers",
  "churned_customers",
  "churn_rate"
FROM "customer_churn_rate"
WHERE
  "order_month" BETWEEN '2022-01-01' AND '2022-05-31'