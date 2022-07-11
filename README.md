# hypermeanr

Development of a R function to calculate hypermean.

**Note:** This is very early version.

## Hypermean?

**Hypermeans** are weighted means with weights that weaken the contribution of those who tend to be far from the normal mean and amplify the contribution of those who tend to be closer to the normal mean. The idea behind this is the wisdom of crowds, that people who are far from the mean tend to be wrong more than those who are closer to the mean (Feliciani et al. 2022).

The **wisdom of the crowds ** is the idea that the collective opinion of a diverse independent group of individuals rather than that of a single expert (Surowiecki, 2004). This phenomenon is explained by the fact that there is noise inherent in each individual decision, and that taking the average of a large number of responses cancels out some of the effects of this noise (Yi et al., 2012).

There are a series of weighting rules. For exmaples, the rules include trimmed mean (Jose and Winkler 2008), past performance (Budescu & Chen, 2015). Feliciani et al. (2022) uses the correlation (Spearman's $\rho$) between the individuals' and overall rankings of evaluation because the variable of interest is rankings. 

## Weighting rules

###  Trimmed mean

Trimmed mean is technically not a hypermean in a narrow sense, but we can think of that weight of observations outside of an arbitral threshold is zero, and those inside is one. 

Jose and Winkler (2008) test the performance of trimmed means and Winsorizing means when combining forecasts to obtain a single aggregated forecast. They conclude that trimmed and Winsorizing means are slightly better than the ordinary (simple) mean. 

Suppose there are $n$ forecasts, $X_1,\ldots,X_{n}$ of the interest of forecast, $Y$. Suppose the $X$ are ordered, and the $X_{(i)}$ is the $i$th order statistic for $X_{1},\ldots,X_n$. The trimmed mean $T(i)$ and Winsorized mean $W(i)$ are defined as follows. 

$$
 T(i) = \frac{1}{n-2i}\sum_{k=i+1}^{n-i}X_{(k)} \\
 W(i) = \frac{1}{n}[iX_{i+1} + \sum_{k=i+1}^{n-i}X_{(k)}+iX_{(n-i)}]
$$

Intuitively, trimmed mean simply trimmed the both sides outliers by $i$, while Winsorized mean set the value of outliers equal to $i+1$ th value from the edge. 

The question is, how much should we trim or Winsorize? Jose and Winkler (2008) recommend 10-30% (5-15% on each side) for trimming, and 15-45% (7.5-22.5% on each side) for Winsorizing. 

The figure below is an intuitive example of trimmed and Winsorized averages using simulated data. The data are generated from $X ~ N(0,1)$ and the sample size is 1000. While the raw data follows a normal distribution, the trimmed data loses samples with values far from the mean or median; the Winsorized data has bunching at the same support end as the Trimmed data.

![Examples of trimmed and Winsorized means with simulated data.](https://github.com/keita43a/hypermeanr/blob/master/output/docs/hypermean_files/figure-html/unnamed-chunk-4-1.png?raw=true)


### Distribution weighting

Trimming deletes the outliers but does not change the weights of the individuals remaining in the sample. 
Here, we suggest a weighting rule based on distributions arbitrarily chosen. 

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


![Common kernel distribution functions](https://github.com/keita43a/hypermeanr/blob/master/output/docs/hypermean_files/figure-html/unnamed-chunk-6-1.png?raw=true)

### Application of distribution weighting  

How do we apply the kernel distribution, whose support is usually $[-1,1]$, to apply to the data? 

**Idea**: The closer edge of the trimmed data is the edge of the support. That is, we standardize the data to align with the support of the kernel distribution. 

$$
  z = \frac{(x - E(x))}{\min[x-\min(x),\max(x)-x]}
$$

Then either minimum or maximum of the trimmed data $x$ will be on the edge of the support of the kernel distribution, and the mean of the kernel is equal to the mean of the data. 

The graphical examples are shown below. The first one is the data generated from standard normal distribution. After trimming, the data is fairly symmetric. By overlaying the kernel distribution using the standardized data $z$, it shows a fair weighting. 

![Example of applying distribution weight with simulated data. The sample is generated from standard normal distribution and trimmed by 10%. Epanechnikov kernel is applied for the weight.](https://github.com/keita43a/hypermeanr/blob/master/output/docs/hypermean_files/figure-html/unnamed-chunk-8-1.png?raw=true)

The second figure below shows the data generated from standard log normal distribution. After trimming, the data is not symmetric. The overlay-ed kernel distribution shows the weighting but the most frequent values are not largely weighted. 

![Example of applying distribution weight with simulated data. The sample is generated from standard log normal distribution and trimmed by 10%. Epanechnikov kernel is applied for the weight.](https://github.com/keita43a/hypermeanr/blob/master/output/docs/hypermean_files/figure-html/unnamed-chunk-9-1.png?raw=true)

## Use of function

```r

# install
devtools::install_github("keita43a/hypermeanr")

# load package
library("hypermeanr")

# random data
x<-rnorm(1000,0,1)

# hypermeans 
hypermean(x) # trimmed mean trimming 10% of the sample. 

hypermean(x, size = 0.2) # trimmed mean trimming 20% of the sample

hypermean(x, type = "epa") # weighted mean using Epanechnikov distribution as weight

hypermean(x, ret="vector") # returns the trimmed vector instead of the mean.

```


## References

Budescu, David V, and Eva Chen. 2015. Identifying Expertise to Extract the Wisdom of Crowds. Management science 61 (2): 267–80.

Feliciani, Thomas, Michael Morreau, Junwen Luo, Pablo Lucas, and Kalpana Shankar. 2022. Designing grant-review panels for better funding decisions: Lessons from an empirically calibrated simulation model. Research policy 51 (4): 104467.

Jose, Victor Richmond R, and Robert L Winkler. 2008. Simple robust averages of forecasts: Some empirical results. International journal of forecasting 24 (1): 163–69.

Surowiecki, James. 2005. The Wisdom of Crowds. Knopf Doubleday Publishing Group.

Yi, Sheng Kung Michael, Mark Steyvers, Michael D Lee, and Matthew J Dry. 2012. The wisdom of the crowd in combinatorial problems. Cognitive science 36 (3): 452–70.
