### prepare the data for parcoord
require(bit64)
require(data.table)

dt <- fread("data/parcoord_data.csv")
str(dt)

# quick quality check (without bit64 package, next command will not print large values correctly)
dt[SAVID == 273894936, 
   .(Technology_Wallet4FYs_COLLAB, Technology_Wallet4FYs_DC, Technology_Wallet4FYs_ENTNET, 
     Technology_Wallet4FYs_OTHERS, Technology_Wallet4FYs_SECURITY, 
     Technology_Wallet4FYs_SERVICES, Technology_Wallet4FYs_SP)]

max(dt[, Technology_Wallet4FYs_SP])
# SFDC_Active is being read as 'integer64'
cols64 <- names(dt[1, .SD, .SDcols = sapply(dt, is.integer64)])
for (col in cols64)
  dt[ , (col) := as.numeric( get(col) )]

str(dt)

# just to make sure there's no integer overflow
dt[, Technology_Wallet4FYs_COLLAB   := as.numeric(Technology_Wallet4FYs_COLLAB)]
dt[, Technology_Wallet4FYs_DC       := as.numeric(Technology_Wallet4FYs_DC)]
dt[, Technology_Wallet4FYs_ENTNET   := as.numeric(Technology_Wallet4FYs_ENTNET)]
dt[, Technology_Wallet4FYs_SECURITY := as.numeric(Technology_Wallet4FYs_SECURITY)]
dt[, Technology_Wallet4FYs_SERVICES := as.numeric(Technology_Wallet4FYs_SERVICES)]
dt[, Technology_Wallet4FYs_SP       := as.numeric(Technology_Wallet4FYs_SP)]
dt[, Technology_Wallet4FYs_OTHERS   := as.numeric(Technology_Wallet4FYs_OTHERS)]

dt[, Total_Wallet4FYs   := as.numeric(Total_Wallet4FYs)]
dt[, Total_WalletFY17   := as.numeric(Total_WalletFY17)]
dt[, Total_BICFY17      := as.numeric(Total_BICFY17)]
dt[, Total_StatFY17     := as.numeric(Total_StatFY17)]
dt[, Total_WalletFY18   := as.numeric(Total_WalletFY18)]
dt[, Total_BICFY18      := as.numeric(Total_BICFY18)]
dt[, Total_StatFY18     := as.numeric(Total_StatFY18)]

# change the way we express Wallet for techs: now use % of total wallet
dt[, Wal4FYs_pct_EntNet := ifelse(Total_Wallet4FYs == 0, 0, round(Technology_Wallet4FYs_ENTNET   / Total_Wallet4FYs, 2))]
dt[, Wal4FYs_pct_DC     := ifelse(Total_Wallet4FYs == 0, 0, round(Technology_Wallet4FYs_DC       / Total_Wallet4FYs, 2))]
dt[, Wal4FYs_pct_Secur  := ifelse(Total_Wallet4FYs == 0, 0, round(Technology_Wallet4FYs_SECURITY / Total_Wallet4FYs, 2))]
dt[, Wal4FYs_pct_Collab := ifelse(Total_Wallet4FYs == 0, 0, round(Technology_Wallet4FYs_COLLAB   / Total_Wallet4FYs, 2))]
dt[, Wal4FYs_pct_Svcs   := ifelse(Total_Wallet4FYs == 0, 0, round(Technology_Wallet4FYs_SERVICES / Total_Wallet4FYs, 2))]
dt[, Wal4FYs_pct_SPtech := ifelse(Total_Wallet4FYs == 0, 0, round(Technology_Wallet4FYs_SP       / Total_Wallet4FYs, 2))]
dt[, Wal4FYs_pct_Others := ifelse(Total_Wallet4FYs == 0, 0, round(Technology_Wallet4FYs_OTHERS   / Total_Wallet4FYs, 2))]

