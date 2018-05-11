#' Creation of candidate models for calibration
#'
#' @description kuenm_cal creates and executes a batch file for generating candidate models in Maxent
#' to test multiple parameter combinations, including distinct regularization multiplier values,
#' various feature classes, and different sets of environmental variables.
#'
#' @param occ.joint (character) is the name of the csv file with all the occurrences; columns must be: species, longitude, latitude.
#' @param occ.tra (character) is the name of the csv file with the calibration occurrences; columns equal to occ.joint.
#' @param M.var.dir (character) is the name of the folder containing other folders with different sets of environmental variables.
#' @param batch (character) name of the batch file with the code to create all candidate models.
#' @param out.dir (character) name of the folder that will contain all calibration model subfolders.
#' @param reg.mult (numeric vector) regularization multiplier(s) to be evaluated.
#' @param f.clas (character) feature clases can be selected from  five different combination sets or manually.
#' Combination sets are: "all", "basic", "no.t.h", "no.h", and "no.t". Default = "all".
#' basic = "l", "lq", "lqp", "lqpt", "lqpth". Combinations "no.t.h", "no.h", and "no.t", exclude t and/or h.
#' Options from the following list can be selected manually:
#' "l", "q", "p", "t", "h", "lq", "lp", "lt", "lh", "qp", "qt", "qh",
#' "pt", "ph", "th", "lqp", "lqt", "lqh", "lpt", "lph", "qpt", "qph",
#' "qth", "pth", "lqpt", "lqph", "lqth", "lpth", and "lqpth".
#' @param run (logical) if true the batch runs after its creation, if false it will only be created and its runnig would be
#' manual, default = TRUE.
#'
#' @return A folder named out.dir with all the subfolders to save Maxent results when running the .bat file.
#' A .bat file containing the java codes to run the calibration models, it will run auotmatically or on some
#' computers a dialog box will ask if running is allowed.
#'
#' @details Java needs to be installed in the computer and maxent.jar needs to be located in the working directory.
#' Java can be obtained from \url{https://java.com/es/download/manual.jsp}. Maxent can be downloaded from
#' \url{https://biodiversityinformatics.amnh.org/open_source/maxent/}

