# Load libraries
library(RJDBC)
library(dplyr)
library(geosphere)
library(zipcode)
library(reshape2)

# Function to establish SQL connection
establish_connection <- function() {
  # Connect to the server
  drv <- JDBC(driverClass = "com.microsoft.sqlserver.jdbc.SQLServerDriver", 
              classPath = "/home/example/R-DCM/Drivers/sqljdbc_7.0/enu/mssql-jdbc-7.0.0.jre8.jar")
  conn <- dbConnect(drv, 'jdbc:sqlserver://bi.example.com:1433;databaseName=exampledata', 'user', 'password')
  return(conn)
}

# Function to get list of tables
get_table_list <- function(conn) {
  table.list <- dbGetQuery(conn, "SELECT * FROM INFORMATION_SCHEMA.TABLES")
  table.list$queryname <- paste0(table.list$TABLE_SCHEMA, ".", table.list$TABLE_NAME)
  return(table.list)
}

# Function to get sales data by zip
get_sales_by_zip <- function(conn) {
  query <- "SELECT DISTINCT loc_desc, postal_cd, sum(CONVERT(Float, sales)) as sales 
            FROM Client.CustomerCountbyStore 
            GROUP BY loc_desc, postal_cd"
  sales.data <- dbGetQuery(conn, query)
  return(sales.data)
}

# Function to calculate distance
calculate_distance <- function(target, zipcode.civicspace, b = 200) {
  ziplist <- array()
  
  for (i in 1:nrow(target)) {
    a <- as.character(target[i, 1])
    
    ab <- target[i, c("longitude", "latitude")]
    ab2 <- zipcode.civicspace[, c("longitude", "latitude")]
    
    test <- as.data.frame(distm(ab, ab2))
    test1 <- as.data.frame(t(test))
    test2 <- cbind(zipcode.civicspace, test1)
    colnames(test2) <- c("zip", "city", "state", "lattitude", "longitude", "meter")
    test2 <- mutate(test2, kilometer = meter/1000, miles = kilometer * 0.621371)
    
    zip1 <- filter(test2, miles <= b)
    zip1 <- mutate(zip1, store = a)
    ziplist <- rbind(zip1, ziplist)
    ziplist <- filter(ziplist, store != "")
  }
  return(ziplist)
}

# Function to merge sales data with distance data
merge_sales_distance <- function(sales_data, ziplist, store_list) {
  sales_data$loc_number <- as.numeric(sapply(strsplit(sales_data$loc_desc, " "), "[", 1))
  sales_data <- merge(sales_data, store_list, by.x = "loc_number", by.y = "STORE.NUMBER")
  sales_data <- sales_data[sales_data$COUNTRY == "US", ]
  return(merge(sales_data, ziplist, by.x = c("store", "zip2"), by.y = c("store", "zip"), all.x = TRUE))
}

# Function to calculate store radius
calculate_store_radius <- function(sales_distance_data) {
  sales_distance_data$radius <- ifelse(is.na(sales_distance_data$miles), "8.N/A",
                                       ifelse(sales_distance_data$miles < 5, "1. <5mi",
                                              ifelse(sales_distance_data$miles < 10, "2. 5-10mi",
                                                     ifelse(sales_distance_data$miles < 15, "3. 10-15mi",
                                                            ifelse(sales_distance_data$miles < 20, "4. 15-20mi",
                                                                   ifelse(sales_distance_data$miles < 30, "5. 20-30mi",
                                                                          ifelse(sales_distance_data$miles < 50, "6. 30-50mi", "7. 50+mi")))))))
  
  store_radius <- summarise(group_by(sales_distance_data, store, radius), sales = sum(sales))
  store_radius_t <- dcast(store_radius, store ~ radius)
  total_radius <- summarise(group_by(sales_distance_data, radius), sales = sum(sales))
  total_radius <- mutate(total_radius, sales_pct = sales / sum(sales))
  
  return(list(store_radius_t = store_radius_t, total_radius = total_radius))
}

# Function to calculate rolling sum of radius
calculate_rolling_sum <- function(sales_distance_data) {
  roll_data <- sales_distance_data[!is.na(sales_distance_data$miles), c("store", "sales", "miles")]
  roll_data <- roll_data[order(roll_data$store, roll_data$miles), ]
  roll_data$sales_csum <- ave(roll_data$sales, roll_data$store, FUN = cumsum)
  roll_data$totalsales <- ave(roll_data$sales, roll_data$store, FUN = sum)
  roll_data$sales_cpct <- roll_data$sales_csum / roll_data$totalsales
  roll_data$totalmiles <- ave(roll_data$miles, roll_data$store, FUN = sum)
  roll_data$meanmiles <- aggregate(. ~ store, roll_data[7], mean)
  roll_data_v1 <- roll_data %>%
    group_by(store)