dt[, WalFY17_pct_EntNet := ifelse(Total_WalletFY17 == 0, 0, round(Technology_WalletFY17_ENTNET   / Total_WalletFY17, 2))]
dt[, WalFY17_pct_DC     := ifelse(Total_WalletFY17 == 0, 0, round(Technology_WalletFY17_DC       / Total_WalletFY17, 2))]
dt[, WalFY17_pct_Secur  := ifelse(Total_WalletFY17 == 0, 0, round(Technology_WalletFY17_SECURITY / Total_WalletFY17, 2))]
dt[, WalFY17_pct_Collab := ifelse(Total_WalletFY17 == 0, 0, round(Technology_WalletFY17_COLLAB   / Total_WalletFY17, 2))]
dt[, WalFY17_pct_Svcs   := ifelse(Total_WalletFY17 == 0, 0, round(Technology_WalletFY17_SERVICES / Total_WalletFY17, 2))]
dt[, WalFY17_pct_SPtech := ifelse(Total_WalletFY17 == 0, 0, round(Technology_WalletFY17_SP       / Total_WalletFY17, 2))]
dt[, WalFY17_pct_Others := ifelse(Total_WalletFY17 == 0, 0, round(Technology_WalletFY17_OTHERS   / Total_WalletFY17, 2))]

dt[, WalFY18_pct_EntNet := ifelse(Total_WalletFY18 == 0, 0, round(Technology_WalletFY18_ENTNET   / Total_WalletFY18, 2))]
dt[, WalFY18_pct_DC     := ifelse(Total_WalletFY18 == 0, 0, round(Technology_WalletFY18_DC       / Total_WalletFY18, 2))]
dt[, WalFY18_pct_Secur  := ifelse(Total_WalletFY18 == 0, 0, round(Technology_WalletFY18_SECURITY / Total_WalletFY18, 2))]
dt[, WalFY18_pct_Collab := ifelse(Total_WalletFY18 == 0, 0, round(Technology_WalletFY18_COLLAB   / Total_WalletFY18, 2))]
dt[, WalFY18_pct_Svcs   := ifelse(Total_WalletFY18 == 0, 0, round(Technology_WalletFY18_SERVICES / Total_WalletFY18, 2))]
dt[, WalFY18_pct_SPtech := ifelse(Total_WalletFY18 == 0, 0, round(Technology_WalletFY18_SP       / Total_WalletFY18, 2))]
dt[, WalFY18_pct_Others := ifelse(Total_WalletFY18 == 0, 0, round(Technology_WalletFY18_OTHERS   / Total_WalletFY18, 2))]

# for now use the vertical as group - eventually use a cluster on principal components
#dt[, group := SAV_Vertical]

setnames(dt, "SAVName", "name")

setnames(dt, "Technology_WS4FYs_ENTNET", "WS4FYs_EntNet")
setnames(dt, "Technology_WS4FYs_DC", "WS4FYs_DC")
setnames(dt, "Technology_WS4FYs_SECURITY", "WS4FYs_Secur")
setnames(dt, "Technology_WS4FYs_COLLAB", "WS4FYs_Collab")
setnames(dt, "Technology_WS4FYs_SERVICES", "WS4FYs_Svcs")
setnames(dt, "Technology_WS4FYs_SP", "WS4FYs_SPtech")
setnames(dt, "Technology_WS4FYs_OTHERS", "WS4FYs_Others")

setnames(dt, "Total_WS4FYs", "WS4FYs_Total")
setnames(dt, "Total_Wallet4FYs", "Wal4FYs_Total")
setnames(dt, "Total_WalletFY17", "WalFY17_Total")
setnames(dt, "Total_BICFY17", "BICFY17_Total")
setnames(dt, "Total_StatFY17", "StatFY17_Total")
setnames(dt, "Total_WalletFY18", "WalFY18_Total")
setnames(dt, "Total_BICFY18", "BICFY18_Total")
setnames(dt, "Total_StatFY18", "StatFY18_Total")

setnames(dt, "ExpBkngsPriority_ENTNET", "ExpBkgs_EntNet")
setnames(dt, "ExpBkngsPriority_DC", "ExpBkgs_DC")
setnames(dt, "ExpBkngsPriority_SECURITY", "ExpBkgs_Secur")
setnames(dt, "ExpBkngsPriority_COLLAB", "ExpBkgs_Collab")
setnames(dt, "ExpBkngsPriority_SERVICES", "ExpBkgs_Svcs")
setnames(dt, "ExpBkngsPriority_SP", "ExpBkgs_SPtech")
setnames(dt, "ExpBkngsPriority_OTHERS", "ExpBkgs_Others")

