





#' @title Get used packages in a R function
#'
#' @description Retrive used packages in a R function
#'
#' @param path Path to .R file
#'
#' @value Return a character vector of all used packages in .R file
#'
#' @importFrom stringi stri_match_all_regex
#' @export


pkg_names_finder <- function(path){

  text <- readLines(path)
  text <- paste(text, collapse = " ")

  result <- unlist(
    stringi::stri_match_all_regex(
      str = text,
      pattern = paste0(
        "(?<=^library\\()[a-zA-Z0-9._]+|",
        "(?<= library\\()[a-zA-Z0-9._]+|",
        "(?<=\\(library\\()[a-zA-Z0-9._]+|",
        "(?<=,library\\()[a-zA-Z0-9._]+|",
        "(?<=^require\\()[a-zA-Z0-9._]+|",
        "(?<= require\\()[a-zA-Z0-9._]+|",
        "(?<=\\(require\\()[a-zA-Z0-9._]+|",
        "(?<=,require\\()[a-zA-Z0-9._]+|",
        "(?<=^requireNamespace\\()[a-zA-Z0-9._]+|",
        "(?<= requireNamespace\\()[a-zA-Z0-9._]+|",
        "(?<=\\(requireNamespace\\()[a-zA-Z0-9._]+|",
        "(?<=,requireNamespace\\()[a-zA-Z0-9._]+|",
        "[a-zA-Z0-9._]+(?=::)"),
      omit_no_match = T
    )
  )
  result <- unique(result)

  return(result)
}





#' @title Search for packages inside a folder
#'
#' @description  Search for packages, by name, inside a folder
#'
#' @param path Path to folder to search to
#' @param pkg_names Name of packages to search

lib_path_machine <- function(path,pkg_names){
  list_of_packages <- list.files(path,full.names = T)
  pkgs <- list.files(path,full.names = F)
  filtro <- pkgs %in% pkg_names
  list_of_packages <- list_of_packages[filtro]
  return(list_of_packages)
}

#' @title  Read depends from a package
#'
#' @description  Giving a path to a library, this function read the DESCRIPTION FILE and parse the Depends of that package
#' @importFrom stringi stri_trim_both
#' @importFrom stringi stri_replace_all
#' @importFrom stringi stri_split
#' @param path Path to the library that you want discovery the depends


read_depends <- function(path){
  files <- list.files(path)
  full_path <- list.files(path, full.names = T)
  full_path <- full_path[files == "DESCRIPTION"]
  text <- readLines(full_path)
  text <- paste(text, collapse = " ")
  depends <- unlist(stringi::stri_extract_all(str = text, regex =  "(?<=Depends:)[a-zA-Z0-9._,\\n \\(\\)\\>\\=]+(?= [A-Za-z]+:)"))
  depends <- stringi::stri_trim_both(depends)
  depends <- stringi::stri_replace_all(depends, replacement = "", regex = "\\([ \\>\\=0-9.]+\\)")
  depends <- stringi::stri_trim_both(depends)
  depends <- unlist(stringi::stri_split(depends, regex = ","))
  depends <- stringi::stri_trim_both(depends)
  depends <- depends[depends != "R"]
  return(depends)
}

#' @title  Read Imports from a package
#'
#' @description  Giving a path to a library, this function read the DESCRIPTION FILE and parse the Imports of that package
#' @importFrom stringi stri_trim_both
#' @importFrom stringi stri_replace_all
#' @importFrom stringi stri_split
#' @param path Path to the library that you want discovery the imports


read_imports <- function(path){
  files <- list.files(path)
  full_path <- list.files(path, full.names = T)
  full_path <- full_path[files == "DESCRIPTION"]
  text <- readLines(full_path)
  text <- paste(text, collapse = " ")
  imports <- unlist(stringi::stri_extract_all(str = text, regex =  "(?<=Imports:)[a-zA-Z0-9._,\\n \\(\\)\\>\\=]+(?= [A-Za-z]+:)"))
  imports <- stringi::stri_trim_both(imports)
  imports <- stringi::stri_replace_all(imports, replacement = "", regex = "\\([ \\>\\=0-9.]+\\)")
  imports <- stringi::stri_trim_both(imports)
  imports <- unlist(stringi::stri_split(imports, regex = ","))
  imports <- stringi::stri_trim_both(imports)
  imports <- imports[imports != "R"]

  return(imports)
}

