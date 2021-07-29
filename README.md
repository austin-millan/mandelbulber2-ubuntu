[![pipeline status](https://gitlab.com/mandelbulber/mandelbulber2-ubuntu/badges/master/pipeline.svg)](https://gitlab.com/mandelbulber/mandelbulber2-ubuntu/commits/master)

# mandelbulber2-ubuntu

## About

Run [Mandelbulber](https://www.mandelbulber.com/) in a docker container.

Note that docker registries may not have the latest version.
If you are interested in running the latest mandelbuler2 in a container but registries are outdated, see [Build](Build).

## Build

You can build a specific version of mandelbulber2 by setting the build argument `VERSION` when building the image locally, e.g.:

```bash
$ git clone git@gitlab.com:mandelbulber/mandelbulber2-ubuntu.git && cd mandelbulber2-ubuntu
$ NEW_RELEASE=X.Y; docker build --build-arg VERSION=$NEW_RELEASE -t austin-millan/mandelbulber2:$NEW_RELEASE
```

## Examples

### Usage

<details>
  <summary>Expand for Usage</summary>

```bashh
$ docker run -e USER_UID=${id} -it --entrypoint="mandelbulber2" registry.gitlab.com/mandelbulber/mandelbulber2-ubuntu:2.25 --help
Detected 12 CPUs
Mandelbulber 2.25
Log file name: /root/.mandelbulber_log.txt
Program data files directory /usr/share/mandelbulber2/
Default data hidden directory: /root/.mandelbulber/
Default data public directory: /root/mandelbulber/
Usage: mandelbulber2 [options] settings_file
Mandelbulber is an easy to use, handy application designed to help you render 3D Mandelbrot fractals called Mandelbulb and some other kind of 3D fractals like Mandelbox, Bulbbox, Juliabulb, Menger Sponge

Options:
-h, --help             Displays this help.
-v, --version          Displays version information.
-n, --nogui            Starts the program without a GUI.
-o, --output <N>       Saves rendered image(s) to this file / folder.
--logfilepath <N>      Specify custom system log filepath (default is:
                        ~/.mandelbulber_log.txt).
-K, --keyframe         Renders keyframe animation.
-F, --flight           Renders flight animation.
-X, --never-delete     Never delete data, instead Exit CLI application.
-s, --start <N>        Starts rendering from frame number <N>.
-e, --end <N>          Stops rendering on frame number <N>.
-L, --list             Lists all possible parameters '<KEY>' with
                        corresponding default value '<VALUE>'.
-f, --format <FORMAT>  Image output format:
                        jpg  - JPEG format (default)
                        png  - PNG format
                        exr  - EXR format
                        tiff - TIFF format
                        Legacy formats for still frames:
                        png16 - 16-bit PNG format
                        png16alpha - 16-bit PNG with alpha channel format
-r, --res <WxH>        Overrides image resolution. Specify as width and
                        height separated by 'x'
--fpk <N>              Overrides frames per key parameter.
-S, --server           Sets application as a server listening for clients.
-H, --host <N.N.N.N>   Sets application as a client connected to server of
                        given host address (Host can be of type IPv4, IPv6 and
                        Domain name address).
-p, --port <N>         Sets network port number for netrender (default 5555).
-C, --no-cli-color     Starts program without ANSI colors, when execution on
                        CLI.
-q, --queue            Renders all images from common queue.
-t, --test             Runs testcases on the mandelbulber instance
-b, --benchmark        Runs benchmarks on the mandelbulber instance, specify
                        optional parameter difficulty (1 -> very easy, > 20 ->
                        very hard, 10 -> default). When [output] option is set
                        to a folder, the example-test images will be stored
                        there.
-T, --touch            Resaves a settings file (can be used to update a
                        settings file)
-V, --voxel <FORMAT>   Renders the voxel volume. Output formats are:
                        slice - stack of PNG images into one folder (default)
                        ply   - Polygon File Format (single 3d file)

-O, --override <...>   <KEY=VALUE> overrides item '<KEY>' from settings file
                        with new value '<VALUE>'.
                        Specify multiple KEY=VALUE pairs by separating with a
                        '#': <KEY1=VALUE1#KEY2=VALUE2>. Quote whole expression
                        to avoid whitespace parsing issues
                        Override fractal parameter in the form
                        'fractal<N>_KEY=VALUE' with <N> being index of fractal
--stats                Shows statistics while rendering in CLI mode.
-g, --gpu              Runs the program in opencl mode and selects first
                        available gpu device.
-G, --gpuall           Runs the program in opencl mode and selects all
                        available gpu devices.
--help-input           Shows help about input.
--help-examples        Shows example commands.
--help-opencl          Shows commands regarding OpenCL.

Arguments:
settings_file          file with fractal settings (program also tries
                        to find file in ./mandelbulber/settings directory)
                        When settings_file is put as a command line argument
                        then program will start in noGUI mode<settings_file>
                        can also be specified as a list, see all options with
                        --help-input
```

</details>

### NetRender

> NetRender is a tool that allows you to render the same image or animation on multiple computerssimultaneously.
> [Mandelbulber_Manual](https://github.com/buddhi1980/mandelbulber_doc/releases/download/2.24.0/Mandelbulber_Manual.pdf)

Run as `client`:

```bash
docker run \
    -e USER_UID=${id} \
    -it \
    --net=host \
    --env="DISPLAY" \
    -v $HOME/.mandelbulber:/root/.mandelbulber:rw \
    -v $HOME/.Xauthority:/root/.Xauthority:rw \
    aamillan/mandelbulber2-ubuntu:latest \
    mandelbulber2 --nogui --host 192.168.1.12 --port 5555
```

Run as `server`:

```bash
docker run \
    -e USER_UID=${id} \
    -it \
    --net=host \
    --env="DISPLAY" \
    -v $HOME/.mandelbulber:/root/.mandelbulber:rw \
    -v $HOME/.Xauthority:/root/.Xauthority:rw \
    aamillan/mandelbulber2-ubuntu:latest \
    --server --port 5555
```
