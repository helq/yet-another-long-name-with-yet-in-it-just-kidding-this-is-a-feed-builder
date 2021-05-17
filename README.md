# What is this #

This is a little (hacky) feed builder written in Ruby with the power of creating feeds of
anything I want. To create a new feed just read the example rules, they're (I hope) pretty
self explanatory.

Once `feed_builder` is running it will serve feeds on port `53412` of `localhost`.

# How to use #

To run it, you need to have installed the ruby packages: `builder`, `rack`, `rdoc`,
`nokogiri`, `sqlite3` and `lz4-ruby`. Once they're installed, you can run the script with:

``` bash
ruby main.rb
```

Or you could simply install `bundler` and run:

``` bash
bundle config set --local path '.'
bundler install
bundler exec ruby main.rb
```

Bundler will take care of the dependences, and hopefully all will work smoothly.

Once it is running you can head to [http://localhost:53412/tvmaze/tt1305826]() and
_voilá_, you'll see a rss feed with the last 50 airing dates of Adventure Time's episodes.

# Features #

All pages are downloaded and cached into a sqlite3 database by using the `FeedBuilder`'s
method: `download_file_with_cache`. In short, if you ask, for example, for a feed twice in
a row, `feed_builder` will only download the necessary files once, and it will access the
cached files for the second call.

The cache can be adjusted to stay in memory as long as you want, I like to keep things
updated daily, so the cache gets overwritten if a new feed request is made 24 hours after
the last request (a request is for a specific url feed (e.g.,
[http://localhost:53412/tvmaze/tt1305826]()), i.e., each url feed has it's "own" cache, a
cached that is cleaned every 24 hours, sort of speak).

# TODO #

- Improve error messages
- Improve this document
