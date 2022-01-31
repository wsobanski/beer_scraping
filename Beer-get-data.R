
library(dplyr)
library(rvest)
library(stringi)
library(stringr)
link = 'https://ipiwo.pl/sklep/'
?rvest
closeAllConnections()
get_desc = function(beer_link){
  beer_page = read_html(beer_link)
  beer_desc = beer_page |>
    html_nodes('#tab-description') |>
    html_text()|>
    stri_trim_both()
  beer_desc
return (beer_desc)  
} #function for geting description of product from given link
get_alc = function(beer_link){
  beer_page = read_html(beer_link)
  beer_details = beer_page |>
    html_nodes('#tab-additional_information') |>
    html_table()
  beer_details = as.data.frame(beer_details)
  beer_alc = beer_details$X2[beer_details$X1 == "Alkohol (%)"]
  return(beer_alc)
} #gets info abaout alcohol contribution 
get_exctract = function(beer_link){

  beer_page = read_html(beer_link)
  beer_details = beer_page |>
    html_nodes('#tab-additional_information') |>
    html_table()
  beer_details = as.data.frame(beer_details)
  beer_exctract = beer_details$X2[beer_details$X1 == "Ekstrakt"]
  beer_details
  if (length(beer_exctract) == 0){
    return(NA)
  } else {
    return(beer_exctract)
  }
} #gets info about exctract contribution
get_type = function(beer_link){
  beer_page = read_html(beer_link)
  beer_details = beer_page |>
    html_nodes('#tab-additional_information') |>
    html_table()
  beer_details = as.data.frame(beer_details)
  beer_type = beer_details$X2[beer_details$X1 == "Rodzaj piwa"]
  return(beer_type)
} #gest info about beer type
get_price = function(beer_link){
  beer_page = read_html(beer_link)
  beer_price = beer_page |>
    html_nodes('bdi') |>
    html_text() #this return all "bdi" nodes, there are few on every page, firs one is value of your shopping cart, the second one is price of the beer
beer_price =str_remove(beer_price[2], "zł") #remove "zł" from each price
beer_price = as.numeric(stri_trim_right(str_replace(beer_price, ",", "."))) # replace all "," to "." (so this is posible to convert to numeric) and trim whitespaces
return(beer_price) 
}


# Get name, link for product and brewery from website (shop - pages from 1 to 2 )
set = data.frame()
for(page_result in seq(from = 1, to = 10, by =1)){ #loop for given number of pages - loop exctracts informations from pages
  link = paste0("https://ipiwo.pl/sklep/page/", page_result, "/") #create link to the given page number
page = read_html(link)

name = page |>
  html_nodes('.woocommerce-loop-product__link') |>
  html_text()

brewery = page|>
  html_nodes('.op-7') |>
  html_text()|>
  stri_trim_both() #Delete all whitespaces at the beggining and at the end

beer_link = page |>
  html_nodes('.woocommerce-loop-product__link') |> html_attr('href')
beer_link

set = rbind(set, data.frame(name, brewery, beer_link))

print(paste("page: " ,page_result))
}

#delete unused values and data structures

rm(beer_link, brewery, link, name, page_result, page)


# aplying functions for details on links acquired in loop above
# while iterating loop, two error types can occur:
  # 1. timeout error
  # 2. zero length change
# when error 1 occur you need to reset loop - it will automatically start at the itertion when error occured
# this error means that there were problem with connecting to server - it happens after 10 sec when there is no response
# this happens quite a lot even when your internet connection speed is high
# you can use closeAllConnections() command to free up memory after timeout error occurrece, so it should work better

# zero length change error  means that apropriate node was not found at given page - it can happen especially in case of non-alcoholic beers
# becouse sctructure of details table is a bit diffrent - to hande this problem you need to manually change "i" for the next observation and omit
# observation causing problem
# this vector below contains indexes of all observations that caused zero length change error
# when downloading data you can create if statement to check if numer of iteration is in vector with problematic observations
# and if so, just omit those obserwations

indexes_to_omit = c(165,166,226:233, 495, 496,572:576, 576, 849, 850, 869, 879)

# this is possible to fully automate this process by implementing try/cach statements, but for now it is what it is...


i = 1
for (i in i:nrow(set)){
  set$alc[i] = get_alc(set$beer_link[i])
  print(paste(i, set$beer_link[i], set$acl[i]))
  i = i + 1
  }
closeAllConnections()

i = 1
for (i in i:nrow(set)){
  set$exctract[i] = get_exctract(set$beer_link[i])
  print(paste(i, set$beer_link[i], set$exctract[i]))
  i = i + 1
  }
closeAllConnections()

i = 1
for (i in i:nrow(set)){
  set$type[i] = get_type(set$beer_link[i])
  print(paste(i, set$beer_link[i], set$type[i]))
  i = i + 1
  }
closeAllConnections()

i =1
for (i in i:nrow(set)){
  set$desc[i] = get_desc(set$beer_link[i])
  print(paste(i, set$beer_link[i]))
  i = i + 1
  }
closeAllConnections()


i =1
for (i in i:nrow(set)){
  set$price[i] = get_price(set$beer_link[i])
  print(paste(i, set$beer_link[i], set$price[i]))
  i = i + 1
  }
closeAllConnections()



View(set)
write.csv2(set, file='beers.csv')

