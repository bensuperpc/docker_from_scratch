# docker_from_scratch
### _Build main images (Ubuntu, Debian, Alpine, ArchLinux) from scratch_

 [![forthebadge](https://forthebadge.com/images/badges/built-with-love.svg)](https://forthebadge.com) [![forthebadge](https://forthebadge.com/images/badges/powered-by-jeffs-keyboard.svg)](https://forthebadge.com) [![forthebadge](https://forthebadge.com/images/badges/contains-cat-gifs.svg)](https://forthebadge.com)
 
 [![Twitter](https://img.shields.io/twitter/follow/Bensuperpc?style=social)](https://img.shields.io/twitter/follow/Bensuperpc?style=social) [![Youtube](https://img.shields.io/youtube/channel/subscribers/UCJsQFFL7QW4LSX9eskq-9Yg?style=social)](https://img.shields.io/youtube/channel/subscribers/UCJsQFFL7QW4LSX9eskq-9Yg?style=social) 

# New Features !

  - Add Archlinux and improve alpine build
  - Add multiple version: Ubuntu 14.04 to 20.04, debian stretch to bullseye, alpine linux v3.11 to v3.14 ....

#### Install
You need Linux distribution like Ubuntu or Manjaoro
```sh
https://github.com/bensuperpc/docker_from_scratch.git
```
```sh
cd docker_from_scratch
```
##### and some package:
```sh
docker debootstrap debian-archive-keyring ubuntu-keyring archlinux-keyring xz-utils tar wget curl make rsync (maybe others ?)
```

#### Usage
##### _Build ubuntu focal (20.04)_

```sh
sudo make focal or sudo make ubuntu
```
##### _Build debian bullseye (11.xx)_

```sh
sudo make bullseye or sudo make debian
```
##### _Build alpine linux (3.14.xx)_

```sh
sudo make v3.14 or sudo make alpine
```

##### _Build arch linux (3.14.xx)_

```sh
sudo make archlinux
```

### Todos

 - Write Tests
 - Continue dev. :D

### More info : 
- https://releases.ubuntu.com/

License
----

MIT License


**Free Software forever !**
