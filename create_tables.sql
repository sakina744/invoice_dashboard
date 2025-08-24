
 CREATE TABLE customers ( customer_id INT AUTO_INCREMENT PRIMARY KEY,  name VARCHAR(100) NOT NULL);

CREATE TABLE invoices (
  invoice_id SERIAL PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES customers(customer_id),
  invoice_date DATE NOT NULL,
  due_date DATE NOT NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0)
);

CREATE TABLE payments (
  payment_id SERIAL PRIMARY KEY,
  invoice_id INT NOT NULL REFERENCES invoices(invoice_id),
  payment_date DATE NOT NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0)
);

INSERT INTO customers (name) VALUES ('Alice'), ('Bob'), ('Charlie'), ('Eve'),('David');

INSERT INTO invoices (customer_id, invoice_date, due_date, amount)
VALUES 
(1, '2025-08-01', '2025-08-15', 1000),
(2, '2024-04-30', '2024-06-15', 1200),
(3, '2025-08-10', '2025-08-25', 800),
(4, '2025-01-12', '2025-07-16', 900),
(5, '2025-03-30', '2025-05-30', 1900);

INSERT INTO payments (invoice_id, payment_date, amount)
VALUES 
(1, '2025-08-12', 550),
(2, '2025-08-18', 650),
(3, '2025-08-12', 100),
(4, '2025-08-18', 400),
(5, '2025-08-12', 1000);