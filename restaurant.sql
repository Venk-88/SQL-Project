-- Restaurant Database


PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS OrderDetails;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Menu;
DROP TABLE IF EXISTS Customers;

PRAGMA foreign_keys = ON;

--  Create Tables


CREATE TABLE Customers (
    id INTEGER PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    gender TEXT CHECK(gender IN ('Male','Female','Other')),
    membership TEXT CHECK(membership IN ('Bronze','Silver','Gold','Platinum')),
    dob DATE,
    registration DATE
);

CREATE TABLE Menu (
    id INTEGER PRIMARY KEY,
    name TEXT,
    category TEXT CHECK(category IN ('Starter','Main','Dessert','Drink')),
    price REAL,
    calories REAL,
    spice_level INTEGER CHECK(spice_level BETWEEN 0 AND 5)
);

CREATE TABLE Orders (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    order_date DATE,
    total REAL,
    payment TEXT CHECK(payment IN ('Cash','Card','Online')),
    FOREIGN KEY(customer_id) REFERENCES Customers(id)
);

CREATE TABLE OrderDetails (
    order_id INTEGER,
    menu_id INTEGER,
    quantity INTEGER,
    PRIMARY KEY(order_id, menu_id),
    FOREIGN KEY(order_id) REFERENCES Orders(id),
    FOREIGN KEY(menu_id) REFERENCES Menu(id)
);


--  Customers (1000 realistic entries)

WITH RECURSIVE counter(x) AS (
    SELECT 1
    UNION ALL
    SELECT x + 1 FROM counter WHERE x < 1000
)
INSERT INTO Customers(first_name, last_name, gender, membership, dob, registration)
SELECT
    'Customer_' || x,
    'Surname_' || x,
    CASE ABS(RANDOM() % 3)
        WHEN 0 THEN 'Male'
        WHEN 1 THEN 'Female'
        ELSE 'Other'
    END,
    CASE ABS(RANDOM() % 4)
        WHEN 0 THEN 'Bronze'
        WHEN 1 THEN 'Silver'
        WHEN 2 THEN 'Gold'
        ELSE 'Platinum'
    END,
    DATE('1970-01-01', '+' || ABS(RANDOM() % 18000) || ' days'),
    DATE('2020-01-01', '+' || ABS(RANDOM() % 1000) || ' days')
FROM counter;


--  Menu (50 items, realistic names and categories)

WITH RECURSIVE counter(x) AS (
    SELECT 1
    UNION ALL
    SELECT x + 1 FROM counter WHERE x < 50
)
INSERT INTO Menu(name, category, price, calories, spice_level)
SELECT
    CASE ABS(RANDOM() % 10)
        WHEN 0 THEN 'Caesar Salad'
        WHEN 1 THEN 'Bruschetta'
        WHEN 2 THEN 'Garlic Bread'
        WHEN 3 THEN 'Tomato Soup'
        WHEN 4 THEN 'Stuffed Mushrooms'
        WHEN 5 THEN 'Margherita Pizza'
        WHEN 6 THEN 'Pepperoni Pizza'
        WHEN 7 THEN 'Veggie Pizza'
        WHEN 8 THEN 'BBQ Chicken Pizza'
        ELSE 'Hawaiian Pizza'
    END || ' #' || x,
    CASE
        WHEN x <= 10 THEN 'Starter'
        WHEN x <= 30 THEN 'Main'
        WHEN x <= 40 THEN 'Dessert'
        ELSE 'Drink'
    END,
    ROUND(5 + (ABS(RANDOM()) % 1500)/100.0,2),
    ROUND(100 + (ABS(RANDOM()) % 800),0),
    ABS(RANDOM() % 6)
FROM counter;


--  Orders (1000 orders with realistic spread)

WITH RECURSIVE counter(x) AS (
    SELECT 1
    UNION ALL
    SELECT x + 1 FROM counter WHERE x < 1000
)
INSERT INTO Orders(customer_id, order_date, total, payment)
SELECT
    ABS(RANDOM() % 1000) + 1,  -- random customer
    DATE('2023-01-01', '+' || ABS(RANDOM() % 365) || ' days'),
    0,  -- temporary, will be calculated after adding order details
    CASE ABS(RANDOM() % 3)
        WHEN 0 THEN 'Cash'
        WHEN 1 THEN 'Card'
        ELSE 'Online'
    END
FROM counter;


--  OrderDetails (2000 items, humanized)

WITH order_list AS (
    SELECT id AS order_id FROM Orders
),
menu_list AS (
    SELECT id, category, price FROM Menu
),
comb AS (
    SELECT o.order_id, m.id AS menu_id, m.category, m.price
    FROM order_list o
    JOIN menu_list m
),
selected AS (
    SELECT * FROM comb ORDER BY RANDOM() LIMIT 2000
)
INSERT INTO OrderDetails(order_id, menu_id, quantity)
SELECT
    order_id,
    menu_id,
    CASE 
        WHEN category = 'Drink' THEN 1   -- usually 1 drink
        ELSE ABS(RANDOM() % 2) + 1      -- 1-2 for other items
    END
FROM selected;

-- Update Orders total based on OrderDetails

UPDATE Orders
SET total = (
    SELECT ROUND(SUM(Menu.price * od.quantity), 2)
    FROM OrderDetails od
    JOIN Menu ON od.menu_id = Menu.id
    WHERE od.order_id = Orders.id
);

