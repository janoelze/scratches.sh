<p align="center">
  <img width="200" src="https://i.imgur.com/2OfUtfs.png" />
</p>

# scratches

a place for your php, html, js, css experiments. allows you to manage a directory of experiments and serve them locally via php's builtin server.

## Dependencies

* PHP

## Installation

```
$ git clone git@github.com:janoelze/scratches.git
```

After cloning the repository you can add an alias to your .bashrc or .zshrc:

```
alias scratches="sh {locationToRepo}/scratches.sh"
```

## Usage

__Create a new sketch__
```
$ scratches new
Enter a name for the scratch (optional): hello world
Created scratch 'hello-world'.
```

__List all sketches__
```
$ scratches ls
RUNNING	68500	audio-visualizer  http://audio-visualizer.scratch:63928
RUNNING	13316	hello-world       http://hello-world.scratch:56233
```

__Open a sketch in Visual Studio Code__
```
$ scratches edit "hello-world"
```

__Delete a sketch__
```
$ scratches rm "hello world"
Created scratch 'hello-world'.
```

__Shut down all sketches__
```
$ scratches stop
Stopped 2 scratches.
```

__Start all sketches__
```
$ scratches start
Started 2 scratches.
```
__Open an ngrok tunnel to your scratch (requires ngrok to be installed)__
```
$ scratches tunnel "hello-world"
```
