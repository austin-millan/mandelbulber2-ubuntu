#!/usr/bin/env bash

tags=$(curl -s "https://api.github.com/repos/buddhi1980/mandelbulber2/releases" | jq -r '.[].tag_name')
readarray -t tag_array <<<"$tags"
end_index=7
start_index=$((end_index - $LOOKBACK))
start_index=$((start_index < 0 ? 0 : start_index))
echo "Lookback: $LOOKBACK"
for (( idx=end_index; idx>=start_index; idx-- )); do
    tag="${tag_array[idx]}"
    echo "tag: $tag"
    if [ "$tag" = "continuous" ] || [[ "$tag" == *"alpha"* ]]; then
        continue
    fi
    # if [ $count -ge $LOOKBACK ]; then
        # break
    # fi
    echo "building version: $tag"
    docker build --cache-from registry.gitlab.com/mandelbulber/$CI_PROJECT_NAME:${tag} --build-arg VERSION=${tag} -t $CI_PROJECT_NAME:${tag} .
    echo "built"
    docker tag $CI_PROJECT_NAME:${tag} registry.gitlab.com/mandelbulber/$CI_PROJECT_NAME:${tag}
    docker push registry.gitlab.com/mandelbulber/$CI_PROJECT_NAME:${tag}
    docker tag $CI_PROJECT_NAME:${tag} $DOCKERHUB_USER/$CI_PROJECT_NAME:${tag}
    echo "pushing to Dockerhub..."
    docker push $DOCKERHUB_USER/$CI_PROJECT_NAME:${tag}
    if [ "$idx" -eq 1 ]; then
        echo "latest: $tag"
        docker build --cache-from registry.gitlab.com/mandelbulber/$CI_PROJECT_NAME:latest --build-arg VERSION=${tag} -t $CI_PROJECT_NAME:latest . 
        docker tag $CI_PROJECT_NAME:latest registry.gitlab.com/mandelbulber/$CI_PROJECT_NAME:latest
        docker push registry.gitlab.com/mandelbulber/$CI_PROJECT_NAME:latest
        docker tag $CI_PROJECT_NAME:latest $DOCKERHUB_USER/$CI_PROJECT_NAME:latest
        echo "pushing to Dockerhub..."
        docker push $DOCKERHUB_USER/$CI_PROJECT_NAME:latest
    fi
done