setnames(dt, "Score_ENTNET", "Score_EntNet")
setnames(dt, "Score_DC", "Score_DC")
setnames(dt, "Score_SECURITY", "Score_Secur")
setnames(dt, "Score_COLLAB", "Score_Collab")
setnames(dt, "Score_SERVICES", "Score_Svcs")
setnames(dt, "Score_SP", "Score_SPtech")
setnames(dt, "Score_OTHERS", "Score_Others")

setnames(dt, "Seg_Need_Segments", "Needs_Segment")
setnames(dt, "Bargain_Power", "BargainPower_Segment")
setnames(dt, "Seg_Partner_Support", "PartnerSuppt_Segment")


# here the order matters as that's how the parcoord shows the vars

vars <- c(
  "SAVID", "name",  
  
  "WS4FYs_Total", 
  "WS4FYs_EntNet", "WS4FYs_DC", "WS4FYs_Secur", "WS4FYs_Collab", "WS4FYs_Svcs", "WS4FYs_SPtech", "WS4FYs_Others",  
  
  "Wal4FYs_Total",   
  "Wal4FYs_pct_EntNet", "Wal4FYs_pct_DC", "Wal4FYs_pct_Secur", "Wal4FYs_pct_Collab", "Wal4FYs_pct_Svcs", "Wal4FYs_pct_SPtech", "Wal4FYs_pct_Others",
  
  "WalFY17_Total", 
  "WalFY17_pct_EntNet", "WalFY17_pct_DC", "WalFY17_pct_Secur", "WalFY17_pct_Collab", "WalFY17_pct_Svcs", "WalFY17_pct_SPtech", "WalFY17_pct_Others",
  
  "BICFY17_Total", "StatFY17_Total", 
  
  "WalFY18_Total", 
  "WalFY18_pct_EntNet", "WalFY18_pct_DC", "WalFY18_pct_Secur", "WalFY18_pct_Collab", "WalFY18_pct_Svcs", "WalFY18_pct_SPtech", "WalFY18_pct_Others",
  
  "BICFY18_Total", "StatFY18_Total", 

  "techAdopt_early_pct", "techAdopt_late_pct", 
  "Needs_Segment", "BargainPower_Segment", "PartnerSuppt_Segment",
  
  "pTier1_2fys_pct", "pTier2_2fys_pct", "pTierSP_2fys_pct", 
  
  "SAV_TYPE", "SAV_Vertical", "SAV_Country", "SAV_Segment",   
  
  "Contacts_All", "contacts_pct_active", "contacts_pct_decMakers", "contacts_pct_business", 
  
  "Targets_QMeanLast4Qs", "Targets_pctGrowth", 
  "Resps_QMeanLast4Qs", "Resps_pctGrowth", 
  "ccoPgs_QMeanLast4Qs", "ccoPgs_pctGrowth", 
  "SFDCOpendUSD_QMeanLast4Qs", "SFDCOpendUSD_pctGrowth", 
  "SFDCBookdUSD_QMeanLast4Qs", "SFDCBookdUSD_pctGrowth" ,         
  "SFDCLostUSD_QMeanLast4Qs", "SFDCLostUSD_pctGrowth",
  "SFDCOpendCt_QMeanLast4Qs", "SFDCOpendCt_pctGrowth", 
  "SFDCBookdCt_QMeanLast4Qs", "SFDCBookdCt_pctGrowth",
  "SFDCLostCt_QMeanLast4Qs", "SFDCLostCt_pctGrowth",

    #"NeedsSeg_IntSeek", "NeedsSeg_ITStrat", "NeedsSeg_MainStr", "NeedsSeg_LowPric", "NeedsSeg_RelatReli", 
  
  "Score_EntNet", "Score_DC", "Score_Secur", "Score_Collab", "Score_Svcs", "Score_SPtech", "Score_Others",
  "ExpBkgs_EntNet", "ExpBkgs_DC", "ExpBkgs_Secur", "ExpBkgs_Collab", "ExpBkgs_Svcs", "ExpBkgs_SPtech", "ExpBkgs_Others",
  
  "Sales_Level_1", "Sales_Level_2_key", "Sales_Level_3_key", 
  "Sales_Level_4_key", "Sales_Level_5_key", "Sales_Level_6_key"

   #,"group"
)

