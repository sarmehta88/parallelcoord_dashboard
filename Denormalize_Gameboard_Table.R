require(data.table)
require(bit64)
#detach("package:bit64", unload=TRUE)

system.time(
  gb <- fread("gameboard_event_target_Q2FY17.csv")
)

dim(gb)
names(gb)
# [1] "rec_type"                         "SAVID"                            "SAV_TYPE"                        
# [4] "SAVName"                          "Sales_Level_1"                    "Sales_Level_2_key"               
# [7] "Sales_Level_3_key"                "Sales_Level_4_key"                "Sales_Level_5_key"               
# [10] "Sales_Level_6_key"                "Account_Manager"                  "SAV_Vertical"                    
# [13] "SAV_Country"                      "SAV_Segment"                      "Total_WS4FYs"                    
# [16] "Total_Bookings4FYs"               "Total_Wallet4FYs"                 "Total_WalletFY17"                
# [19] "Total_BICFY17"                    "Total_StatFY17"                   "Technology"                      
# [22] "Technology_WS4FYs"                "Technology_Bookings4FYs"          "Technology_Wallet4FYs"           
# [25] "Technology_BookingsFY17"          "Technology_BookingsFY18"          "Technology_WalletFY17"           
# [28] "Technology_WalletFY18"            "Technology_BICFY17"               "Technology_BICFY18"              
# [31] "Technology_StatFY17"              "Technology_StatFY18"              "Contacts_All"                    
# [34] "Contacts_Active_Emailable"        "Contacts_CCO_Userids"             "BP_CXOs"                         
# [37] "BP_Net_Atch_Infra"                "BP_DC_Server"                     "BP_Security"                     
# [40] "DM_BDM"                           "DM_TDM"                           "DM_B"                            
# [43] "DM_T"                             "MI_QTR_Date"                      "MI_Targets"                      
# [46] "MI_Resp"                          "CCO_Num_Pages"                    "SFDC_Active"                     
# [49] "SFDC_Active_Count"                "SFDC_Booked"                      "SFDC_Booked_Count"               
# [52] "SFDC_Lost_Canceled"               "SFDC_Lost_Canceled_Count"         "TA_StgA"                         
# [55] "TA_StgB"                          "TA_StgC"                          "Seg_Bargain_Power"               
# [58] "Seg_Partner_Support"              "Seg_Need_Segments"                "PC_Gold_Silver_BookingL2yrs"     
# [61] "PC_Select_Premier_BookingL2yrs"   "PC_None_BookingL2yrs"             "PC_Gold_Silver_Count"            
# [64] "PC_Select_Premier_Count"          "PC_None_Count"                    "PC_Type_DVAR_BookingL2yrs"       
# [67] "PC_Type_VAR_BookingL2yrs"         "PC_Type_SP_BookingL2yrs"          "PC_Type_Distributor_BookingL2yrs"
# [70] "PC_Type_DVAR_Count"               "PC_Type_VAR_Count"                "PC_Type_SP_Count"                
# [73] "PC_Type_Distributor_Count"        "Score"                            "ExpBkngsPriority" 

head(gb)
str(gb)

# SFDC_Active is being read as 'integer64'
gb[, SFDC_Active:=as.numeric(SFDC_Active)]
str(gb)

#max(gb[, SFDC_Active], na.rm = TRUE)
gb[, lapply(.SD, max, na.rm=TRUE)]

gb[SFDC_Active < 1, SFDC_Active := 0]

gb[Technology_Bookings4FYs > Technology_Wallet4FYs, Technology_Wallet4FYs := Technology_Bookings4FYs]
gb[Technology_Bookings4FYs == Technology_Wallet4FYs, Technology_WS4FYs := 1]

max(gb[, Technology_WS4FYs], na.rm = TRUE)

