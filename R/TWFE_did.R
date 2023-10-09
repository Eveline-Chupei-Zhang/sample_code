# -- utf-8 --#
# -- Two-way fixed effects DID -- #
# -- author: Chupei Zhang -- #



# ---------------------------------------------------------------------------------------------------------------- #
# -------------------------------------------- retrieve the dataset ---------------------------------------------- #
# -----------------------------------------------------------------------------------------------------------------#
library(readr)
library(tidyverse)
library(fixest)
library(dplyr)
library(magrittr)
library(data.table)
library(stats)
library(datawizard)
library(psych)
library(openxlsx)



coin_exchange <- read_csv("~/dataset/final_coin_exchange_level.csv")
attach(coin_exchange)
summary(coin_exchange)



# -----------------------------------------------------------------------------------------------------------------#
# ----------------------- construct 'Listing' and 'PreThreedayListing' dummy variables ----------------------------#
# -----------------------------------------------------------------------------------------------------------------#

# central exchange: Binance
coin_exchange$Listing1 <- ifelse(listing_day_BINANCE <= day, 1, 0)
coin_exchange$Listing1[is.na(coin_exchange$Listing1)]=0

coin_exchange$PreThreedayListing1 <- ifelse(day+1 <= listing_day_BINANCE & listing_day_BINANCE <= day+3, 1, 0)
coin_exchange$PreThreedayListing1[is.na(coin_exchange$PreThreedayListing1)]=0


# central exchange: Coinbase
coin_exchange$Listing2 <- ifelse(listing_day_COINBASE <= day, 1, 0)
coin_exchange$Listing2[is.na(coin_exchange$Listing2)]=0

coin_exchange$PreThreedayListing2 <- ifelse(day+1 <= listing_day_COINBASE & listing_day_COINBASE <= day+3, 1, 0)
coin_exchange$PreThreedayListing2[is.na(coin_exchange$PreThreedayListing2)]=0


# central exchange: Pool
coin_exchange$Listing3 <- ifelse(listing_day_pool <= day, 1, 0)
coin_exchange$Listing3[is.na(coin_exchange$Listing3)]=0

coin_exchange$PreThreedayListing3 <- ifelse(day+1 <= listing_day_pool & listing_day_pool <= day+3, 1, 0)
coin_exchange$PreThreedayListing3[is.na(coin_exchange$PreThreedayListing3)]=0





# -----------------------------------------------------------------------------------------------------------------#
# -------------------- construct 'volatility', 'intra_day_spread' and 'dispersion' variables ----------------------#
# -----------------------------------------------------------------------------------------------------------------#

coin_exchange$volatility=return^2

# winsorize: see Table3: Volatility and Dispersion





# -----------------------------------------------------------------------------------------------------------------#
# ----------------------------------- count the number of listings on all exchanges -------------------------------#
# -----------------------------------------------------------------------------------------------------------------#

listing_count=coin_exchange %>%
  group_by(coin,day) %>%
  summarize(listing_count=n())

listing_count
coin_exchange=merge(coin_exchange,listing_count,by =c("coin"))




# -----------------------------------------------------------------------------------------------------------------#
# -------------------------------------------- static TWFE DID ----------------------------------------------------#
# -----------------------------------------------------------------------------------------------------------------#


#----------------------------------------------- Table2: Volume ---------------------------------------------------#
# central exchange: Binance
##col 1,2
did_t2_Binance1 <- feols(data = coin_exchange, 
                         log(volume) ~ csw(Listing1,PreThreedayListing1)+log(lag_volume_1)+log(lag_volume_2))

print(did_t2_Binance1)

##col 3
did_t2_Binance2 <- feols(data = coin_exchange,
                     log(volume) ~ Listing1+PreThreedayListing1+log(lag_volume_1)+log(lag_volume_2) | exchange^coin + day,
                     vcov = "twoway",
                     fixef.tol = 1e-4)

print(did_t2_Binance2)
etable(did_t2_Binance1, did_t2_Binance2, headers = c("(1)","(2)","(3)"))

# P.S.
# the estimated results are the same as the followings:
# did_t2_Coinbase2 <- feols(data = coin_exchange %>%
#                              group_by(exchange, coin) %>%
#                              mutate(exchange_coin = cur_group_id()),
#                            log(volume) ~ Listing2+PreThreedayListing2+log(lag_volume_1)+log(lag_volume_2) | exchange_coin + day,
#                            vcov = "twoway",
#                            fixef.tol = 1e-4)




