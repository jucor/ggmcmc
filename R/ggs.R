#' Import MCMC samples into a ggs object than can be used by all ggs_* graphical functions.
#'
#' This function manages MCMC samples from different sources (JAGS, MCMCpack, STAN -both via rstan and via csv files-) and converts them into a data frame. The resulting data frame has four columns (Iteration, Parameter, value, Chain) and seven attributes (nChains, nParameters, nIterations, nBurnin, nThin, description and parallel). The ggs object returned is then used as the input of the ggs_* functions to actually plot the different convergence diagnostics.
#'
#' @param S Either a \code{mcmc.list} object with samples from JAGS, a \code{mcmc} object with samples from MCMCpack, a \code{stanfit} object with samples from rstan, or a list with the filenames of \code{csv} files generated by stan outside rstan (where the order of the files is assumed to be the order of the chains). ggmcmc guesses what is the original object and tries to import it accordingly. rstan is not expected to be in CRAN soon, and so coda::mcmc is used to extract stan samples instead of the more canonical rstan::extract.
#' @param family Name of the family of parameters to process, as given by a character vector or a regular expression. A family of parameters is considered to be any group of parameters with the same name but different numerical value between square brackets (as beta[1], beta[2], etc).
#' @param description Character vector giving a short descriptive text that identifies the model.
#' @param burnin Logical or numerical value. When logical and TRUE (the default), the number of samples in the burnin period will be taken into account, if it can be guessed by the extracting process. Otherwise, iterations will start counting from 1. If a numerical vector is given, the user then supplies the length of the burnin period. 
#' @param par_labels data frame with two colums. One named "Parameter" with the same names of the parameters of the model. Another named "Label" with the label of the parameter. When missing, the names passed to the model are used for representation. When there is no correspondence between a Parameter and a Label, the original name of the parameter is used. The order of the levels of the original Parameter does not change.
#' @param inc_warmup Logical. When dealing with stanfit objects from rstan, logical value whether the warmup samples are included. Defaults to FALSE.
#' @param stan_include_auxiliar Logical value to include "lp__" parameter in rstan, and "lp__", "treedepth__" and "stepsize__" in stan running without rstan. Defaults to FALSE.
#' @param parallel Logical value for using parallel computing when managing the data frame in other functions. Defaults to FALSE. It needs a registered parallel backend. Currently it has only been extensively tested in \code{doMC}.
#' @export
#' @return D A data frame with the data arranged and ready to be used by the rest of the \code{ggmcmc} functions. The data frame has four columns, namely: Iteration, Parameter, value and Chain, and seven attributes: nChains, nParameters, nIterations, nBurnin, nThin, description and parallel.
#' @examples
#' # Assign 'D' to be a data frame suitable for \code{ggmcmc} functions from 
#' # a coda object called S
#' data(samples)
#' D <- ggs(S)        # S is a coda object
ggs <- function(S, family=NA, description=NA, burnin=TRUE, par_labels=NA, inc_warmup=FALSE, stan_include_auxiliar=FALSE, parallel=FALSE) {
  processed <- FALSE # set by default that there has not been any processed samples
  #
  # Manage stanfit obcjets
  # Manage stan output first because it is firstly converted into an mcmc.list
  #
  if (class(S)=="stanfit") { 
    if (inc_warmup) warning("inc_warmup must be 'FALSE', so it is ignored.")
    D <- melt(as.array(S))
    names(D)[1:3] <- c("Iteration", "Chain", "Parameter")
    D$Chain <- as.integer(gsub("chain:", "", D$Chain))
    # Exclude, by default, lp parameter
    if (!stan_include_auxiliar) {
      D <- subset(D, Parameter!="lp__") # delete lp__
      D$Parameter <- factor(as.character(D$Parameter))
    }
    nBurnin <- S@sim$warmup
    nThin <- S@sim$thin
    mDescription <- S@model_name
    processed <- TRUE  # whether the object has been processed or not
  }
  #
  # Manage csv files than contain stan samples
  # Also converted first to an mcmc.list
  #
  if (class(S)=="list") {
    D <- NULL
    for (i in 1:length(S)) {
      samples.c <- read.table(S[[i]], sep=",", header=TRUE, colClasses="numeric") 
      samples <- suppressMessages(melt(samples.c, variable.name="Parameter"))
      D <- rbind(D, cbind(Iteration=1:(dim(samples.c)[1]), Chain=i, samples))
    }
    # Exclude, by default, lp parameter and other auxiliar ones
    if (!stan_include_auxiliar) {
      D <- D[grep("__$", D$Parameter, invert=TRUE),]
      D$Parameter <- factor(as.character(D$Parameter))
    }
    nBurnin <- as.integer(gsub("warmup=", "", scan(S[[i]], "", skip=12, nlines=1, quiet=TRUE)[2]))
    nThin <- as.integer(gsub("thin=", "", scan(S[[i]], "", skip=13, nlines=1, quiet=TRUE)[2]))
    processed <- TRUE
  }
  #
  # Manage mcmc.list and mcmc objects
  #
  if (class(S)=="mcmc.list" | class(S)=="mcmc" | processed) {  # JAGS typical output or MCMCpack (or previously processed stan samples)
    if (!processed) { # only in JAGS or MCMCpack, using coda
      lS <- length(S)
      D <- NULL
      if (lS == 1 | class(S)=="mcmc") { # Single chain or MCMCpack
        if (lS == 1 & class(S)=="mcmc.list") { # single chain
          s <- S[[1]]
        } else { # MCMCpack
          s <- S
        }
        # Process a single chain
        D <- cbind(ggs_chain(s), Chain=1)
        D <- D[,c("Iteration", "Chain", "Parameter", "value")]
        # Get information from mcpar (burnin period, thinning)
        nBurnin <- (attributes(s)$mcpar[1])-(1*attributes(s)$mcpar[3])
        nThin <- attributes(s)$mcpar[3]
      } else {
        # Process multiple chains
        for (l in 1:lS) {
          s <- S[l][[1]]
          D <- rbind(D, cbind(ggs_chain(s), Chain=l))
        }
        D <- D[,c("Iteration", "Chain", "Parameter", "value")]
        # Get information from mcpar (burnin period, thinning). Taking the last
        # chain is fine. All chains are assumed to have the same structure.
        nBurnin <- (attributes(s)$mcpar[1])-(1*attributes(s)$mcpar[3])
        nThin <- attributes(s)$mcpar[3]
      }
    }
    # Set several attributes to the object, to avoid computations afterwards
    # Number of chains
    attr(D, "nChains") <- length(unique(D$Chain))
    # Number of parameters
    attr(D, "nParameters") <- length(unique(D$Parameter))
    # Number of Iterations really present in the sample
    attr(D, "nIterations") <- max(D$Iteration)
    # Number of burning periods previously
    if (is.numeric(burnin) & length(burnin)==1) {
      attr(D, "nBurnin") <- burnin
    } else if (is.logical(burnin)) {
      if (burnin) {
        attr(D, "nBurnin") <- nBurnin
      } else {
        attr(D, "nBurnin") <- 0
      }
    } else {
      stop("burnin must be either logical (TRUE/FALSE) or a numerical vector of length one.")
    }
    # Thinning interval
    attr(D, "nThin") <- nThin
    # Descriptive text
    if (is.character(description)) { # if the description is given, us it when it is a character string
      attr(D, "description") <- description
    } else {
      if (!is.na(description)) { # if it is not a character string and not NA, show an informative message
        print("description is not a text string. The name of the imported object is used instead.")
      }
      if (exists("mDescription")) { # In case of stan model names
        attr(D, "description") <- mDescription
      } else {
        attr(D, "description") <- as.character(sys.call()[2]) # use the name of the source object
      }
    }
    # Whether parallel computing is desired
    attr(D, "parallel") <- parallel
    # Manage subsetting a family of parameters
    # In order to save memory, the exclusion of parameters would be done ideally
    # at the beginning of the processing, but then it has to be done for all
    # input types.
    if (!is.na(family)) {
      D <- get_family(D, family=family)
    }
    # Change the names of the parameters if par_labels argument has been passed
    if (class(par_labels)=="data.frame") {
      if (length(which(c("Parameter", "Label") %in% names(par_labels))) == 2) {
        levels(D$Parameter)[which(levels(D$Parameter) %in% par_labels$Parameter)] <-
          as.character(par_labels$Label[which(par_labels$Parameter %in% levels(D$Parameter))])
      } else {
        stop("par_labels must include at least columns called 'Parameter' and 'Label'.")
      }
    } else {
      if (!is.na(par_labels)) {
        stop("par_labels must be a data frame.")
      }
    }
    # Once everything is ready, return the processed object
    return(D)
  } else {
    stop("ggs is not able to transform the input object into a ggs object suitable for ggmcmc.")
  }
}

#' Auxiliary function that extracts information from a single chain.
#'
#' @param s a single chain to convert into a data frame
#' @return D data frame with the chain arranged
ggs_chain <- function(s) {
  # Get the names of the chains, the number of samples and the vector of
  # iterations
  name.chains <- dimnames(s)[[2]]
  n.samples <- dim(s)[1]
  iter <- 1:n.samples

  # Prepare the dataframe
  d <- data.frame(Iteration=iter, as.matrix(unclass(s)))
  D <- melt(d, id.vars=c("Iteration"), variable.name="Parameter")

  # Revert the name of the parameters to their original names
  levels(D$Parameter) <- name.chains

  # Return the modified data frame
  return(D)
}
