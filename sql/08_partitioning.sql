CREATE SCHEMA IF NOT EXISTS blinkit_partition_test;
SET search_path TO blinkit_partition_test, blinkit, public;

DROP TABLE IF EXISTS order_items_partitioned CASCADE;

CREATE TABLE order_items_partitioned (
    order_id                INT NOT NULL,
    product_id              INT NOT NULL,
    quantity_ordered        INT NOT NULL,
    quantity_delivered      INT NOT NULL,
    unit_price              NUMERIC(10,2) NOT NULL,
    substitute_product_id   INT,
    PRIMARY KEY (order_id, product_id),
    CONSTRAINT chk_order_items_qty_ordered CHECK (quantity_ordered > 0),
    CONSTRAINT chk_order_items_qty_delivered CHECK (
        quantity_delivered >= 0 AND quantity_delivered <= quantity_ordered
    ),
    CONSTRAINT chk_order_items_unit_price CHECK (unit_price >= 0),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
        REFERENCES blinkit.orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id)
        REFERENCES blinkit.products(product_id) ON DELETE RESTRICT,
    CONSTRAINT fk_order_items_substitute FOREIGN KEY (substitute_product_id)
        REFERENCES blinkit.products(product_id) ON DELETE SET NULL
) PARTITION BY HASH (order_id);

CREATE TABLE order_items_p0 PARTITION OF order_items_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE order_items_p1 PARTITION OF order_items_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE order_items_p2 PARTITION OF order_items_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE order_items_p3 PARTITION OF order_items_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 3);

CREATE INDEX idx_order_items_part_product_order
    ON order_items_partitioned (product_id, order_id);

CREATE INDEX idx_order_items_part_substitute
    ON order_items_partitioned (substitute_product_id, order_id)
    WHERE substitute_product_id IS NOT NULL;

INSERT INTO order_items_partitioned
SELECT * FROM blinkit.order_items;

ANALYZE order_items_partitioned;

SELECT 
    'blinkit.order_items' AS source_table, count(*) AS row_count FROM blinkit.order_items
UNION ALL
SELECT 
    'order_items_partitioned' AS source_table, count(*) FROM order_items_partitioned;

SELECT 
    tableoid::regclass AS partition_name, 
    count(*) AS rows_in_partition
FROM order_items_partitioned
GROUP BY tableoid
ORDER BY partition_name;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM order_items_partitioned WHERE order_id = 100;
