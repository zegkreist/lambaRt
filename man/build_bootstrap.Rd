% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/build.R
\name{build_bootstrap}
\alias{build_bootstrap}
\title{Build bootstrap}
\usage{
build_bootstrap(path)
}
\arguments{
\item{path}{Folder to where the file must be written}
}
\value{
Nothing. Builds a text file named bootstrap in the folder that you specify in path
}
\description{
Build boostrap file to be used by AWS Lambda. The file it is a shell script that
make a request to Lambda API to retrieve the event data, pass that to the .R function and post a response
}
