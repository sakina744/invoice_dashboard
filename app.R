library(shiny)
library(DBI)
library(RMySQL)
library(dplyr)
library(DT)
library(plotly)
library(lubridate)

# --- Database connection ---
con <- dbConnect(
  RMySQL::MySQL(),
  dbname = "invoice_db",
  host = "localhost",
  user = "root",
  password = ""
)

# --- Utility function ---
compute_aging_bucket <- function(due_date, today = Sys.Date()) {
  days <- as.numeric(today - due_date)
  if (days <= 0) return("Current")
  else if (days <= 30) return("0-30")
  else if (days <= 60) return("31-60")
  else if (days <= 90) return("61-90")
  else return("90+")
}

# --- UI ---
ui <- fluidPage(
  titlePanel("Invoice Management System"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("customer", "Customer:", choices = c("All")),
      dateRangeInput("daterange", "Invoice Date Range"),
      actionButton("refresh", "Refresh"),
      hr(),
      h4("Record Payment"),
      textInput("invoice_id", "Invoice ID"),
      numericInput("pay_amount", "Amount", value = 0),
      dateInput("pay_date", "Payment Date", value = Sys.Date()),
      actionButton("record", "Add Payment")
    ),
    
    mainPanel(
      fluidRow(
        column(3, h4("Total Invoiced"), textOutput("total_inv")),
        column(3, h4("Total Received"), textOutput("total_rec")),
        column(3, h4("Outstanding"), textOutput("total_out")),
        column(3, h4("% Overdue"), textOutput("perc_overdue"))
      ),
      hr(),
      DTOutput("invoice_table"),
      hr(),
      plotlyOutput("top_chart"),
      hr(),
      h4("Invoices by Aging Bucket"),
      plotlyOutput("aging_chart") 
    )
  )
)

# --- Server ---
server <- function(input, output, session) {
  
  # Dynamically update customer dropdown
  observe({
    customers <- dbGetQuery(con, "SELECT DISTINCT name FROM customers")$name
    updateSelectInput(session, "customer", choices = c("All", customers))
  })
  
  # Reactive data loader with filters
 
  load_data <- reactive({
    df <- dbGetQuery(con, "
    SELECT i.invoice_id, c.name AS customer_name, i.invoice_date, i.due_date, i.amount,
           COALESCE(p.total_paid, 0) AS total_paid
    FROM invoices i
    JOIN customers c ON i.customer_id = c.customer_id
    LEFT JOIN (
        SELECT invoice_id, SUM(amount) AS total_paid
        FROM payments GROUP BY invoice_id
    ) p ON i.invoice_id = p.invoice_id
  ")
    
    df$outstanding <- df$amount - df$total_paid
    df$aging_bucket <- sapply(as.Date(df$due_date), compute_aging_bucket)
    df
  })
  
  
  # Add payment
  observeEvent(input$record, {
    if (input$pay_amount <= 0) {
      showNotification("Payment must be greater than 0", type = "error")
    } else {
      query <- sprintf(
        "INSERT INTO payments (invoice_id, amount, payment_date) VALUES (%d, %.2f, '%s')",
        as.integer(input$invoice_id),
        as.numeric(input$pay_amount),
        as.character(input$pay_date)
      )
      dbExecute(con, query)
      showNotification("Payment added successfully", type = "message")
    }
  })
  
  # --- Outputs ---
  output$invoice_table <- renderDT({
    df <- load_data()
    datatable(
      df,
      options = list(
        pageLength = 5,
        rowCallback = JS("
          function(row, data) {
            if (data[6] != 'Current' && data[5] > 0) {  
              $('td', row).css('background-color', '#f8d7da');
            }
          }
        ")
      )
    )
  })
  
  output$total_inv <- renderText({
    df <- load_data()
    if (nrow(df) == 0) return(0)
    sum(df$amount, na.rm = TRUE)
  })
  
  output$total_rec <- renderText({
    df <- load_data()
    if (nrow(df) == 0) return(0)
    sum(df$total_paid, na.rm = TRUE)
  })
  
  output$total_out <- renderText({
    df <- load_data()
    if (nrow(df) == 0) return(0)
    sum(df$outstanding, na.rm = TRUE)
  })
  
  output$perc_overdue <- renderText({
    df <- load_data()
    if (nrow(df) == 0) return("0%")
    overdue <- df %>% filter(outstanding > 0 & due_date < Sys.Date())
    perc <- 100 * sum(overdue$outstanding, na.rm = TRUE) / sum(df$amount, na.rm = TRUE)
    paste0(round(perc, 2), "%")
  })
  
  output$top_chart <- renderPlotly({
    top <- dbGetQuery(con, "
      SELECT c.name, SUM(i.amount - COALESCE(p.total_paid, 0)) AS outstanding
      FROM invoices i
      JOIN customers c ON i.customer_id = c.customer_id
      LEFT JOIN (
          SELECT invoice_id, SUM(amount) AS total_paid
          FROM payments GROUP BY invoice_id
      ) p ON i.invoice_id = p.invoice_id
      GROUP BY c.name
      ORDER BY outstanding DESC
      LIMIT 5
    ")
    plot_ly(top, x = ~name, y = ~outstanding, type = "bar")
  })
  
  output$aging_chart <- renderPlotly({
    df <- load_data()
    
    # Count invoices in each bucket
    aging_summary <- df %>%
      group_by(aging_bucket) %>%
      summarise(total_outstanding = sum(outstanding, na.rm = TRUE),
                count = n())
    
    # Pie chart (can also do bar chart)
    plot_ly(
      aging_summary,
      labels = ~aging_bucket,
      values = ~total_outstanding,
      type = "pie",
      textinfo = "label+percent",
      insidetextorientation = "radial"
    ) %>%
      layout(title = "Outstanding Amount by Aging Bucket")
  })
  
}

shinyApp(ui, server)
