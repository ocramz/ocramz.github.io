---
layout: post
title: Growing a software architecture with types
date: 2017-11-30
categories: haskell 
---


Yesterday evening I made a short presentation at a [local functional programming meetup](https://www.meetup.com/got-lambda) regarding my recent experience in building a data ingestion microservice in Haskell. To tell the truth, I was more concerned with communicating my design choices rather than the business application per se, and how my current understanding of the language helps (or doesn't) in structuring a large and realistic application.

This blog post reproduces roughly the presentation, and incorporates some feedback I received and some further thoughts I have had on the matter in the meanwhile.



Warm-up: HTTP connections
-------------------------

The library uses [`req`](https://hackage.haskell.org/package/req)

