?-- ============================================================================
-- 1. ANÁLISE INICIAL - VERIFICAÇÃO DE QUALIDADE DOS DADOS
-- ============================================================================

-- 1.1 Verificar valores nulos em tabelas críticas
SELECT 
    'olist_orders' AS tabela,
    COUNT(*) AS total_registros,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS order_id_nulos,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS customer_id_nulos,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS status_nulos,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS data_compra_nulos,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS data_entrega_nulos
FROM dbo.olist_orders_dataset;

-- 1.2 Verificar duplicatas na tabela de pedidos
SELECT 
    order_id,
    COUNT(*) AS ocorrencias
FROM dbo.olist_orders_dataset
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 1.3 Verificar range de datas
SELECT 
    MIN(order_purchase_timestamp) AS primeira_compra,
    MAX(order_purchase_timestamp) AS ultima_compra,
    DATEDIFF(DAY, MIN(order_purchase_timestamp), MAX(order_purchase_timestamp)) AS dias_cobertura
FROM dbo.olist_orders_dataset;


-- ============================================================================
-- 2. LIMPEZA DA TABELA DE PEDIDOS (olist_orders)
-- ============================================================================

-- 2.1 Criar tabela limpa de pedidos com colunas calculadas
DROP TABLE IF EXISTS orders_clean;

SELECT 
    order_id,
    customer_id,
    order_status,
    
    -- Datas originais
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    
    -- Colunas calculadas para análise temporal
    CAST(order_purchase_timestamp AS DATE) AS data_pedido,
    YEAR(order_purchase_timestamp) AS ano,
    MONTH(order_purchase_timestamp) AS mes,
    DATENAME(WEEKDAY, order_purchase_timestamp) AS dia_semana,
    DATEPART(HOUR, order_purchase_timestamp) AS hora_pedido,
    
    -- Cálculo de dias de entrega (apenas para pedidos entregues)
    CASE 
        WHEN order_delivered_customer_date IS NOT NULL 
             AND order_purchase_timestamp IS NOT NULL
        THEN DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)
        ELSE NULL 
    END AS dias_entrega,
    
    -- Flag de atraso na entrega
    CASE 
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
        ELSE 0
    END AS flag_atraso,
    
    -- Dias de atraso (se houver)
    CASE 
        WHEN order_delivered_customer_date > order_estimated_delivery_date 
        THEN DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date)
        ELSE 0
    END AS dias_atraso
    
INTO orders_clean
FROM dbo.olist_orders_dataset
WHERE order_id IS NOT NULL
  AND customer_id IS NOT NULL;


-- ============================================================================
-- 3. LIMPEZA DA TABELA DE ITENS (olist_order_items)
-- ============================================================================

-- 3.1 Verificar valores negativos ou zerados
SELECT 
    COUNT(*) AS total_itens,
    SUM(CASE WHEN price <= 0 THEN 1 ELSE 0 END) AS preco_invalido,
    SUM(CASE WHEN freight_value < 0 THEN 1 ELSE 0 END) AS frete_negativo
FROM dbo.olist_order_items_dataset;

-- 3.2 Criar tabela limpa de itens
DROP TABLE IF EXISTS order_items_clean;

SELECT 
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    
    -- Valores monetários tratados
    ISNULL(price, 0) AS price,
    ISNULL(freight_value, 0) AS freight_value,
    
    -- Valor total do item
    ISNULL(price, 0) + ISNULL(freight_value, 0) AS valor_total_item
    
INTO order_items_clean
FROM dbo.olist_order_items_dataset
WHERE order_id IS NOT NULL
  AND product_id IS NOT NULL
  AND price > 0;


-- ============================================================================
-- 4. LIMPEZA DA TABELA DE CLIENTES (olist_customers)
-- ============================================================================

-- 4.1 Padronizar dados geográficos
DROP TABLE IF EXISTS customers_clean;

SELECT 
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    
    -- Padronização: cidade em maiúsculas e sem espaços extras
    UPPER(LTRIM(RTRIM(customer_city))) AS customer_city,
    
    -- Estado já está padronizado (sigla)
    customer_state,
    
    -- Coluna auxiliar para evitar ambiguidade no Power BI
    -- (estados como MA, PA, MT existem em outros países)
    CONCAT(UPPER(LTRIM(RTRIM(customer_city))), ' - ', customer_state) AS cidade_estado
    
INTO customers_clean
FROM dbo.olist_customers_dataset
WHERE customer_id IS NOT NULL;


