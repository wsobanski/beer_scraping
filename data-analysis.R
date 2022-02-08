library(ggplot2)
library(ggthemes)
library(dplyr)
library(ggpubr)
library(class)

data = data.frame(read.csv2('beers_clean.csv', sep = ';', encoding = 'UTF-8'))
View(data)
data$fermentation = as.factor(data$fermentation)
# creating a tibble to compare two types of fermentation
data |>
  group_by(fermentation) |>
  summarise(count = n(),
            mean_alc = mean(alc),
            mean_blg = mean(blg))


# Creating a scatter plot for all types of beers and fermentation types (Alc~Blg) 
data |>
  ggplot(aes(x = alc, y = blg))+
  geom_point(aes(colour = beer_type,) , size = 3, alpha = 0.8)+
  #geom_smooth(color="red", fill="#69b3a2", se=TRUE)+
  scale_color_manual(values = c('#64B6AC', '#E7DC39', '#31081F', '#2C423F', '#B80C09', '#7AC081', '#E65A30'))+
  #scale_shape_manual(values = c(15,17))+
  ggthemes::theme_fivethirtyeight()+
  labs(title = "Relation between alcohol contribiution\nand extract contribution",
       subtitle = "by type of beer",
       x = "Alcohol contribution (%)",
       y = "Extract contribution (°Blg)",
       color = "Type of beer:",
       shape = "Fermentation type: ")+
  theme(legend.title = element_text(face = 'bold'),
        axis.title = element_text(size = 12))

# Getting description tables for alcohol and blg across two fermentation types
desc_tbl_alc = desc_statby(data, measure.var = "alc",
                           grps = "fermentation")
desc_tbl_alc = desc_tbl_alc[,c('fermentation', 'min', 'max', 'mean', 'sd')]

desc_tbl_blg = desc_statby(data, measure.var = "blg",
                           grps = "fermentation")
desc_tbl_blg = desc_tbl_blg[,c('fermentation', 'min', 'max', 'mean', 'sd')]

# Converting tables to graph objects so we can put them into boxplots
desc_tbl_alc_graph = ggtexttable(format(desc_tbl_alc, digits = 2, scientific = FALSE), rows = NULL, 
                                 theme = ttheme("lBlueWhite"))

desc_tbl_blg_graph = ggtexttable(format(desc_tbl_blg, digits = 2, scientific = FALSE), rows = NULL, 
                                 theme = ttheme("lBlueWhite"))

# boxplot for alcohol contribution among two fermentation types
box_alc = data |>
  ggplot(aes(y = alc, x = fermentation))+
  geom_boxplot(aes(fill = fermentation), show.legend = FALSE, outlier.shape = 4, outlier.colour = '#AF1C21')+
  scale_fill_manual(values = c('#4CAF50', '#FF7043'))+
  theme_fivethirtyeight()+
  labs(title = "Mean alcohol contribution\nby type of fermentation",
       fill = "Fermentation type: ",
       y = "Alcohol contribution (%)")+
  theme(axis.title.y = element_text(size = 12),
        axis.title.x = element_blank())+
  annotation_custom(ggplotGrob(desc_tbl_alc_graph),
                    ymax = 16, ymin = 14, xmin = -1, xmax = 3)

# boxplot for extract contribution among two fermentation types
box_extr = data |>
  ggplot(aes(y = blg, x = fermentation))+
  geom_boxplot(aes(fill = fermentation), show.legend = FALSE, outlier.shape = 4, outlier.colour = '#AF1C21')+
  scale_fill_manual(values = c('#4CAF50', '#FF7043'))+
  theme_fivethirtyeight()+
  labs(title = "Mean extract contribution\nby type of fermentation",
       fill = "Fermentation type: ",
       y = "Extract contribution (°Blg)")+
  theme(axis.title.y = element_text(size = 12),
        axis.title.x = element_blank())+
  annotation_custom(ggplotGrob(desc_tbl_blg_graph),
                    ymax = 34, ymin = 32, xmin = -1, xmax = 3)

# plotting two graphs on one picture
ggarrange(box_alc, box_extr,
          ncol = 2,
          nrow = 1)
min(data$alc[data$fermentation == "bottom"])
summary(data)
ggplot(data, aes(x = alc, y = blg))+
  geom_density_2d(aes(color = as.factor(beer_type)))

# Creating sample of 73 beers with top fermetation to have balanced dataset for classification
data_top_subset = sample_n(data[which(data$fermentation == 'top'),], size = 73)

# creating subset of original dataframe containing all beers with bottom fermentation
# and 73 randomly selected beers with top fermentation
# for now seed will be set to constant value
set.seed(101)

data_subset = rbind(data[which(data$fermentation == 'bottom'),], data_top_subset)

# getting rid of not used columns
data_subset = data_subset[,c(2,3:7)]
data_subset

library(caTools)
split = sample.split(data_subset$fermentation, SplitRatio = 0.7)
training_set = subset(data_subset, split == TRUE)
test_set = subset(data_subset, split == FALSE)
nrow(training_set)
# standarization of columns with variables that will be used in knn classification
training_set[,4:5] = scale(training_set[,4:5], scale = T, center = T)
test_set[,4:5] = scale(test_set[,4:5], scale = T, center = T)


acc = vector(length = 10)
# finding optimal value of k 
max(acc)
for (i in 1:10){
  knn_model = knn(train = training_set[,4:5],
                  test = test_set[,4:5],
                  cl = training_set[,6],
                  k = i,
                  prob = TRUE)
  acc[i] = sum(diag(table(test_set[,6],knn_model)))/nrow(test_set)
}

sum(diag(confusion_matrix))/nrow(test_set)
acc
# plot of accuracy by k value
data.frame(k = 1:10,accuracy = acc) |>
  ggplot(aes(x = k, y = accuracy))+
  geom_line(lty = 2, lwd = 1, color = "#BABABD")+
  geom_point(size = 4, color = "#CF3333")+
  scale_x_continuous('k', c(1:10))+
  scale_y_continuous('accuracy', seq(from = 0.75, to = 0.90, by = 0.02))+
  labs(title = 'Accuracy vs. k value')+
  theme_fivethirtyeight()+
  theme(axis.title = element_text(face = "bold"))
confusion_matrix = table(test_set[,6],knn_model)
confusion_matrix
# Optimal value of k - 3
# confusion matrix for k = 3
knn_model = knn(train = training_set[,4:5],
                test = test_set[,4:5],
                cl = training_set[,6],
                k = 3,
                prob = TRUE)

table(test_set[,6],knn_model)

knn_model
# now we will use train and

