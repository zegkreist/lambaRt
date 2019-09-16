
#' @title Build a Dockerfile
#'
#' @description  Build a Dockerfile to extract packages later
#'
#' @param cran_packages A character Vector with all cran packages to install
#' @param gitsomething_packages_df A df with information about remotes
#' @param path Folder to where the file must be written


build_dockerfile <- function(cran_packages = NULL,
                             gitsomething_packages_df = NULL,
                             path ){
  gitsomething_packages_df <- gitsomething_packages_df[!is.na(gitsomething_packages_df$remote_type),]
  if(is.null(cran_packages) & is.null(gitsomething_packages_df)){
    warning("No package informed, the image will be build with only base packages!")
  }


    dockerfile <- "FROM lambci/lambda:build-provided

                  RUN yum -y update \\
                      && yum -y install R "


    if(is.null(cran_packages) & is.null(gitsomething_packages_df)){
      dockerfile <- paste0(dockerfile, " \\
                      && yum clean all ")
      }

    if(!is.null(cran_packages) ){
      dockerfile <- paste0(dockerfile, " \\
                      && R -e \"install.packages(c('",
                           paste0(cran_packages, collapse = "','"),
                           "'), repos='http://cran.rstudio.com/')\"")
    }

    if(!is.null(gitsomething_packages_df) & nrow(gitsomething_packages_df) > 0 ){
      dockerfile <- paste0(dockerfile, " \\
                      && R -e \"install.packages(c('devtools'), repos='http://cran.rstudio.com/')\"")


        dockerfile <- paste0(dockerfile, " \\
                        && R -e \"devtools::install_github(c('",
                             paste0(paste0(gitsomething_packages_df$remote_username,"/", gitsomething_packages_df$remote_repo,"@" ,gitsomething_packages_df$remote_ref), collapse = "','"),
                             "), upgrade = \"always\"')\"")
    }


    if(substr(path, nchar(path), nchar(path)) == "/"){
      write(dockerfile, file = paste0(path, "Dockerfile"))
    }else{
      write(dockerfile, file = paste0(path, "/","Dockerfile"))
    }


}


#' @title Build bootstrap
#'
#' @description  Build boostratp
#'
#' @param path Folder to where the file must be written


build_bootstrap <- function(path){
  bootstrap <- '#!/bin/sh

set -euo pipefail

export R_HOME=/var/task/R

while true
do
  HEADERS="$(mktemp)"

  EVENT_DATA=$(curl -sS -LD "$HEADERS" -X GET "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")
  REQUEST_ID=$(grep -Fi Lambda-Runtime-Aws-Request-Id "$HEADERS" | tr -d \'[:space:]\' | cut -d: -f2)

  RESPONSE=$(/var/task/R/bin/exec/R --slave --no-restore --file=$_HANDLER.R --args "$EVENT_DATA")

  curl -X POST "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$REQUEST_ID/response" -d "$RESPONSE"
done'

  if(substr(path, nchar(path), nchar(path)) == "/"){
    write(bootstrap, file = paste0(path, "bootstrap"))
  }else{
    write(bootstrap, file = paste0(path, "/","bootstrap"))
  }
}

#' @title Build zipfunction.sh
#'
#' @description  Build zip function that compress all packages and libs that you need to pass to lambda
#' @param path Folder to where the file mus be written
#' @param lambda_name Name of the lambda funcion
#' @param pkg_names A character vector of the packages that you need to pass do lambda

build_zipfunciton <- function(path, lambda_name,pkg_names){

  zipfunction <- paste0("#!/bin/sh

set -euxo pipefail

mkdir /tmp/work
cd /tmp/work

cp /opt/work/{bootstrap,", lambda_name, ".R} ./

mkdir -p R/bin/exec
cp /usr/lib64/R/bin/exec/R ./R/bin/exec/

mkdir R/etc
cp /usr/lib64/R/etc/Renviron ./R/etc/

mkdir lib
cp /usr/lib64/{libgfortran.so.3,libquadmath.so.0,libtre.so.5} ./lib/
cp /usr/lib64/R/lib/{libR.so,libRblas.so,libRlapack.so} ./lib/

  copy_r_lib() {
    for lib in $@
      do
    rsync -a /usr/lib64/R/library/$lib R/library/ \\
      --exclude afm \\
      --exclude demo \\
      --exclude doc \\
      --exclude enc \\
      --exclude help \\
      --exclude html \\
      --exclude icc \\
      --exclude misc \\
      --exclude Sweave
    done
  }

mkdir R/library
copy_r_lib base compiler datasets graphics grDevices methods stats utils ", paste(pkg_names, collapse = " "),"

rm -f /opt/work/function.zip
zip -r /opt/work/function.zip .")

  if(substr(path, nchar(path), nchar(path)) == "/"){
    write(zipfunction, file = paste0(path, "zip_funcion.sh"))
  }else{
    write(zipfunction, file = paste0(path, "/","zip_function.sh"))
  }


}

#' @title Build the Build file
#'
#' @description Build the Build File. The build file uses docker to build a image from Dockerfile spin up a container to get the packages to zip function
#' @param path Folder to where the file must be written
#' @param lambda_name Name of lambda function


build_build <- function(path,lambda_name){
  build <- paste0(
    "
      docker build -t ",lambda_name," .
      docker run --rm -v $(pwd):/opt/work ",lambda_name," /opt/work/zip_function.sh
    "
  )


  if(substr(path, nchar(path), nchar(path)) == "/"){
    write(build, file = paste0(path, "build.sh"))
  }else{
    write(build, file = paste0(path, "/","build.sh"))
  }


}

#' @title Write all necessary files to build the zip archive to lambda
#'
#' @description Build bootstrap, dockerfile, build, zip functiona and put lambda file in folder
#' @param path Folder of project
#' @param lambda Path to .R file of lambda
#' @export
build_files <- function(path, lambda){
  if(!dir.exists(path)){
    dir.create(path)
  }
  if(!file.exists(lambda)){
    stop("Must pass a existing .R file")
  }else{
    lambda_name <- unlist(strsplit(lambda, split = "/|\\\\"))
    lambda_name <- lambda_name[length(lambda_name)]
    lambda_name <- stringi::stri_replace_all(lambda_name, replacement = "", regex = ".R")
    pacotes_arquivo <- pkg_names_finder(lambda)
    pacotes_dep <- packages_dep(pacotes_arquivo, recursive = T)
    pacotes <- unique(c(pacotes_arquivo, pacotes_dep))
    pacotes_origin <- package_origin(pacotes)

    build_dockerfile(cran_packages = pacotes_origin$cran,
                     gitsomething_packages_df = pacotes_origin$gitsomething,
                     path = path
                     )
    build_bootstrap(path = path)
    build_zipfunciton(path = path,
                      lambda_name = lambda_name,
                      pkg_names = pacotes)
    build_build(path = path, lambda_name = lambda_name)
    if(substr(path, nchar(path), nchar(path)) == "/"){
      file.copy(from = lambda, to = paste0(path,lambda_name, ".R"))
    }else{
      file.copy(from = lambda, to = paste0(path,"/",lambda_name, ".R"))
    }
  }
}
