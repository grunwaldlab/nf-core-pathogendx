################## BASE IMAGE ######################

FROM eddelbuettel/r2u:22.04

################## METADATA #######################

LABEL about.summary="A test environment to generate the output report for pathogensurveillance."
LABEL about.author="Zachary S.L. Foster"
MAINTAINER Zachary S.L. Foster <zacharyfoster1989@gmail.com>

################## BUILD ######################

RUN <<EOF
apt-get update && apt install -y --no-install-recommends \
    pandoc \
    pandoc-citeproc \
    curl \
    gdebi-core \
    libuv1 \
    texlive-base \
    texlive-xetex \
    lmodern \
    texlive-plain-generic \
    texlive-fonts-recommended \
    texlive-fonts-extra
rm -rf /var/lib/apt/lists/*
EOF

RUN <<EOF
install.r \
    shiny \
    jsonlite \
    htmltools \
    remotes \
    renv \
    rmarkdown \
    quarto \
    dplyr \
    readr \
    knitr \
    readr \
    purrr \
    yaml \
    phylocanvas \
    ape \
    magrittr \
    pheatmap \
    tidyverse \
    palmerpenguins \
    ade4 \
    adegenet \
    poppr \
    ggtree \
    igraph \
    visNetwork \
    phangorn \
    ggplot2 \
    ggnewscale \
    kableExtra \
    plotly \
    webshot2 \
    metacoder \
    ggdendro \
    DT \
    heatmaply \
    leaflet
EOF

RUN <<EOF
curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb
gdebi --non-interactive quarto-linux-amd64.deb
EOF

RUN <<EOF
curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt-get install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb
EOF

RUN <<EOF
install.r devtools
Rscript -e 'devtools::install_github("grunwaldlab/psminer@ab6280ab7737bef8c8fac78e90c4c7c6e56d9cd7")'
EOF

USER root