-- ============================================================================
-- 5. LIMPEZA DA TABELA DE AVALIAÇÕES (olist_order_reviews)
-- ============================================================================

-- 5.1 Verificar distribuição de scores
SELECT 
    review_score,
    COUNT(*) AS quantidade,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS percentual
FROM dbo.olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score;

-- 5.2 Criar tabela limpa de avaliações
DROP TABLE IF EXISTS reviews_clean;

SELECT 
    review_id,
    order_id,
    review_score,
    
    -- Classificação textual do score
    CASE 
        WHEN review_score >= 4 THEN 'Positiva'
        WHEN review_score = 3 THEN 'Neutra'
        ELSE 'Negativa'
    END AS classificacao_review,
    
    -- Flag binário para análise
    CASE WHEN review_score >= 4 THEN 1 ELSE 0 END AS flag_positivo,
    
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
    
INTO reviews_clean
FROM dbo.olist_order_reviews_dataset
WHERE review_id IS NOT NULL
  AND order_id IS NOT NULL
  AND review_score BETWEEN 1 AND 5;


-- ============================================================================
-- 6. LIMPEZA DA TABELA DE PRODUTOS (olist_products)
-- ============================================================================

-- 6.1 Verificar categorias com valores nulos
SELECT 
    COUNT(*) AS total_produtos,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS sem_categoria
FROM dbo.olist_products_dataset;

-- 6.2 Criar tabela limpa de produtos
DROP TABLE IF EXISTS products_clean;

SELECT 
    product_id,
    
    -- Tratar categoria nula
    ISNULL(product_category_name, 'sem_categoria') AS product_category_name,
    
    -- Dimensões do produto
    ISNULL(product_name_lenght, 0) AS product_name_lenght,
    ISNULL(product_description_lenght, 0) AS product_description_lenght,
    ISNULL(product_photos_qty, 0) AS product_photos_qty,
    ISNULL(product_weight_g, 0) AS product_weight_g,
    ISNULL(product_length_cm, 0) AS product_length_cm,
    ISNULL(product_height_cm, 0) AS product_height_cm,
    ISNULL(product_width_cm, 0) AS product_width_cm,
    
    -- Volume calculado (cm³)
    ISNULL(product_length_cm, 0) * 
    ISNULL(product_height_cm, 0) * 
    ISNULL(product_width_cm, 0) AS volume_cm3
    
INTO products_clean
FROM dbo.olist_products_dataset
WHERE product_id IS NOT NULL;


-- ============================================================================
-- 7. LIMPEZA DA TABELA DE PAGAMENTOS (olist_order_payments)
-- ============================================================================

DROP TABLE IF EXISTS payments_clean;

SELECT 
    order_id,
    payment_sequential,
    payment_type,
    
    -- Tradução do tipo de pagamento para português
    CASE payment_type
        WHEN 'credit_card' THEN 'Cartão de Crédito'
        WHEN 'boleto' THEN 'Boleto'
        WHEN 'voucher' THEN 'Voucher'
        WHEN 'debit_card' THEN 'Cartão de Débito'
        ELSE 'Outros'
    END AS tipo_pagamento_pt,
    
    payment_installments,
    ISNULL(payment_value, 0) AS payment_value
    
INTO payments_clean
FROM dbo.olist_order_payments_dataset
WHERE order_id IS NOT NULL
  AND payment_value > 0;


-- ============================================================================
-- 8. VALIDAÇÃO FINAL - CONTAGEM DE REGISTROS
-- ============================================================================

SELECT 'orders_clean' AS tabela, COUNT(*) AS registros FROM orders_clean
UNION ALL
SELECT 'order_items_clean', COUNT(*) FROM order_items_clean
UNION ALL
SELECT 'customers_clean', COUNT(*) FROM customers_clean
UNION ALL
SELECT 'reviews_clean', COUNT(*) FROM reviews_clean
UNION ALL
SELECT 'products_clean', COUNT(*) FROM products_clean
UNION ALL
SELECT 'payments_clean', COUNT(*) FROM payments_clean;


/*
===============================================================================
?? NOTAS:
- Este script deve ser executado antes da criação das views de dimensão e fato
- As tabelas _clean são intermediárias para facilitar a modelagem Star Schema
- Valores nulos foram tratados com ISNULL() para evitar erros em cálculos
- Colunas calculadas (dias_entrega, flag_atraso) otimizam queries no Power BI
===============================================================================
*/