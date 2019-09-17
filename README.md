
## Intro

This packages helps build a collection of files necessary to submit a R function to AWS lambda. Today only works in a linux environment.

The present work is based on this [repo](https://github.com/vt-iwamoto/aws-lambda-r-playground)

After the elucidative [article](https://medium.com/veltra-engineering/running-r-script-on-aws-lambda-custom-runtime-3a87403dcb) that Takashi Iwamoto make. I, and my collegue Lucas, only build functions to search of packages used in .R lambda and its dependencies. We use the structure and code provided by Iwamoto.


## TL:DR

You use only a function with two arguments. One is the path taht will contain all files the function will create. The second argument is the path of your function, a .R file.

## Instructions

Let's say that you have a folder to receive all the files e a already built function in a .R file.

In a R environment

```
lambaRt::build_files("./test/output/", lambda = "./test/function_test/test.R")
```

That you generate all the necessary files to build you lambda file.

- **Dockerfile:** This build a image with necessary packages and R base using a lambci image. **CAUTION** If you use a R package that has some system requirements you need to edit that by hand.

- **Bootstrap:** A Shell script that will be executed at call of lambda. It makes a request in lambda API to get event data, pass that to the R function, capture the response que send back to lambda API

- **zip_function:** This shell script will copy every binary that base R uses, your function and necessary libraries to a zip file to be submited to AWS Lambda.**CAUTION** If you use a R package that has some system requirements you need to edit that by hand (eg: Shared libs).

- **Build:** This little guy will build a image using the Dockerfile created earlier. After that will run the image mount the current folder and executing zip_funcion.sh as command, creating the zip file. **You need to execute this guy by hand**



With that zip file you can create a AWS Lambda with R runtime.
