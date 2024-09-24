library(reshape2)  # For melting the data into long format
library(ggplot2)

#csvfile = path_to_csvfile

aktacsvreader <- function(csvfile) {
  # Read the CSV file
  data <- read.csv(csvfile, stringsAsFactors = FALSE, skip = 1)
  
  head(data)
 
  # Loop over each input column
  #col = 4
  
  # Load required libraries

  
  # Initialize an empty data frame to store all data in long format
  data_table <- list()
  
  # Loop through every 2nd column to extract 'volume' and 'measurement'
  for (col in (1:(ncol(data)/2)) * 2) {
    
    # Get the name and unit for each data frame
    data_name <- colnames(data)[col-1]
    data_unit <- data[1, col-1]  # Assuming the first row has units (optional)
    
    # Extract 'volume' and 'measurement' columns
    volume <- as.numeric(data[-1, col-1])
    measurement <- as.numeric(data[-1, col])
    
    # Create a data frame with 'volume' and the measurement column named as 'data_name'
    df <- data.frame(volume = volume, measurement)
    colnames(df)[2] <- data_name
    
    # Remove rows where the 'volume' is NA
    df <- df[!is.na(df$volume), ]
    
    # Store the data frame in the list with 'data_name' as the key
    data_table[[data_name]] <- df
  }
  
  return(data_table)
}


path_to_csvfile = "C:/Users/Øyvind/OneDrive - Universitetet i Oslo/Work/03_UiO/15_instrument_data/Akta/20240923_129_S01_amCh_unconjugated Superdex 75 120 ml 500 µl injection new 001 001.csv"
