/*
CST8911 Scenario 2 - Azure SQL Database bookstore schema
Source: https://databasesample.com/datasets/online-bookstore-orders-and-reviews-dataset
Adapted from the supplied MSSQL v1 script (synthetic data, CC0-1.0).

Run this entire file in your empty PROJECT database, not master.
It creates seven empty tables; Data Factory loads the CSV records later.
It does not delete or replace existing tables and will stop if a target exists.

Design and Data Factory mapping notes:
  * IDs are INT primary keys, without IDENTITY: map CSV id -> SQL id.
  * Map remaining columns by name, with these THREE exceptions:
      order_lines.csv: do NOT map line_total (a SQL computed column).
      order_lines.csv: do NOT map ordered_at (obtain from orders.placed_at).
      reviews.csv:     do NOT map book_id (obtain through order_lines).
  * Keep unit_price on each order line as the historical price at purchase.
  * Enable "First row as header" in each DelimitedText source dataset.
  * Load authors, publishers, customers first (they may run in parallel).
    Then books and orders; then order_lines; finally reviews.
  * Column relationships and validation checks are enforced in SQL.
  * SQL views and analysis queries are a later step.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() IN (N'master', N'model', N'msdb', N'tempdb')
    THROW 50001, 'Connect to your bookstore project database before running this file.', 1;

IF @@TRANCOUNT <> 0
    THROW 50002, 'An earlier transaction is still open. Finish it before running this file.', 1;

IF EXISTS (
    SELECT 1
    FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    WHERE s.name = N'dbo'
      AND t.name IN (N'authors', N'publishers', N'customers', N'books',
                     N'orders', N'order_lines', N'reviews')
)
    THROW 50003, 'A bookstore table already exists. This file only creates a new schema; it does not replace tables.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    CREATE TABLE dbo.authors (
        [id] int NOT NULL CONSTRAINT PK_authors PRIMARY KEY,
        [first_name] nvarchar(30) NOT NULL,
        [last_name] nvarchar(44) NOT NULL,
        [country] nvarchar(14) NOT NULL,
        [debut_year] int NOT NULL
    );

    CREATE TABLE dbo.publishers (
        [id] int NOT NULL CONSTRAINT PK_publishers PRIMARY KEY,
        [name] nvarchar(20) NOT NULL,
        [country] nvarchar(14) NOT NULL,
        [founded_year] int NOT NULL,
        CONSTRAINT UQ_publishers_name UNIQUE ([name])
    );

    CREATE TABLE dbo.customers (
        [id] int NOT NULL CONSTRAINT PK_customers PRIMARY KEY,
        [first_name] nvarchar(30) NOT NULL,
        [last_name] nvarchar(44) NOT NULL,
        [email] nvarchar(77) NOT NULL,
        [city] nvarchar(40) NOT NULL,
        [state] nvarchar(3) NOT NULL,
        [registered_on] date NOT NULL,
        CONSTRAINT UQ_customers_email UNIQUE ([email])
    );

    CREATE TABLE dbo.books (
        [id] int NOT NULL CONSTRAINT PK_books PRIMARY KEY,
        [title] nvarchar(120) NOT NULL,
        [isbn] nvarchar(26) NOT NULL,
        [author_id] int NOT NULL,
        [publisher_id] int NOT NULL,
        [genre] nvarchar(15) NOT NULL,
        [format] nvarchar(9) NOT NULL,
        [pages] int NOT NULL,
        [list_price] decimal(14,2) NOT NULL,
        [published_on] date NOT NULL,
        CONSTRAINT UQ_books_title UNIQUE ([title]),
        CONSTRAINT UQ_books_isbn UNIQUE ([isbn]),
        CONSTRAINT FK_books_author FOREIGN KEY ([author_id]) REFERENCES dbo.authors ([id]),
        CONSTRAINT FK_books_publisher FOREIGN KEY ([publisher_id]) REFERENCES dbo.publishers ([id]),
        CONSTRAINT CK_books_pages CHECK ([pages] > 0),
        CONSTRAINT CK_books_list_price CHECK ([list_price] >= 0)
    );

    CREATE TABLE dbo.orders (
        [id] int NOT NULL CONSTRAINT PK_orders PRIMARY KEY,
        [customer_id] int NOT NULL,
        [placed_at] datetime2 NOT NULL,
        [payment_method] nvarchar(13) NOT NULL,
        [status] nvarchar(9) NOT NULL,
        [shipped_at] datetime2 NOT NULL,
        [shipping_fee] decimal(14,2) NOT NULL,
        CONSTRAINT FK_orders_customer FOREIGN KEY ([customer_id]) REFERENCES dbo.customers ([id]),
        CONSTRAINT CK_orders_status CHECK ([status] IN (N'delivered', N'returned')),
        CONSTRAINT CK_orders_shipping_fee CHECK ([shipping_fee] >= 0),
        CONSTRAINT CK_orders_shipped_at CHECK ([shipped_at] >= [placed_at])
    );

    CREATE TABLE dbo.order_lines (
        [id] int NOT NULL CONSTRAINT PK_order_lines PRIMARY KEY,
        [order_id] int NOT NULL,
        [book_id] int NOT NULL,
        [quantity] int NOT NULL,
        [unit_price] decimal(14,2) NOT NULL,
        [line_total] AS ([quantity] * [unit_price]),
        CONSTRAINT FK_order_lines_order FOREIGN KEY ([order_id]) REFERENCES dbo.orders ([id]),
        CONSTRAINT FK_order_lines_book FOREIGN KEY ([book_id]) REFERENCES dbo.books ([id]),
        CONSTRAINT CK_order_lines_quantity CHECK ([quantity] > 0),
        CONSTRAINT CK_order_lines_unit_price CHECK ([unit_price] >= 0)
    );

    CREATE TABLE dbo.reviews (
        [id] int NOT NULL CONSTRAINT PK_reviews PRIMARY KEY,
        [order_line_id] int NOT NULL,
        [rating] int NOT NULL,
        [helpful_votes] int NOT NULL,
        [reviewed_at] datetime2 NOT NULL,
        CONSTRAINT UQ_reviews_order_line UNIQUE ([order_line_id]),
        CONSTRAINT FK_reviews_order_line FOREIGN KEY ([order_line_id]) REFERENCES dbo.order_lines ([id]),
        CONSTRAINT CK_reviews_rating CHECK ([rating] BETWEEN 1 AND 5),
        CONSTRAINT CK_reviews_helpful_votes CHECK ([helpful_votes] >= 0)
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- Verification only: all seven counts should initially be zero.
SELECT N'authors' AS [TableName], COUNT_BIG(*) AS [RowCount] FROM dbo.authors
UNION ALL SELECT N'publishers', COUNT_BIG(*) FROM dbo.publishers
UNION ALL SELECT N'customers', COUNT_BIG(*) FROM dbo.customers
UNION ALL SELECT N'books', COUNT_BIG(*) FROM dbo.books
UNION ALL SELECT N'orders', COUNT_BIG(*) FROM dbo.orders
UNION ALL SELECT N'order_lines', COUNT_BIG(*) FROM dbo.order_lines
UNION ALL SELECT N'reviews', COUNT_BIG(*) FROM dbo.reviews;
