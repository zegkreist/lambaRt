% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/build.R
\name{build_build}
\alias{build_build}
\title{Build the Build file}
\usage{
build_build(path, lambda_name)
}
\arguments{
\item{path}{Folder to where the file must be written}

\item{lambda_name}{Name of lambda function}
}
\value{
Nothing. Builds a text file named build in the folder that you specify in path
}
\description{
Build the Build File. The build file is a shell script that
uses docker to build a a container based on Dockerfile created early. Spin up a container, mount the necessary folders to get the packages to zip function
}