# reformat dollar values, no cents
gb[, Total_Bookings4FYs := round(Total_Bookings4FYs)]
gb[, Total_Wallet4FYs  := round(Total_Wallet4FYs )]
gb[, Total_WalletFY17 := round(Total_WalletFY17)]
gb[, Total_BICFY17 := round(Total_BICFY17)]
gb[, Total_StatFY17 := round(Total_StatFY17)]
gb[, Technology_Bookings4FYs := round(Technology_Bookings4FYs)]
gb[, Technology_Wallet4FYs := round(Technology_Wallet4FYs)]
gb[, Technology_BookingsFY17 := round(Technology_BookingsFY17)]
gb[, Technology_BookingsFY18 := round(Technology_BookingsFY18)]
gb[, Technology_WalletFY17 := round(Technology_WalletFY17)]
gb[, Technology_WalletFY18 := round(Technology_WalletFY18)]
gb[, Technology_BICFY17 := round(Technology_BICFY17)]
gb[, Technology_BICFY18 := round(Technology_BICFY18)]
gb[, Technology_StatFY17 := round(Technology_StatFY17)]
gb[, Technology_StatFY18 := round(Technology_StatFY18)]

gb[, SFDC_Active := round(SFDC_Active)]
gb[, SFDC_Booked := round(SFDC_Booked)]
gb[, SFDC_Lost_Canceled := round(SFDC_Lost_Canceled)]

gb[, PC_Gold_Silver_BookingL2yrs := round(PC_Gold_Silver_BookingL2yrs)]
gb[, PC_Select_Premier_BookingL2yrs := round(PC_Select_Premier_BookingL2yrs)]
gb[, PC_None_BookingL2yrs := round(PC_None_BookingL2yrs)]
gb[, PC_Type_DVAR_BookingL2yrs := round(PC_Type_DVAR_BookingL2yrs)]
gb[, PC_Type_VAR_BookingL2yrs := round(PC_Type_VAR_BookingL2yrs)]
gb[, PC_Type_SP_BookingL2yrs := round(PC_Type_SP_BookingL2yrs)]
gb[, PC_Type_Distributor_BookingL2yrs := round(PC_Type_Distributor_BookingL2yrs)]

gb[, ExpBkngsPriority := round(ExpBkngsPriority)]

# strTmp = c('Total_Bookings4FYs','Total_Wallet4FYs', 'Total_WalletFY17', 'Total_BICFY17', 'Total_StatFY17', 
#            'Technology_Bookings4FYs', 'Technology_Wallet4FYs', 'Technology_BookingsFY17', 'Technology_BookingsFY18',
#            'Technology_WalletFY17', 'Technology_WalletFY18', 'Technology_BICFY17', 'Technology_BICFY18',
#            'Technology_StatFY17', 'Technology_StatFY18', 'SFDC_Active', 'SFDC_Booked', 'SFDC_Lost_Canceled', ), 
# ind <- match(strTmp, names(gb))
# 
# for (i in seq_along(ind)) {
#     set(gb, NULL, ind[i], as.numeric(gb[[ind[i]]]))
# }

# now the percentages
gb[, Technology_WS4FYs := round(Technology_WS4FYs,4)]
gb[, Score := round(Score,4)]



#------------------------------------------------------------------------------
### WALLET RECORDS

# de-normalizing technology (long to wide) in W records
head(gb[rec_type == "W",])
Ws <- gb[rec_type == "W", .(SAVID, Technology, 
                            Technology_WS4FYs,  Technology_Wallet4FYs, #Technology_Bookings4FYs,
                            Technology_BookingsFY17, 
                            Technology_WalletFY17, Technology_BICFY17, Technology_StatFY17 
                            #,Technology_WalletFY18, Technology_BICFY18, Technology_StatFY18
                            ,Score, ExpBkngsPriority
)] # [1:1000]

# dCASTING - transpose long to wide 
Wwide <- dcast(Ws,  
               SAVID ~ Technology,           # id and vert are id vars (will be kept intact); 
               # technology  will be used to name value.vars 
               value.var = c('Technology_WS4FYs', 'Technology_Wallet4FYs', 
                             'Technology_BookingsFY17',
                             'Technology_WalletFY17',  'Technology_BICFY17', 'Technology_StatFY17',
                             "Score", "ExpBkngsPriority" ))   
head(Wwide)

# replace missing in numeric vars (and make sure they're positive)
replmiss <- function(dt) {
  numVars <- names(dt[, .SD, .SDcols = sapply(dt, is.numeric)])
  for (var in numVars) {
    set(dt, which(is.na(dt[[var]])), var, 0)
    set(dt, which(dt[[var]] < 0), var, 0)
  }
}

replmiss(Wwide)

Wwide <- Wwide[order(SAVID)]


head(Wwide)


#------------------------------------------------------------------------------
### INTERACTION RECORDS

