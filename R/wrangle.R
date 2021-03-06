# Wrangle Data With data.table

#======================================================================================================
# Install data.table

install.packages("data.table")

#======================================================================================================
# Load data.table

library(data.table)

#======================================================================================================
# Build a data.table from scratch

transactions <- data.table(
  TransactionID = seq(1, 10),
  TransactionDate = as.Date(c("2010-08-21", "2011-05-26", "2011-06-16", "2012-08-26", "2013-06-06", 
                              "2013-12-23", "2013-12-30", "2014-04-24", "2015-04-24", "2016-05-08")),
  UserID = c(7L, 3L, 3L, 1L, 2L, 2L, 3L, NA, 7L, 3L),
  ProductID = c(2L, 4L, 3L, 2L, 4L, 5L, 4L, 2L, 4L, 4L),
  Quantity = c(1L, 1L, 1L, 3L, 1L, 6L, 1L, 3L, 3L, 4L)
)

#======================================================================================================
# Read data from a CSV file

# Load transactions
transactions <- fread("https://raw.githubusercontent.com/ben519/DataWrangling/master/Data/transactions.csv")

#======================================================================================================
# Meta info

# Full summary
str(transactions)

# How many rows?
nrow(transactions)

# How many columns?
ncol(transactions)

# Get the row names
rownames(transactions)

# Get the column names
colnames(transactions)

# Change the name of column "Quantity" to "Quant"
setnames(transactions, "Quantity", "Quant")
setnames(transactions, "Quant", "Quantity")  # change it back

# Change the name of columns ProductID and UserID to PID and UID respectively
setnames(transactions, c("ProductID", "UserID"), c("PID", "UID"))
setnames(transactions, c("PID", "UID"), c("ProductID", "UserID"))  # change them back

#======================================================================================================
# Ordering the rows of a data.table

# Order the rows of transactions by TransactionID descending
transactions[order(-TransactionID)]

# Order the rows of transactions by Quantity ascending, TransactionDate descending
setorderv(transactions, c("Quantity", "TransactionDate"), order=c(1, -1))
setorder(transactions, TransactionID)  # change it back

#======================================================================================================
# Ordering the columns of a data.table

# Set the column order of transactions as ProductID, Quantity, TransactionDate, TransactionID, UserID
setcolorder(transactions, c("ProductID", "Quantity", "TransactionDate", "TransactionID", "UserID"))
setcolorder(transactions, c("TransactionID", "TransactionDate", "UserID", "ProductID", "Quantity"))  # reset the column order

# Make UserID the first column of transactions
setcolorder(transactions, unique(c("UserID", colnames(transactions))))
setcolorder(transactions, c("TransactionID", "TransactionDate", "UserID", "ProductID", "Quantity"))  # reset the column order

#======================================================================================================
# Extracting vectors from a data.table

# Get the 2nd column
transactions[[2]]

# Get the ProductID vector
transactions$ProductID

# Get the ProductID vector using a variable
col <- "ProductID"
transactions[[col]]

#======================================================================================================
# Row subsetting

# Subset rows 1, 3, and 6
transactions[c(1,3,6)]

# Subset rows exlcuding 1, 3, and 6
transactions[-c(1,3,6)]
transactions[!c(1,3,6)]

# Subset the first 3 rows
transactions[1:3]
head(transactions, 3)

# Subset rows excluding the first 3 rows
transactions[-1:-3]
tail(transactions, -3)

# Subset the last 2 rows
tail(transactions, 2)

# Subset rows excluding the last 2 rows
tail(transactions, -2)

# Subset rows where Quantity > 1
transactions[Quantity > 1]

# Subset rows where UserID = 2
transactions[UserID == 2]

# Subset rows where Quantity > 1 and UserID = 2
transactions[Quantity > 1 & UserID == 2]

# Subset rows where Quantity + UserID is > 3
transactions[Quantity + UserID > 3]

# Subset rows where an external vector, foo, is TRUE
foo <- c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE, FALSE, TRUE, FALSE)
transactions[foo]

# Subset rows where an external vector, bar, is positive
bar <- c(1, -3, 2, 2, 0, -4, -4, 0, 0, 2)
transactions[bar > 0]

# Subset rows where foo is TRUE or bar is negative
transactions[foo | bar < 0]

# Subset the rows where foo is not TRUE and bar is not negative
transactions[!foo & bar >= 0]

#======================================================================================================
# Column subsetting

# Subset by columns 1 and 3
transactions[, c(1, 3), with=FALSE]

# Subset by columns TransactionID and TransactionDate
transactions[, list(TransactionID, TransactionDate)]
transactions[, .(TransactionID, TransactionDate)]  # short-hand version of line above

