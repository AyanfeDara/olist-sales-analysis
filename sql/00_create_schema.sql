-- =====================================================================
-- 00_create_schema.sql
-- Creates the Olist e-commerce database tables.
-- Run once, connected to the "olist" database.
-- Safe to re-run: it drops and rebuilds every table.
-- =====================================================================

SET client_min_messages = warning;   -- hides "table does not exist" notices on the first run

DROP TABLE IF EXISTS order_reviews, order_payments, order_items, orders,
                     products, sellers, customers, geolocation,
                     category_translation CASCADE;

-- One row per customer account used for an order.
-- customer_unique_id identifies the real person across orders.
CREATE TABLE customers (
    customer_id              TEXT PRIMARY KEY,
    customer_unique_id       TEXT NOT NULL,
    customer_zip_code_prefix TEXT,          -- text keeps leading zeros
    customer_city            TEXT,
    customer_state           CHAR(2)
);

-- Zip prefix to coordinates. Zips repeat, so there is no primary key.
CREATE TABLE geolocation (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat             DOUBLE PRECISION,
    geolocation_lng             DOUBLE PRECISION,
    geolocation_city            TEXT,
    geolocation_state           CHAR(2)
);

CREATE TABLE sellers (
    seller_id              TEXT PRIMARY KEY,
    seller_zip_code_prefix TEXT,
    seller_city            TEXT,
    seller_state           CHAR(2)
);

-- Portuguese category name to English.
CREATE TABLE category_translation (
    product_category_name         TEXT PRIMARY KEY,
    product_category_name_english TEXT NOT NULL
);

-- The source file spells "length" as "lenght"; the column names here are corrected.
CREATE TABLE products (
    product_id                 TEXT PRIMARY KEY,
    product_category_name      TEXT,
    product_name_length        INTEGER,
    product_description_length INTEGER,
    product_photos_qty         INTEGER,
    product_weight_g           INTEGER,
    product_length_cm          INTEGER,
    product_height_cm          INTEGER,
    product_width_cm           INTEGER
);

-- The core table: one row per order.
CREATE TABLE orders (
    order_id                      TEXT PRIMARY KEY,
    customer_id                   TEXT NOT NULL REFERENCES customers (customer_id),
    order_status                  TEXT NOT NULL,
    order_purchase_timestamp      TIMESTAMP NOT NULL,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- One row per item in an order (an order with 3 items has 3 rows).
CREATE TABLE order_items (
    order_id            TEXT    NOT NULL REFERENCES orders (order_id),
    order_item_id       INTEGER NOT NULL,
    product_id          TEXT    NOT NULL REFERENCES products (product_id),
    seller_id           TEXT    NOT NULL REFERENCES sellers (seller_id),
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(10, 2) NOT NULL,
    freight_value       NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

-- One row per payment; an order can be paid in several parts.
CREATE TABLE order_payments (
    order_id             TEXT    NOT NULL REFERENCES orders (order_id),
    payment_sequential   INTEGER NOT NULL,
    payment_type         TEXT,
    payment_installments INTEGER,
    payment_value        NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

-- review_id alone is not unique in the source data, so the key is (review_id, order_id).
CREATE TABLE order_reviews (
    review_id               TEXT NOT NULL,
    order_id                TEXT NOT NULL REFERENCES orders (order_id),
    review_score            SMALLINT CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    PRIMARY KEY (review_id, order_id)
);

-- Indexes for the joins used most often.
CREATE INDEX idx_orders_customer   ON orders (customer_id);
CREATE INDEX idx_items_product     ON order_items (product_id);
CREATE INDEX idx_items_seller      ON order_items (seller_id);
CREATE INDEX idx_reviews_order     ON order_reviews (order_id);
CREATE INDEX idx_customers_unique  ON customers (customer_unique_id);
CREATE INDEX idx_geo_zip           ON geolocation (geolocation_zip_code_prefix);
