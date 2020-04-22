#!/bin/sh

if [ "$(uname)" == "Darwin" ]; then
    # Running on macOS.
    # Let's assume that the user has the Docker CE installed
    # which doesn't require a root password.
    echo "The preview will be available at http://localhost:8080/"
    docker run --rm -v $(pwd):/antora:ro -v $(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf:ro -p 8080:80 nginx

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Running on Linux.
    # Fedora Workstation has python3 installed as a default, so using that
    echo ""
    echo "The preview is available at http://localhost:8080"
    echo ""

    if [[ "$*" == *--refresh* ]]; then
        if ! [ -x "$(command -v inotifywait)" ]; then
            echo 'Error: inofitywait (inotify-utils) is not installed.' >&2
            exit 1
        fi

        # Setup trap to kill this process group on ctrl+c.
        killgroup(){
            kill 0
        }
        trap killgroup SIGINT

        # Run the Python's webserver.
        python3 -m http.server 8080 --directory ./public &

        while inotifywait -r ./modules -e create -e moved_to -e modify; do
             echo "Documentation source changed, rebuilding ..."
            ./build.sh
        done
    else
        python3 -m http.server 8080 --directory ./public
    fi
fi
