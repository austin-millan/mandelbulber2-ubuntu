# mandelbulber2-ubuntu

Run [Mandelbulber](https://www.mandelbulber.com/) in a docker container.

## Example Usage

Run the program via CLI in client-mode for network rendering:

```bash
docker run \
    --rm \
    --network=host \
    -it aamillan/mandelbulber2-ubuntu:bionic \
    bash -c "mandelbulber2 --nogui --host 192.168.1.12 --port 5555"
```
