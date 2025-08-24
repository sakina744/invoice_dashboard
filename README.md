# Shiny Invoice Dashboard (R + MySQL)

Single-file Shiny app (`app.R`) to manage **customers, invoices, and payments** using a MySQL backend.

---

## Features

- **Filters:** Customer dropdown and invoice date range  
- **KPI Tiles:** Total Invoiced, Total Received, Outstanding, % Overdue  
- **Invoice Table:** Search, sort and view invoices; overdue rows highlighted  
- **Record Payment:** Modal/form to add partial or full payments (updates KPIs and table)  
- **Charts:** Bar chart for top customers by outstanding and pie chart for aging buckets

---

## Project Files

- `app.R` — single-file Shiny app (connects to MySQL)  
- `create_tables.sql` —  SQL script to create the database/tables (if you prefer CLI)  
- `README.md` — this file  
- `screenshots/` — screenshot images used in README

---

## Setup & Run

1. Install required R packages:

```r
install.packages(c("shiny", "DBI", "RMySQL", "DT", "ggplot2"))
```
2. Configure DB credentials in app.R 

```r
con <- dbConnect(
  RMySQL::MySQL(),
  dbname = "invoice_db",
  host   = "localhost",
  user   = "root",
  password = ""
)
```
3. Tables will be created automatically on first run of create_tables.sql.

4. Run the app

```r
library(shiny)
shiny::runApp("app.R")
```

5. Screenshots

- **Dashboard + KPI tiles** → save as dashboard.png

- **Invoice table with overdue rows** → save as invoice_table.png

- **Record payment modal** → save as record_payment.png


- **Chart** → save as chart.png

  6. Github Link
     https://github.com/sakina744/invoice_dashboard
