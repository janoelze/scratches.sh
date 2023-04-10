# scratches

a place for your php, html, js, css experiments.

## Installation

```
$ git clone git@github.com:janoelze/scratches.git
```

After cloning the repository you can add an alias to your .bashrc or .zshrc:

```
alias scratches="sh {locationToRepo}/scratches.sh"
```

## Usage

```
$ scratches new # creates a new sketch
Enter a name for the scratch (optional): hello world
Created scratch 'hello-world'.
```

```
$ scratches ls # lists all scratches
RUNNING	68500	audio-visualizer	http://audio-visualizer.scratch:63928
RUNNING	13316	hello-world	      http://hello-world.scratch:56233
```

```
$ scratches edit "hello-world" # opens the sketch in visual studio code
```

```
$ scratches rm "hello world" # deletes the sketch
Created scratch 'hello-world'.
```

```
$ scratches stop # stops all sketches
Stopped 2 scratches.
```

```
$ scratches start # stops all sketches
Started 2 scratches.
```

```
$ scratches tunnel "hello-world" # opens a ngrok tunnel to your scratch (requires ngrok to be installed)
```