library(shiny)
library(ggplot2)
library(DT)
library(readxl)
library(RCurl)
library(bslib)
library(dplyr)
library(tidyr)

data_url <- getURL("https://raw.githubusercontent.com/retflipper/DATA332_CountingCars/refs/heads/main/data/Counting_Cars.csv")
dataset <- read.csv(text = data_url)

dataset <- dataset[-1]
dataset <- dataset[1:9]

car_types <- c(
  "1" = "Emergency",
  "2" = "Hatchback",
  "3" = "Sedan",
  "4" = "SUV",
  "5" = "Van",
  "6" = "Minivan",
  "7" = "Motorcycle",
  "8" = "Coupe",
  "9" = "Truck",
  "10" = "Pickup Truck"
)
dataset$Type_of_Car <- car_types[as.character(dataset$Type_of_Car)]

column_names<-colnames(dataset) #for input selections

dataset <- dataset %>%
  mutate(Speeding_Classification = case_when(
    Difference_In_Readings <= 0 ~ "not_speeding",
    Difference_In_Readings > 0 & Difference_In_Readings <= 5 ~ "speeding_by_5_or_less",
    Difference_In_Readings > 5 ~ "speeding_by_more_than_5"
  ))

car_type_speeding_pivot_table <- dataset %>%
  group_by(Type_of_Car, Speeding_Classification) %>%
  summarize(Count = n())

ui <- fluidPage( 
  
  titlePanel(title = "Explore Counting Car Dataset"),
  
  
  navset_card_underline(
    
    nav_panel("Scatter Plots", fluidRow(
      column(2,
             selectInput('X', 'Choose X', column_names, column_names[1]),
             selectInput('Y', 'Choose Y', column_names, column_names[3]),
             selectInput('Splitby', 'Split By', column_names, column_names[3])
      ),
      column(4, plotOutput('scatter_plot')),
      column(6,
             DT::dataTableOutput("table_01", width = "100%"),
             h5("Summary Statistics for Selected Columns"),
             tableOutput("scatter_summary"),
             h5("analysis here")
      )
    )),
    
    nav_panel("Difference in Speed Box Plots",
              plotOutput("difference_in_speed_box_plot"),
              h5("Summary Statistics for Difference in Readings"),
              tableOutput("diff_summary"),
              h5("This box & whisker plot displays the difference in speed from a driver's initial .vs. their final read. 
                 The mean and median both being at or near zero respectively show that the 
                 pressence of a speed sign may not deter drivers from lowering there speed.")
    ),
    
    nav_panel("Final Speed Box Plots",
              plotOutput("final_speed_box_plot"),
              h5("Summary Statistics for Final Read"),
              tableOutput("final_summary"),
              h5("analysis here")
    ),

    nav_panel("Speeding by Car Type",
              plotOutput("speeding_by_car_type"),
              h5("Summary Statistics for Final Read"),
              tableOutput("final_summary"),
              h5("analysis here")
    )
  )
)


server <- function(input, output) {
  
  # Scatter plot
  output$scatter_plot <- renderPlot({
    ggplot(dataset, aes_string(x = input$X, y = input$Y, colour = input$Splitby)) + 
      geom_point()
  })
  
  # Data Table
  output$table_01 <- DT::renderDataTable({
    dataset[, c(input$X, input$Y, input$Splitby)]
  }, options = list(pageLength = 4))
  
  # Summary for Scatter Plot
  output$scatter_summary <- renderTable({
    df <- dataset[, c(input$X, input$Y)]
    data.frame(
      Variable = names(df),
      Min = sapply(df, min, na.rm = TRUE),
      Mean = round(sapply(df, mean, na.rm = TRUE), 2),
      Median = sapply(df, median, na.rm = TRUE),
      Max = sapply(df, max, na.rm = TRUE),
      SD = round(sapply(df, sd, na.rm = TRUE), 2)
    )
  })
  
  # Boxplot: Difference in Speed
  output$difference_in_speed_box_plot <- renderPlot({
    boxplot(dataset$Difference_In_Readings, col = "#69b3a2", xlab = "Difference in Readings", horizontal = TRUE)
  })
  
  # Summary for Difference in Speed
  output$diff_summary <- renderTable({
    diff_data <- dataset$Difference_In_Readings
    data.frame(
      Min = min(diff_data, na.rm = TRUE),
      Mean = round(mean(diff_data, na.rm = TRUE), 2),
      Median = median(diff_data, na.rm = TRUE),
      Max = max(diff_data, na.rm = TRUE),
      SD = round(sd(diff_data, na.rm = TRUE), 2)
    )
  })
  
  # Boxplot: Final Speed
  output$final_speed_box_plot <- renderPlot({
    boxplot(dataset$Final_Read, col = "#69b3a2", xlab = "Final Read", horizontal = TRUE)
  })
  
  # Summary for Final Read
  output$final_summary <- renderTable({
    final_data <- dataset$Final_Read
    data.frame(
      Min = min(final_data, na.rm = TRUE),
      Mean = round(mean(final_data, na.rm = TRUE), 2),
      Median = median(final_data, na.rm = TRUE),
      Max = max(final_data, na.rm = TRUE),
      SD = round(sd(final_data, na.rm = TRUE), 2)
    )

  # Bar Chart for Speeding by Car Type
  output$speeding_by_car_type <- renderPlot({
    ggplot(car_type_speeding_pivot_table, aes(fill=Speeding_Classification, y=Count, x=Type_of_Car)) + 
      geom_bar(position="stack", stat="identity") +
      scale_fill_manual(values = c("#2dc937", "#e7b416", "#cc3232")) +
      xlab("Type of Car")
  })
  })
}


shinyApp(ui=ui, server=server)
