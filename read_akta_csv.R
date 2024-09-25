library(reshape2)  # For melting the data into long format
library(ggplot2)
library(yaml)


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


# set working directory
working_dir = "C:/Users/oodeg/OneDrive - Universitetet i Oslo/Work/03_UiO/15_instrument_data/Akta"
setwd(working_dir)


# Read files
csvfiles = list.files(working_dir, pattern = ".csv$" )
data_tables = lapply(csvfiles, aktacsvreader)
names(data_tables) <- basename(csvfiles)

# Make yaml file for defining plot naming

yaml_file_path = "experiment_info.yaml"

if(!file.exists(yaml_file_path)){
  fill_in_text = "Please_fill_in_name_to_be_shown_in_plot"
  yamlfile = lapply(csvfiles, function(x){
    list(dir = dirname(x),
         filename = basename(x),
         plot_name = fill_in_text
    )
  })
  write_yaml(yamlfile, "experiment_info.yaml")
}


yamlfile = read_yaml(yaml_file_path)

#TODO
# Write a break point if the user has not filled in the correct names

# Save data as RDS
# sapply(csvfiles, function(x){
#   print(x)
#   path_to_rdsfile = gsub(".csv$", ".rds", x)
#   saveRDS(data_tables[basename(x)], file = path_to_rdsfile)
# })


# Merge table into one big data.frame

df_uv = data.frame()

#i =1
for (i in 1:length(data_tables)) {
  dt = data_tables[[i]]
  # UV
  uv = data.frame(volume = dt$UV$volume, uv = dt$UV$UV, name = yamlfile[[i]]$plot_name )
  df_uv <- rbind(df_uv, uv)
}

library(plotly)

# Assuming df_uv is already created
p <- ggplot(df_uv) +
  geom_line(aes(x = volume, y = uv, col = name))

# Convert to plotly interactive plot
ggplotly(p)

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


