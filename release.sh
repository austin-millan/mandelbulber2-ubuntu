#!/bin/bash

count=0
for tag in $(curl -s "https://api.github.com/repos/buddhi1980/mandelbulber2/releases" | jq -r '.[].tag_name'); do
    if [ "$tag" = "continuous" ]; then
        continue
    fi
    if [ $count -ge 5 ]; then
        break
    fi
    echo "building version: $tag"
    if [ "$count" -eq 0 ]; then
        echo "latest: $tag"
        docker build --build-arg VERSION=${tag} -t abc:latest . 
        #docker build --build-arg VERSION=${tag} -t $CI_PROJECT_NAME:latest . 
        #docker tag $CI_PROJECT_NAME:latest registry.gitlab.com/mandelbulber/$CI_PROJECT_NAME:latest
        #docker push registry.gitlab.com/mandelbulber/$CI_PROJECT_NAME:latest
    fi
    #docker build --from-cache registry.gitlab.com/mandelbulber/$CI_PROJECT_NAME:${tag} --build-arg VERSION=${tag} -t $CI_PROJECT_NAME:${tag} .
    #docker tag $CI_PROJECT_NAME:${tag} registry.gitlab.com/mandelbulber/$CI_PROJECT_NAME:${tag}
    #docker push registry.gitlab.com/mandelbulber/$CI_PROJECT_NAME:${tag}
    count=$((count+1))
done

# VERSION=2.26
# export DOWNLOAD_URL=$(curl https://api.github.com/repos/buddhi1980/mandelbulber2/releases | jq -r -c ".[] | select (.[\"tag_name\"] != \"continuous\") | select( .[\"tag_name\"] | contains(\"${VERSION}\")) | .assets[] | select (.content_type | contains(\"application/gzip\")) | .[\"browser_download_url\"]"); echo ${DOWNLOAD_URL}; wget -O ./downloads/mandelbulber-${VERSION}.tar.gz ${DOWNLOAD_URL}