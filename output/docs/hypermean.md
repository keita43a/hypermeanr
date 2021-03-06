---
title: "Hypermean"
author: "Keita Abe"
date: "2022-07-11"
output:
  html_document: 
    keep_md: yes
    code_folding: hide
    results_folding: hide
    df_print: paged
    highlight: "default"
    md_extensions: -ascii_identifiers
    number_section: true
    theme: "default"
    toc: yes
    toc_depth: 3
    toc_float:
      collapsed: yes
      smooth_scroll: yes
editor_options: 
  chunk_output_type: console
knit: (function(inputFile, encoding) {
  rmarkdown::render(inputFile, encoding = encoding, output_dir = "../output/docs") })
---




```r
# ---- data load -----
dat_survey = read_xlsx("../data/norstat/SNA97433_220707.xlsx") %>%
  separate(date,into=c("date","time"),sep=" ") %>%
  mutate(date = as.Date(date, format="%m/%d/%Y")) %>%
  mutate(week = ifelse(date >= as.Date("2022-07-04",format="%Y-%m-%d"),
                       "Week 2","Week 1")) %>%
  relocate(week,.after=time)

# ---- True values and Yr forecast ------
 
 # Week 1
 rain_yr1 = 60  # prediction was 60%
 temp_yr1 = 16.0
 
 rain_true1 = 0 # it did not rain
 temp_true1 = 16.3
 
 # Week 2
 rain_yr2 = 60  # prediction was 60%
 temp_yr2 = 12.0  # prediction was 12C
 
 rain_true2 = 0     # it did not rain
 temp_true2 = 12.0
 
 # Stone true value is unchanged across weeks
 stone_true = 19.8 # Bla steinen surface area measured by Margrethe

# ---- Corresponding the number and category in words ------
    # Question 1
    dat_q1 = data.frame(
      Q1 = c(1:7),
      Q1_ans = c("Once a day","5-6 times a week","3-4 times a week",
              "1-2 times a week","Less than once a week","Never",
              "I do not know")
      )
    
    # Question 2
    
    dat_q2 = data.frame(
      Q2 =1:5,
      Q2_ans = c("Very likely","Probably","As Likely as Unlikely",
                  "Unlikely","Not likely")
    )
    
    
    # Question 4
    dat_q4 = data.frame(
      Q4 =1:4,
      Q4_ans = c("Less than 10 m2","Between 10-25 m2","Between 26-40 m2","Larger than 40 m2")
      )

# ---- Compile the data ----------

dat_survey2 = dat_survey %>%
      # category for age group.
  mutate(age_group_fct = factor(age_group, labels = c("<=29","30-39","40-49",">=50")),
         gender_fct = factor(gender, labels=c("Male","Female"))) %>%
      # merge category data for question answers. 
  left_join(dat_q1, by=c("Q1")) %>%
  left_join(dat_q2, by=c("Q2")) %>%
  left_join(dat_q4, by=c("Q4")) %>%
  # add true values as variable
  mutate(
    rain_true = ifelse(week=="Week 1",rain_true1,rain_true2),
    temp_true = ifelse(week=="Week 1",temp_true1,temp_true2),
    rain_yr = ifelse(week=="Week 1",rain_yr1,rain_yr2),
    temp_yr = ifelse(week=="Week 1",temp_yr1,temp_yr2),
    stone_true = stone_true
  ) %>%
  # convert it into factor to preserve the order
  mutate(Q1_ans = factor(Q1_ans,levels=c("Once a day",
                                         "5-6 times a week",
                                         "3-4 times a week",
                                         "1-2 times a week",
                                         "Less than once a week",
                                         "Never","I do not know")),
         Q2_ans = factor(Q2_ans,levels=c("Very likely",
                                         "Probably",
                                         "As Likely as Unlikely",
                                         "Unlikely",
                                         "Not likely")),
         Q4_ans = factor(Q4_ans,levels=c("Less than 10 m2",
                                         "Between 10-25 m2",
                                         "Between 26-40 m2",
                                         "Larger than 40 m2")),
         # Brier score and absolute errors
         Q2_brier = (q2x1/100 - rain_true)^2,  # Brier Score (probabilistic question)
         Q3_error = abs(Q3 - temp_true),       # absolute error
         Q4_error = abs(Q4x1 - stone_true)     # absolute error
         ) %>%
   group_by(week) %>%
   mutate(across(.cols = c(q2x1,Q3,Q4x1,Q2_brier,Q3_error,Q4_error),
                 .fns = list(mean=~mean(.x,na.rm=TRUE),
                             median=~median(.x,na.rm=TRUE)
                             ))) %>%
      ungroup()
```