Is <- gb[rec_type == "I",]
Is[MI_QTR_Date ==  "2015-08-01", Qtr := "FY16Q1"]
Is[MI_QTR_Date ==  "2015-11-01", Qtr := "FY16Q2"]
Is[MI_QTR_Date ==  "2016-02-01", Qtr := "FY16Q3"]
Is[MI_QTR_Date ==  "2016-05-01", Qtr := "FY16Q4"]
Is[MI_QTR_Date ==  "2016-08-01", Qtr := "FY17Q1"]
Is[MI_QTR_Date ==  "2016-11-01", Qtr := "FY17Q2"]
Is[MI_QTR_Date ==  "2017-02-01", Qtr := "FY17Q3"]
Is[MI_QTR_Date ==  "2017-05-01", Qtr := "FY17Q4"]
unique(Is$Qtr)
head(Is)


Is <- Is[order(SAVID, Qtr)]

# calculate average and slope (as a % of average) of quarterly data
# assumes there's only 4 qtrs with data:

targets <- Is[, 
              {   # some aux calculations
                ux <- mean(1:4)
                uy <- mean(MI_Targets)
                slope <- sum((1:4 - ux) * (MI_Targets - uy)) / sum((1:4 - ux) ^ 2)
                
                # now here's what will be returned
                list(#slope = round(slope), 
                  #intercept = uy - slope * ux,
                  Targets_QMeanLast4Qs = round(uy), # mean
                  Targets_pctGrowth = ifelse(uy == 0, 0, round(slope/uy,3)) )
              }, by=SAVID ]

# check for missings
for (j in names(targets))
  print(paste(sum( is.na(targets[[j]]) ), 'missings in', j))

resps <- Is[, 
            {   # some aux calculations
              ux <- mean(1:4)
              uy <- mean(MI_Resp)
              slope <- sum((1:4 - ux) * (MI_Resp - uy)) / sum((1:4 - ux) ^ 2)
              
              # now here's what will be returned
              list(#slope = round(slope), 
                #intercept = uy - slope * ux,
                Resps_QMeanLast4Qs = round(uy), # mean
                Resps_pctGrowth = ifelse(uy == 0, 0, round(slope/uy,3)) )
            }, by=SAVID ]

# check for missings
for (j in names(resps))
  print(paste(sum( is.na(resps[[j]]) ), 'missings in', j))

ccoPgs <- Is[, 
             {   # some aux calculations
               ux <- mean(1:4)
               uy <- mean(CCO_Num_Pages)
               slope <- sum((1:4 - ux) * (CCO_Num_Pages - uy)) / sum((1:4 - ux) ^ 2)
               
               # now here's what will be returned
               list(#slope = round(slope), 
                 #intercept = uy - slope * ux,
                 ccoPgs_QMeanLast4Qs = round(uy), # mean
                 ccoPgs_pctGrowth = ifelse(uy == 0, 0, round(slope/uy,3)) )
             }, by=SAVID ]

# check for missings
for (j in names(ccoPgs))
  print(paste(sum( is.na(ccoPgs[[j]]) ), 'missings in', j))

SFDC_ActiveUSD <- Is[, 
                     {   # some aux calculations
                       ux <- mean(1:4)
                       uy <- mean(SFDC_Active)
                       slope <- sum((1:4 - ux) * (SFDC_Active - uy)) / sum((1:4 - ux) ^ 2)
                       
                       # now here's what will be returned
                       list(#slope = round(slope), 
                         #intercept = uy - slope * ux,
                         SFDCActvUSD_QMeanLast4Qs = round(uy), # mean
                         SFDCActvUSD_pctGrowth = ifelse(uy == 0, 0, round(slope/uy,3)) )
                     }, by=SAVID ]

# check for missings
for (j in names(SFDC_ActiveUSD))
  print(paste(sum( is.na(SFDC_ActiveUSD[[j]]) ), 'missings in', j))

SFDC_BookedUSD <- Is[, 
                     {   # some aux calculations
                       ux <- mean(1:4)
                       uy <- mean(SFDC_Booked)
                       slope <- sum((1:4 - ux) * (SFDC_Booked - uy)) / sum((1:4 - ux) ^ 2)
                       
                       # now here's what will be returned
                       list(#slope = round(slope), 
                         #intercept = uy - slope * ux,
                         SFDCBookdUSD_QMeanLast4Qs = round(uy), # mean
                         SFDCBookdUSD_pctGrowth = ifelse(uy == 0, 0, round(slope/uy,3)) )
                     }, by=SAVID ]