# remove (25) records that in vQ2FY17 had issues in the wallet share 
dim(dt)
nrow(dt[ !(WS4FYs_Total <= 1  & WS4FYs_EntNet <= 1 & WS4FYs_DC <= 1     & WS4FYs_Secur <= 1 & 
        WS4FYs_Collab <= 1 & WS4FYs_Svcs <= 1   & WS4FYs_SPtech <= 1 & WS4FYs_Others <= 1)  ,]) 
dt <- dt[ WS4FYs_Total <= 1  & WS4FYs_EntNet <= 1 & WS4FYs_DC <= 1     & WS4FYs_Secur <= 1 & 
            WS4FYs_Collab <= 1 & WS4FYs_Svcs <= 1   & WS4FYs_SPtech <= 1 & WS4FYs_Others <= 1  ,]  
dim(dt)

# for testing purposes
# dt[ , .(.N) , by = Sales_Level_4_key ][order(-N)]

dt <- dt[, (vars), with=F]
dim(dt)

# dt <- dt[1:100000, (vars), with=F]
# data <- dt[ Sales_Level_4_key == 83,]

# NOTE - the following variables should have LOG SCALE:
# Wal4FYs_Total, Total_BICFY17, Total_StatFY17 Contacts_All



### fix issues with caracter encoding that is hurting the javascript portion

remdia <- function(oldchar, newchar, x) {
  # remove diacritics
  t <- grepl(oldchar, x); 
  print(paste(sum(t), 'rows with', oldchar, 'found and changed to', newchar))
  return(gsub(oldchar, newchar, x))
}

names <- dt[,name]
print(head(names))

# "XP INVESTIMENTOS CORRETORA DE CAMBIO TITULOS E VALORES MOBILIA\032RIOS SA":
#print(dt[SAVID == 222472614, name])

# some of the issues
#troublemakers <- c(122930, 144629, 269668, 285783, 402263, 402278, 402286, 150528)
#print(names[troublemakers])
# names[troublemakers]
# 
# tt <- names[troublemakers]
# Encoding(tt) <- "UTF-8"
# Encoding(tt) <- "latin1"
# tt



Encoding(names) <- "latin1"

# x <- grepl('\xc3\032', names); names[which(x)]
# troublemakers <- which(x)
# x <- grepl('\\xc3\\x81', names); names[which(x)]
# troublemakers <- c(which(x), troublemakers)
# x <- grepl('\\xc3\\x87', names); names[which(x)]
# troublemakers <- c(which(x), troublemakers)


#names <- gsub("\\xc3\\x80", "A", names)
names <- remdia("\\xc3\\x80", "A", names)
names <- remdia("\\xc3\\x81", "A", names)
names <- remdia("\\xc3\\x82", "A", names)
names <- remdia("\\xc3\\x83", "A", names)
names <- remdia("\\xc3\\x84", "A", names)
names <- remdia("\\xc3\\x85", "A", names)

names <- remdia("\\xc3\\x87", "C", names)

names <- remdia("\\xc3\\x88", "E", names)
names <- remdia("\\xc3\\x89", "E", names)
names <- remdia("\\xc3\\x8a", "E", names)
names <- remdia("\\xc3\\x8b", "E", names)

names <- remdia("\\xc3\\x8c", "I", names)
names <- remdia("\\xc3\\x8d", "I", names)
names <- remdia("\\xc3\\x8e", "I", names)
names <- remdia("\\xc3\\x8f", "I", names)

names <- remdia("\\xc3\\x92", "O", names)
names <- remdia("\\xc3\\x93", "O", names)
names <- remdia("\\xc3\\x94", "O", names)
names <- remdia("\\xc3\\x95", "O", names)
names <- remdia("\\xc3\\x96", "O", names)
names <- remdia("\\xc3\\x98", "O", names)

