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
path_to_rdsfile = gsub(".csv$", ".rds", path_to_csvfile)
dt = aktacsvreader(path_to_csvfile)

saveRDS(data_table, file = path_to_rdsfile)

# Define starting values
dt$Fraction$volume_start = dt$Fraction$volume - dt$Injection$volume

dt$Fraction$Fraction

fractions = dt$Fraction[1,] 

divisible_by_5 <- dt$Fraction[!is.na(dt$Fraction$Fraction) & dt$Fraction$Fraction %% 5 == 0,]

fractions_to_plot = rbind(fractions,divisible_by_5 )



ggplot() +
  geom_line(data = dt$UV, aes(x = volume, y = UV)) +
  # Add a small vertical line below the graph
  geom_segment(aes(x = dt$Fraction$volume_start, 
                   xend = dt$Fraction$volume_start, 
                   y = 0,  # Start just below the plot
                   yend = -0.4),  # End at y = 0 (or adjust as needed)
               color = "blue", 
               size = 0.5) +  # Adjust size as needed
  geom_text(aes(x = fractions_to_plot$volume_start+0.5, 
                y = -0.8,  # Positioning the text right at the y = 0 level
                label = fractions_to_plot$Fraction),  # Text label
            vjust = -0.5,  # Adjust vertical positioning
            color = "red", 
            size = 4) +  # Adjust size as needed
  theme_minimal()


