
      docker build -t test .
      docker run --rm -v $(pwd):/opt/work test /opt/work/zip_function.sh
    
