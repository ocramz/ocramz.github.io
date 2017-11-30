---
layout: post
title: Growing a software architecture with types
date: 2017-11-30
categories: haskell 
---


Yesterday evening I made a short presentation at a [local functional programming meetup](https://www.meetup.com/got-lambda) regarding my recent experience in building a data ingestion microservice in Haskell. To tell the truth, I was more concerned with communicating the rationale for my design choices rather than the business application per se, and how my current understanding of the language helps (or doesn't) in structuring a large and realistic application.

This blog post reproduces roughly the presentation, and incorporates some feedback I received and some further thoughts I have had on the matter in the meanwhile. It is written for people who had some prior exposure to Haskell, but I'll try to keep the exposition as intuitive as possible.



Warm-up: HTTP connections
-------------------------

The library uses the excellent [`req`](https://hackage.haskell.org/package/req) library for HTTP connections. It's very well thought out and documented, so I really recommend it.

Its only function is called, quite fittingly, `req`; its type signature reflects the typeclass-oriented design (i.e. function parameters are constrained to belong to certain sets, so to speak). Let's focus on the constraints:

    req :: (HttpResponse response, HttpBody body, HttpMethod method,
      MonadHttp m,
      HttpBodyAllowed (AllowsBody method) (ProvidesBody body)) =>

