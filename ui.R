library(shiny)
library(shinydashboard)
library(shinyjs)
library(data.table)
# library(ggplot2)
# library(plotly)
# library(dplyr)


#--------------------------------------------------------------------------------------
# UI Header
header <- dashboardHeader(
  #theme = "bootswatch-spacelab.css" 
  title = "Accounts Visualization"
)


#--------------------------------------------------------------------------------------
# UI Side Bar
sidebar <- dashboardSidebar(
  
  useShinyjs(),
  
  sidebarMenu(id = "sidebarmenu",
    # add a conditional panel that shows SL1-4 only if SPACE tab is chosen
    menuItem("Load PaCEx", icon = icon("th"), tabName = "custom") , 
    # each menu item must have a corresponding item in the body of the UI
    menuItem("PaCEx", tabName = "parcoord", icon = icon("dashboard")),
    
    #menuItem("Widgets", icon = icon("th"), tabName = "widgets"
    #           # mark the menu item with label "new"
    #           #,badgeLabel = "new", badgeColor = "green"
    # )
    # 
         
    # add dropdowns for the selection of Sales Hierarchies
    conditionalPanel("input.sidebarmenu === 'parcoord'"
        ,selectInput("selIn_SL1", "Select Sales Level 1",
                     choices = character(0))
    
        ,selectInput("selIn_SL2", "Select Sales Level 2",
                     choices = "select SL1 first")
    
        ,selectInput("selIn_SL3", "Select Sales Level 3",
                     choices = "select SL2 first")
    
        ,selectInput("selIn_SL4", "Select Sales Level 4",
                     choices = "select SL3 first")
    ) # end conditional panel
  )
)

#--------------------------------------------------------------------------------------
## UI Body Content
body <- dashboardBody( 
  tabItems(
    # First tab content
    tabItem(tabName = "custom", 
          div(
            tags$iframe(src= "fisheye/custom_pc_index.html", width = '100%', height='100%', id="custompc",
                        frameborder="0", scrolling="yes") #end iframe  
          ,style="height:90vh;") # end div, set parent div's height
            
    ), #end first Tab Item
    # Second tab content
    tabItem(tabName = "parcoord",
            
            # display Title for the Parallel Coord graph
            uiOutput("show_pc_header"),                   
            div( id ="page_loading_header",h4("Parallel Coordinates Explorer - Loading page...")),
            hidden(h4(id= "prepping_data_status","Preparing graph, stand by...")),
            
            # handler to receive data from server
            singleton(tags$head(tags$script(HTML("
              // initialize the data that is being sent from server.R
              var data_orig;
              
              // tunnel from fisheye iframe to this parent html
              // parent calls a function in the iframe after iframe loads completely
              function tunnel(fn) {
                      console.log('shiny: tunnel')
                      // wait for shiny on change selectbox 
                      // if there is a change, then call the function fn()
                       $(document).on('shiny:inputchanged', function(event) {

                              // When to show the parcoords html    !!!!!!!!!!CHANGE HERE!!!!!!!!!!!!
                              if (event.name === 'selIn_SL4') {      
                                  Shiny.addCustomMessageHandler('sendFishEyeData', function(cluster_aves) {
                                      fn(cluster_aves,1);
                                  });
                              } // end if 
                              
                      }); // end doc on shinyinputchanged
  
              }// end tunnel()
              "  )))),
            
            fluidRow(
              class = "myRow1", 
              column(width =12,
                     # the data is being passed to the div id in the server when user selects from dropdown
                     div(id = "toHide", 
                         tags$iframe(src= "fisheye/index.html", width = '100%', height='100%', id="fisheyeframe", name="fisheyeframe",
                                     frameborder="0", scrolling="yes") #end iframe
                         , style="height:90vh;") # end div, set parent div's height
              )) #end column, fluidRow
    ) # First tab content
  ) # tabItems()
) # dashboardBody()


#--------------------------------------------------------------------------------------
ui <- dashboardPage(
  header,
  sidebar,
  body,
  title = "PaCE - Parallel Coordinates Explorer"
)
