# Plato2

Work in progress...



---

## How to setup

### 0. Requirements

- [Ruby](https://www.ruby-lang.org/) 2.x
- [GNU bison](https://www.gnu.org/software/bison/) 2.x
- [git](https://git-scm.com/) 2.x
- [Microsoft Visual Studio Code](https://code.visualstudio.com/) 1.30 (or later)

#### Windows only

- [MinGW](http://www.mingw.org/)  2.3(or later)


### 1. Download and initialize Plato2 develop environment

```bash
$ git clone --recursive https://scskq.backlog.jp/git/SUPPO_IN/plato2.git
$ cd plato2
$ make init
```

### 2. Setup Plato2

Build `Plato2` components and setup runtime environment.

```bash
$ make
```

### 3. How to launch `Plato2`

Open `Plato2` application.

#### On Windows

```
start C:\Plato2\plato-ui\bin\plato2-win32-ia32.exe
```

#### On macOS

```
open ~/Plato2/plato-ui/bin/plato2-darwin-x64/plato2.app
```


## How to make `Plato2` installer

```
$ cd <plato2 directory>
$ make installer
```