# check for missings
for (j in names(SFDC_BookedUSD))
  print(paste(sum( is.na(SFDC_BookedUSD[[j]]) ), 'missings in', j))

SFDC_LostUSD <- Is[, 
                   {   # some aux calculations
                     ux <- mean(1:4)
                     uy <- mean(SFDC_Lost_Canceled)
                     slope <- sum((1:4 - ux) * (SFDC_Lost_Canceled - uy)) / sum((1:4 - ux) ^ 2)
                     
                     # now here's what will be returned
                     list(#slope = round(slope), 
                       #intercept = uy - slope * ux,
                       SFDCLostUSD_QMeanLast4Qs = round(uy), # mean
                       SFDCLostUSD_pctGrowth = ifelse(uy == 0, 0, round(slope/uy,3)) )
                   }, by=SAVID ]

# check for missings
for (j in names(SFDC_LostUSD))
  print(paste(sum( is.na(SFDC_LostUSD[[j]]) ), 'missings in', j))

SFDC_ActiveCt <- Is[, 
                    {   # some aux calculations
                      ux <- mean(1:4)
                      uy <- mean(SFDC_Active_Count)
                      slope <- sum((1:4 - ux) * (SFDC_Active_Count - uy)) / sum((1:4 - ux) ^ 2)
                      
                      # now here's what will be returned
                      list(#slope = round(slope), 
                        #intercept = uy - slope * ux,
                        SFDCActvCt_QMeanLast4Qs = round(uy), # mean
                        SFDCActvCt_pctGrowth = ifelse(uy == 0, 0, round(slope/uy,3)) )
                    }, by=SAVID ]

# check for missings
for (j in names(SFDC_ActiveCt))
  print(paste(sum( is.na(SFDC_ActiveCt[[j]]) ), 'missings in', j))

SFDC_BookedCt <- Is[, 
                    {   # some aux calculations
                      ux <- mean(1:4)
                      uy <- mean(SFDC_Booked_Count)
                      slope <- sum((1:4 - ux) * (SFDC_Booked_Count - uy)) / sum((1:4 - ux) ^ 2)
                      
                      # now here's what will be returned
                      list(#slope = round(slope), 
                        #intercept = uy - slope * ux,
                        SFDCBookdCt_QMeanLast4Qs = round(uy), # mean
                        SFDCBookdCt_pctGrowth = ifelse(uy == 0, 0, round(slope/uy,3)) )
                    }, by=SAVID ]

# check for missings
for (j in names(SFDC_BookedCt))
  print(paste(sum( is.na(SFDC_BookedCt[[j]]) ), 'missings in', j))

SFDC_LostCt <- Is[, 
                  {   # some aux calculations
                    ux <- mean(1:4)
                    uy <- mean(SFDC_Lost_Canceled_Count)
                    slope <- sum((1:4 - ux) * (SFDC_Lost_Canceled_Count - uy)) / sum((1:4 - ux) ^ 2)
                    
                    # now here's what will be returned
                    list(#slope = round(slope), 
                      #intercept = uy - slope * ux,
                      SFDCLostCt_QMeanLast4Qs = round(uy), # mean
                      SFDCLostCt_pctGrowth = ifelse(uy == 0, 0, round(slope/uy,3)) )
                  }, by=SAVID ]

# check for missings
for (j in names(SFDC_LostCt))
  print(paste(sum( is.na(SFDC_LostCt[[j]]) ), 'missings in', j))


# dCASTING - transpose long to wide 
#Iwide <- dcast(Is, 
#               SAVID ~ Qtr,           # id and vert are id vars (will be kept intact); 
#               # Qtr  will be used to name value.vars 
#               value.var = c('MI_Targets', 'MI_Resp', 'CCO_Num_Pages', 
#                             'SFDC_Active', 'SFDC_Booked', 'SFDC_Lost_Canceled' ))   
#head(Iwide)




replmiss(Iwide)


#------------------------------------------------------------------------------
### C Records: CONTACT, PERSONAS / INTERACTIONS / TOTAL WALLET & BKNGS / TECH ADOPTION / PARTNER

