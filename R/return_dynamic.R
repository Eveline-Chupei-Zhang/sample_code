# -- utf-8 --#
# -- Dynamic DID & Figures-- #
# -- author: Chupei Zhang -- #



# Import dataset
library(lubridate)


df_DID_coin_exchange <- fread("~/dataset/final_coin_exchange_level.csv") %>%
  tibble() %>%
  select(-listing_day_BINANCEUS, -listing_day_BITFINEX,
         -listing_day_BITSTAMP, -listing_day_FTX,
         -listing_day_GEMINI, -listing_day_KRAKEN, -listing_day_KUCOIN,
         -listing_day_OKEX) %>%
  select(-correlation_BINANCEUS, -correlation_BITFINEX,
         -correlation_BITSTAMP, -correlation_FTX,
         -correlation_GEMINI, -correlation_KRAKEN, -correlation_KUCOIN,
         -correlation_OKEX) 


# pre and post 30-day window (5 days per period)
breaks <- c(-Inf, seq(-30, 30, 1) ,Inf)
levels <- c("Other", seq(-30, 30, 1))


# Binance
did_volume_Binance_dynamic <- feols(data = df_DID_coin_exchange %>%
                                      group_by(exchange, coin) %>%
                                      mutate(dis = time_length(interval(listing_day_BINANCE, day), "day"),
                                             dis = ifelse(is.na(dis), -100, dis),
                                             dis_factor = cut(dis, breaks, levels, right = F),
                                             lag_return_1=lag(return, n = 1),
                                             lag_return_2=lag(return, n = 2),
                                             exchange_coin = cur_group_id()),
                                    return ~ i(dis_factor, ref = -30) + lag_return_1 + lag_return_2 | exchange_coin + day,
                                    vcov = "twoway")
results_Binance_dynamic <- 
  data.frame(dis = seq(-30, 30, 1), coef = c(0, did_volume_Binance_dynamic$coefficients[2:61]),
             se = c(0, did_volume_Binance_dynamic$se[2:61])) %>%
  mutate(coef_u = coef + 2 * se,
         coef_l = coef - 2 * se)
(
  fig_Binance <- ggplot(results_Binance_dynamic, aes(x = dis)) + geom_line(aes(y = coef)) +
    geom_point(aes(y = coef)) + 
    geom_line(aes(y = coef_u), linetype = "66") +
    geom_line(aes(y = coef_l), linetype = "66") +
    theme_bw() +
    geom_vline(xintercept = 0, color = "red", size = 0.8, alpha = 0.5) +
    labs(x = "Distance to listing day", y = "Coefficients on Return")  +
    ggtitle("Binance(controlling for lagged variable)")
)

# Coinbase
did_volume_Coinbase_dynamic <- feols(data = df_DID_coin_exchange %>%
                                       group_by(exchange, coin) %>%
                                       mutate(dis = time_length(interval(listing_day_COINBASE, day), "day"),
                                              dis = ifelse(is.na(dis), -100, dis),
                                              dis_factor = cut(dis, breaks, levels, right = F),
                                              lag_return_1=lag(return, n = 1),
                                              lag_return_2=lag(return, n = 2),
                                              exchange_coin = cur_group_id()),
                                     return ~ i(dis_factor, ref = -30) + lag_return_1 + lag_return_2 | exchange_coin + day,
                                     vcov = "twoway")
results_Coinbase_dynamic <- 
  data.frame(dis = seq(-30, 30, 1), coef = c(0, did_volume_Coinbase_dynamic$coefficients[2:61]),
             se = c(0, did_volume_Coinbase_dynamic$se[2:61])) %>%
  mutate(coef_u = coef + 2 * se,
         coef_l = coef - 2 * se)
(
  fig_Coinbase <- ggplot(results_Coinbase_dynamic, aes(x = dis)) + geom_line(aes(y = coef)) +
    geom_point(aes(y = coef)) + 
    geom_line(aes(y = coef_u), linetype = "66") +
    geom_line(aes(y = coef_l), linetype = "66") +
    theme_bw() +
    geom_vline(xintercept = 0, color = "red", size = 0.8, alpha = 0.5) +
    labs(x = "Distance to listing day", y = "Coefficients on Return")  +
    ggtitle("Coinbase(controlling for lagged variable)")
)

# Pool
did_volume_pool_dynamic <- feols(data = df_DID_coin_exchange %>%
                                   group_by(exchange, coin) %>%
                                   mutate(dis = time_length(interval(listing_day_pool, day), "day"),
                                          dis = ifelse(is.na(dis), -100, dis),
                                          dis_factor = cut(dis, breaks, levels, right = F),
                                          lag_return_1=lag(return, n = 1),
                                          lag_return_2=lag(return, n = 2),
                                          exchange_coin = cur_group_id()),
                                 return ~ i(dis_factor, ref = -30) + lag_return_1 + lag_return_2 | exchange_coin + day,
                                 vcov = "twoway")
results_pool_dynamic <- 
  data.frame(dis = seq(-30, 30, 1), coef = c(0, did_volume_pool_dynamic$coefficients[2:61]),
             se = c(0, did_volume_pool_dynamic$se[2:61])) %>%
  mutate(coef_u = coef + 2 * se,
         coef_l = coef - 2 * se)
(
  fig_pool <- ggplot(results_pool_dynamic, aes(x = dis)) + geom_line(aes(y = coef)) +
    geom_point(aes(y = coef)) + 
    geom_line(aes(y = coef_u), linetype = "66") +
    geom_line(aes(y = coef_l), linetype = "66") +
    theme_bw() +
    geom_vline(xintercept = 0, color = "red", size = 0.8, alpha = 0.5) +
    labs(x = "Distance to listing day", y = "Coefficients on Return")  +
    ggtitle("Pool(controlling for lagged variable)")
)



#final <- (fig_Binance | fig_Coinbase | fig_pool)
ggsave(fig_Binance, filename = "/Fig/fig_Binance_return2.pdf", width = 9*1.5, height = 3*1.5)
ggsave(fig_Coinbase, filename = "/Fig/fig_Coinbase_return2.pdf", width = 9*1.5, height = 3*1.5)
ggsave(fig_pool, filename = "/Fig/fig_pool_return2.pdf", width = 9*1.5, height = 3*1.5)



