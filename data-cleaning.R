library(dplyr)
library(stringr)

# reading data extracted by Beer-get-data script
data = data.frame(read.csv("beers.csv", sep = ";",header = TRUE))

# replacing ',' in price column with '.' so it is possible to change its type to numeric
data$price = stringr::str_replace_all(data$price, ",", ".")|>
  as.numeric()

data$type = as.factor(data$type)
summary(data$type)

# table of all unique types of beers

all_types = data %>% group_by(type) %>% summarize(count=n())
head(all_types)

# Creating grouped types and filtering out these types that we wont analyse
# for now there will be groups such as: IPA, APA, Ale, Stout, Pszeniczne, Pils, Lager

# Assign apropiriate type_grouped value for beers containing key-words in type field
for (i in 1:nrow(data)){
  if(str_detect(data$type[i], regex("IPA", ignore_case = T)) ==TRUE){data$type_grouped[i] = "IPA"}
  else if (str_detect(data$type[i], regex("APA", ignore_case = T)) ==TRUE){data$type_grouped[i] = "APA"}
  else if (str_detect(data$type[i], regex("Lager", ignore_case = T)) ==TRUE){data$type_grouped[i] = "Lager"}
  else if (str_detect(data$type[i], regex("Stout", ignore_case = T)) ==TRUE){data$type_grouped[i] = "Stout"}
  else if (str_detect(data$type[i], regex("Pils", ignore_case = T)) ==TRUE){data$type_grouped[i] = "Pils"}
  else if (str_detect(data$type[i], regex("Ale", ignore_case = T)) ==TRUE){data$type_grouped[i] = "Ale"}
  else if (str_detect(data$type[i], regex("Pszeniczne", ignore_case = T)) ==TRUE){data$type_grouped[i] = "Pszeniczne"}
  else {data$type_grouped[i] = NA}
}

data$type = as.factor(data$type)
data$type_grouped = as.factor(data$type_grouped)

# summary
data %>% group_by(type_grouped) %>% summarize(count=n())

# getting rid of non-alcoholic beverages and corecting format of some rows
data = subset(data, alc>0.5)
data$alc = stringr::str_replace_all(data$alc, "%", "")|>
  as.numeric()

# corecting some observations and changing type of column to numeric

data$exctract= as.numeric(data$exctract)

# omit all observations with null values
data = na.omit(data)

# rename misspelled variable name
data = data |>
  rename("blg" = extract)

# creating new variable based on type_grouped:
# this variable will assign fermentation type to every observation based on type of product.
# there are two common types of fermentation in brewery: top fermentation and bottom fermentation
# top fermentation is used in production of various types of beers such as: 
# ale, ipa, apa, pszeniczne, stout
# and bottom fermentation is used in production of lager and pils
for (i in 1:nrow(data)){
  if(str_detect(data$type[i], regex("Lager", ignore_case = T)) ==TRUE |
     str_detect(data$type[i], regex("Pils", ignore_case = T)) ==TRUE){
    data$fermentation[i] = "bottom"}
  else {data$fermentation[i] = "top"}
}

# Creating clean dataframe 
data_clean = data.frame("name" = data$name,
                        "brewery" = data$brewery,
                        "beer_type" = data$type_grouped,
                        "alc" = data$alc,
                        "blg" = data$blg,
                        "fermentation" = data$fermentation,
                        "price" = data$price)

# Some of the beers in filed "brewery" doest have info about brewery - sometimes there is info about sale or "new product" tag
# we can replace these by using first word in "name" field, becouse it has information about brewery there.
# sometimes breweries have name containing two or more words e.g. "Trzech Kumpli", so out function will return only "Trzech"
# in cases like this fields has to be filled manually

# This chunk of code iterate through all observations and check if in the filed "brewery" are tags like:
# popularne, nowosci w butelce/puszce, piwa trudno dostepne or zagraniczne
# if tag is detected then from field "name" first word is extracted and "brewery" is replaced with that word

for (i in 1:nrow(data_clean)){
  if (str_detect(data_clean$brewery[i], regex("Nowości", ignore_case = T))==TRUE){
    data_clean$brewery[i] = str_extract(data_clean$name[i], regex("([^ ]+)") )
  }
  if (str_detect(data_clean$brewery[i], regex("trudno", ignore_case = T))==TRUE){
    data_clean$brewery[i] = str_extract(data_clean$name[i], regex("([^ ]+)") )
  }
  if (str_detect(data_clean$brewery[i], regex("zagraniczne", ignore_case = T))==TRUE){
    data_clean$brewery[i] = str_extract(data_clean$name[i], regex("([^ ]+)") )
  }
  if (str_detect(data_clean$brewery[i], regex("Popularne", ignore_case = T))==TRUE){
    data_clean$brewery[i] = str_extract(data_clean$name[i], regex("([^ ]+)") )
  }
}

# Manually setting remaining observations
data_clean$brewery[96:99] = "Browar Zakładowy"
data_clean$brewery[191] = "Hamowniki"
data_clean$brewery[269] = "Kultowe"
data_clean$brewery[405:422] = "Piwne podziemie"
data_clean$brewery[462:479] = "Trzech Kumpli"
data_clean$brewery[487] = "wielka sowa"
data_clean$brewery[499] = "za miastem"
data_clean$brewery[522] = "za miastem"

data_clean$brewery = tolower(data_clean$brewery)
data_clean$beer_type = tolower(data_clean$beer_type)

# clear non used value for iteration
rm(i)

# save clean dataset as csv
write.csv2(data_clean, file='beers_clean.csv', fileEncoding = 'UTF-8')