#' @title Discovery dependencies of installed packages
#'
#' @description  Giving a list of installed packages discovery all package dependencies
#'
#' @param pkg_names Vector of packages names that you want discovery dependencies
#' @param recursive default: F. If TRUE search for the dependencies of dependencies
#'
#' @value Retorn a character vector with the names of all dependencies packages
#'
#' @export



packages_dep <- function(pkg_names, recursive = F){
  lib_paths <- .libPaths()
  packages <- lapply(lib_paths, lib_path_machine, pkg_names = pkg_names)
  packages <- unlist(packages)
  if(length(packages) == 0){
    stop("Packages: ", paste0(pkg_names, collapse = " , "), " not found!")
  }
  result <- c(unique(unlist(lapply(packages, read_depends))),
              unique(unlist(lapply(packages, read_imports)))
  )

  result <- result[!is.na(result)]

  if(recursive){
    if(length(result) == 0){
      result <- result[result != "BH"]
      return(result)
    }else{
      result <- unique(c(result, packages_dep(pkg_names = result, recursive = recursive)))
      result <- result[result != "BH"]
      return(result)
    }

  }else{
    result <- result[result != "BH"]
    return(result)
  }
}

#' @title Get remote type of non cran packages
#'
#' @description  Giving a list of non cran packages return remote info
#' @importFrom stringi stri_trim_both
#' @importFrom stringi stri_extract_all
#' @param path Path of the library that you want remote info


package_get_git <- function(path){
  files <- list.files(path)
  full_path <- list.files(path, full.names = T)
  full_path <- full_path[files == "DESCRIPTION"]
  text <- readLines(full_path)
  text <- paste(text, collapse = " ")

  remote_type <- unlist(stringi::stri_extract_all(str = text, regex =  "(?<=RemoteType:)[a-zA-Z0-9._,\\n \\(\\)\\>\\=]+(?= [A-Za-z]+:)"))
  remote_type <- stringi::stri_trim_both(remote_type)

  remote_host <- unlist(stringi::stri_extract_all(str = text, regex =  "(?<=RemoteHost:)[a-zA-Z0-9._,\\n \\(\\)\\>\\=]+(?= [A-Za-z]+:)"))
  remote_host <- stringi::stri_trim_both(remote_host)

  remote_repo <- unlist(stringi::stri_extract_all(str = text, regex =  "(?<=RemoteRepo:)[a-zA-Z0-9._,\\n \\(\\)\\>\\=]+(?= [A-Za-z]+:)"))
  remote_repo <- stringi::stri_trim_both(remote_repo)

  remote_username <- unlist(stringi::stri_extract_all(str = text, regex =  "(?<=RemoteUsername:)[a-zA-Z0-9._,\\n \\(\\)\\>\\=]+(?= [A-Za-z]+:)"))
  remote_username <- stringi::stri_trim_both(remote_username)

  remote_ref <- unlist(stringi::stri_extract_all(str = text, regex =  "(?<=RemoteRef:)[a-zA-Z0-9._,\\n \\(\\)\\>\\=]+(?= [A-Za-z]+:)"))
  remote_ref <- stringi::stri_trim_both(remote_ref)

  result <- data.frame(remote_type     = remote_type,
                       remote_host     = remote_host,
                       remote_repo     = remote_repo,
                       remote_username = remote_username,
                       remote_ref      = remote_ref
  )
  return(result)



}

#' @title Get origin of package CRAN of GITsomething
#'
#' @description Givin a vector of pkg_names return the origin of these.
#' @param pkg_names Names of packages that you want discovery the origins
#'
#' @value List of two slots. First one with a vector of all CRAN packages. The second slot has a df with remote info about gitsomething packages
#' @export
package_origin <- function(pkg_names){
  lib_paths <- .libPaths()
  db <- utils::available.packages()
  db <- subset(db, rownames(db) %in% pkg_names)
  cran_packages <- unique(db[, "Package"])
  other_packages <- pkg_names[!pkg_names %in% cran_packages]
  other_packages <- lapply(lib_paths, lib_path_machine, pkg_names = other_packages)
  other_packages <- unlist(other_packages)

  other_packages_list <- lapply(other_packages, package_get_git)
  other_packages_df <- do.call("rbind", other_packages_list)

  result <- list(cran = cran_packages,
                 gitsomething = other_packages_df[other_packages_df$remote_type == "github",]
  )
  return(result)
}


