library(reshape2)  # For melting the data into long format
library(ggplot2)
library(yaml)
library(plotly)
library(dplyr)


#csvfile = path_to_csvfile

aktacsvreader <- function(csvfile, plot_name) {
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
    df <- data.frame(volume = volume, measurement = measurement, plot_name = plot_name)
    colnames(df)[2] <- data_name
    
    # Remove rows where the 'volume' is NA
    df <- df[!is.na(df$volume), ]
    
    # Store the data frame in the list with 'data_name' as the key
    data_table[[data_name]] <- df
  }
  
  return(data_table)
}


# set working directory
working_dir = c("C:/Users/oodeg/OneDrive - Universitetet i Oslo/Work/03_UiO/15_instrument_data/Akta",
                "C:/Users/Øyvind/OneDrive - Universitetet i Oslo/Work/03_UiO/15_instrument_data/Akta")

working_dir = working_dir[file.exists(working_dir)]
setwd(working_dir)


# Define files to use
csvfiles = list.files(working_dir, pattern = ".csv$" )

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


# Read data and make data table
i = 1
data_tables = lapply(1:length(csvfiles), function(i){
  aktacsvreader(csvfiles[[i]], yamlfile[[i]]$plot_name)
})
names(data_tables) <- basename(csvfiles)

# Extract UV data
df_uv = data.frame()
for (i in 1:length(data_tables)) {
  dt = data_tables[[i]]
  # UV
  uv = data.frame(volume = dt$UV$volume, uv = dt$UV$UV, name = yamlfile[[i]]$plot_name )
  df_uv <- rbind(df_uv, uv)
}

#Extract Fraction data
df_Fractions = data.frame()
for (i in 1:length(data_tables)) {
  dt = data_tables[[i]]
  # UV
  Fractions = data.frame(volume = dt$Fraction$volume, Fraction = dt$Fraction$Fraction, name = yamlfile[[i]]$plot_name )
  # The fractions is offset by the injection volume
  # And each fraction starts from the value after that adjustment until the next value in the list
  Fractions$volume = Fractions$volume -  data_tables[[i]]$Injection$volume
  
  df_Fractions <- rbind(df_Fractions, Fractions)
}

# Summarize the mean and standard deviation volume for each fraction across all experiments
df_Fractions_mean <- df_Fractions %>%
  select(-name) %>%  # Remove the 'name' column
  group_by(Fraction) %>%
  summarise(
    mean_volume = mean(volume, na.rm = TRUE),
    sd_volume = sd(volume, na.rm = TRUE)
  )

fraction_size_mean = mean(c(Fractions$volume, NA) -c(NA, Fractions$volume), na.rm = TRUE)
 

fractions_divisible_by_5 <- df_Fractions_mean[!is.na(df_Fractions_mean$Fraction) & df_Fractions_mean$Fraction %% 5 == 0,]

fractions_to_plot = rbind(df_Fractions_mean[1,],fractions_divisible_by_5 )

p <- ggplot() +
  geom_vline(xintercept = Fractions$volume,
             col = "grey",
             linetype = "dotted"
             ) +
  geom_line(
    data = df_uv,
    aes(x = volume, y = uv, col = name)
  )+
  geom_text(aes(x = fractions_to_plot$mean_volume + (fraction_size_mean/2),
                y = -5),
                color ="red",
                size = 4,
                label = fractions_to_plot$Fraction ) +
  theme_minimal() 


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


