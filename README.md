<p align="center">
  <br>
  <img width="200" src="https://i.imgur.com/wPatf2t.png" />
  <br>
</p>

# scratches

*__get in loser, we're ditching docker!__*

_scratches_ is a place for your php, html, js, css experiments. it manages a simple directory of experiments – called scratches – and serves them locally via php's builtin server. in short: type "scratch new" in your terminal, give your scratch a name and you'll get a directory where you can tinker with PHP, html and all sorts of static files.

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

__Create a new scratch__
```
$ scratches new
Enter a name for the scratch (optional): hello world
Created scratch 'hello-world'.
```

__List all scratches__
```
$ scratches ls
RUNNING	68500	audio-visualizer  http://audio-visualizer.scratch:63928
RUNNING	13316	hello-world       http://hello-world.scratch:56233
```

__Open a scratch in your default browser__
```
$ scratches open "hello-world"
```

__Open a scratch in Visual Studio Code__
```
$ scratches edit "hello-world"
```

__Delete a scratch__
```
$ scratches rm "hello world"
Created scratch 'hello-world'.
```

__Shut down all scratches__
```
$ scratches stop
Stopped 2 scratches.
```

__Start all scratches__
```
$ scratches start
Started 2 scratches.
```
__Open an ngrok tunnel to your scratch (requires ngrok to be installed)__
```
$ scratches tunnel "hello-world"
```
