\docType{package}
\name{ggmcmc}
\alias{ggmcmc}
\alias{ggmcmc-package}
\title{Wrapper function that creates a single pdf file with all plots that ggmcmc can produce.}
\usage{
  ggmcmc(D, file = "ggmcmc-output.pdf", family = NA,
    param.page = 5, width = 7, height = 10, ...)
}
\arguments{
  \item{D}{Data frame whith the simulations, previously
  arranged using \code{\link{ggs}}}

  \item{file}{Character vector with the name of the file to
  create. Defaults to "ggmcmc-output.pdf". When NULL, no
  pdf device is opened or closed. This allows the user to
  work with an opened pdf (or other) device.}

  \item{family}{Name of the family of parameters to plot,
  as given by a character vector or a regular expression. A
  family of parameters is considered to be any group of
  parameters with the same name but different numerical
  value between square brackets (as beta[1], beta[2],
  etc).}

  \item{param.page}{Numerical, number of parameters to plot
  for each page. Defaults to 5.}

  \item{width}{Width of the pdf display, in inches.
  Defaults to 7.}

  \item{height}{Height of the pdf display, in inches.
  Defaults to 10.}

  \item{...}{Other options passed to the pdf device.}
}
\description{
  \code{ggmcmc()} is simply a wrapper function that
  generates a pdf file with all the potential plots that
  the package can produce.

  ggmcmc is a tool for assessing and diagnosing convergence
  of Markov Chain Monte Carlo simulations, as well as for
  graphically display results from full MCMC analysis. The
  package also facilitates the graphical interpretation of
  models by providing flexible functions to plot the
  results against observed variables.
}
\details{
  Notice that caterpillar plots are only created when there
  are multiple parameters within the same family. A family
  of parameters is considered to be all parameters that
  have the same name (usually the same greek letter) but
  different number within square brackets (such as
  alpha[1], alpha[2], ...).
}
\examples{
data(samples)
ggmcmc(ggs(S))  # Directly from a coda object
}
\references{
  \url{http://xavier-fim.net/packages/ggmcmc}.
}