Cs <- gb[rec_type == "C",
         .(SAVID, SAV_TYPE, SAVName, SAV_Vertical, SAV_Country, SAV_Segment, 
           Sales_Level_1, Sales_Level_2_key, Sales_Level_3_key,
           Sales_Level_4_key, Sales_Level_5_key, Sales_Level_6_key, 
           Total_WS4FYs, Total_Wallet4FYs, 
           Total_WalletFY17, Total_BICFY17, Total_StatFY17,
           Contacts_All, Contacts_Active_Emailable, Contacts_CCO_Userids,
           DM_BDM, DM_TDM, DM_B, DM_T,
           BP_CXOs, BP_Net_Atch_Infra, BP_DC_Server, BP_Security, 
           TA_StgA, TA_StgB, TA_StgC,
           PC_Gold_Silver_BookingL2yrs, PC_Select_Premier_BookingL2yrs, PC_None_BookingL2yrs,
           PC_Gold_Silver_Count, PC_Select_Premier_Count, PC_None_Count,
           PC_Type_DVAR_BookingL2yrs, PC_Type_VAR_BookingL2yrs, PC_Type_SP_BookingL2yrs, PC_Type_Distributor_BookingL2yrs,
           PC_Type_DVAR_Count, PC_Type_VAR_Count, PC_Type_SP_Count, PC_Type_Distributor_Count,
           Seg_Bargain_Power, Seg_Partner_Support, Seg_Need_Segments
         )]

replmiss(Cs)

# vars <- names(Cs)
# numVars <- setdiff(vars, c("SAVID",              "SAV_TYPE",          "SAVName",                         
#                            "SAV_Vertical",       "SAV_Country",       "SAV_Segment",                     
#                            "Sales_Level_1",      "Sales_Level_2_key", "Sales_Level_3_key",               
#                            "Sales_Level_4_key",  "Sales_Level_5_key", "Sales_Level_6_key" ) )
# 
# # replace missing
# for (var in numVars)
#     set(Cs, which(is.na(Cs[[var]])), var, 0)


# create some metrics for contact data
Cs[, contacts_pct_active := ifelse(Contacts_All == 0, 0, round(Contacts_Active_Emailable/Contacts_All,2))]

# sum of DMs do not match Contacts_All  apparently
Cs[, allContacts := (DM_BDM + DM_TDM + DM_B + DM_T)]

Cs[, contacts_pct_decMakers := ifelse(allContacts  ==0, 0, round((DM_BDM + DM_TDM)/allContacts,2))]
Cs[, contacts_pct_business := ifelse(allContacts  ==0, 0, round((DM_BDM + DM_B)/allContacts,2))]

Cs[, allContacts := NULL]


# create some metrics for partners
Cs[, allTiers := (PC_Type_DVAR_BookingL2yrs + 
                    PC_Type_VAR_BookingL2yrs +
                    PC_Type_SP_BookingL2yrs +
                    PC_Type_Distributor_BookingL2yrs)]

Cs[, pTier1_2fys_pct := ifelse(allTiers == 0, 0, round(PC_Type_DVAR_BookingL2yrs / allTiers, 2))]

Cs[, pTier2_2fys_pct := ifelse(allTiers == 0, 0, 
                               round((PC_Type_VAR_BookingL2yrs + PC_Type_Distributor_BookingL2yrs) / 
                                       allTiers, 2))]

Cs[, pTierSP_2fys_pct := ifelse(allTiers == 0, 0, 
                                round(PC_Type_DVAR_BookingL2yrs / allTiers,2))]

Cs[, allTiers := NULL]


# create some metrics for Tech Adoption
Cs[, allStg := TA_StgA + TA_StgB + TA_StgC]

Cs[, techAdopt_early_pct := ifelse(allStg == 0, 0, round(TA_StgA / allStg, 2))]
Cs[, techAdopt_late_pct  := ifelse(allStg == 0, 0, round(TA_StgC / allStg, 2))]

Cs[, allStg := NULL]


# create some metrics for Tech Adoption
Cs[, Bargain_Power := ifelse(Seg_Bargain_Power == 'Hig', '1-Hi', 
                             ifelse(Seg_Bargain_Power == 'Med', '2-Med', '3-Low'))]

