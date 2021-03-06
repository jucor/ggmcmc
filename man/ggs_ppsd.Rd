\name{ggs_ppsd}
\alias{ggs_ppsd}
\title{Posterior predictive plot comparing the outcome vs the posterior standard deviations.}
\usage{
  ggs_ppsd(D, outcome, family = NA, bins = 30)
}
\arguments{
  \item{D}{Data frame whith the simulations. Notice that
  only the posterior outcomes are needed, and so either the
  ggs() call limits the parameters to the outcomes or the
  user provides a family of parameters to limit it.}

  \item{outcome}{vector (or matrix or array) containing the
  observed outcome variable. Currently only a vector is
  supported.}

  \item{family}{Name of the family of parameters to plot,
  as given by a character vector or a regular expression. A
  family of parameters is considered to be any group of
  parameters with the same name but different numerical
  value between square brackets (as beta[1], beta[2],
  etc).}

  \item{bins}{integer indicating the total number of bins
  in which to divide the histogram. Defaults to 30, which
  is the same as geom_histogram()}
}
\value{
  A \code{ggplot} object.
}
\description{
  Histogram with the distribution of the predicted
  posterior standard deviations, compared with the standard
  deviationsof the observed outcome.
}
\examples{
\dontrun{
data(samples)
ggs_ppsd(ggs(S, family="y"), outcome="y")
}
}

