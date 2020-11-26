library(shiny)
library(tidyverse)

DATA_PATH = "df5.csv"
NTWEETS <- 50

campaign = 'pyladies'
thankyou_messages = list()
thankyou_messages[['pyladies']] = "<br/><h3> Děkujeme! </h3> 
<p>A přejeme 
úspěšné dokončení datového kurzu PyLadies. Když nám vyplníš jméno a email, pošleme ti sbírku
nejlepších pythonových, až ji teda budeme mít hotovou.</p>

<p>Nezapomeň, prosím, kliknout na tlačítko Save, jinak se tvé odpovědi neuloží.</p>
<br/>"


df <- read_csv(DATA_PATH)
df <- df[sample(nrow(df), NTWEETS),]

server <- function(input, output, session) {
  
  rv <- reactiveValues(n = 1,
                       done = FALSE,
                       results = data.frame(id=numeric(), text=character(), 
                                          eval=numeric(), duplicated=logical(), stringsAsFactors = FALSE)) 
  
  observeEvent(input$goNext, {
    if (rv$n < nrow(df)) {
      rv$results[nrow(rv$results) + 1,] = c(df$id[rv$n], df$full_text[rv$n], input$eval, input$duplicated);
      rv$n <- rv$n + 1;
      updateSliderInput(session, "n", value = rv$n);
      updateCheckboxInput(session, "duplicated", value = FALSE)
    }  
  })
  
  observeEvent(input$goPrevious, {
    if (rv$n > 1) {
      rv$n <- rv$n - 1;
      rv$results <- head(rv$results, -1);
      updateSliderInput(session, "n", value = rv$n);
      updateCheckboxInput(session, "duplicated", value = FALSE)
    } 
  })
  
  # using https://community.rstudio.com/t/embed-twitter-tweet-in-shiny-app/51364
  output$tweet <- renderUI({
    tagList(
      tags$blockquote(class = "twitter-tweet",
                      tags$a(href = df$url[rv$n])),
      tags$script('twttr.widgets.load(document.getElementById("tweet"));')
    )
  })
  
  output$finished = renderText({
    if (rv$done) {
      return('Your answers have been saved.')
    } else {
      return('')
    }
  })
  
  observeEvent(input$saveResults, {
    if (!rv$done) {
      timestamp = as.numeric(Sys.time())
      
      filename = paste0("answers/", input$name, "-", timestamp, ".csv")
      content = rv$results
      content[nrow(rv$results) + 1,] = c(df$id[rv$n], df$full_text[rv$n], 
                                              input$eval, input$duplicated)
      write_csv(content, filename)
      
      filename2 = paste0("responders/", input$name, "-", timestamp, ".txt")
      content2 = paste(input$name, timestamp, input$email, input$pylevel, campaign, sep="\t")
      writeLines(content2, filename2)
      
      rv$done = TRUE
    }  
  })
}  





ui <- fluidPage(
  
  tags$head(
    tags$script(async = NA, src = "https://platform.twitter.com/widgets.js")
  ),
  
  # Application title
  titlePanel("Pytips Evaluator"),
  
  # Sidebar with a slider input
  sliderInput("n",
              "Tweet nb:",
              min = 1,
              max = nrow(df),
              value = 1,
              width = "60%"),
  
  column(3,
         
         radioButtons("eval", "Quality of the tweet (7=best, 1=worst):", selected = "4", inline = TRUE,
                      choices = c("1" = "1", "2" = "2", "3" = "3", "4" = "4", "5" = "5", "6" = "6", "7" = "7")),
         checkboxInput("duplicated", "Duplicated (= very similar to another tip)"), 
         actionButton("goPrevious", "Previous"),
         actionButton("goNext", "Next"),
         
         conditionalPanel(condition = paste("input.n ==", NTWEETS),
                          HTML(thankyou_messages[[campaign]])),
         
         conditionalPanel(condition = paste("input.n ==", NTWEETS),
                          textInput("name", "Your name:", "")),
         
         conditionalPanel(condition = paste("input.n ==", NTWEETS),
                          textInput("name", "Your email:", "")),
         
         conditionalPanel(condition = paste("input.n ==", NTWEETS),
                          radioButtons("pylevel", "Regarding Python, I am", selected = "Intermediate", inline = TRUE,
                                       choices = c("Beginner" = "Beginner", "Intermediate" = "Intermediate", "Advanced" = "Advanced"))),
         
         conditionalPanel(condition = paste("input.n ==", NTWEETS),
                          actionButton("saveResults", "Save", icon = icon("download"))),
         conditionalPanel(condition = paste("input.n ==", NTWEETS),
                          textOutput('finished'))
  ),
  
  column(9,
         # Show a plot of the generated distribution
         uiOutput("tweet")),
)

# Run the application 
shinyApp(ui = ui, server = server)