# demo.racket-lang.org
Framework for a Racket snippets page

## Introduction

Helping implement an idea listed on 
https://github.com/racket/racket/wiki/Intro-Projects

<blockquote>
Make a web page (demo.racket-lang.org ?) that contains Racket snippets. Use
the programs from http://rosettacode.org/wiki/Category:Racket to get
started.
</blockquote>

There are many examples of Racket code floating around, including:
* https://github.com/samth/racket-examples
* [Rosetta Code (above)](http://rosettacode.org/wiki/Category:Racket)

* Maybe, occasionally, someone posts something worthy on
  <http://www.pasterack.org> -- you never know
* [Schematics Cookbook](https://web-beta.archive.org/web/20150321002014/http://schemecookbook.org:80/Cookbook/TOC)
* <http://community.schemewiki.org>

The longterm idea of demo.racket-lang.org would be to provide some kind
of cookbook for Racket. 

## Plan of Action

1. Scrape Rosetta Code
  1. Scrape Rosetta Code’s tasks with a Racket implementation.
     Along with the task description.
  2. Put the scrapings into a database.
  3. Serve said database using a simple API.
2. (and more) Scrape this and that other source...
3. Produce an HTML Front-End to the database
  - mocking / features of the interface will be through `mock-ups/**`
  - the implementation of the interface will be through `templates/**`
  - all the fun of user registration/editing, contribution. You know,
    the kind of stuff that’s popular on the Internet nowadays

## Layout of This Here Repository

| Path | `.gitignore` | Purpose |
|------|--------------|---------|
| ./sql | no | SQL either loaded by Racket, or run into a CLI |
| ./racket | no | Code, written in racket |
| ./dist | yes | The built product |
| ./mock-ups | no | Mockups for website and ideas |
| ./mock-ups/{css,js,html} | no | Probably best that we keep everything in these directories |
| ./templates | no | Template web site files |
| ./templates/{css,js,html} | no | |
| ./scrapings      |yes| HTML scraping from sources - RC to start with |

<sup>†</sup>benevolence optional
```vim
 vim: tw=72
```
