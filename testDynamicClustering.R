library(fpc)
library(data.table)

### study best way to dynamically cluster data automagically

DT <- fread("data/parcoord_data_prep.csv")

data <- DT[Sales_Level_2_key == 4, ]

### principal components - exclusively based on Wallet Share and Wallet, past and future
pca <- prcomp(data[, c("WS4FYs_Total", "WS4FYs_EntNet", "WS4FYs_DC", "WS4FYs_Secur", "WS4FYs_Collab", "WS4FYs_Svcs",           
                       "WS4FYs_SPtech", "WS4FYs_Others", "Wal4FYs_Total", "Wal4FYs_pct_EntNet", "Wal4FYs_pct_DC",
                       "Wal4FYs_pct_Secur", "Wal4FYs_pct_Collab", "Wal4FYs_pct_Svcs", "Wal4FYs_pct_Others", 
                       "WalFY17_Total", "WalFY17_pct_EntNet", "WalFY17_pct_DC", "WalFY17_pct_Secur",
                       "WalFY17_pct_Collab", "WalFY17_pct_Svcs", "WalFY17_pct_SPtech", "WalFY17_pct_Others", "BICFY17_Total"), 
                   with=FALSE], 
              scale=TRUE, cor=TRUE, scores=TRUE)

no_comps3 <- sum(summary(pca)$importance["Cumulative Proportion",] < 0.80) + 1
print(paste0("Using ", no_comps3, " components (", summary(pca)$importance["Cumulative Proportion", no_comps3]," of tot var)"))


testx <- pca$x[, 1:no_comps3]
dim(testx)

options(digits=3)
# use optimum average silhouette width to estimate the best number of clusters
set.seed(1234)
pamk.best <- pamk(testx, krange = 4:10, criterion = "asw", usepam = FALSE, samples=80)
cat("number of clusters estimated by optimum average silhouette width:", pamk.best$nc, "\n")


data[, group := paste0("cluster", as.character(pamk.best$pamobject$clustering))]

plot(cluster::clara(testx, pamk.best$nc))