Cs[, Seg_Need_Segments := ifelse(Seg_Need_Segments == 'E', 'IntgSeek',  # Integration Seekers
                                 ifelse(Seg_Need_Segments == 'I', 'ITStrat',   # IT Strategists
                                        ifelse(Seg_Need_Segments == 'M', 'Mainstr',   # Mainstream Buyer
                                               ifelse(Seg_Need_Segments == 'L', 'LowPrice',  # Low Price Seeker
                                                      ifelse(Seg_Need_Segments == 'R', 'RelatRel',  # Relationship Reliant
                                                             'NA')))))]    # not known


#Needs Based Segmentation: E=IntegrSeek, I=ITStrat, M=Mainstream, R=RelatReli, L=LowPrice, N=NA
# Cs[, NeedsSeg_IntSeek := ifelse(Seg_Need_Segments == 'E', 1L, 0L)]
# Cs[, NeedsSeg_ITStrat := ifelse(Seg_Need_Segments == 'I', 1L, 0L)]
# Cs[, NeedsSeg_MainStr := ifelse(Seg_Need_Segments == 'M', 1L, 0L)]
# Cs[, NeedsSeg_LowPric := ifelse(Seg_Need_Segments == 'L', 1L, 0L)]
# Cs[, NeedsSeg_RelatReli := ifelse(Seg_Need_Segments == 'R', 1L, 0L)]
# Cs[, Seg_Need_Segments := NULL]

Cs <- Cs[order(SAVID)]


#------------------------------------------------------------------------------
### Merge C's, Wwide's and Iwide's
dim(Cs)
dim(Wwide)
#dim(Iwide)
dim(targets)
dim(resps)
dim(ccoPgs)
dim(SFDC_ActiveUSD) 
dim(SFDC_BookedUSD)
dim(SFDC_LostUSD)
dim(SFDC_ActiveCt)
dim(SFDC_BookedCt)
dim(SFDC_LostCt)


setkey(Cs, SAVID)
setkey(Wwide, SAVID)
#setkey(Iwide, SAVID)
setkey(targets, SAVID)
setkey(resps, SAVID)
setkey(ccoPgs, SAVID)
setkey(SFDC_ActiveUSD, SAVID) 
setkey(SFDC_BookedUSD, SAVID)
setkey(SFDC_LostUSD, SAVID)
setkey(SFDC_ActiveCt, SAVID)
setkey(SFDC_BookedCt, SAVID)
setkey(SFDC_LostCt, SAVID)


# left join merge
Out <- merge(Cs, Wwide, all.x=TRUE); dim(Out)
Out <- merge(Out, targets, all.x=TRUE); dim(Out)
Out <- merge(Out, resps, all.x=TRUE); dim(Out)
Out <- merge(Out, ccoPgs, all.x=TRUE); dim(Out)
Out <- merge(Out, SFDC_ActiveUSD, all.x=TRUE); dim(Out)
Out <- merge(Out, SFDC_BookedUSD, all.x=TRUE); dim(Out)
Out <- merge(Out, SFDC_LostUSD, all.x=TRUE); dim(Out)
Out <- merge(Out, SFDC_ActiveCt, all.x=TRUE); dim(Out)
Out <- merge(Out, SFDC_BookedCt, all.x=TRUE); dim(Out)
Out <- merge(Out, SFDC_LostCt, all.x=TRUE); dim(Out)


#Out <- merge(Out, Iwide, all.x=TRUE)
#dim(Out)

head(Out)


### quick validation:
Out[SAVID == 273894936, 
    .(Technology_Wallet4FYs_COLLAB, Technology_Wallet4FYs_DC, Technology_Wallet4FYs_ENTNET, 
      Technology_Wallet4FYs_OTHERS, Technology_Wallet4FYs_SECURITY, 
      Technology_Wallet4FYs_SERVICES, Technology_Wallet4FYs_SP)]

#------------------------------------------------------------------------------
### Merge C's, Wwide's and Iwide's
fwrite(Out, "parcoord_data.csv")


test <- fread("parcoord_data.csv")
test[SAVID == 273894936, 
     .(Technology_Wallet4FYs_COLLAB, Technology_Wallet4FYs_DC, Technology_Wallet4FYs_ENTNET, 
       Technology_Wallet4FYs_OTHERS, Technology_Wallet4FYs_SECURITY, 
       Technology_Wallet4FYs_SERVICES, Technology_Wallet4FYs_SP)]
