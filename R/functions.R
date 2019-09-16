package_parser <- function(text){
  if(is.null(text)) return(NULL)

  return(text %>%
           strsplit(split = "[, ]+") %>%
           unlist())
}

package_extract <- function(text){
  if(is.null(text)) return(NULL)

  return(text %>%
           lapply(function(x) stringr::str_match(x, "(?<=\\/)[a-zA-Z0-9.]+") %>% c()) %>%
           unlist())
}

github_package_parser <- function(text){
  if(is.null(text)) return(NULL)

  devGithubPackages <- text %>%
    package_parser()

  githubPackages <- text %>%
    package_parser() %>%
    package_extract()

  return(list(devGithubPackages = devGithubPackages, githubPackages= githubPackages))
}

cran_package_parser <- function(lambda = NULL){

  if (text == "AUTO"){
    if(is.null(lambda)) return(stop("A function must be supplied."))

    code <- read.table(lambda, sep = "\n", stringsAsFactors = F) %>%
      dplyr::as_tibble() %>%
      dplyr::rename(text = V1)

    packages <- code %>%
      dplyr::mutate(text = stringr::str_squish(text)) %>%
      dplyr::filter(stringr::str_detect(text, "(library|require)\\(.*\\)|::")) %>%
      dplyr::mutate(packages = stringr::str_match_all(text
                                                      , paste0(
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
                                                        "[a-zA-Z0-9._]+(?=::)")) %>% c())

    packages <- packages$packages %>%
      unlist() %>%
      unique()

  } else {
    packages <- text %>%
      package_parser()
  }

  #Removing R base packages
  packages <- packages[!packages %in% rownames(installed.packages(priority="base"))]

  return(packages)
}

lib_path_machine <- function(path,pkg_names){
  list_of_packages <- list.files(path,full.names = T)
  pkgs <- list.files(path,full.names = F)
  filtro <- pkgs %in% pkg_names
  list_of_packages <- list_of_packages[filtro]
  return(list_of_packages)
}


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
      return(result)
    }else{
      result <- unique(c(result, packages_dep(pkg_names = result, recursive = recursive)))
      return(result)
    }

  }else{
    return(result)
  }
}
package_get_git <- function(path){
  files <- list.files(path)
  full_path <- list.files(path, full.names = T)
  full_path <- full_path[files == "DESCRIPTION"]
  text <- readLines(full_path)
  text <- paste(text, collapse = " ")

  remote_type <- unlist(stringi::stri_extract_all(str = text, regex =  "(?<=RemoteType:)[a-zA-Z0-9._,\\n \\(\\)\\>\\=]+(?= [A-Za-z]+:)"))
  remote_type <- stringi::stri_trim_both(remotetype)

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
                 github = other_packages_df[other_packages_df$remote_type == "github"]
                 )
  return(result)
}



packages_printer <- function(str) {
  str %>%
    gsub("\\b", "'", ., perl = T) %>%
    paste(., collapse = ", ")
}
