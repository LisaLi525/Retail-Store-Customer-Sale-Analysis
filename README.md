# Retail Store Customer Distance and Sales Analysis

## Overview
This R project performs an analysis of customer distance and sales for retail stores. It includes functionalities to establish a connection with a SQL server, retrieve sales data, calculate distances between stores and zip codes, and analyze sales within specified radius categories.

## Project Structure
- **`helper_functions.R`**: Contains all the helper functions used in the analysis.
- **`main_analysis.R`**: Main script that executes the entire analysis, including data retrieval, distance calculation, and sales analysis.
- **`data`**: Directory containing input data files, such as store lists and sales data.
- **`output`**: Directory storing the output files generated during the analysis, including CSV files with store radius and 75th percentile sales data.

## Instructions
1. Install required R packages by running `install.packages(c("RJDBC", "dplyr", "geosphere", "zipcode", "reshape2"))`.
2. Execute `main_analysis.R` to run the analysis. Ensure that you have the necessary data files in the `data` directory.
3. Review the generated output files in the `output` directory for store radius and 75th percentile sales data.

## File Descriptions
- **`main_analysis.R`**: The main script orchestrating the analysis.
- **`helper_functions.R`**: A collection of helper functions used in the analysis.
- **`data/store_list.csv`**: Store list data.
- **`data/sales_data.csv`**: Sales data for customer counts by store.
- **`output/store_radius.csv`**: CSV file containing sales data grouped by store and radius category.
- **`output/store_75pct.csv`**: CSV file containing sales data for stores in the 75th percentile.

## Dependencies
Ensure that the following R packages are installed before running the analysis:
- `RJDBC`
- `dplyr`
- `geosphere`
- `zipcode`
- `reshape2`

## Notes
- The analysis requires a SQL server connection for retrieving data. Update the connection details in `helper_functions.R` if necessary.
- Input data files (`store_list.csv` and `sales_data.csv`) should be placed in the `data` directory.

Feel free to reach out for any questions or clarifications.