# Subset rows where TransactionID > 5 and subset columns by TransactionID and TransactionDate
transactions[TransactionID > 5, list(TransactionID, TransactionDate)]

# Subset columns by a variable vector of columm names
cols <- c("TransactionID", "UserID", "Quantity")
transactions[, cols, with=FALSE]

# Subset columns excluding a variable vector of column names
cols <- c("TransactionID", "UserID", "Quantity")
transactions[, !cols, with=FALSE]

#======================================================================================================
# Inserting and updating values

# Convert the TransactionDate column to type Date
transactions[, TransactionDate := as.Date(TransactionDate)]

# Insert a new column, Foo = UserID + ProductID
transactions[, Foo := UserID + ProductID]

# Subset rows where TransactionID is even and set Foo = NA
transactions[TransactionID %% 2 == 0, Foo := NA]

# Add 100 to each TransactionID
transactions[, TransactionID := TransactionID + 100L]
transactions[, TransactionID := TransactionID - 100L]  # revert to original IDs

# Insert a column indicating each row number
transactions[, RowIdx := .I]

# Insert columns indicating the rank of each Quantity, minimum Quantity and maximum Quantity
transactions[, `:=`(QuantityRk=frank(Quantity, ties.method = "average"), QuantityMin=min(Quantity), QuantityMax=max(Quantity))]

# Remove column Foo
transactions[, Foo := NULL]

# Remove multiple columns RowIdx, QuantityRk, and RowIdx
transactions[, c("RowIdx", "QuantityRk", "QuantityMin", "QuantityMax") := NULL]

#======================================================================================================
# Grouping the rows of a data.table

#--------------------------------------------------
# Group By + Aggregate

# Group the transations per user, measuring the number of transactions per user
transactions[, list(Transactions = .N), by=UserID]

# Group the transactions per user, measuring the transactions and average quantity per user
transactions[, list(Transactions = .N, QuantityAvg = mean(Quantity)), by=UserID]

# Group the transactions per year of the transaction date, measuring the number of transactions per year
transactions[, list(Transactions = .N), by=year(TransactionDate)]

# Group the transactions per (user, transaction-year) pair, measuring the number of transactions per group
transactions[, list(Transactions = .N), by=list(UserID, TransactionYear=year(TransactionDate))]

# Group the transactions per user, measuring the max quantity each user made for a single transaction and the date of that transaction
transactions[, list(MaxTransactionQuantityDate=TransactionDate[which.max(Quantity)], MaxQuantity=max(Quantity)), by=UserID]

# Group the transactions per (user, transaction-year), and then group by transaction-year to get the number of users who made a transaction each year
transactions[, list(Transactions = .N), by=list(UserID, TransactionYear=year(TransactionDate))][, list(Users=.N), by=TransactionYear]

#--------------------------------------------------
# Group By + Update

# Insert a column in transactions indicating the number of transactions per user
transactions[, UserTransactions := .N, by=UserID]

# Insert columns in transactions indicating the first transaction date and last transaction date per user
transactions[, `:=`(FirstTransactionDate=min(TransactionDate), LastTransactionDate=max(TransactionDate)), by=UserID]

# For each transaction, get the date of the previous transaction made by the same user
setorder(transactions, "UserID", "TransactionDate")
transactions[, PrevTransactionDate := c(as.Date(NA), head(TransactionDate, -1)), by=UserID]

#======================================================================================================
# Joining data.tables

# Load datasets from CSV
users <- fread("https://raw.githubusercontent.com/ben519/DataWrangling/master/Data/users.csv")
sessions <- fread("https://raw.githubusercontent.com/ben519/DataWrangling/master/Data/sessions.csv")
products <- fread("https://raw.githubusercontent.com/ben519/DataWrangling/master/Data/products.csv")
transactions <- transactions <- fread("https://raw.githubusercontent.com/ben519/DataWrangling/master/Data/transactions.csv")

# Convert date columns to Date type
users[, `:=`(Registered = as.Date(Registered), Cancelled = as.Date(Cancelled))]
sessions[, SessionDate := as.Date(SessionDate)]
transactions[, TransactionDate := as.Date(TransactionDate)]

#--------------------------------------------------
# Basic Joins

# Join users to transactions, keeping all rows from transactions and only matching rows from users (left join)
users[transactions, on="UserID"]

# Which transactions have a UserID not in users? (anti join)
transactions[!users, on="UserID"]

# Join users to transactions, keeping only rows from transactions and users that match via UserID (inner join)
users[transactions, on="UserID", nomatch=0]

# Join users to transactions, displaying all matching rows AND all non-matching rows (full outer join)
merge(users, transactions, by="UserID", all=TRUE)

# Determine which sessions occured on the same day each user registered
users[sessions, on=c("UserID", "Registered" = "SessionDate"), nomatch=0]

