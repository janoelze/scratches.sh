<p align="center">
  <br>
  <img width="200" src="https://i.imgur.com/6G8vLej.png" />
  <br>
</p>

# scratches

*__get in loser, we're ditching docker!__*

_Scratches_ is a place for your web experiments. Think of it as a local version of codepen.io or JSFiddle. It manages a simple directory of experiments (called scratches), registers a host in your /etc/hosts file and serves them locally through PHP's builtin server, resulting in a URL like hello-world.sketch:8080. In short: Just type `scratch new` in your terminal, give your scratch a name and _scratches_ will provide you with directory where you can tinker just like you would on an Apache server.

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

## Commands

```
$ scratches
scratches.sh
  new - create a new scratch
  list - list all scratches
  open - open a scratch in your default browser
  start - start all scratches
  stop - stop all scratches
  edit - edit a scratch (requires vscode)
  tunnel - tunnel all scratches (requires ngrok)
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
