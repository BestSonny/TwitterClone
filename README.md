[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0) [![Build Status](https://travis-ci.com/BestSonny/TwitterClone.svg?token=vpYCDh8iPb2D3tqooPvo&branch=master)](https://travis-ci.com/BestSonny/TwitterClone)

# Phoenix-Twitter

A small twitter clone created with Elixir and Phoenix Framework that has the
following features:

  * Signup and login a user
  * Update user settings
  * Upload profile picture
  * Post tweet (can include user mentions and hashtags)
  * Post retweets
  * Favorite tweet
  * Follow other users
  * Clickable user mention links
  * Clickable hashtags to view all tweets with that hashtag

There are some Postgres spcific SQL commands since there is no union
functionality in Ecto. The CSS is done with [SASS](http://sass-lang.com/) and
[bootstrap-sass](https://github.com/twbs/bootstrap-sass) with the addition of
[Font Awesome](http://fontawesome.io/).

# Installation
From the phoenix-twitter root directory, execute the following:
```
sudo apt-get install postgresql postgresql-contrib
sudo -u postgres createdb phoenix_twitter_dev
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"
sudo apt-get install build-essential checkinstall
sudo apt-get install libssl-dev
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh | bash
source ~/.bashrc
nvm install 8.9
mix deps.get
mix ecto.create
mix ecto.migrate
npm install
mix phoenix.server
```
Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

# Installation on Windows
```
install Elixir
```
type 'cmd' in start menu, in the command prompt, type
```
mix local.hex
```
to install hex
```
download postgresql
```
open pgAdmin 4, login 'PostgreSQL 10' using the possword we set in the instal part
create database 'phoenix_twitter_dev'
```
download node.js
```

open 'cmd' command prompt in administrtor mode, head to the TwitterClone folder
```
mix deps.get
npm install -g windows-build-tools
```

Restart computer, open Visula Studio 2015 build tools command prompt, head to TwitterClone folder
```
mix ecto.create
mix ecto.migrate
npm install
mix phoenix.server
```
Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


# License

GPL Version 3.
