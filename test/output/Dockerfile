FROM lambci/lambda:build-provided

                  RUN yum -y update \
                      && yum -y install R  \
                      && R -e "install.packages(c('assertthat','backports','cli','colorspace','crayon','data.table','digest','ellipsis','fansi','ggplot2','glue','gtable','labeling','lattice','lazyeval','magrittr','MASS','Matrix','mgcv','munsell','pillar','pkgconfig','plyr','R6','RColorBrewer','Rcpp','reshape2','rlang','scales','stringi','stringr','tibble','utf8','vctrs','viridisLite','withr','zeallot'), repos='http://cran.rstudio.com/')"
