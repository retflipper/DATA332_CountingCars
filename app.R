library(shiny)
library(ggplot2)
library(DT)
library(readxl)
library(RCurl)
library(bslib)

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


ui<-fluidPage( 
  
  titlePanel(title = "Explore Counting Cars Dataset"),
  
  
  navset_card_underline(
    
    nav_panel("Scatter Plots", fluidRow(
      column(2,
             selectInput('X', 'Choose X',column_names,column_names[1]),
             selectInput('Y', 'Choose Y',column_names,column_names[3]),
             selectInput('Splitby', 'Split By', column_names,column_names[3])
      ),
      column(4,plotOutput('scatter_plot')),
      column(6,DT::dataTableOutput("table_01", width = "100%"),
             h5("text here"))
    )),
    
    nav_panel("Difference in Speed Box Plots", plotOutput("difference_in_speed_box_plot"),
              h5("text here")),
    
    nav_panel("Final Speed Box Plots", plotOutput("final_speed_box_plot"),
              h5("text here"))
  )
  
  
)

server<-function(input,output){
  
  output$scatter_plot <- renderPlot({
    ggplot(dataset, aes_string(x=input$X, y=input$Y, colour=input$Splitby))+ geom_point()
  })
  
  output$difference_in_speed_box_plot <- renderPlot({
    boxplot(dataset$Difference_In_Readings , col="#69b3a2" , xlab="complete box", horizontal=TRUE)
  })
  
  output$final_speed_box_plot <- renderPlot({
    boxplot(dataset$Final_Read , col="#69b3a2" , xlab="complete box", horizontal=TRUE)
  })
  
  output$table_01<-DT::renderDataTable(dataset[,c(input$X,input$Y,input$Splitby)],options = list(pageLength = 4))
}

shinyApp(ui=ui, server=server)
