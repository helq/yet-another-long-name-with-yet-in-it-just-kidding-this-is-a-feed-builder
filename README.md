# What is this #

This is a little hacky feed builder written in Ruby with the power of creating feeds of
anything I want. To create a new feed just read the rule examples, they're (I hope) pretty
self explanatory.

# How to use #

To run it, you need to have installed `builder`, `rack`, `rdoc`, `nokogiri`, `sqlite3` and `lz4-ruby`

``` bash
ruby feed_builder.rb
```

or simply install `bundler` and run:

``` bash
ruby install --path .
bundler exec ruby main.rb
```

Once it is running you can head to [http://localhost:53412/tvmaze/tt1305826]() and voilá
you have the dates of all past episodes of a tv show.

# Features #

Use of a sqlite3 database as cache for the downloaded pages. Use

# TODO #

[] Improve error messages
[] Improve this document
