# CST8911 Midterm Project — Scenario 2: Online Bookstore

| Member | Name | Responsibility |
| :--- | :--- | :--- |
| Person 1 | Hussein Dawod | Created the Azure resource group, storage account, Data Factory instance, SQL server, and database; configured initial access settings |
| Person 2 | Dapeng (David) Han | Prepared bookstore datasets; designed the Azure SQL schema; wrote T-SQL scripts and analytical views |
| Person 3 | Xiaoting (Ellie) Zheng | Built and tested Data Factory pipelines and data mappings; loaded the datasets into Azure SQL; created the Power BI dashboard |

This project demonstrates a data workflow from **Azure Blob Storage → Azure Data Factory → Azure SQL Database → Power BI** using an online bookstore dataset.

## Team contributions

### Person 1 — Azure Resources and Infrastructure

- Created and configured the resource group, Azure Blob Storage, Azure Data Factory, Azure SQL Server, and Azure SQL Database.
- Managed resource access and connectivity settings needed for the data workflow, including permissions, storage access, and SQL networking.

### Person 2 — Datasets and SQL

- Prepared seven bookstore datasets: authors, books, customers, orders, order lines, publishers, and reviews.
- Created the related tables in Azure SQL Database and wrote the T-SQL scripts in `SQL Scripts/`.
- Created SQL views for monthly delivered book sales, sales by customer state, and customer purchasing behavior.

### Person 3 — Azure Data Factory and Power BI**

- Configured Azure Data Factory datasets, connections, field mappings, and copy pipelines to load the CSV files from Blob Storage into the SQL tables.
- Ran and verified the data loads, including resolving a mapping issue with the SQL computed column `line_total`.
- Connected Power BI Desktop to Azure SQL Database and created `OnlineBookstore_Dashboard.pbix` with four visuals: monthly sales, sales by state, customers by city, and top customers by book sales.

## Repository files

- `Datasets/` — source CSV files
- `SQL Scripts/` — table creation and analytical view scripts
- `Azure Data Factory/` — exported ARM template and parameters
- `Power BI/` — Power BI Desktop dashboard file

**Sales definition:** Sales visuals use merchandise totals from delivered orders; shipping fees are excluded. Screenshots of the Azure settings, Data Factory pipeline runs, SQL results, and Power BI dashboard, with brief explanations of key decisions, will be included in the final report submitted through Brightspace.

## Acknowledgement of AI Use

Given our small group size and limited time, our team used OpenAI ChatGPT to help plan a fair division of work, organize and draft parts of the documentation, and troubleshoot technical issues. Team members completed the project work, reviewed the AI-assisted content, and are responsible for the accuracy of the final submission.