names <- remdia("\\xc3\\x99", "U", names)
names <- remdia("\\xc3\\x9a", "U", names)
names <- remdia("\\xc3\\x9b", "U", names)
names <- remdia("\\xc3\\x9c", "U", names)

names <- remdia("\\xc3\\x9f", "SS", names)

names <- remdia("\\xc3\\xa0", "a", names)
names <- remdia("\\xc3\\xa1", "a", names)
names <- remdia("\\xc3\\xa2", "a", names)
names <- remdia("\\xc3\\xa3", "a", names)
names <- remdia("\\xc3\\xa4", "a", names)
names <- remdia("\\xc3\\xa5", "a", names)
names <- remdia("\\xc3\\xa6", "a", names)

names <- remdia("\\xc3\\xa7", "c", names)

names <- remdia("\\xc3\\xa8", "e", names)
names <- remdia("\\xc3\\xa9", "e", names)
names <- remdia("\\xc3\\xaa", "e", names)
names <- remdia("\\xc3\\xab", "e", names)

names <- remdia("\\xc3\\xac", "i", names)
names <- remdia("\\xc3\\xad", "i", names)
names <- remdia("\\xc3\\xae", "i", names)
names <- remdia("\\xc3\\xaf", "i", names)

names <- remdia("\\xc3\\xb2", "o", names)
names <- remdia("\\xc3\\xb3", "o", names)
names <- remdia("\\xc3\\xb4", "o", names)
names <- remdia("\\xc3\\xb5", "o", names)
names <- remdia("\\xc3\\xb6", "o", names)
names <- remdia("\\xc3\\xb8", "o", names)

names <- remdia("\\xc3\\xb9", "u", names)
names <- remdia("\\xc3\\xba", "u", names)
names <- remdia("\\xc3\\xbb", "u", names)
names <- remdia("\\xc3\\xbc", "u", names)

#print(names[troublemakers])

print(dt[grep("XP INVESTIMENTOS", names), .(SAVID,name)])

## fix "XP INVESTIMENTOS CORRETORA DE CAMBIO TITULOS E VALORES MOBILIA\032RIOS SA"
names <- remdia("\032", "", names)

dt[, name:= names]
print(dt[grep("XP INVESTIMENTOS", names), .(SAVID,name)])


nrow(dt[is.na(Needs_Segment),])
dt[is.na(Needs_Segment), Needs_Segment := "N/A"]

nrow(dt[is.na(PartnerSuppt_Segment),])
nrow(dt[PartnerSuppt_Segment == "",])
dt[is.na(PartnerSuppt_Segment), PartnerSuppt_Segment := "N/A"]
dt[PartnerSuppt_Segment == "", PartnerSuppt_Segment := "N/A"]

#nrow(dt[BargainPower_Segment == "",])


fwrite(dt,"data/parcoord_data_prep.csv")




###----------------------------------------------------------------------------
# some validation:
summary(dt[, !names(dt) %in% c("SAVID", "name", "group", "Sales_Level_1",
                               "Sales_Level_2_key", "Sales_Level_3_key",
                               "Sales_Level_4_key", "Sales_Level_5_key",
                               "Sales_Level_6_key", "SAV_TYPE", "SAV_Vertical",
                               "SAV_Country", "SAV_Segment", "Bargain_Power",
                               "Seg_Partner_Support", "Wal4FYs_pct_SPtech", 
                               "Score_Svcs", "Score_SPtech", "ExpBkgs_Svcs", 
                               "ExpBkgs_SPtech"), with=FALSE])

# there should not be any row here:
head(dt[WS4FYs_Others > 1,], 40)





###----------------------------------------------------------------------------
### treats Sales Hierarchy levels and keys
sl <- fread("data/sav_levels_keys_Q2FY17.csv")

sl[,SAVID := NULL]
dim(sl)

sl <- unique(sl)
dim(sl)

fwrite(sl, "data/sales_levels_keys_Q2FY17.csv")

