[![pipeline status](https://gitlab.com/mandelbulber/mandelbulber2-ubuntu/badges/master/pipeline.svg)](https://gitlab.com/mandelbulber/mandelbulber2-ubuntu/commits/master)

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