# central exchange: Coinbase
##col 4,5
did_t2_Coinbase1 <- feols(data = coin_exchange, 
                          log(volume) ~ csw(Listing2,PreThreedayListing2)+log(lag_volume_1)+log(lag_volume_2))

print(did_t2_Coinbase1)

##col 6
did_t2_Coinbase2 <- feols(data = coin_exchange %>%
                          group_by(exchange, coin) %>%
                          mutate(exchange_coin = cur_group_id()),
                         log(volume) ~ Listing2+PreThreedayListing2+log(lag_volume_1)+log(lag_volume_2) | exchange_coin + day,
                         vcov = "twoway",
                         fixef.tol = 1e-4)

print(did_t2_Coinbase2)
etable(did_t2_Coinbase1, did_t2_Coinbase2, headers = c("(4)","(5)","(6)"))




# central exchange: Pool
##col 7,8
did_t2_Pool1 <- feols(data = coin_exchange, 
                      log(volume) ~ csw(Listing3,PreThreedayListing3)+log(lag_volume_1)+log(lag_volume_2))

print(did_t2_Pool1)

##col 9
did_t2_Pool2 <- feols(data = coin_exchange %>%
                        group_by(exchange, coin) %>%
                        mutate(exchange_coin = cur_group_id()),
                      log(volume) ~ Listing3+PreThreedayListing3+log(lag_volume_1)+log(lag_volume_2) | exchange_coin + day,
                      vcov = "twoway",
                      fixef.tol = 1e-4)

print(did_t2_Pool2)
etable(did_t2_Pool1, did_t2_Pool2, headers = c("(7)","(8)","(9)"))






#------------------------------------------- Table3: Volatility and Dispersion ------------------------------------#

# Binance, col "(1)","(4)","(7)"
did_t3_Binance <- feols(data = coin_exchange %>%
                          group_by(exchange, coin) %>%
                          mutate(wins_price_high=winsorize(price_high,threshold = 0.01),
                                 wins_price_low=winsorize(price_low,threshold = 0.01),
                                 wins_price=winsorize(price,threshold = 0.01),
                                 wins_ave_price=(wins_price_high+wins_price_low)/2,
                            wins_intra_day_spread=(wins_price_high-wins_price_low)/wins_ave_price,
                            wins_dispersion=sd(wins_price, na.rm = TRUE)/wins_ave_price,
                            exchange_coin = cur_group_id()),
                     sw(volatility, wins_intra_day_spread, wins_dispersion) ~ Listing1+PreThreedayListing1 | exchange_coin + day,
                     vcov = "twoway")
#print(did_t3_Binance)
etable(did_t3_Binance, headers = c("(1)","(4)","(7)"))




# Coinbase, col "(2)","(5)","(8)"
did_t3_Coinbase <- feols(data = coin_exchange %>%
                           group_by(exchange, coin) %>%
                           mutate(wins_price_high=winsorize(price_high,threshold = 0.01),
                                  wins_price_low=winsorize(price_low,threshold = 0.01),
                                  wins_price=winsorize(price,threshold = 0.01),
                                  wins_ave_price=(wins_price_high+wins_price_low)/2,
                                  wins_intra_day_spread=(wins_price_high-wins_price_low)/wins_ave_price,
                                  wins_dispersion=sd(wins_price, na.rm = TRUE)/wins_ave_price,
                                  exchange_coin = cur_group_id()),
                         sw(volatility, wins_intra_day_spread, wins_dispersion) ~ Listing2+PreThreedayListing2 | exchange_coin + day,
                         vcov = "twoway")
#print(did_t3_Coinbase)
etable(did_t3_Coinbase, headers = c("(2)","(5)","(8)"))



# Pool, col "(3)","(6)","(9)"
did_t3_Pool <- feols(data = coin_exchange %>%
                       group_by(exchange, coin) %>%
                       mutate(wins_price_high=winsorize(price_high,threshold = 0.01),
                              wins_price_low=winsorize(price_low,threshold = 0.01),
                              wins_price=winsorize(price,threshold = 0.01),
                              wins_ave_price=(wins_price_high+wins_price_low)/2,
                              wins_intra_day_spread=(wins_price_high-wins_price_low)/wins_ave_price,
                              wins_dispersion=sd(wins_price, na.rm = TRUE)/wins_ave_price,
                              exchange_coin = cur_group_id()),
                     sw(volatility, wins_intra_day_spread, wins_dispersion) ~ Listing3+PreThreedayListing3 | exchange_coin + day,
                     vcov = "twoway")
