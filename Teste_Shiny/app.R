library(shiny)

ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      h3("Entrada dos arquivos"),
      fileInput(inputId = "bams_path",
                label = "BAMs",
                multiple = T)
    ),
    mainPanel(
      textOutput(outputId = "arquivos_bam")
    )
  )
  
  
  
)

server <- function(input, output, session) {
  
  output$arquivos_bam <- renderText({
    if(!is.null(input$bams_path)){
      tools::file_path_sans_ext(input$bams_path)
    }
    
  })
}

shinyApp(ui, server)