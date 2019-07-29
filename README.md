[![Build Status](https://travis-ci.org/programming-nu/nu.svg?branch=master)](https://travis-ci.org/programming-nu/nu)

# Introduction

Hello and welcome to Nu.

I created Nu because I wanted a better way to write software.

I wanted to write with a language as flexible and powerful as Lisp, but I 
also wanted to be able to work with the many libraries and high-performance
subsystems written in C, including the ones that I write myself.  So a tight 
integration with C was my highest priority; that ruled and drove the 
implementation of Nu.  That's why Nu is "C over lambda."

It is easier to integrate with C when you have a disciplined way of structuring 
C code.  Popular scripting languages (Python, Ruby, Lua, etc.) make many 
implementation-dependent impositions on the C code that they call.  Their
artifacts are often called "glue code" and are usually ugly, cumbersome, and 
unpleasant to generate.

Objective-C provides a proven way of structuring C code that has no scripting 
language implementation dependencies.  But it can do much more than that.
Objective-C can also serve as a platform for a powerful dynamic language.  
Nu was designed to take full advantage of that.  It was also designed to 
provide many of the elements of successful scripting languages, notably 
Ruby, while adding the syntactic simplicity and flexibility of Lisp.   

## Legal

Nu is copyrighted open-source software that is released under the Apache
License, version 2.0.  For details on the license, see the LICENSE file.
In its use to name a programming language, "Nu" is a trademark of Radtastical 
Inc.

## Installation

### Macintosh / Ubuntu 

These are the instructions for installing Nu on a Macintosh or Linux system. 
Linux builds require several additional dependencies. The included 
[ubuntu.sh](ubuntu.sh) script can be used to install these dependencies on 
a system running Ubuntu 18.04 (and possibly other versions). Installation 
instructions for some other UNIX-based operating systems (Debian, OpenSolaris, 
and FreeBSD) are in [notes/OBSOLETE](notes/OBSOLETE) and will probably not 
work without modifications. Macintosh and Ubuntu builds are verified with
[Travis](.travis.yml).

If you've installed Nu previously using a package manager (e.g. Fink, MacPorts), 
start by using the package manager to uninstall the old version.

#### Building Nu

1. Use make to build mininush, a minimal version of the Nu shell.

```bash
$ make
```

2. Now use mininush to run nuke to complete the Nu build process.
   This builds Nu.framework and nush, the Nu shell.

```bash
$ ./mininush tools/nuke
```
#### Installing & Testing

3. Use mininush again to install Nu, nush, and the Nu tools.

```bash
$ ./mininush tools/nuke install
```

Since the copying step uses `sudo`, you will be prompted for your password.

4. Test your installation.

```bash
$ nuke test
```

From now on, you can use the installed nush to run nuke. To see for
yourself, rebuild everything from scratch:

```bash
$ nuke clobber
$ nuke
$ nuke install
```

See the Nukefile for other useful tasks.

### System Requirements

On Macintosh systems, Nu requires Mac OS X version 10.5 or greater.
It is also possible to build Nu to run on Linux systems and the 
Apple iPhone.

## Going Further

* [notes/DEMO](https://github.com/timburks/nu/blob/master/notes/DEMO) contains a simple tutorial exercise that can acquaint you with Nu.
* [notes/USAGE](https://github.com/timburks/nu/blob/master/notes/USAGE) describes a few of the ways that you can use Nu.
* [notes/ERRORS](https://github.com/timburks/nu/blob/master/notes/ERRORS) contains some pitfalls that I've encountered when programming with Nu.
* [notes/TODO](https://github.com/timburks/nu/blob/master/notes/TODO) contains some open issues that I'd like to address in Nu.
* The [examples](https://github.com/timburks/nu/tree/master/examples) directory contains several fun and interesting examples.

## Author

Tim Burks (tim@radtastical.com)<br/>
Radtastical Inc.<br/>
Palo Alto, California, USA<br/>
http://www.radtastical.com
