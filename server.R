library(shiny)
library(cluster)
library(rjson)
library(shinyjs)
library(data.table)
library(fpc)
library(bit64)

shinyServer(function(input, output, session) {
  
 # observe the tab type, if parcoord is selected, then load csv and apply R logic to the data
 # otherwise, the tab is custome parcoord
 observeEvent(input$sidebarmenu,{
   if(input$sidebarmenu == 'parcoord'){
      value <- reactiveValues(show_iframe = 0,
                              sl3_key = NULL,
                              sl2_key = NULL)
                              
     
      shinyjs::hide("toHide")
      
      toJSONArray <- function(obj, json = TRUE, nonames = TRUE) {
        list2keyval <- function(l) {
          keys = names(l)
          lapply(keys, function(key) {
            list(key = key, values = l[[key]])
          })
        }
  
        obj2list <- function(df) {
          l = plyr::alply(df, 1, as.list)
          if (nonames) {
            names(l) = NULL
          }
          return(l)
        }
  
        if (json) {
          toJSON(obj2list(obj))
        } else {
          obj2list(obj)
        }
      }
  
      
      # reads columns from fisheye data csv - DONE IN THE UI part of the process
      DT <- fread("data/parcoord_data_prep.csv")
      
      # some large wallet values are being read as big integers and creating problems later
      # so let's convert them to floating
      cols64 <- names(DT[1, .SD, .SDcols = sapply(DT, is.integer64)])
      for (col in cols64) {
          DT[ , (col) := as.numeric( get(col) )]
      }
      
      # just to make sure - force wallet vars to float
      colsWallet <- c("Wal4FYs_Total", "WalFY17_Total", "BICFY17_Total", "StatFY17_Total", 
                      "WalFY18_Total", "BICFY18_Total", "StatFY18_Total",
                      "SFDCOpendUSD_QMeanLast4Qs", "SFDCBookdUSD_QMeanLast4Qs", "SFDCLostUSD_QMeanLast4Qs")
      for (col in colsWallet) {
          DT[ , (col) := as.numeric( get(col) )]
      }
      
      DT[, Wal4FYs_Total := Wal4FYs_Total + 4]   # annual avg will be taken soon (by dividing by 4) 
      DT[, WalFY17_Total := WalFY17_Total + 1]
      DT[, BICFY17_Total := BICFY17_Total + 1]
      DT[, StatFY17_Total := StatFY17_Total + 1]
      DT[, WalFY18_Total := WalFY18_Total + 1]
      DT[, BICFY18_Total := BICFY18_Total + 1]
      DT[, StatFY18_Total := StatFY18_Total + 1]
      DT[, SFDCOpendUSD_QMeanLast4Qs := SFDCOpendUSD_QMeanLast4Qs + 1]
      DT[, SFDCBookdUSD_QMeanLast4Qs := SFDCBookdUSD_QMeanLast4Qs + 1]
      DT[, SFDCLostUSD_QMeanLast4Qs := SFDCLostUSD_QMeanLast4Qs + 1]
  
      
      # parallel.js assumes that the following vars exist in the data passed to it:
      #   group: shows in the list in the bottom center
      #   id (actually changed to SAVID in parallel.js): is never shown as a coordinate
      #   name: its the name that identifies a line in the viz. Here, the SAVName
      
      # sl <- fread("data/sales_levels_keys_Q2FY17.csv")
      # sl2 <- unique(sl[, .(LEVEL_2, LEVEL_2_key)])
      # sl3 <- unique(sl[, .(LEVEL_3, LEVEL_3_key)])
      # sl4 <- unique(sl[, .(LEVEL_4, LEVEL_4_key)])
      # sl5 <- unique(sl[, .(LEVEL_5, LEVEL_5_key)])
      # sl6 <- unique(sl[, .(LEVEL_6, LEVEL_6_key)])
  
      sl2 <- fread("data/Sales_level_2.csv")
      sl3 <- fread("data/Sales_level_3.csv")
      sl4 <- fread("data/Sales_level_4.csv")
      sl5 <- fread("data/Sales_level_5.csv")
      sl6 <- fread("data/Sales_level_6.csv")
      
      setkey(sl2, LEVEL_2_key)
      setkey(sl3, LEVEL_3_key)
      setkey(sl4, LEVEL_4_key)
      setkey(sl5, LEVEL_5_key)
      setkey(sl6, LEVEL_6_key)
      
      
      # if Select Level 1 choice is null, then hide the header that states the page is loading
      shinyjs::hide('page_loading_header')
      
      
      sl1_choices <- unique(DT$Sales_Level_1)
      
      updateSelectizeInput(
          session,
          "selIn_SL1",
          label = "Select Sales Level 1",
          choices = sl1_choices,
          selected = NULL,
          options = list(
              placeholder = 'Select an option',
              onInitialize = I('function() { this.setValue(""); }')
          )
      )
      
      
      observeEvent(input$selIn_SL1, {
          # handler function called 'sendFishEyeData' sends data to the ui.R which then sends
          if (is.null(input$selIn_SL1)) {
              print("OBSERVE SL1 IS NULL")
          } else {
              print(paste0("selected sl1 ", input$selIn_SL1))
              
              sl2_choices_key <-
                  unique(DT[Sales_Level_1 == input$selIn_SL1, Sales_Level_2_key])
              # from key to value
              sl2_choices <- sl2[sl2_choices_key]
              
              updateSelectizeInput(
                  session,
                  "selIn_SL2",
                  label = "Select Sales Level 2",
                  choices = sl2_choices$LEVEL_2,
                  selected = NULL,
                  options = list(
                      placeholder = 'Select an option',
                      onInitialize = I('function() { this.setValue(""); }')
                  )
              )
          }
      })
      
      observeEvent(input$selIn_SL2, {
          # handler function called 'sendFishEyeData' sends data to the ui.R which then sends
          if (is.null(input$selIn_SL2)) {
              print("OBSERVE SL2 IS NULL")
          } else {
              #print(input$selIn_SL2)
              # from value to key
              value$sl2_key <- sl2[LEVEL_2 == input$selIn_SL2, LEVEL_2_key]
              
              print(paste0(
                  "selected sl2 ",
                  input$selIn_SL2,
                  ' (',
                  value$sl2_key,
                  ')'
              ))
              
              sl3_choices_key <-
                  unique(DT[Sales_Level_2_key == value$sl2_key, Sales_Level_3_key])
              # from key to value
              sl3_choices <- sl3[sl3_choices_key]
              
              updateSelectizeInput(
                  session,
                  "selIn_SL3",
                  label = "Select Sales Level 3",
                  #choices = sl3_choices$LEVEL_3,
                  choices = c("All", sl3_choices$LEVEL_3),
                  selected = NULL,
                  options = list(
                      placeholder = 'Select an option',
                      onInitialize = I('function() { this.setValue(""); }')
                  )
              )
          }
      })
      
      observeEvent(input$selIn_SL3, {
          # handler function called 'sendFishEyeData' sends data to the ui.R which then sends
          if (is.null(input$selIn_SL3)) {
              print("OBSERVE SL3 IS NULL")
          } else {
              if (input$selIn_SL3 != "All") {
                  # from value to key
                  
                  #print(input$selIn_SL3)
                  # from value to key
                  value$sl3_key <-
                      sl3[LEVEL_3 == input$selIn_SL3, LEVEL_3_key]
                  
                  print(paste0(
                      "selected sl3 ",
                      input$selIn_SL3,
                      ' (',
                      value$sl3_key,
                      ')'
                  ))
                  
                  sl4_choices_key <-
                      unique(DT[Sales_Level_3_key == value$sl3_key, Sales_Level_4_key])
                  # from key to value
                  sl4_choices <- sl4[sl4_choices_key]
                  
              } else {
                  # use all SL3 values from the selected SL2
                  print(paste0(
                      "selected 'All' sl3s from sl2 key ",
                      value$sl2_key
                  ))
                  
                  value$sl3_key <- 0 # will represent ALL SL3s
                  
                  # take all distinct sl4 keys associated with the sl2 previously selected
                  sl4_choices_key <-
                      unique(DT[Sales_Level_2_key == value$sl2_key, Sales_Level_4_key])
                  # from key to value
                  sl4_choices <- sl4[sl4_choices_key]
                  
              }
              
              # assemble list of choices for SL4 dropdown
              updateSelectizeInput(
                  session,
                  "selIn_SL4",
                  label = "Select Sales Level 4",
                  choices = c("All", sl4_choices$LEVEL_4),
                  selected = NULL,
                  options = list(
                      placeholder = 'Select an option',
                      onInitialize = I('function() { this.setValue(""); }')
                  )
              )
          }
      })
      
      
      observeEvent(input$selIn_SL4, {
          # handler function called 'sendFishEyeData' sends data to the ui.R which then sends
          if (is.null(input$selIn_SL4) ||
              input$selIn_SL4 == "" || input$selIn_SL4 == "select SL3 first") {
              print("OBSERVE SL4 IS NULL")
              value$show_iframe = 0
          } else {
              # show a status that we are preparing the data and hide the iframe until the data is ready
              shinyjs::show("prepping_data_status")
              shinyjs::hide("show_pc_header")
              shinyjs::hide("toHide")
              
              if (input$selIn_SL4 != "All") {
                  # from value to key
                  sl4_key <- sl4[LEVEL_4 == input$selIn_SL4, LEVEL_4_key]
                  print(paste0(
                      "selected sl4 ",
                      input$selIn_SL4,
                      ' (',
                      sl4_key,
                      ')'
                  ))
                  
                  data <- DT[Sales_Level_4_key == sl4_key,]
                  
              } else {
                  if (value$sl3_key != 0) {
                      # use all SL4 values from the selected SL3
                      print(paste0(
                          "selected 'All' SL4s from SL3 key ",
                          value$sl3_key
                      ))
                      data <- DT[Sales_Level_3_key == value$sl3_key,]
                      
                  } else {
                      # use all SL4 values from the selected SL2
                      print(paste0(
                          "selected 'All' SL4s from SL2 key ",
                          value$sl2_key
                      ))
                      data <- DT[Sales_Level_2_key == value$sl2_key,]
                      
                  }
              }

              # for testing purposes
              # data <- DT[Sales_Level_4_key == 53, ] #Brazil
              # data <- DT[Sales_Level_3_key == 15,]    
              # data <- DT[Sales_Level_2_key == 15,]    
              
              print(paste('rows selected: ', nrow(data)))
              
              # represent the percentages as percentages (no decimal places)
              for (col in names(data)[grep("pct|WS4", names(data))]) {
                  data[, (col) := round(data[[col]] *100)]
              }
              
              
              
              #--------------------------------------------------------------------------------------
              ### Add some statistical sugar on top of the data
              #--------------------------------------------------------------------------------------
              
              ### Reduce the data into the main components using Principal Components
              # TODO: need to catch potential failures
              
              # take out influence of large wallet values - for PCA only
              data[, Wal4FYs_log := log(Wal4FYs_Total)]
              data[, WalFY17_log := log(WalFY17_Total)]
              data[, WalFY18_log := log(WalFY18_Total)]
              
              # how much of the wallet can we still "gain"
              data[, GainSharePctFY17 := ifelse(WalFY17_Total == 0, 
                                                0, (BICFY17_Total - StatFY17_Total) / WalFY17_Total)]
              data[, GainSharePctFY18 := ifelse(WalFY18_Total == 0, 
                                                0, (BICFY18_Total - StatFY18_Total) / WalFY18_Total)]
              
              w_ws_vars <- c(
                  "Wal4FYs_log", "WalFY17_log", # "WalFY18_log",
                  
                  "WS4FYs_Total", "WS4FYs_EntNet", "WS4FYs_DC", "WS4FYs_Secur",
                  "WS4FYs_Collab", "WS4FYs_Svcs", "WS4FYs_SPtech", 
                  #"WS4FYs_Others",
                  
                  "Wal4FYs_pct_EntNet", "Wal4FYs_pct_DC", "Wal4FYs_pct_Secur",
                  "Wal4FYs_pct_Collab", "Wal4FYs_pct_Svcs", "Wal4FYs_pct_SPtech", 
                  #"Wal4FYs_pct_Others",
                  
                  "WalFY17_pct_EntNet", "WalFY17_pct_DC", "WalFY17_pct_Secur",
                  "WalFY17_pct_Collab", "WalFY17_pct_Svcs", "WalFY17_pct_SPtech" 
                  #,"WalFY17_pct_Others" 
                  
                  ,"BICFY17_Total", "GainSharePctFY17" 
              )
              
              data[, NS_IS := ifelse(Needs_Segment == 'IntgSeek', 1L, 0L)]
              data[, NS_IT := ifelse(Needs_Segment == 'ITStrat', 1L, 0L)]
              data[, NS_MB := ifelse(Needs_Segment == 'Mainstr', 1L, 0L)]
              data[, NS_LP := ifelse(Needs_Segment == 'LowPrice', 1L, 0L)]
              data[, NS_RR := ifelse(Needs_Segment == 'RelatRel', 1L, 0L)]
              
              # take the dummy NS vars only if they have more than 1 value in the set of chosen accounts
              NSvars <- c("NS_IS", "NS_IT", "NS_MB", "NS_LP", "NS_RR")[
                  which(data[, lapply(.SD, uniqueN), 
                   .SDcols = c("NS_IS", "NS_IT", "NS_MB", "NS_LP", "NS_RR")] > 1)]
              
              # if not enough rows for PCA and cluster just use 1 single group
              if (nrow(data) >= 5) {
                  pca <- prcomp(
                          data[, c(w_ws_vars,     # wallet and wallet share vars
                                   NSvars ),      # needs based sgmt (that have more than 1 unique value in set)
                                 with = FALSE], scale = TRUE, cor = TRUE, scores = TRUE, retx = TRUE
                      )
                  
                  # plot(pca, type = "l")
                  
                  # Method1: how many components have std dev > 1?
                  # no_comps1 <- sum(summary(pca)$importance["Standard deviation",] >= 1.0 )
                  # print(paste0("Using ", no_comps1, " components (", summary(pca)$importance["Cumulative Proportion", no_comps1]," of tot var)"))
                  
                  # Method2: how many components until no more significant decline in std dev (scree)?
                  # find first occurrence of a decrease of less than 3% in subsequent components
                  # pct_decr <- (pca$sdev[-length(pca$sdev)] - pca$sdev[2:length(pca$sdev)]) / pca$sdev[-length(pca$sdev)] > 0.03
                  # for (i in 1:length(pct_decr)) { if (!pct_decr[i]) break }
                  # no_comps2 <- i
                  # print(paste0("Using ", no_comps2, " components (", summary(pca)$importance["Cumulative Proportion", no_comps2]," of tot var)"))
                  
                  # Method3: how many components provide +80% of the variability?
                  no_comps3 <-
                      min(10, sum(summary(pca)$importance["Cumulative Proportion", ] < 0.80) + 1)
                  print(
                      paste0("Using ", no_comps3, " components (",
                              summary(pca)$importance["Cumulative Proportion", no_comps3],
                              " of tot var)"
                      )
                  )
                  
                  # rotate the pca loadings to facilitate interpretation (using varimax)
                  vm <- varimax(pca$rotation[,1:no_comps3])
                  # print(varmax$loadings)
                  
                  # print the top 2 and bottom2 rotated loadings for each component (here as "factors") 
                  vm2 <- as.data.frame(vm$loadings[,1:no_comps3], optional = TRUE, row.names = "var")
                  vm2$var <- rownames(vm$loadings)
                  for (i in 1:no_comps3) {
                      print(vm2[order(-vm2[,i]),][c(1,2,nrow(vm2)-1,nrow(vm2)),c(i,no_comps3+1)]);cat("\n")
                  }
                  
                  # cluster on the top k components - here using method 3 to define # components
                  set.seed(1234)
                  pamk.best <- pamk(
                      pca$x[, 1:no_comps3],
                      krange = 3:(min(nrow(data)-1, 10)),   # number of clusters to be tried for best
                      criterion = "asw",
                      usepam = FALSE,
                      samples = 80)
                  
                  cat("number of clusters estimated by optimum average silhouette width:",
                      pamk.best$nc, "\n" )
                  
                  #clust <- cluster::clara( pca$x[, 1:no_comps3], 10, samples=80 )
                  
                  # label clusters as cluster01, cluster02, ..., cluster10
                  cl <- paste0("0", as.character(pamk.best$pamobject$clustering))
                  cl <- substr(cl, nchar(cl) - 1, nchar(cl))
                  data[, group := paste0("cluster", cl)]
                  
              } else {
                  data[, group := "cluster01"]
              }
              
              m <- data[, lapply(.SD, mean), by = group, 
                        .SDcols = c("Wal4FYs_Total", "WalFY17_Total", "WalFY18_Total", 
                                    w_ws_vars, NSvars)]
              m <- m[, lapply(.SD, round, 2), by = group]
              m[, c("Wal4FYs_Total", "WalFY17_Total", "WalFY18_Total") := 
                  .(round(Wal4FYs_Total), round(WalFY17_Total), round(WalFY18_Total))]
              m[, c("Wal4FYs_log", "WalFY17_log", "WalFY18_log") := NULL]
              print(m)
              
              # delete the dummmy vars from needs based segment
              data[,c("NS_IS", "NS_IT", "NS_MB", "NS_LP", "NS_RR",
                      "Wal4FYs_log", "WalFY17_log", "WalFY18_log"):= NULL]
              
              # for testing purposes
              #data[, group := paste0("cluster", as.character(clust$clustering))]
              
              # small correction (rows have this issue in Q2 data)
              #data[BICFY17_Total < StatFY17_Total, BICFY17_Total :=  StatFY17_Total]
              
              
              # show avg wallet in the last 4 FYs instead of full total
              data[, Wal4FYs_Total := round(Wal4FYs_Total/4)]
              
                          
              # Rename variables so they look better in the headers of the parallel axis
              # print(names(data))
              
              setnames(data, c(
                      "SAVID", "name",
                      
                      "Wallet Share last4FY Tot %", "Wallet Share last4FY EntNet %", "Wallet Share last4FY DC %", "Wallet Share last4FY Secur %",
                      "Wallet Share last4FY Collab %", "Wallet Share last4FY Svcs %", "Wallet Share last4FY SPtech %", "Wallet Share last4FY Others %",
                      
                      "Wallet last4FY Tot avg", "Wallet 4FY %EntNet", "Wallet last4FY %DC", "Wallet last4FY %Secur",
                      "Wallet last4FY %Collab", "Wallet last4FY %Svcs", "Wallet last4FY %SPtech", "Wallet last4FY %Others",
                      
                      "Wallet FY17 Tot", "Wallet FY17 %EntNet", "Wallet FY17 %DC", "Wallet FY17 %Secur",
                      "Wallet FY17 %Collab", "Wallet FY17 %Svcs", "Wallet FY17 %SPtech", "Wallet FY17 %Others",
                      "BIC Oppty FY17 Tot", "Stat Oppty FY17 Tot", 
                      
                      "Wallet FY18 Tot", "Wallet FY18 %EntNet", "Wallet FY18 %DC", "Wallet FY18 %Secur",
                      "Wallet FY18 %Collab", "Wallet FY18 %Svcs", "Wallet FY18 %SPtech", "Wallet FY18 %Others",
                      "BIC Oppty FY18 Tot", "Stat Oppty FY18 Tot", 
  
                      "Tech Adoption %Early", "Tech Adoption %Late",
                      "Needs Based Segment", "Bargain Power Segment",
                      
                      "Partner Suppt Segment", "Partner Tier1 2FY %", "Partner Tier2 2FY %", "Partner TierSP 2FY %",
                      
                      "SAV TYPE", "SAV Vertical", "SAV Country", "SAV Segment",
                      
                      "Contacts # All", "Contacts %Active", "Contacts %Decision Makers", "Contacts %Business",
                      
                      "Targets # QtrlyMean 4Qs", "Targets Qtrly Growth%",
                      "Responses # QtrlyMean 4Qs", "Responses Qtrly Growth%",
                      "cco PageViews # QtrlyMean 4Qs", "cco PageViews Qtrly Growth%",
                      
                      "SFDC Opened$ QtrlyMean 4Qs", "SFDC Opened$ Qtrly Growth%",
                      "SFDC Booked$ QtrlyMean 4Qs", "SFDC Booked$ Qtrly Growth%",
                      "SFDC Lost$ QtrlyMean 4Qs", "SFDC Lost$ Qtrly Growth%",
                      "SFDC Opened# QtrlyMean 4Qs", "SFDC Opened# Qtrly Growth%",
                      "SFDC Booked# QtrlyMean 4Qs", "SFDC Booked# Qtrly Growth%",
                      "SFDC Lost# QtrlyMean 4Qs", "SFDC Lost# Qtrly Growth%",
                      
                      "P2B Score EntNet", "P2B Score DC", "P2B Score Secur", "P2B Score Collab",
                      "P2B Score Svcs", "P2B Score SPtech", "P2B Score Others", 
                      "P2B ExpBkgs EntNet", "P2B ExpBkgs DC", "P2B ExpBkgs Secur", "P2B ExpBkgs Collab", 
                      "P2B ExpBkgs Svcs", "P2B ExpBkgs SPtech","P2B ExpBkgs Others",
                      
                      "Sales_Level_1", "Sales_Level_2_key", "Sales_Level_3_key", "Sales_Level_4_key",  
                      "Sales_Level_5_key", "Sales_Level_6_key",
  
                      "Gain Share as %of Wallet FY17", "Gain Share as %of Wallet FY18",
                      
                      "group"
              ))
              
              
              # note that if you change the names of the vars you may have to change
              # parallel.js, if log scale is needed, and maketable (2 lines to be changed!!!)
              
              setcolorder(data, c(
                  "SAVID", "name",
                  
                  "Wallet Share last4FY Tot %", "Wallet last4FY Tot avg", "Wallet FY17 Tot", 
                  
                  "Tech Adoption %Early", "Tech Adoption %Late",
                  "Needs Based Segment", "Bargain Power Segment", 
                  "Partner Suppt Segment", 
                  
                  "Wallet Share last4FY EntNet %", "Wallet Share last4FY DC %", "Wallet Share last4FY Secur %",
                  "Wallet Share last4FY Collab %", "Wallet Share last4FY Svcs %", "Wallet Share last4FY SPtech %", "Wallet Share last4FY Others %",
                  
                  "Wallet 4FY %EntNet", "Wallet last4FY %DC", "Wallet last4FY %Secur",
                  "Wallet last4FY %Collab", "Wallet last4FY %Svcs", "Wallet last4FY %SPtech", "Wallet last4FY %Others",
                  
                  "Wallet FY17 %EntNet", "Wallet FY17 %DC", "Wallet FY17 %Secur",
                  "Wallet FY17 %Collab", "Wallet FY17 %Svcs", "Wallet FY17 %SPtech", "Wallet FY17 %Others",
                  "BIC Oppty FY17 Tot", "Stat Oppty FY17 Tot", "Gain Share as %of Wallet FY17",
                  
                  "Wallet FY18 Tot", "Wallet FY18 %EntNet", "Wallet FY18 %DC", "Wallet FY18 %Secur",
                  "Wallet FY18 %Collab", "Wallet FY18 %Svcs", "Wallet FY18 %SPtech", "Wallet FY18 %Others",
                  "BIC Oppty FY18 Tot", "Stat Oppty FY18 Tot", "Gain Share as %of Wallet FY18",
                  
                  "Partner Tier1 2FY %", "Partner Tier2 2FY %", "Partner TierSP 2FY %",
                  
                  "SAV TYPE", "SAV Vertical", "SAV Country", "SAV Segment",
                  
                  "Contacts # All", "Contacts %Active", "Contacts %Decision Makers", "Contacts %Business",
                  
                  "Targets # QtrlyMean 4Qs", "Targets Qtrly Growth%",
                  "Responses # QtrlyMean 4Qs", "Responses Qtrly Growth%",
                  "cco PageViews # QtrlyMean 4Qs", "cco PageViews Qtrly Growth%",
                  
                  "SFDC Opened$ QtrlyMean 4Qs", "SFDC Opened$ Qtrly Growth%",
                  "SFDC Booked$ QtrlyMean 4Qs", "SFDC Booked$ Qtrly Growth%",
                  "SFDC Lost$ QtrlyMean 4Qs", "SFDC Lost$ Qtrly Growth%",
                  "SFDC Opened# QtrlyMean 4Qs", "SFDC Opened# Qtrly Growth%",
                  "SFDC Booked# QtrlyMean 4Qs", "SFDC Booked# Qtrly Growth%",
                  "SFDC Lost# QtrlyMean 4Qs", "SFDC Lost# Qtrly Growth%",
                  
                  "P2B Score EntNet", "P2B Score DC", "P2B Score Secur", "P2B Score Collab",
                  "P2B Score Svcs", "P2B Score SPtech", "P2B Score Others", 
                  "P2B ExpBkgs EntNet", "P2B ExpBkgs DC", "P2B ExpBkgs Secur", "P2B ExpBkgs Collab", 
                  "P2B ExpBkgs Svcs", "P2B ExpBkgs SPtech","P2B ExpBkgs Others",
                  
                  "Sales_Level_1", "Sales_Level_2_key", "Sales_Level_3_key", "Sales_Level_4_key",  
                  "Sales_Level_5_key", "Sales_Level_6_key",
                  
                  "group"
                  ))
  
              #remove the FY18 wallet for now
              fy18cols <- c("Wallet FY18 %EntNet", "Wallet FY18 %DC", "Wallet FY18 %Secur",
                            "Wallet FY18 %Collab", "Wallet FY18 %Svcs", "Wallet FY18 %SPtech", "Wallet FY18 %Others",
                            "BIC Oppty FY18 Tot", "Stat Oppty FY18 Tot", "Gain Share as %of Wallet FY18")
              data[, (fy18cols) := NULL]
              
              data[, name := paste0(name, " (",SAVID,")")]
              
              ##### Calculate Cluster Averages:
              
              # for each group, get the means for columns that have a % in their name
              column_names = colnames(data)
              percent_cols = grep("%",colnames(data))
              percent_col_names = column_names[percent_cols]
              percent_data_ave <- data[, lapply(.SD, mean), by = group, .SDcols = percent_col_names]
              
              # for each group, get the sum for columns that are not in percent_cols and are numeric
              numeric_cols = column_names[sapply(data, is.numeric)]
              nonpercent_cols = column_names[-percent_cols]
              # remove anything with _key, SAVID
              sum_col_names = intersect(nonpercent_cols,numeric_cols) # exclude SAVID which is first col
              sum_col_names = sum_col_names[-grep("SAVID", sum_col_names)]
              sum_col_names_final = sum_col_names[-grep("_key", sum_col_names)]
              nonpercent_data_sum <- data[, lapply(.SD, mean), by = group, .SDcols = sum_col_names_final]
              
              # Create the mode function for string and numeric data types
              getmode <- function(v) {
                uniqv <- unique(v)
                uniqv[which.max(tabulate(match(v, uniqv)))]
              }
              # all other columns that are not in the above 2 groups, get the mode (mostly char column types)
              mode_col_names = setdiff(column_names, union(percent_col_names, sum_col_names_final))
              string_data_mode <- data[, lapply(.SD, getmode), by = group, .SDcols = mode_col_names]
              # remove the extra group
              string_data_mode[,group:=NULL]
              # set the ON clause as keys of the tables:
              setkey(nonpercent_data_sum,group)
              setkey(percent_data_ave,group)
              setkey(string_data_mode,group)
              
              # perform the join, eliminating not matched rows from Right
              join1 <- nonpercent_data_sum[percent_data_ave, nomatch=0]
              join2 <- join1[string_data_mode, nomatch=0] # this is the final cluster_data df
              join2[,name:=paste(group,"stats")]
              
              print("CLuster data")
              print(join2)
              # convert join2 to JSON
              cluster_data = toJSONArray(join2)
              
              # send this join2 to the server
                        
              fwrite(data, "www/fisheye/data/acct_data.csv")
              
              session$sendCustomMessage(type = "sendFishEyeData", cluster_data)
              
              # how many records in each cluster
              #data[ , .(.N) , by = group ][order(-N)]
              #print(head(data,4))
              
              #data_json = toJSONArray( data , json = FALSE)
              
              #print(dim(  DT[Sales_Level_4_key == sl4_key,] ))
              #print(data_json)
              
              #session$sendCustomMessage(type = "sendFishEyeData", data_json)
              
              value$show_iframe = 1
              # hide a status that we are preparing the data
              shinyjs::hide("prepping_data_status")
              shinyjs::show("show_pc_header")
              shinyjs::show("toHide")
              
              
          }
      }, ignoreNULL = FALSE)
      
      
      # output the Header/Title of the page which also states the status of the Parallel Coordinates App
      output$show_pc_header <- renderUI({
          if (value$show_iframe == 1) {
              h4("PaCEx - Parallel Coordinates Explorer")
          }
          else{
              # when no iframe is being displayed, state that the Data is Loading
              h4("Parallel Coordinates Explorer - Use filters to select accounts")
          }
          
      })
      
  }
  else{
     print("In CUstom server tab")
  }
 }) # end observeEvent for the Menu Item tab selected in the Ui 
    
}) # end of shinyServer()
