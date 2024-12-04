library(shiny)
library(shinyFiles)
library(parallel)
library(Rcpp)

Rcpp::sourceCpp(file = "../Cpp/runMinimap2.cpp")

ui <- fluidPage(
  h2("Alinhador UI"),
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
      verbatimTextOutput(outputId = "main"),  # This will display the console output
      verbatimTextOutput(outputId = "console_output")  # Console output will appear here
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
                      ticks = F),
          textInput(inputId = "output_name",
                    label = "Output label",
                    placeholder = "aligment.sam"),
          helpText("*por favor adicione a extensão .sam"),
          actionButton(inputId = "runAlingment",
                       label = "Run!")
        )
      }
    }
    
    
  })
  
  #Fastq files
  shinyFileChoose(input,
                  'fastq_files',
                  root=c(root='/',home = "~"),
                  filetypes=c('', 'fastq'))
  
  #Reference files
  shinyFileChoose(input,
                  'ref_files',
                  root=c(root='/',home = "~"),
                  filetypes=c('', 'fa',"fasta","fna"))
  
  output$main <- renderText({
    req(input$fastq_files)
    req(input$ref_files)
    
    if(!is.null(input$analysis)){
      if(nchar(input$analysis) > 1 & !is.null(input$fastq_files) & !is.null(input$ref_files)){
        
        fastq <- parseFilePaths(root=c(root='',home = "~"),input$fastq_files)
        refs <- parseFilePaths(root=c(root='',home = "~"),input$ref_files)
        (paste0("FASTQ = ",fastq$datapath,"\n\n\n",
                "Reference = ",refs$datapath))
      }
      
    }
    
    
  })
  
  observeEvent(input$runAlingment,{
    req(input$fastq_files)
    req(input$ref_files)
    req(input$threads)
    req(input$output_name)
    
    fastq <- parseFilePaths(root=c(root='/',home = "~"), input$fastq_files)
    refs <- parseFilePaths(root=c(root='/',home = "~"), input$ref_files)
    
    # Extracting the file paths as strings
    fastq_path <- fastq$datapath[1]  # Assuming a single file selection
    ref_path <- refs$datapath[1]     # Assuming a single reference file
    
    # Run the Minimap2 function (replace with correct function)
    
    runMinimap2(input = fastq_path,
                reference = ref_path,
                threads_num = input$threads,
                output = input$output_name)
    
    output$console_output <- renderText({
      
      paste("roudou!!!!\n")
    })
    
    
  })
  
  
}

shinyApp(ui, server)