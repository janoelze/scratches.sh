<p align="center">
  <br>
  <img width="200" src="https://i.imgur.com/6G8vLej.png" />
  <br>
</p>

# scratches.sh

*__get in loser, we're ditching docker!__*

`scratches.sh` is a place for your web experiments. Think of it as a local version of codepen.io or JSFiddle or a pure CLI MAMP. It manages a simple directory of experiments (called scratches), registers hostnamese in your /etc/hosts file and serves them locally through PHP's builtin server, resulting in an URL like hello-world.sketch:8080. In short: Just type `scratch new` in your terminal, give your scratch a name and `scratches.sh` will provide you with a directory where you can tinker just like you would on an Apache server.

__Why use `scratches.sh`?__
* Build web experiments using the tools and IDE you know and trust, instead of a weird in-browser editor that tries to upsell you.
* Real files on a real hard drive, navigateable with a real file browser
* Abstracts away the repetive setup for small web experiments

## Dependencies

* PHP

## Installation

```
$ git clone git@github.com:janoelze/scratches.sh.git
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
