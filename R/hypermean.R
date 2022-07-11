
#' @title hypermean
#' @description This function computes hypermeans, weighted means with weights that weaken the contribution of those who tend to be far from the normal mean and amplify the contribution of those who tend to be closer to the normal mean.
#' @param x vector of observations
#' @param size trimming size. The value should be from 0 to 1.  (e.g. 0.1 is trimming 10%)
#' @param type Type of weighting. Default is \code{"trim"}. \code{c("trim","wins","epa","triw","trig","gauss")}
#' @param ret Return value. Default is \code{"mean"}. \code{c("mean","vector")}
#' @examples
#' x <- rnorm(1000,0,1)
#' hypermean(x,size=0.1,type="trim")

hypermean = function(x, size = 0.1, type = "trim",ret="mean"){

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
  nn = length(x)     # number of elements
  trimming = round(nn*size/2,digits=0) # amount to trim on one side

  new_x = sort(x)      # sorting the vector

  if(type == "trim"){
    # trimming
    new_x[1:trimming] = NA                    # trimming lefthand side
    new_x[(nn-trimming):nn] = NA              # trimming righthand side

    new_x2 = new_x                          # to return vector
    hyp_mean = mean(new_x,na.rm=TRUE)         # return hypermean
  }else if(type=="wins"){
    # winsorizing
    new_x[1:trimming] = new_x[trimming+1]          # Winsorizing lefthand side
    new_x[(nn-trimming):nn] = new_x[nn-trimming-1] # Winsorizing righthand side

    new_x2 = new_x                          # to return vector
    hyp_mean = mean(new_x,na.rm=TRUE)         # return hypermean
  }else if(type=="epa"){
    # epanechnikov
    new_x[1:trimming] = NA                    # trimming lefthand side
    new_x[(nn-trimming):nn] = NA              # trimming righthand side
    # dist.
    z = dist.conv(new_x)                     # standardize the values to get the weight
    w = dist.epa(z)
    w = ifelse(w < 0,0,w)
    w2 = w/sum(w,na.rm=TRUE)
    new_x2 = new_x*w2
    hyp_mean = sum(new_x2,na.rm=TRUE)
  }else if(type=="triw"){
    # triweight
    new_x[1:trimming] = NA                    # trimming lefthand side
    new_x[(nn-trimming):nn] = NA              # trimming righthand side
    # dist.
    z = dist.conv(new_x)                     # standardize the values to get the weight
    w = dist.triw(z)
    w = ifelse(w < 0,0,w)
    w2 = w/sum(w,na.rm=TRUE)
    new_x2 = new_x*w2
    hyp_mean = sum(new_x2,na.rm=TRUE)
  }else if(type=="trig"){
    # triangle distribution
    new_x[1:trimming] = NA                    # trimming lefthand side
    new_x[(nn-trimming):nn] = NA              # trimming righthand side
    # dist.
    z = dist.conv(new_x)                     # standardize the values to get the weight
    w = dist.trig(z)
    w = ifelse(w < 0,0,w)
    w2 = w/sum(w,na.rm=TRUE)
    new_x2 = new_x*w2
    hyp_mean = sum(new_x2,na.rm=TRUE)
  }else if(type=="gauss"){
    # gaussian distribution
    # So far no trimming for gaussian (because the support is not limited to -1 to 1), so comment out below.
    ## new_x[1:trimming] = NA                    # trimming lefthand side
    ## new_x[(nn-trimming):nn] = NA              # trimming righthand side
    # dist.
    z = dist.conv.gauss(new_x)                     # standardize the values to get the weight. standardized by SE of data
    w = dist.gauss(z)
    w = ifelse(w < 0,0,w)
    w2 = w/sum(w,na.rm=TRUE)
    new_x2 = new_x*w2
    hyp_mean = sum(new_x2,na.rm=TRUE)
  }

  # return either hypermean or vector
  if(ret == "mean"){
    return(hyp_mean)
  }else if(ret =="vector"){
    return(new_x2)
  }
}
