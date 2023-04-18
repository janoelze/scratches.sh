<p align="center">
  <br>
  <img width="200" src="https://i.imgur.com/6G8vLej.png" />
  <br>
</p>

# scratches.sh

*__"get in loser, we're ditching docker!"__*

`scratches.sh` is a place for your web experiments. Think of it as a local version of codepen.io/JSFiddle or a pure CLI MAMP. It manages a simple directory of experiments (called scratches), registers hostnames in your /etc/hosts file and serves them locally through PHP's builtin server, resulting in an URL like hello-world.sketch:8080. In short: Just type `scratch new` in your terminal, give your scratch a name and `scratches.sh` will provide you with a directory where you can tinker just like you would on an Apache server.

__Why use `scratches.sh`?__
* Use the tools and IDE you know and trust — instead of a weird in-browser editor that tries to upsell you.
* Real files. On a real hard drive. Navigateable with a real file browser.
* Abstracts away repetitive setup for small web experiments.

## Dependencies

* [PHP](https://github.com/php/php-src)
* [jq](https://github.com/stedolan/jq)
* zsh

## Installation

```
curl -sSL https://raw.githubusercontent.com/janoelze/scratches.sh/main/install.sh | zsh
```

## Commands

```
$ scratches
scratches.sh
  new - creates a new scratch
  ls - lists all scratches
  open - opens a scratch in your default browser
  start - starts all scratches
  stop - stops all scratches
  edit - opens a scratch in visual studio code (requires vscode)
  tunnel - tunnel a scratch (requires ngrok)
```

## Usage

__Create a new scratch__
```
$ scratches new
Enter a name for the scratch (optional): hello world
Created scratch 'hello-world'
```

__List all scratches__
```
$ scratches ls
2   running   24031   facebook-api        http://facebook-api.scratch:52093
3   running   24291   foursquare-api      http://foursquare-api.scratch:60262
4   stopped   n/a     hello-world         n/a
5   running   61123   mastodon-api        http://mastodon-api.scratch:64557
6   stopped   n/a     twitter-api         n/a
```

__Open a scratch in your default browser__
```
$ scratches open hello-world
```

__Open a scratch in Visual Studio Code__
```
$ scratches edit hello-world
```

__Delete a scratch__
```
$ scratches rm hello-world
Stopped scratch 'hello-world'
Removed scratch 'hello-world'
```

__Start all scratches__
```
$ scratches start
Started 2 scratches
```

__Shut down all scratches__
```
$ scratches stop
Stopped 2 scratches
```

__Open a public ngrok tunnel to your scratch (requires ngrok to be installed)__
```
$ scratches tunnel "hello-world"
```