kuenm_cal <- function(occ.joint, occ.tra, M.var.dir, batch, out.dir, reg.mult,
                       f.clas = "all", run = TRUE) {

  #Data
  ##Environmental variables sets
  m <- dir(M.var.dir)
  ms <- paste(M.var.dir, "\\", m, sep = "")
  env <- vector()
  for (i in 1:length(ms)) {
    env[i] <- paste("environmentallayers=", ms[i], sep = "")
  }

  ##Species occurrences
  oc <- occ.joint
  samp <- paste("samplesfile=", oc, sep = "")
  occ <- occ.tra
  samp1 <- paste("samplesfile=", occ, sep = "")

  #Maxent settings
  ##Featire classes combinations
  fea <- c("linear=true quadratic=false product=false threshold=false hinge=false",
           "linear=false quadratic=true product=false threshold=false hinge=false",
           "linear=false quadratic=false product=true threshold=false hinge=false",
           "linear=false quadratic=false product=false threshold=true hinge=false",
           "linear=false quadratic=false product=false threshold=false hinge=true",
           "linear=true quadratic=true product=false threshold=false hinge=false",
           "linear=true quadratic=false product=true threshold=false hinge=false",
           "linear=true quadratic=false product=false threshold=true hinge=false",
           "linear=true quadratic=false product=false threshold=false hinge=true",
           "linear=false quadratic=true product=true threshold=false hinge=false",
           "linear=false quadratic=true product=false threshold=true hinge=false",
           "linear=false quadratic=true product=false threshold=false hinge=true",
           "linear=false quadratic=false product=true threshold=true hinge=false",
           "linear=false quadratic=false product=true threshold=false hinge=true",
           "linear=false quadratic=false product=false threshold=true hinge=true",
           "linear=true quadratic=true product=true threshold=false hinge=false",
           "linear=true quadratic=true product=false threshold=true hinge=false",
           "linear=true quadratic=true product=false threshold=false hinge=true",
           "linear=true quadratic=false product=true threshold=true hinge=false",
           "linear=true quadratic=false product=true threshold=false hinge=true",
           "linear=false quadratic=true product=true threshold=true hinge=false",
           "linear=false quadratic=true product=true threshold=false hinge=true",
           "linear=false quadratic=true product=false threshold=true hinge=true",
           "linear=false quadratic=false product=true threshold=true hinge=true",
           "linear=true quadratic=true product=true threshold=true hinge=false",
           "linear=true quadratic=true product=true threshold=false hinge=true",
           "linear=true quadratic=true product=false threshold=true hinge=true",
           "linear=true quadratic=false product=true threshold=true hinge=true",
           "linear=true quadratic=true product=true threshold=true hinge=true")

  names(fea) <- c("l", "q", "p", "t", "h", "lq", "lp", "lt", "lh", "qp", "qt", "qh",
                  "pt", "ph", "th", "lqp", "lqt", "lqh", "lpt", "lph", "qpt", "qph",
                  "qth", "pth", "lqpt", "lqph", "lqth", "lpth", "lqpth")

  suppressWarnings(if(f.clas == "all"|f.clas == "basic"|f.clas == "no.t.h"|f.clas == "no.h"|f.clas == "no.t"){
    if(f.clas == "all"){fea <- fea} #for choosing all potential combinations
    if(f.clas == "basic"){fea <- fea[c(1, 6, 16, 25, 29)]} #for choosing combinations ordered for increasing complexity (all fc)
    if(f.clas == "no.t.h"){fea <- fea[c(1:3, 6:7, 10, 16)]} #for choosing all combinations ordered for increasing complexity (no t no h)
    if(f.clas == "no.h"){fea <- fea[c(1:4, 6:8, 10:11, 13, 16:17, 19, 21, 25)]}
    if(f.clas == "no.t"){fea <- fea[c(1:3, 5:7, 9:10, 12, 14, 16, 18, 20, 22, 26)]}
  }else{
    fea <- fea[f.clas]
  })


  #output directories
  dir.create(out.dir)

  #Getting ram to be used
  ram <- paste("-mx", (round((get_free_ram()/1000)*0.5)), "m", sep = "")

  #Fixed commands
  ##Intitial command
  in.comm <- paste("java", ram, "-jar maxent.jar", sep = " ")

  ##Autofeature
  a.fea <- "autofeature=false"

  ##Other maxent settings
  fin.com <- "extrapolate=false doclamp=false replicates=1 replicatetype=Bootstrap responsecurves=false jackknife=false plots=false pictures=false outputformat=raw warnings=false visible=false redoifexists autorun\n"
  fin.com1 <- "extrapolate=false doclamp=false replicates=1 replicatetype=Bootstrap responsecurves=false jackknife=false plots=false pictures=false outputformat=logistic warnings=false visible=false redoifexists autorun\n"

  #Final code
  pb <- winProgressBar(title = "Progress bar", min = 0, max = length(reg.mult), width = 300) #progress bar
  sink(paste(batch, ".bat", sep = ""))

  for (i in 1:length(reg.mult)) {
    Sys.sleep(0.1)
    setWinProgressBar(pb, i, title = paste( round(i / length(reg.mult) * 100, 0), "% finished"))
    for (j in 1:length(fea)) {
      for (k in 1:length(ms)) {
        subfol <- paste("outputdirectory=", out.dir, "\\",
                        paste("M", reg.mult[i], "F", names(fea)[j], m[k], "all", sep = "_"), sep = "")
        dir.create(paste(out.dir, "/",
                         paste("M", reg.mult[i], "F", names(fea)[j], m[k], "all", sep = "_"), sep = ""))
        reg.m <- paste("betamultiplier=", reg.mult[i], sep = "")
        cat(paste(in.comm, env[k], samp, subfol, reg.m, a.fea, fea[j], fin.com, sep = " "))

        subfol1 <- paste("outputdirectory=", out.dir, "\\",
                         paste("M", reg.mult[i], "F", names(fea)[j], m[k], "cal", sep = "_"), sep = "")
        dir.create(paste(out.dir, "/",
                         paste("M", reg.mult[i], "F", names(fea)[j], m[k], "cal", sep = "_"), sep = ""))
        cat(paste(in.comm, env[k], samp1, subfol1, reg.m, a.fea, fea[j], fin.com1, sep = " "))
      }
    }
  }
  sink()
  suppressMessages(close(pb))

  cat("\nIf asked and run = TRUE, allow runing as administrator.")

  if(run == TRUE){
    shell.exec(file.path(getwd(), paste(batch, ".bat", sep = "")))
  }

  cat("\nProcess finished\n")
  cat(paste("A maxent batch file for creating", i * j * k, "calibration models has been written", sep = " "))
  cat(paste("\nCheck your working directory!!!", getwd(), sep = "    "))
}