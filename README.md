# mandelbulber2-ubuntu

Run [Mandelbulber](https://www.mandelbulber.com/) in a docker container.

## Example Usage

Run the program via CLI in client-mode for network rendering:

```bash
docker run \
    --rm \
    --network=host \
    -it aamillan/mandelbulber2-ubuntu:master \
    mandelbulber2 --nogui --host 192.168.1.12 --port 5555
```

## Repository Views

[![HitCount](http://hits.dwyl.com/austin-millan/mandelbulber2-ubuntu.svg)](http://hits.dwyl.com/austin-millan/mandelbulber2-ubuntu)
