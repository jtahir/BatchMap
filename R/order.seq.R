#######################################################################
#                                                                     #
# Package: BatchMap                                                     #
#                                                                     #
# File: order.seq.R                                                   #
# Contains: order.seq, print.order                                    #
#                                                                     #
# Written by Gabriel R A Margarido & Marcelo Mollinari                #
# copyright (c) 2009, Gabriel R A Margarido & Marcelo Mollinari       #
# Modified by Bastian Schiffthaler                                    #
#                                                                     #
# First version: 02/27/2009                                           #
# Last update: 01/14/2016                                             #
# License: GNU General Public License version 2 (June, 1991) or later #
#                                                                     #
#######################################################################

## This function automates linkage map construction in two steps:
## first, it applies the 'compare' algorithm to a subset of markers;
## second, it adds markers sequentially with the 'try' function


##' Search for the best order of markers combining compare and try.seq
##' functions
##'
##' For a given sequence of markers, this function first uses the
##' \code{compare} function to create a framework for a subset of informative
##' markers. Then, it tries to map remaining ones using the \code{try.seq}
##' function.
##'
##' For outcrossing populations, the initial subset and the order in which
##' remaining markers will be used in the \code{try.seq} step is given by the
##' degree of informativeness of markers (i.e markers of type A, B, C and D, in
##' this order).
##'
##' For backcrosses, F2s or RILs, two methods can be used for
##' choosing the initial subset: i) \code{"sample"} randomly chooses a number
##' of markers, indicated by \code{n.init}, and calculates the multipoint
##' log-likelihood of the \eqn{\frac{n.init!}{2}}{n.init!/2} possible orders.
##' If the LOD Score of the second best order is greater than
##' \code{subset.THRES}, than it takes the best order to proceed with the
##' \code{try.seq} step. If not, the procedure is repeated. The maximum number
##' of times to repeat this procedure is given by the \code{subset.n.try}
##' argument. ii) \code{"twopt"} uses a two-point based algorithm, given by the
##' option \code{"twopt.alg"}, to construct a two-point based map. The options
##' are \code{"rec"} for RECORD algorithm, \code{"rcd"} for Rapid Chain
##' Delineation, \code{"ser"} for Seriation and \code{"ug"} for Unidirectional
##' Growth. Then, equally spaced markers are taken from this map. The
##' \code{"compare"} step will then be applied on this subset of markers.
##'
##' In both cases, the order in which the other markers will be used in the
##' \code{try.seq} step is given by marker types (i.e. co-dominant before
##' dominant) and by the missing information on each marker.
##'
##' After running the \code{compare} and \code{try.seq} steps, which result in
##' a "safe" order, markers that could not be mapped are "forced" into the map,
##' resulting in a map with all markers positioned.
##'
##' @param input.seq an object of class \code{sequence}.
##' @param n.init the number of markers to be used in the \code{compare} step
##' (defaults to 5).
##' @param subset.search a character string indicating which method should be
##' used to search for a subset of informative markers for the
##' \code{\link{compare}} step. It is used for backcross, \eqn{F_2}{F_2} or RIL
##' populations, but not for outcrosses. See the \code{Details} section.
##' @param subset.n.try integer. The number of times to repeat the subset
##' search procedure. It is only used if \code{subset.search=="sample"}. See
##' the \code{Details} section.
##' @param subset.THRES numerical. The threshold for the subset search
##' procedure. It is only used if \code{subset.search=="sample"}. See the
##' \code{Details} section.
##' @param twopt.alg a character string indicating which two-point algorithm
##' should be used if \code{subset.search=="twopt"}. See the \code{Details}
##' section.
##' @param THRES threshold to be used when positioning markers in the
##' \code{try.seq} step.
##' @param touchdown logical. If \code{FALSE} (default), the \code{try.seq}
##' step is run only once, with the value of \code{THRES}. If \code{TRUE},
##' \code{try.seq} runs with \code{THRES} and then once more, with
##' \code{THRES-1}. The latter calculations take longer, but usually are able
##' to map more markers.
##' \code{try.seq} step is displayed. See \code{Details} section in
##' \code{\link[BatchMap]{try.seq}} function.
##' @param wait the minimum time interval in seconds to display the diagnostic
##' graphic for each \code{try.seq} step. Defaults to 0.00
##' @param tol tolerance number for the C routine, i.e., the value used to
##' evaluate convergence of the EM algorithm.
##' @return An object of class \code{order}, which is a list containing the
##' following components: \item{ord}{an object of class \code{sequence}
##' containing the "safe" order.} \item{mrk.unpos}{a \code{vector} with
##' unpositioned markers (if they exist).} \item{LOD.unpos}{a \code{matrix}
##' with LOD-Scores for unmapped markers, if any, for each position in the
##' "safe" order.} \item{THRES}{the same as the input value, just for
##' printing.} \item{ord.all}{an object of class \code{sequence} containing the
##' "forced" order, i.e., the best order with all markers.}
##' \item{data.name}{name of the object of class \code{outcross} with the raw
##' data.} \item{twopt}{name of the object of class \code{rf.2pts} with the
##' 2-point analyses.}
##' @author Gabriel R A Margarido, \email{gramarga@@usp.br} and Marcelo
##' Mollinari, \email{mmollina@@gmail.com}
##' @seealso \code{\link[BatchMap]{make.seq}}, \code{\link[BatchMap]{compare}} and
##' \code{\link[BatchMap]{try.seq}}.
##' @references Broman, K. W., Wu, H., Churchill, G., Sen, S., Yandell, B.
##' (2008) \emph{qtl: Tools for analyzing QTL experiments} R package version
##' 1.09-43
##'
##' Jiang, C. and Zeng, Z.-B. (1997). Mapping quantitative trait loci with
##' dominant and missing markers in various crosses from two inbred lines.
##' \emph{Genetica} 101: 47-58.
##'
##' Lander, E. S. and Green, P. (1987). Construction of multilocus genetic
##' linkage maps in humans. \emph{Proc. Natl. Acad. Sci. USA} 84: 2363-2367.
##'
##' Lander, E. S., Green, P., Abrahamson, J., Barlow, A., Daly, M. J., Lincoln,
##' S. E. and Newburg, L. (1987) MAPMAKER: An interactive computer package for
##' constructing primary genetic linkage maps of experimental and natural
##' populations. \emph{Genomics} 1: 174-181.
##'
##' Mollinari, M., Margarido, G. R. A., Vencovsky, R. and Garcia, A. A. F.
##' (2009) Evaluation of algorithms used to order markers on genetics maps.
##' \emph{Heredity} 103: 494-502.
##'
##' Wu, R., Ma, C.-X., Painter, I. and Zeng, Z.-B. (2002a) Simultaneous maximum
##' likelihood estimation of linkage and linkage phases in outcrossing species.
##' \emph{Theoretical Population Biology} 61: 349-363.
##'
##' Wu, R., Ma, C.-X., Wu, S. S. and Zeng, Z.-B. (2002b). Linkage mapping of
##' sex-specific differences. \emph{Genetical Research} 79: 85-96
##' @keywords utilities
##' @examples
##'
##' \dontrun{
##'   #outcross example
##'   data(example.out)
##'   twopt <- rf.2pts(example.out)
##'   all.mark <- make.seq(twopt,"all")
##'   groups <- group(all.mark)
##'   LG2 <- make.seq(groups,2)
##'   LG2.ord <- order.seq(LG2,touchdown=TRUE)
##'   LG2.ord
##'   make.seq(LG2.ord) # get safe sequence
##'   make.seq(LG2.ord,"force") # get forced sequence
##'
##' }
##'
order.seq <- function(input.seq, n.init=5, subset.search=c("twopt", "sample"),
                      subset.n.try=30, subset.THRES=3, twopt.alg= c("rec", "rcd", "ser", "ug"),
                      THRES=3, touchdown=FALSE, wait=0, tol=10E-2) {
  ## checking for correct objects
  if(!any(class(input.seq)=="sequence")) stop(deparse(substitute(input.seq))," is not an object of class 'sequence'")
  if(n.init < 2) stop("'n.init' must be greater than or equal to 2")
  if(!is.logical(touchdown)) stop("'touchdown' must be logical")
  if(!touchdown && THRES <= 10E-10) stop("Threshold must be greater than 0 if 'touchdown' is FALSE")
  if(touchdown && THRES <= (1 + 10E-10)) stop("Threshold must be greater than 1 if 'touchdown' is TRUE")
  if(wait < 0){
    warning("'wait' should not be < 0!")
    wait<-0
  }
  wait<-0
  if(length(input.seq$seq.num) <= n.init) {
    ## in this case, only the 'compare' function is used
    cat("   Length of sequence ",deparse(substitute(input.seq))," is less than n.init \n   Returning the best order using compare function:\n")
    ifelse(length(input.seq$seq.num) == 2, seq.ord <- map(input.seq,tol=10E-5), seq.ord <- make.seq(compare(input.seq=input.seq,tol=10E-5),1))
    seq.ord<-map(seq.ord, tol=10E-5)
    structure(list(ord=seq.ord, mrk.unpos=NULL, LOD.unpos=NULL, THRES=THRES,
                   ord.all=seq.ord, data.name=input.seq$data.name, twopt=input.seq$twopt), class = "order")
  }
  else
  {
    ## here, the complete algorithm will be applied
    cross.type <- class(get(input.seq$data.name, pos=1))[2]
    FLAG <- "outcross"
    ## select the order in which markers will be added

    cat("\nCross type: outcross\nUsing segregation types of the markers to choose initial subset\n")
    segregation.types <- get(input.seq$data.name, pos=1)$segr.type.num[input.seq$seq.num]
    if(sum(segregation.types == 7) > sum(segregation.types == 6)) segregation.types[segregation.types == 6] <- 8 ## if there are more markers of type D2 than D1, try to map those first
    seq.work <- order(segregation.types)
    seq.init <- input.seq$seq.num[seq.work[1:n.init]]
  }
  ##apply the 'compare' step to the subset of initial markers
  seq.ord <- compare(input.seq=make.seq(get(input.seq$twopt), seq.init, twopt=input.seq$twopt), n.best=50)

  ## 'try' to map remaining markers
  input.seq2 <- make.seq(seq.ord,1)
  cat ("\n\nRunning try algorithm\n")
  for (i in (n.init+1):length(input.seq$seq.num)){
    time.elapsed<-system.time(seq.ord <- try.seq(input.seq2,input.seq$seq.num[seq.work[i]],tol=tol))[3]
    if(time.elapsed < wait)
      Sys.sleep(wait - time.elapsed)
    if(all(seq.ord$LOD[-which(seq.ord$LOD==max(seq.ord$LOD))[1]] < -THRES))
      input.seq2 <- make.seq(seq.ord,which.max(seq.ord$LOD))
  }

  ## markers that do not meet the threshold remain unpositioned
  mrk.unpos <- input.seq$seq.num[which(is.na(match(input.seq$seq.num, input.seq2$seq.num)))]
  LOD.unpos <- NULL
  cat("\nLOD threshold =",THRES,"\n\nPositioned markers:", input.seq2$seq.num, "\n\n")
  cat("Markers not placed on the map:", mrk.unpos, "\n")

  if(touchdown && length(mrk.unpos) > 0) {
    ## here, a second round of the 'try' algorithm is performed, if requested
    cat("\n\n\nTrying to map remaining markers with LOD threshold ",THRES-1,"\n")
    for (i in mrk.unpos) {
      time.elapsed<-system.time(seq.ord <- try.seq(input.seq2,i,tol=tol))[3]
      if(time.elapsed < wait)
        Sys.sleep(wait - time.elapsed)
      if(all(seq.ord$LOD[-which(seq.ord$LOD==max(seq.ord$LOD))[1]] < (-THRES+1)))
        input.seq2 <- make.seq(seq.ord,which.max(seq.ord$LOD))
    }

    ## markers that do not meet this second threshold still remain unpositioned
    mrk.unpos <- input.seq$seq.num[which(is.na(match(input.seq$seq.num, input.seq2$seq.num)))]
    cat("\nLOD threshold =",THRES-1,"\n\nPositioned markers:", input.seq2$seq.num, "\n\n")
    cat("Markers not placed on the map:", mrk.unpos, "\n")
  }

  if(length(mrk.unpos) > 0) {
    ## LOD-Scores are calculated for each position, for each unmapped marker, if any
    LOD.unpos <- matrix(NA,length(mrk.unpos),(length(input.seq2$seq.num)+1))
    j <- 1
    cat("\n\nCalculating LOD-Scores\n")
    for (i in mrk.unpos){
      LOD.unpos[j,] <- try.seq(input.seq=input.seq2,mrk=i,tol=tol)$LOD
      j <- j+1
    }
  } else mrk.unpos <- NULL

  ## to end the algorithm, possibly remaining markers are 'forced' into the map
  input.seq3 <- input.seq2
  if(!is.null(mrk.unpos)) {
    cat("\n\nPlacing remaining marker(s) at most likely position\n")

    ## these markers are added from the least to the most doubtful
    which.order <- order(apply(LOD.unpos,1,function(x) max(x[-which(x==0)[1]])))

    for (i in mrk.unpos[which.order]) {
      time.elapsed<-system.time(seq.ord <- try.seq(input.seq3,i,tol))[3]
      if(time.elapsed < wait)
        Sys.sleep(wait - time.elapsed)
      input.seq3 <- make.seq(seq.ord,which(seq.ord$LOD==0)[sample(sum(seq.ord$LOD==0))[1]])
    }
  }
  cat("\nEstimating final genetic map using tol = 10E-5.\n\n")
  input.seq2<-map(input.seq2, tol=10E-5)
  input.seq3<-map(input.seq3, tol=10E-5)
  structure(list(ord=input.seq2, mrk.unpos=mrk.unpos, LOD.unpos=LOD.unpos, THRES=THRES,
                 ord.all=input.seq3, data.name=input.seq$data.name, twopt=input.seq$twopt), class = "order")
}

