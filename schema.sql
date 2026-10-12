-- Sales Analytics and Employee Performance System (MySQL 8.0+)
DROP DATABASE IF EXISTS sales_analytics;
CREATE DATABASE sales_analytics CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sales_analytics;

CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_name     VARCHAR(50)  NOT NULL UNIQUE,
    location      VARCHAR(50)  NOT NULL
) ENGINE=InnoDB;

CREATE TABLE employees (
    employee_id   INT AUTO_INCREMENT PRIMARY KEY,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(15),
    hire_date     DATE         NOT NULL,
    job_title     VARCHAR(50)  NOT NULL,
    department_id INT          NOT NULL,
    manager_id    INT          NULL,
    salary        DECIMAL(10,2) NOT NULL,
    region        ENUM('North','South','East','West','Central') NOT NULL,
    status        ENUM('Active','On Leave','Resigned') NOT NULL DEFAULT 'Active',
    CONSTRAINT chk_emp_salary CHECK (salary > 0),
    CONSTRAINT chk_emp_email  CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) REFERENCES departments(department_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_emp_mgr  FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_emp_dept (department_id),
    INDEX idx_emp_mgr (manager_id)
) ENGINE=InnoDB;

CREATE TABLE customers (
    customer_id   INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    city          VARCHAR(50)  NOT NULL,
    state         VARCHAR(50)  NOT NULL,
    segment       ENUM('Retail','Corporate','Small Business') NOT NULL DEFAULT 'Retail',
    created_at    DATE         NOT NULL,
    INDEX idx_cust_city (city)
) ENGINE=InnoDB;

CREATE TABLE products (
    product_id    INT AUTO_INCREMENT PRIMARY KEY,
    product_name  VARCHAR(100) NOT NULL,
    category      VARCHAR(50)  NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    cost_price    DECIMAL(10,2) NOT NULL,
    stock_qty     INT NOT NULL DEFAULT 0,
    CONSTRAINT chk_prod_price CHECK (unit_price > 0),
    CONSTRAINT chk_prod_cost  CHECK (cost_price >= 0 AND cost_price <= unit_price),
    CONSTRAINT chk_prod_stock CHECK (stock_qty >= 0),
    INDEX idx_prod_cat (category)
) ENGINE=InnoDB;

CREATE TABLE orders (
    order_id       INT AUTO_INCREMENT PRIMARY KEY,
    customer_id    INT NOT NULL,
    employee_id    INT NOT NULL,                 -- sales rep who closed the order
    order_date     DATETIME NOT NULL,
    status         ENUM('Pending','Shipped','Delivered','Cancelled','Returned') NOT NULL DEFAULT 'Pending',
    payment_method ENUM('Card','UPI','Cash','NetBanking') NOT NULL,
    discount_pct   DECIMAL(5,2) NOT NULL DEFAULT 0,
    CONSTRAINT chk_ord_disc CHECK (discount_pct BETWEEN 0 AND 100),
    CONSTRAINT fk_ord_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ord_emp  FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_ord_date (order_date),
    INDEX idx_ord_cust (customer_id),
    INDEX idx_ord_emp_date (employee_id, order_date)
) ENGINE=InnoDB;

CREATE TABLE order_items (
    item_id    INT AUTO_INCREMENT PRIMARY KEY,
    order_id   INT NOT NULL,
    product_id INT NOT NULL,
    quantity   INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,           -- price at time of sale
    CONSTRAINT chk_item_qty   CHECK (quantity > 0),
    CONSTRAINT chk_item_price CHECK (unit_price > 0),
    CONSTRAINT uq_order_product UNIQUE (order_id, product_id),
    CONSTRAINT fk_item_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_item_prod  FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_item_prod (product_id)
) ENGINE=InnoDB;

CREATE TABLE sales_targets (
    target_id     INT AUTO_INCREMENT PRIMARY KEY,
    employee_id   INT NOT NULL,
    target_year   SMALLINT NOT NULL,
    target_month  TINYINT  NOT NULL,
    target_amount DECIMAL(12,2) NOT NULL,
    CONSTRAINT chk_tgt_month  CHECK (target_month BETWEEN 1 AND 12),
    CONSTRAINT chk_tgt_amount CHECK (target_amount > 0),
    CONSTRAINT uq_tgt UNIQUE (employee_id, target_year, target_month),
    CONSTRAINT fk_tgt_emp FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE performance_reviews (
    review_id      INT AUTO_INCREMENT PRIMARY KEY,
    employee_id    INT NOT NULL,
    reviewer_id    INT NOT NULL,
    review_year    SMALLINT NOT NULL,
    review_quarter TINYINT  NOT NULL,
    rating         TINYINT  NOT NULL,
    kpi_score      DECIMAL(5,2) NOT NULL,
    comments       VARCHAR(255),
    CONSTRAINT chk_rev_quarter CHECK (review_quarter BETWEEN 1 AND 4),
    CONSTRAINT chk_rev_rating  CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT chk_rev_kpi     CHECK (kpi_score BETWEEN 0 AND 100),
    CONSTRAINT chk_rev_self    CHECK (employee_id <> reviewer_id),
    CONSTRAINT uq_review UNIQUE (employee_id, review_year, review_quarter),
    CONSTRAINT fk_rev_emp  FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        on delete restrict,
    CONSTRAINT fk_rev_rvwr FOREIGN KEY (reviewer_id) REFERENCES employees(employee_id)
        on  DELETE RESTRICT
) ENGINE=InnoDB;