#print(did_t3_Pool)
etable(did_t3_Pool, headers = c("(3)","(6)","(9)"))

etable(did_t3_Binance, did_t3_Coinbase, did_t3_Pool,headers = c("(1)","(4)","(7)","(2)","(5)","(8)","(3)","(6)","(9)"))







#--------------------------------------------- Table4: listing following ----------------------------------------- #
# Binance
did_t4_Binance <- fepois(data = coin_exchange %>%
                           group_by(exchange,coin) %>%
                           mutate(exchange_coin = cur_group_id()),
                        listing_count ~ Listing1+PreThreedayListing1+log(volume) | exchange_coin + day,
                        vcov = "twoway")
#print(did_t4_Binance)
etable(did_t4_Binance, headers="Binance")




# Coinbase
did_t4_Coinbase <- fepois(data = coin_exchange %>%
                            group_by(exchange,coin) %>%
                            mutate(exchange_coin = cur_group_id()),
                          listing_count ~ Listing2+PreThreedayListing2+log(volume) | exchange_coin + day,
                          vcov = "twoway")
#print(did_t4_Coinbase)
etable(did_t4_Coinbase,headers="Coinbase")



# Pool
did_t4_Pool <- fepois(data = coin_exchange %>%
                        group_by(exchange,coin) %>%
                        mutate(listing_count=n_distinct(exchange),
                               exchange_coin = cur_group_id()),
                      listing_count ~ Listing3+PreThreedayListing3+log(volume) | exchange_coin + day,
                      vcov = "twoway")
#print(did_t4_Pool)
etable(did_t4_Pool,headers="Pool")

etable(did_t4_Binance, did_t4_Coinbase, did_t4_Pool, headers=c("Binance","Coinbase","Pool"))







#---------------------------------------------- Table6: Coin returns ----------------------------------------------#

# central exchange: Binance
##col 1,2
did_t6_Binance1 <- feols(return ~ csw(Listing1,PreThreedayListing1),
                     data = coin_exchange) 

print(did_t6_Binance1)


##col 3
did_t6_Binance2 <- feols(data = coin_exchange %>%
                          group_by(exchange, coin) %>%
                          mutate(exchange_coin = cur_group_id()),
                         return ~ Listing1+PreThreedayListing1 | exchange_coin + day,
                         vcov = "twoway",
                         fixef.tol = 1e-4)

print(did_t6_Binance2)
etable(did_t6_Binance1, did_t6_Binance2, headers = c("(1)","(2)","(3)"))




# central exchange: Coinbase
##col 4,5
did_t6_Coinbase1 <- feols (return ~ csw(Listing2,PreThreedayListing2),
                      data = coin_exchange)
#print(did_t6_Coinbase1)

##col 6
did_t6_Coinbase2 <- feols(data = coin_exchange %>%
                            group_by(exchange, coin) %>%
                            mutate(exchange_coin = cur_group_id()),
                     return ~ Listing2+PreThreedayListing2 | exchange_coin + day,
                     vcov = "twoway",
                     fixef.tol = 1e-4)

#print(did_t6_Coinbase2)
etable(did_t6_Coinbase1, did_t6_Coinbase2, headers = c("(4)","(5)","(6)"))



# central exchange: Pool
##col 7,8
did_t6_Pool1 <- feols(return ~ csw(Listing3,PreThreedayListing3),
                     data = coin_exchange)
#print(did_t6_Pool1)


##col 9
did_t6_Pool2 <- feols(data = coin_exchange %>%
                        group_by(exchange, coin) %>%
                        mutate(exchange_coin = cur_group_id()),
                     return ~ Listing3+PreThreedayListing3 | exchange_coin + day,
                     vcov = "twoway",
                     fixef.tol = 1e-4)

#print(did_t6_Pool2)
etable(did_t6_Pool1, did_t6_Pool2, headers = c("(7)","(8)","(9)"))

write.xlsx(coin_exchange, "/Users/chupei.zhang/Dropbox/crypto_exchanges/dataset/final_coin_exchange_level.xlsx")


