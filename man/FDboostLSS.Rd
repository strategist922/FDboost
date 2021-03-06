% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/FDboostLSS.R
\name{FDboostLSS}
\alias{FDboostLSS}
\title{Model-based Gradient Boosting for Functional GAMLSS}
\usage{
FDboostLSS(formula, timeformula, data = list(), families = GaussianLSS(),
  control = boost_control(), weights = NULL, method = c("cyclic",
  "noncyclic"), ...)
}
\arguments{
\item{formula}{a symbolic description of the model to be fit. 
If \code{formula} is a single formula, the same formula is used for all distribution parameters. 
\code{formula} can also be a (named) list, where each list element corresponds to one distribution 
parameter of the GAMLSS distribution. The names must be the same as in the \code{families}.}

\item{timeformula}{one-sided formula for the expansion over the index of the response. 
For a functional response \eqn{Y_i(t)} typically \code{~bbs(t)} to obtain a smooth 
expansion of the effects along \code{t}. In the limiting case that \eqn{Y_i} is a scalar response
use \code{~bols(1)}, which sets up a base-learner for the scalar 1. 
Or you can use \code{timeformula=NULL}, then the scalar response is treated as scalar. 
Analogously to \code{formula}, \code{timeformula} can either be a one-sided formula or 
a named list of one-sided formulas.}

\item{data}{a data frame or list containing the variables in the model.}

\item{families}{an object of class \code{families}. It can be either one of the pre-defined distributions 
that come along with the package \code{gamboostLSS} or a new distribution specified by the user 
(see \code{\link[gamboostLSS]{Families}} for details). 
Per default, the two-parametric \code{\link[gamboostLSS]{GaussianLSS}} family is used.}

\item{control}{a list of parameters controlling the algorithm. 
For more details see \code{\link[mboost]{boost_control}}.}

\item{weights}{does not work!}

\item{method}{fitting method, currently two methods are supported: 
\code{"cyclic"} (see Mayr et al., 2012) and \code{"noncyclic"} 
(algorithm with inner loss of Thomas et al., 2016).}

\item{...}{additional arguments passed to \code{\link[FDboost]{FDboost}}, 
including, \code{family} and \code{control}.}
}
\value{
An object of class \code{FDboostLSS} that inherits from \code{mboostLSS}. 
The \code{FDboostLSS}-object is a named list containing one list entry per distribution parameter
and some attributes. The list is named like the parameters, e.g. mu and sigma, 
if the parameters mu and sigma are modeled. Each list-element is an object of class \code{FDboost}.
}
\description{
Function for fitting generalized additive models for location, scale and shape (GAMLSS)  
with functional data using component-wise gradient boosting, for details see 
Brockhaus et al. (2015a).
}
\details{
For details on the theory of GAMLSS, see Rigby and Stasinopoulos (2005). 
\code{FDboostLSS} calls \code{FDboost} to fit the distribution parameters of a GAMLSS - 
a functional boosting model is fitted for each parameter of the response distribution.  
In \code{\link[gamboostLSS]{mboostLSS}}, details on boosting of GAMLSS based on 
Mayr et al. (2012) and Thomas et al. (2016) are given.   
In \code{\link{FDboost}}, details on boosting regression models with functional variables 
are given (Brockhaus et al., 2015b, Brockhaus et al., 2017).
}
\examples{
########### simulate Gaussian scalar-on-function data
n <- 500 ## number of observations
G <- 120 ## number of observations per functional covariate
set.seed(123) ## ensure reproducibility
z <- runif(n) ## scalar covariate
z <- z - mean(z)
s <- seq(0, 1, l=G) ## index of functional covariate
## generate functional covariate
if(require(splines)){
   x <- t(replicate(n, drop(bs(s, df = 5, int = TRUE) \%*\% runif(5, min = -1, max = 1))))
}else{
  x <- matrix(rnorm(n*G), ncol = G, nrow = n)
}
x <- scale(x, center = TRUE, scale = FALSE) ## center x per observation point

mu <- 2 + 0.5*z + (1/G*x) \%*\% sin(s*pi)*5 ## true functions for expectation
sigma <- exp(0.5*z - (1/G*x) \%*\% cos(s*pi)*2) ## for standard deviation

y <- rnorm(mean = mu, sd = sigma, n = n) ## draw respone y_i ~ N(mu_i, sigma_i)

## save data as list containing s as well 
dat_list <- list(y = y, z = z, x = I(x), s = s)

## model fit assuming Gaussian location scale model 
m_boost <- FDboostLSS(list(mu = y ~ bols(z, df = 2) + bsignal(x, s, df = 2, knots = 16), 
                           sigma = y ~ bols(z, df = 2) + bsignal(x, s, df = 2, knots = 16)), 
                           timeformula = NULL, data = dat_list)
summary(m_boost)

\dontrun{
 if(require(gamboostLSS)){
  ## find optimal number of boosting iterations on a grid in [1, 500]
  ## using 5-fold bootstrap
  grid <-  make.grid(c(mu = 500, sigma = 500), length.out = 10)
  ## takes some time, easy to parallelize on Linux
  set.seed(123) 
  cvr <- cvrisk(m_boost, folds = cv(model.weights(m_boost[[1]]), B = 5),
                grid = grid, trace = FALSE)
  ## use model at optimal stopping iterations 
  m_boost <- m_boost[mstop(cvr)] ## [c(172, 63)]
   
  ## plot smooth effects of functional covariates
  par(mfrow = c(1,2))
  plot(m_boost$mu, which = 2, ylim = c(0,5))
  lines(s, sin(s*pi)*5, col = 3, lwd = 2)
  plot(m_boost$sigma, which = 2, ylim = c(-2.5,2.5))
  lines(s, -cos(s*pi)*2, col = 3, lwd = 2)
 }
}
}
\references{
Brockhaus, S. and Fuest, A. and Mayr, A. and Greven, S. (2015a): 
Functional regression models for location, scale and shape applied to stock returns. 
In: Friedl H. and Wagner H. (eds), 
Proceedings of the 30th International Workshop on Statistical Modelling: 117-122.  

Brockhaus, S., Scheipl, F., Hothorn, T. and Greven, S. (2015b). 
The functional linear array model. Statistical Modelling, 15(3), 279-300.

Brockhaus, S., Melcher, M., Leisch, F. and Greven, S. (2017): 
Boosting flexible functional regression models with a high number of functional historical effects,  
Statistics and Computing, 27(4), 913-926.

Mayr, A., Fenske, N., Hofner, B., Kneib, T. and Schmid, M. (2012): 
Generalized additive models for location, scale and shape for high-dimensional 
data - a flexible approach based on boosting. 
Journal of the Royal Statistical Society: Series C (Applied Statistics), 61(3), 403-427. 

Rigby, R. A. and D. M. Stasinopoulos (2005):  
Generalized additive models for location, scale and shape (with discussion). 
Journal of the Royal Statistical Society: Series C (Applied Statistics), 54(3), 507-554. 

Thomas, J., Mayr, A., Bischl, B., Schmid, M., Smith, A., and Hofner, B. (2016), 
Gradient boosting for distributional regression - faster tuning and improved 
variable selection via noncyclical updates. 
Accepted for publication in Statistics and Computing.  
Preliminary version: \url{http://arxiv.org/abs/1611.10171}.
}
\seealso{
Note that \code{FDboostLSS} calls \code{\link{FDboost}} directly.
}
\author{
Sarah Brockhaus
}
\keyword{models,}
\keyword{nonlinear}
