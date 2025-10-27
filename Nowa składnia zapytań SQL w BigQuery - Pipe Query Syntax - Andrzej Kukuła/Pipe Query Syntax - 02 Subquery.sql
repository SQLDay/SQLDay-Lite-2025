# Numbers of customers that placed most orders

SELECT num_orders, COUNT(*) AS num_customers
FROM
  (
    SELECT c_custkey, COUNT(o_orderkey) AS num_orders
    FROM tpch.customer
    LEFT JOIN tpch.orders ON c_custkey = o_custkey
    GROUP BY c_custkey
  ) AS num_orders_by_customer
GROUP BY num_orders
ORDER BY num_orders DESC
LIMIT 10;



# The same using Pipe Query Syntax
FROM tpch.customer
|> LEFT JOIN tpch.orders ON c_custkey = o_custkey
|> AGGREGATE COUNT(o_orderkey) AS num_orders
   GROUP BY c_custkey
|> AGGREGATE COUNT(*) AS num_customers
   GROUP AND ORDER BY num_orders DESC
|> LIMIT 10
;