print.order <- function(x,...) {
  cat("\nBest sequence found.")
  ## print the 'safe' order
  print(x$ord)
  if(!is.null(x$mrk.unpos)) {
    ## print LOD-Score information for unpositioned markers
    cat("\n\nThe following markers could not be uniquely positioned.\n")
    cat("Printing most likely positions for each unpositioned marker:\n")

    size1 <- max(3,max(nchar(x$mrk.unpos)))
    mrk.unpos.pr <- format(x$mrk.unpos,width=size1)
    size2 <- max(nchar(x$ord$seq.num))
    seq.pr <- format(x$ord$seq.num,width=size2)

######limit <- (x$THRES-2)/2 ## previously used limit

    cat("\n")
    cat(paste(rep("-",size2+4+length(mrk.unpos.pr)*(size1+3)),collapse=""),"\n")
    cat("| ",rep("",size2),"|")
###### MAYBE WE SHOULD PUT A LIMIT TO THE NUMBER OF UNPOSITIONED MARKERS
    for(j in 1:length(mrk.unpos.pr)) {
      cat(rep("",max(0,3-size1)+1),mrk.unpos.pr[j],"|")
    }
    cat("\n")
    cat(paste("|",paste(rep("-",size2+2),collapse=""),"|",sep=""))
    cat(paste(rep(paste(paste(rep("-",size1+2),collapse=""),"|",sep=""),length(mrk.unpos.pr)),collapse=""),"\n")
    cat("| ",rep("",size2),"|")
    for(j in 1:length(x$mrk.unpos)) {
      if(x$LOD.unpos[j,1] > -0.0001) cat(rep("",max(0,3-size1)+1),"*** |")
      else if(x$LOD.unpos[j,1] > -1.0) cat(rep("",max(0,3-size1)+1),"**  |")
      else if(x$LOD.unpos[j,1] > -2.0) cat(rep("",max(0,3-size1)+1),"*   |")
      else cat(rep("",max(0,3-size1)+1),"    |")
    }
    cat("\n")
    for(i in 1:length(seq.pr)) {
      cat("|",seq.pr[i],"|")
      cat(paste(rep(paste(paste(rep(" ",size1+2),collapse=""),"|",sep=""),length(mrk.unpos.pr)),collapse=""),"\n")
      cat(paste("|",paste(rep(" ",size2+2),collapse=""),"|",sep=""))
      for(j in 1:length(x$mrk.unpos)) {
        if(x$LOD.unpos[j,i+1] > -0.0001) cat(rep("",max(0,3-size1)+1),"*** |")
        else if(x$LOD.unpos[j,i+1] > -1.0) cat(rep("",max(0,3-size1)+1),"**  |")
        else if(x$LOD.unpos[j,i+1] > -2.0) cat(rep("",max(0,3-size1)+1),"*   |")
        else cat(rep("",max(0,3-size1)+1),"    |")
      }
      cat("\n")
    }
    cat(paste(rep("-",size2+4+length(mrk.unpos.pr)*(size1+3)),collapse=""),"\n")
    cat("\n")
    cat("'***' indicates the most likely position(s) (LOD = 0.0)\n\n")
    cat("'**' indicates very likely positions (LOD > -1.0)\n\n")
    cat("'*' indicates likely positions (LOD > -2.0)\n\n")
  }
}

## end of file
