library(shiny)
library(shinyFiles)
library(parallel)
library(Rcpp)

ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
     selectInput(
       inputId = "analysis",
       label = "Qual análise?",
       choices = c("","Alinhamento de dados ONT",
                   "Alinhamento de dados Illumina PE",
                   "Alinhamento de dados Illumina SE"),
       selected = NULL),
     uiOutput(outputId = "opt_analysis")
    ),
    mainPanel(
    )
  )
  
  
  
)

server <- function(input, output, session) {
  
  output$opt_analysis <- renderUI({
    if(!is.null(input$analysis)){
      if(nchar(input$analysis) > 1){
        
        tagList(
          h5("Please select your FASTQ file"),
          shinyFilesButton('fastq_files',
                           label='FASTQ file',
                           title='Please select a file',
                           multiple=ifelse(input$analysis == "Alinhamento de dados Illumina PE",T,F)),
          h5("Please select your reference genome"),
          shinyFilesButton('ref_files',
                           label='Reference genome',
                           title='Please select a file',
                           multiple=FALSE),
          sliderInput(inputId = "threads",
                      label = "Number of threads",
                      min = 1,
                      max = detectCores(),
                      value = 4,
                      step = 1,
                      ticks = F)
        )
      }
    }
    
    
  })
  
  #Fastq files
  shinyFileChoose(input,
                  'fastq_files',
                  root=c(root='.',home = "~"),
                  filetypes=c('', 'fastq'))
  
  #Reference files
  shinyFileChoose(input,
                  'ref_files',
                  root=c(root='.',home = "~"),
                  filetypes=c('', 'fa',"fasta","fna"))
  

}

shinyApp(ui, server)