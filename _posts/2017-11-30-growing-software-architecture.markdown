---
layout: post
title: Growing a software architecture with types
date: 2017-11-30
categories: haskell 
---


Yesterday evening I made a presentation at a [local functional programming meetup](https://www.meetup.com/got-lambda) regarding my recent experience in building a data ingestion microservice in Haskell. To tell the truth, I was more concerned with communicating the rationale for my design choices rather than the business application per se, and how my current understanding of the language helps (or doesn't) in structuring a large and realistic application.

This blog post reproduces roughly the presentation, and incorporates some feedback I received and some further thoughts I have had on the matter in the meanwhile. It is written for people who had some prior exposure to Haskell, but I'll try to keep the exposition as intuitive as possible.



Warm-up: HTTP connections
-------------------------

This project uses the excellent [`req`](https://hackage.haskell.org/package/req) library for HTTP connections. It's very well thought out and documented, so I really recommend it.

The library is structured around a single function called, quite fittingly, `req`; its type signature reflects the typeclass-oriented design (i.e. function parameters are constrained to belong to certain sets, rather than being fixed upfront). Let's focus on the constraint part of the signature:

{% highlight haskell %}
req :: (HttpResponse response, HttpBody body, HttpMethod method,
  MonadHttp m,
  HttpBodyAllowed (AllowsBody method) (ProvidesBody body)) => ...
{% endhighlight %}

This should be mentally read: "the type `response` must be an instance of the `HttpResponse` class, `body` and `method` are jointly constrained by `HttpBodyAllowed` ..", etc.

As soon as we populate all of `req`'s parameter slots, the typechecker infers a more concrete (and understandable) type signature. The following example declares a GET request to a certain address, containing no body or parameters, and requires that the response be returned as a "lazy" [`bytestring`](http://hackage.haskell.org/packages/bytestring).


{% highlight haskell %}
requestGet :: MonadHttp m => m LB.ByteString
requestGet = do
   r <- req
      GET
      (https "www.meetup.com" /: "got-lambda")
      NoReqBody
      lbsResponse
      mempty
   return $ responseBody r   
{% endhighlight %}

The above already requires the user to be familiar with typeclasses, lazy evaluation and a couple standard typeclasses (Monoid and Monad).




{% highlight haskell %}

{% endhighlight %}