# Build a dataset with every possible (UserID, ProductID) pair (cross join)
CJ(UserID=users$UserID, ProductID=products$ProductID)

# Determine how much quantity of each product was purchased by each user
transactions[, list(Quantity=sum(Quantity)), by=list(UserID, ProductID)][CJ(UserID=users$UserID, ProductID=products$ProductID), on=c("UserID", "ProductID")]

# For each user, get each possible pair of pair transactions (TransactionID1, TransactionID2)
t1 <- transactions[, list(UserID, TransactionID1=TransactionID)]
t2 <- transactions[, list(UserID, TransactionID2=TransactionID)]
t1[t2, on="UserID", allow.cartesian=TRUE]

# Join each user to his/her first occuring transaction in the transactions table
transactions[users, on="UserID", mult="first"]

#--------------------------------------------------
# Rolling Joins

# Determine the ID of the last session which occured prior to (and including) the date of each transaction per user
sessions[, RollDate := SessionDate]
transactions[, RollDate := TransactionDate]
setkey(sessions, "UserID", "RollDate")
setkey(transactions, "UserID", "RollDate")
sessions[transactions, roll=TRUE]

# Determine the ID of the first session which occured after (and including) the date of each transaction per user
sessions[, RollDate := SessionDate]
transactions[, RollDate := TransactionDate]
setkey(sessions, "UserID", "RollDate")
setkey(transactions, "UserID", "RollDate")
sessions[transactions, roll=-Inf]

#--------------------------------------------------
# Non-equi joins

# Determine the first transaction that occured for each user prior to (and including) his/her Cancelled date
setorder(transactions, "TransactionDate")
transactions[users, on=list(UserID, TransactionDate <= Cancelled), mult="first"]

# Get all transactions where TransactionDate is after the user's Cancellation Date
users[transactions, on=list(UserID, Cancelled < TransactionDate), nomatch=0]

#--------------------------------------------------
# Join + Update

# Insert the price of each product in the transactions dataset (join + update)
transactions[products, ProductPrice := Price, on="ProductID"]

# Insert the number of transactions each user made into the users dataset
users[transactions, on="UserID", Transactions := .N, by=UserID]

#--------------------------------------------------
# Setting a key and secondary indexing

# Set the key of Transactions as UserID
setkey(transactions, "UserID")  # notice rows are now sorted by UserID

# View the key of transactions
key(transactions)

# Set the key of users as UserID and join to transactions, matching rows only (inner join)
setkey(users, "UserID")
transactions[users, nomatch=0]

# Set ProductID as the key of transactions and products without re-ordering the rows, then join matching rows only
setkey(transactions, "ProductID", physical=FALSE)
setkey(products, "ProductID", physical=FALSE)
transactions[products, nomatch=0]

# Set each ID column as a secondary join index
setindex(transactions, "TransactionID")
setindex(transactions, "ProductID")
setindex(transactions, "UserID")
setindex(products, "ProductID")
setindex(users, "UserID")

# View indices
indices(transactions)
indices(products)
indices(users)

# Inner join between users, transactions, and products
users[transactions, on="UserID"][products, on="ProductID"]  # Note that having the pre-computed secondary indices makes this faster

#======================================================================================================
# Reshaping a data.table

# Read datasets from CSV
users <- fread("https://raw.githubusercontent.com/ben519/DataWrangling/master/Data/users.csv")
transactions <- transactions <- fread("https://raw.githubusercontent.com/ben519/DataWrangling/master/Data/transactions.csv")

# Convert date columns to Date type
users[, `:=`(Registered = as.Date(Registered), Cancelled = as.Date(Cancelled))]
transactions[, TransactionDate := as.Date(TransactionDate)]

# Add column TransactionWeekday as a factor with levels Sunday through Saturday
transactions[, TransactionWeekday := factor(weekdays(TransactionDate), levels=c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"))]

#--------------------------------------------------
# Convert data from tall format to wide format

# One-hot encode Weekday (i.e. convert data from tall to wide, where each possible weekday is a column)
dcast(transactions, TransactionID ~ TransactionWeekday, value.var="TransactionWeekday", fun.aggregate=function(x) length(x))

#--------------------------------------------------
# Convert data from wide format to tall format

# Build a data.table with columns {UserID, ActionType, Date} where ActionType is either "Registered" or "Cancelled" and Date is the corresponding date value
melt(users, id.vars="UserID", measure.vars=c("Registered", "Cancelled"), variable.name="ActionType", value.name="Date")

#======================================================================================================
# To Do

# Get rows which contain at least 1 NA value
# Get rows which contain at least 1 NA value within a subset of columns

# Get rows which contain all NA values
# Get rows which contain all NA values within a subset of columns

# Get the max value per row
# Get the max value per row within a subset of columns