# Hypermean

## Description

**Hypermeans** are weighted means with weights that weaken the contribution of those who tend to be far from the normal mean and amplify the contribution of those who tend to be closer to the normal mean. The idea behind this is the wisdom of crowds, that people who are far from the mean tend to be wrong more than those who are closer to the mean (Feliciani et al. 2022).

## Weighting rules

### Trimmed and Winsorizing means

There are a series of weighting rules. For exmaples, the rules include trimmed mean (Jose and Winkler 2008), past performance (Budescu & Chen, 2015). Feliciani et al. (2022) uses the correlation (Spearman's $\rho$) between the individuals' and overall rankings of evaluation because the variable of interest is rankings. 

Jose and Winkler (2008) test the performance of trimmed means and Winsorizing means when combining forecasts to obtain a single aggregated forecast. They conclude that trimmed and Winsorizing means are slightly better than the ordinary (simple) mean. 

Suppose there are $n$ forecasts, $X_1,\ldots,X_{n}$ of the interest of forecast, $Y$. Suppose the $X$ are ordered, and the $X_{(i)}$ is the $i$th order statistic for $X_{1},\ldots,X_n$. The trimmed mean $T(i)$ and Winsorized mean $W(i)$ are defined as follows. 

$$
 T(i) = \frac{1}{n-2i}\sum_{k=i+1}^{n-i}X_{(k)} \\
 W(i) = \frac{1}{n}[iX_{i+1} + \sum_{k=i+1}^{n-i}X_{(k)}+iX_{(n-i)}]
$$

Intuitively, trimmed mean simply trimmed the both sides outliers by $i$, while Winsorized mean set the value of outliers equal to $i+1$ th value from the edge. 

The question is, how much should we trim or Winsorize? Jose and Winkler (2008) recommend 10-30% (5-15% on each side) for trimming, and 15-45% (7.5-22.5% on each side) for Winsorizing. 

The figure below is an intuitive example of trimmed and Winsorized averages using simulated data. The data are generated from $X ~ N(0,1)$ and the sample size is 1000. While the raw data follows a normal distribution, the trimmed data loses samples with values far from the mean or median; the Winsorized data has bunching at the same support end as the Trimmed data.



```r
# Defining function to generate trimmed or Winsorized mean

hypermean = function(vec, size = 0.1, type = "trim",ret="mean"){

  # ---- check inputs ------
    # check size
    if(size == 0.1){
      message("size = 0.1 is default")
      }else if(size > 1 | size < 0){
        stop("size should be between 0 and 1: default is 0.1")
      }
    
    # Check type
    if(type == "trim"){
      message("Trimming is performed")
    }else if(type == "wins"){
      message("Winsorizing is performed")
    }else if(type %in% c("epa","triw","trig","gauss")){
      message("Weighting by kernel is performed.")
    }else{
      stop("type should be trim (trimmed), wins (Winsorized), epa (Epanechnikov), triw (Triweight), trig (Triangle), gauss (Gaussian)")
    }
  
  # check return object
    if(!(ret %in% c("mean","vector"))){
      ret="mean"
      message("The hypermean is returned.")
    }
  
  # ----- define functions------
      # kernel distributions
      dist.trig = function(x) 1-abs(x)
      dist.epa = function(x) (3/4)*(1-x^2)
      dist.triw = function(x) (35/32)*(1-x^2)^3
      dist.gauss = function(x) dnorm(x)
            
      # convert the each element into standardized support based on distribution
      dist.conv = function(v){
        mv = mean(v,na.rm=TRUE)
        z=(v-mv)/min(abs(min(v,na.rm=TRUE)-mv),abs(max(v,na.rm=TRUE)-mv))
        return(z)
      }
      dist.conv.gauss = function(v){
        mv = mean(v,na.rm=TRUE)
        sv = sd(v,na.rm=TRUE)
        z=(v-mv)/sv
        return(z)
      }
  
  # ----- main part: calculating trimmed -----
  nn = length(vec)     # number of elements
  trimming = round(nn*size/2,digits=0) # amount to trim on one side

  new_vec = sort(vec)      # sorting the vector
  
  if(type == "trim"){
  # trimming
  new_vec[1:trimming] = NA                    # trimming lefthand side
  new_vec[(nn-trimming):nn] = NA              # trimming righthand side
  
  new_vec2 = new_vec                          # to return vector
  hyp_mean = mean(new_vec,na.rm=TRUE)         # return hypermean
  }else if(type=="wins"){
  # winsorizing
  new_vec[1:trimming] = new_vec[trimming+1]          # Winsorizing lefthand side
  new_vec[(nn-trimming):nn] = new_vec[nn-trimming-1] # Winsorizing righthand side
  
  new_vec2 = new_vec                          # to return vector
  hyp_mean = mean(new_vec,na.rm=TRUE)         # return hypermean
  }else if(type=="epa"){
  # epanechnikov
  new_vec[1:trimming] = NA                    # trimming lefthand side
  new_vec[(nn-trimming):nn] = NA              # trimming righthand side
   # dist.
   z = dist.conv(new_vec)                     # standardize the values to get the weight
   w = dist.epa(z)                            
   w = ifelse(w < 0,0,w)
   w2 = w/sum(w,na.rm=TRUE)
   new_vec2 = new_vec*w2
   hyp_mean = sum(new_vec2,na.rm=TRUE)
  }else if(type=="triw"){
  # triweight
  new_vec[1:trimming] = NA                    # trimming lefthand side
  new_vec[(nn-trimming):nn] = NA              # trimming righthand side
   # dist.
   z = dist.conv(new_vec)                     # standardize the values to get the weight
   w = dist.triw(z)                            
   w = ifelse(w < 0,0,w)
   w2 = w/sum(w,na.rm=TRUE)
   new_vec2 = new_vec*w2
   hyp_mean = sum(new_vec2,na.rm=TRUE)
  }else if(type=="trig"){
  # triangle distribution
  new_vec[1:trimming] = NA                    # trimming lefthand side
  new_vec[(nn-trimming):nn] = NA              # trimming righthand side
   # dist.
   z = dist.conv(new_vec)                     # standardize the values to get the weight
   w = dist.trig(z)                            
   w = ifelse(w < 0,0,w)
   w2 = w/sum(w,na.rm=TRUE)
   new_vec2 = new_vec*w2
   hyp_mean = sum(new_vec2,na.rm=TRUE)
  }else if(type=="gauss"){
  # gaussian distribution
  # So far no trimming for gaussian (because the support is not limited to -1 to 1), so comment out below.
  ## new_vec[1:trimming] = NA                    # trimming lefthand side
  ## new_vec[(nn-trimming):nn] = NA              # trimming righthand side
   # dist.
   z = dist.conv.gauss(new_vec)                     # standardize the values to get the weight. standardized by SE of data
   w = dist.gauss(z)                            
   w = ifelse(w < 0,0,w)
   w2 = w/sum(w,na.rm=TRUE)
   new_vec2 = new_vec*w2
   hyp_mean = sum(new_vec2,na.rm=TRUE)
  }
  
  # return either hypermean or vector
  if(ret == "mean"){
    return(hyp_mean)  
  }else if(ret =="vector"){
    return(new_vec2)  
  }
}
```


```r
# intuitively exihibit the trimmed and 
set.seed(3)
vec1 = tibble(Raw = rnorm(1000,0,1)) %>%
  arrange(Raw) %>%
  mutate(rank = rank(Raw),
         Trimmed = ifelse(rank <= 100 | rank >= (1000-100), NA, Raw),
         Winsorized = Trimmed) %>%
  fill(Winsorized,.direction=c("downup")) %>%
  pivot_longer(cols = c(Raw,Trimmed,Winsorized),names_to = "type",values_to = "value")
```


```r
ggplot(vec1, aes(x=value)) + 
  geom_histogram() +
  geom_vline(aes(xintercept = mean(value))) +
  theme_bw() +
  facet_wrap(~type,nrow = 2)
```

![Examples of trimmed and Winsorized means with simulated data.](/Users/keita/Dropbox/Research/hypermean/output/docs/hypermean_files/figure-html/unnamed-chunk-4-1.png)


### Distribution weighting

Trimming deletes the outliers but does not change the weights of the individuals remaining in the sample. Here, we put weights based on distributions arbitrarily chosen. 

#### Selection of distribution

We try distributions that are commonly used for weighting the samples for nonparametric kernel estimations. 

Common kernel functions include:
- Uniform
- Epanechikov
- Triangle
- Triweight
- Gaussian (Normal)

The kernel functions are usually distributed over -1 to 1. 
Hence, we need to trim both sides and scale to the support of the observed data. Trimming mean is essentially the kernel weighted mean with uniform distribution. 


```r
dist.unif = function(x){
  (abs(x) <= 1)*(1/2)   # if absolute value is less than or equal to 1, TRUE, which is 1. otherwise 0. 
}
dist.triangle = function(x) 1-abs(x)
dist.epa = function(x) (3/4)*(1-x^2)
dist.triw = function(x) (35/32)*(1-x^2)^3
dist.gauss = function(x) dnorm(x)
```


```r
ggplot() +
  xlim(c(-2,2)) +
  ylim(c(0,1.25)) +
  geom_function(fun = dist.unif,
                aes(color = "uniform"))+
  geom_function(fun = dist.triangle,
                aes(color = "triangle"))+
  geom_function(fun = dist.epa,
                aes(color = "epanechnikov")) +
  geom_function(fun = dist.triw,
                aes(color = "triweight")) +
  geom_function(fun = dist.gauss,
                aes(color = "gaussian")) +
  guides(colour = guide_legend(title = ""))+
  labs(y="density", color = "kernel") +
  theme_bw()
```

![Common kernel distribution functions](/Users/keita/Dropbox/Research/hypermean/output/docs/hypermean_files/figure-html/unnamed-chunk-6-1.png)



How do we apply the kernel distribution, whose support is usually $[-1,1]$, to apply to the data? 

**Idea**: The closer edge of the trimmed data is the edge of the support. That is, we standardize the data to align with the support of the kernel distribution. 

$$
  z = \frac{(x - E(x))}{\min[x-\min(x),\max(x)-x]}
$$
Then either minimum or maximum of the trimmed data $x$ will be on the edge of the support of the kernel distribution, and the mean of the kernel is equal to the mean of the data. 

The graphical examples are shown below. The first one is the data generated from standard normal distribution. After trimming, the data is fairly symmetric. By overlaying the kernel distribution using the standardized data $z$, it shows a fair weighting. 



```r
 set.seed(3)
vec1 = tibble(Raw = rnorm(1000,0,1)) %>%
  arrange(Raw) %>%
  mutate(rank = rank(Raw),
         Trimmed = ifelse(rank <= 100 | rank >= (1000-100), NA, Raw))

set.seed(3)
vec2 = tibble(Raw = rlnorm(1000,0,1)) %>%
  arrange(Raw) %>%
  mutate(rank = rank(Raw),
         Trimmed = ifelse(rank <= 100 | rank >= (1000-100), NA, Raw))

# function for drawing distribution
dist.vec1 = function(x,vec){
  z = vec$Trimmed
  mz = mean(z,na.rm=TRUE)
  y=(x-mz)/min(abs(min(z,na.rm=TRUE)-mz),abs(max(z,na.rm=TRUE)-mz))
  s = dist.epa(y)
  s =ifelse(s>0, s, 0)
  return(s)
}
```


```r
ggplot(vec1, aes(x=Trimmed)) + 
  geom_histogram(aes(y=..density..)) +
  geom_vline(xintercept = mean(vec1$Trimmed,na.rm=TRUE), linetype=2) +
  stat_function(fun = dist.vec1,col="red",args=list(vec =vec1)) +
  theme_bw()
```

![Example of applying distribution weight with simulated data. The sample is generated from standard normal distribution and trimmed by 10%. Epanechnikov kernel is applied for the weight.](/Users/keita/Dropbox/Research/hypermean/output/docs/hypermean_files/figure-html/unnamed-chunk-8-1.png)

The second figure below shows the data generated from standard log normal distribution. After trimming, the data is not symmetric. The overlay-ed kernel distribution shows the weighting but the most frequent values are not largely weighted. 


```r
ggplot(vec2, aes(x=Trimmed)) + 
  geom_histogram(aes(y=..density..)) +
  geom_vline(xintercept = mean(vec2$Trimmed,na.rm=TRUE), linetype=2) +
  xlim(0,NA) +
  stat_function(fun = dist.vec1,col="red",args=list(vec =vec2)) +
  theme_bw()
```

![Example of applying distribution weight with simulated data. The sample is generated from standard log normal distribution and trimmed by 10%. Epanechnikov kernel is applied for the weight.](/Users/keita/Dropbox/Research/hypermean/output/docs/hypermean_files/figure-html/unnamed-chunk-9-1.png)


## Application to the survey data

We apply the hypermeans to the survey data. 

### Trimmed and Winsorizied means

First, trimmed and Winsorized means are applied to the survey data. 


```r
dat1 = expand.grid(var = c("rain","temp","stone"),size=c(0,0.1,0.2,0.3),type = c("t","w"))

test1 = dat_survey2 %>%
  filter(week == "Week 1") %>%
  summarise(
    across(.cols=c(q2x1,Q3,Q4x1),
           .fns = list(mean = ~mean(.x,na.rm=TRUE),
                       trim_1 = ~hypermean(.x,size=0.1,type="trim"),
                       trim_2 = ~hypermean(.x,size=0.2,type="trim"),
                       trim_3 = ~hypermean(.x,size=0.3,type="trim"),
                       wins_1 = ~hypermean(.x,size=0.1,type="wins"),
                       wins_2 = ~hypermean(.x,size=0.2,type="wins"),
                       wins_3 = ~hypermean(.x,size=0.3,type="wins")
                       ))
  ) %>%
  mutate(q2x1_true = rain_true1,
         Q3_true = temp_true1,
         Q4x1_true = stone_true) %>%
  pivot_longer(cols=everything()) %>%
  separate(col=name,into=c("var","meantype","size"),sep="_") %>%
  # make brier score for Q2 rain
  mutate(var2 = ifelse(var == "q2x1","Rain",
                       ifelse(var=="Q3","Temp.",
                              ifelse(var=="Q4x1","Stone",var))),
         value2 = ifelse(var == "q2x1",(value/100-rain_true1)^2,value),
         size = ifelse(is.na(size),0,size)) %>%
  select(var2,meantype,size,value2) %>%
  mutate(value2 = round(value2,digits = 3)) %>%
  pivot_wider(id_cols = c(meantype,size), names_from = var2, values_from = value2)

test2 = dat_survey2 %>%
  filter(week == "Week 2") %>%
  summarise(
    across(.cols=c(q2x1,Q3,Q4x1),
           .fns = list(mean = ~mean(.x,na.rm=TRUE),
                       trim_1 = ~hypermean(.x,size=0.1,type="trim"),
                       trim_2 = ~hypermean(.x,size=0.2,type="trim"),
                       trim_3 = ~hypermean(.x,size=0.3,type="trim"),
                       wins_1 = ~hypermean(.x,size=0.1,type="wins"),
                       wins_2 = ~hypermean(.x,size=0.2,type="wins"),
                       wins_3 = ~hypermean(.x,size=0.3,type="wins")
                       ))
  ) %>%
  mutate(q2x1_true = rain_true2,
         Q3_true = temp_true2,
         Q4x1_true = stone_true) %>%
  pivot_longer(cols=everything()) %>%
  separate(col=name,into=c("var","meantype","size"),sep="_") %>%
  # make brier score for Q2 rain
  mutate(var2 = ifelse(var == "q2x1","Rain",
                       ifelse(var=="Q3","Temp.",
                              ifelse(var=="Q4x1","Stone",var))),
         value2 = ifelse(var == "q2x1",(value/100-rain_true2)^2,value),
         size = ifelse(is.na(size),0,size)) %>%
  select(var2,meantype,size,value2) %>%
  mutate(value2 = round(value2,digits = 3)) %>%
  pivot_wider(id_cols = c(meantype,size), names_from = var2, values_from = value2)
```


```r
test1 %>% kbl(caption = "Estimated hypermeans of survey answers to Rain probability, temperature, and Blue Stone questions based on trimming and Winsorizing. Week 1") %>% kable_classic(full_width = FALSE)
```

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
<caption>Estimated hypermeans of survey answers to Rain probability, temperature, and Blue Stone questions based on trimming and Winsorizing. Week 1</caption>
 <thead>
  <tr>
   <th style="text-align:left;"> meantype </th>
   <th style="text-align:left;"> size </th>
   <th style="text-align:right;"> Rain </th>
   <th style="text-align:right;"> Temp. </th>
   <th style="text-align:right;"> Stone </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> mean </td>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:right;"> 0.327 </td>
   <td style="text-align:right;"> 17.478 </td>
   <td style="text-align:right;"> 22.396 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> trim </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.358 </td>
   <td style="text-align:right;"> 17.349 </td>
   <td style="text-align:right;"> 20.983 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> trim </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.363 </td>
   <td style="text-align:right;"> 17.300 </td>
   <td style="text-align:right;"> 20.202 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> trim </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.370 </td>
   <td style="text-align:right;"> 17.273 </td>
   <td style="text-align:right;"> 19.775 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> wins </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.331 </td>
   <td style="text-align:right;"> 17.377 </td>
   <td style="text-align:right;"> 21.869 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> wins </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.356 </td>
   <td style="text-align:right;"> 17.351 </td>
   <td style="text-align:right;"> 21.041 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> wins </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.359 </td>
   <td style="text-align:right;"> 17.351 </td>
   <td style="text-align:right;"> 20.646 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> true </td>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 16.300 </td>
   <td style="text-align:right;"> 19.800 </td>
  </tr>
</tbody>
</table>

```r
test2 %>% kbl(caption = "Estimated hypermeans of survey answers to Rain probability, temperature, and Blue Stone questions based on trimming and Winsorizing. Week 2") %>% kable_classic(full_width = FALSE)
```

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
<caption>Estimated hypermeans of survey answers to Rain probability, temperature, and Blue Stone questions based on trimming and Winsorizing. Week 2</caption>
 <thead>
  <tr>
   <th style="text-align:left;"> meantype </th>
   <th style="text-align:left;"> size </th>
   <th style="text-align:right;"> Rain </th>
   <th style="text-align:right;"> Temp. </th>
   <th style="text-align:right;"> Stone </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> mean </td>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:right;"> 0.401 </td>
   <td style="text-align:right;"> 15.500 </td>
   <td style="text-align:right;"> 21.529 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> trim </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.428 </td>
   <td style="text-align:right;"> 15.397 </td>
   <td style="text-align:right;"> 19.791 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> trim </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.436 </td>
   <td style="text-align:right;"> 15.344 </td>
   <td style="text-align:right;"> 19.300 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> trim </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.440 </td>
   <td style="text-align:right;"> 15.304 </td>
   <td style="text-align:right;"> 18.935 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> wins </td>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 0.422 </td>
   <td style="text-align:right;"> 15.474 </td>
   <td style="text-align:right;"> 20.568 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> wins </td>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 0.426 </td>
   <td style="text-align:right;"> 15.384 </td>
   <td style="text-align:right;"> 19.997 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> wins </td>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 0.438 </td>
   <td style="text-align:right;"> 15.519 </td>
   <td style="text-align:right;"> 19.594 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> true </td>
   <td style="text-align:left;"> 0 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 12.000 </td>
   <td style="text-align:right;"> 19.800 </td>
  </tr>
</tbody>
</table>

The table above show the results of hypermean calculations using trimmed and Winsorized mean. 
The "meantype" is the type of means. `mean` is the ordinary mean, and `trim` and `wins` indicates trimmed means and Winsorized means, respectively. `true` is the true value (observed value) of each forecated variable. 
"size" is the size of trimming or Winsorizing. 0.1 means that 10% of the total sample size is trimmed or Winsorized. 
"Rain" column shows the Brier score of the means (not the mean of the Brier score). 

We see that the trimmed means with 0.3 trimming show the closest values to the true value for temperature forecast and Blue Stone surface area forecast. However, as for the rain, the Brier score is the lower than others, meaning that the ordinary mean exhibits the best performance. This is because the majority of the people forecasted greater than 50% probability of rain and it was actually no rain. 

### Hypermeans by distribution weighting 


Here, we try to calculate the hypermeans using kernel distributions. 
The 10% trimming was performed for kernel with support $[-1,1]$ (i.e. Epanechnikov, Triweight, Triangle), and standardized for Gaussian using (ordinary) mean and standard deviation of the raw data. 


```r
dat_hyp1 = dat_survey2 %>%
  filter(week =="Week 1") %>%
  summarise(
    across(.cols=c(q2x1,Q3,Q4x1),
           .fns = list(mean = ~mean(.x,na.rm=TRUE),
                       trim = ~hypermean(.x,size=0.1,type="trim"),
                       epa = ~hypermean(.x,size=0.1,type="epa"),
                       trig = ~hypermean(.x,size=0.1,type="trig"),
                       triw = ~hypermean(.x,size=0.1,type="triw"),
                       gauss = ~hypermean(.x,size=0.1,type="gauss")
                       ))
  ) %>%
  mutate(q2x1_true = rain_true1,
         Q3_true = temp_true1,
         Q4x1_true = stone_true) %>%
  pivot_longer(cols=everything()) %>%
  separate(col=name,into=c("var","meantype","size"),sep="_") %>%
  # make brier score for Q2 rain
  mutate(var2 = ifelse(var == "q2x1","Rain",
                       ifelse(var=="Q3","Temp.",
                              ifelse(var=="Q4x1","Stone",var))),
         value2 = ifelse(var == "q2x1",(value/100-rain_true1)^2,value),
         size = ifelse(is.na(size),0,size)) %>%
  select(var2,meantype,size,value2) %>%
  mutate(value2 = round(value2,digits = 3)) %>%
  pivot_wider(id_cols = c(meantype,size), names_from = var2, values_from = value2)
  


dat_hyp2 = dat_survey2 %>%
  filter(week =="Week 2") %>%
  summarise(
    across(.cols=c(q2x1,Q3,Q4x1),
           .fns = list(mean = ~mean(.x,na.rm=TRUE),
                       trim = ~hypermean(.x,size=0.1,type="trim"),
                       epa = ~hypermean(.x,size=0.1,type="epa"),
                       trig = ~hypermean(.x,size=0.1,type="trig"),
                       triw = ~hypermean(.x,size=0.1,type="triw"),
                       gauss = ~hypermean(.x,size=0.1,type="gauss")
                       ))
  ) %>%
  mutate(q2x1_true = rain_true2,
         Q3_true = temp_true2,
         Q4x1_true = stone_true) %>%
  pivot_longer(cols=everything()) %>%
  separate(col=name,into=c("var","meantype","size"),sep="_") %>%
  # make brier score for Q2 rain
  mutate(var2 = ifelse(var == "q2x1","Rain",
                       ifelse(var=="Q3","Temp.",
                              ifelse(var=="Q4x1","Stone",var))),
         value2 = ifelse(var == "q2x1",(value/100-rain_true2)^2,value),
         size = ifelse(is.na(size),0,size)) %>%
  select(var2,meantype,size,value2) %>%
  mutate(value2 = round(value2,digits = 3)) %>%
  pivot_wider(id_cols = c(meantype,size), names_from = var2, values_from = value2)
```


```r
dat_hyp1 %>% kbl(caption = "Estimated hypermeans of survey answers to Rain probability, temperature, and Blue Stone questions based on distribution weighting. Week 1") %>% kable_classic(full_width = FALSE)
```

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
<caption>Estimated hypermeans of survey answers to Rain probability, temperature, and Blue Stone questions based on distribution weighting. Week 1</caption>
 <thead>
  <tr>
   <th style="text-align:left;"> meantype </th>
   <th style="text-align:right;"> size </th>
   <th style="text-align:right;"> Rain </th>
   <th style="text-align:right;"> Temp. </th>
   <th style="text-align:right;"> Stone </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> mean </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.327 </td>
   <td style="text-align:right;"> 17.478 </td>
   <td style="text-align:right;"> 22.396 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> trim </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.358 </td>
   <td style="text-align:right;"> 17.349 </td>
   <td style="text-align:right;"> 20.983 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> epa </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.376 </td>
   <td style="text-align:right;"> 17.240 </td>
   <td style="text-align:right;"> 19.454 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> trig </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.375 </td>
   <td style="text-align:right;"> 17.252 </td>
   <td style="text-align:right;"> 19.783 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> triw </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.376 </td>
   <td style="text-align:right;"> 17.277 </td>
   <td style="text-align:right;"> 20.238 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> gauss </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.354 </td>
   <td style="text-align:right;"> 17.299 </td>
   <td style="text-align:right;"> 19.859 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> true </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 16.300 </td>
   <td style="text-align:right;"> 19.800 </td>
  </tr>
</tbody>
</table>

```r
dat_hyp2 %>% kbl(caption = "Estimated hypermeans of survey answers to Rain probability, temperature, and Blue Stone questions based on distribution weighting. Week 2") %>% kable_classic(full_width = FALSE)
```

<table class=" lightable-classic" style='font-family: "Arial Narrow", "Source Sans Pro", sans-serif; width: auto !important; margin-left: auto; margin-right: auto;'>
<caption>Estimated hypermeans of survey answers to Rain probability, temperature, and Blue Stone questions based on distribution weighting. Week 2</caption>
 <thead>
  <tr>
   <th style="text-align:left;"> meantype </th>
   <th style="text-align:right;"> size </th>
   <th style="text-align:right;"> Rain </th>
   <th style="text-align:right;"> Temp. </th>
   <th style="text-align:right;"> Stone </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> mean </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.401 </td>
   <td style="text-align:right;"> 15.500 </td>
   <td style="text-align:right;"> 21.529 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> trim </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.428 </td>
   <td style="text-align:right;"> 15.397 </td>
   <td style="text-align:right;"> 19.791 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> epa </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.451 </td>
   <td style="text-align:right;"> 15.222 </td>
   <td style="text-align:right;"> 18.572 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> trig </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.450 </td>
   <td style="text-align:right;"> 15.224 </td>
   <td style="text-align:right;"> 18.809 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> triw </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.448 </td>
   <td style="text-align:right;"> 15.210 </td>
   <td style="text-align:right;"> 19.140 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> gauss </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.434 </td>
   <td style="text-align:right;"> 15.287 </td>
   <td style="text-align:right;"> 19.147 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> true </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 0.000 </td>
   <td style="text-align:right;"> 12.000 </td>
   <td style="text-align:right;"> 19.800 </td>
  </tr>
</tbody>
</table>

We observe that the distribution weighting improves the performance of Wisdom of Crowds effect relative to ordinary mean or trimmed mean for Temperature and Blue Stone predictions. 

# References

Budescu, David V, and Eva Chen. 2015. Identifying Expertise to Extract the Wisdom of Crowds. Management science 61 (2): 267???80.

Feliciani, Thomas, Michael Morreau, Junwen Luo, Pablo Lucas, and Kalpana Shankar. 2022. Designing grant-review panels for better funding decisions: Lessons from an empirically calibrated simulation model. Research policy 51 (4): 104467.

Jose, Victor Richmond R, and Robert L Winkler. 2008. Simple robust averages of forecasts: Some empirical results. International journal of forecasting 24 (1): 163???69.
