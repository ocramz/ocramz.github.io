---
layout: post
title: Growing a software architecture with types
date: 2017-11-30
categories: haskell 
---


Yesterday evening I made a presentation at a [local functional programming meetup](https://www.meetup.com/got-lambda) regarding my recent experience in building a data ingestion microservice in Haskell. To tell the truth, I was more concerned with communicating the rationale for my design choices rather than the business application per se, and how my current understanding of the language helps (or doesn't) in structuring a large and realistic application.

This blog post reproduces roughly the presentation, and incorporates some feedback I received and some further thoughts I have had on the matter in the meanwhile. It is written for people who had some prior exposure to Haskell, but I'll try to keep the exposition as intuitive and beginner-friendly as possible. 



Warm-up: HTTP connections and typeclasses
-------------------------------

This project uses the excellent [`req`](https://hackage.haskell.org/package/req) library for HTTP connections. It's very well thought out and documented, so I really recommend it.

The library is structured around a single function called, quite fittingly, `req`; its type signature reflects the typeclass-oriented design (i.e. function parameters are constrained to belong to certain sets, rather than being fixed upfront). Let's focus on the constraint part of the signature:

{% highlight haskell %}
req :: (HttpResponse response, HttpBody body, HttpMethod method,
  MonadHttp m,
  HttpBodyAllowed (AllowsBody method) (ProvidesBody body)) => ...
{% endhighlight %}

This should be mentally read: "the type `response` must be an instance of the `HttpResponse` class, `body` and `method` are jointly constrained by `HttpBodyAllowed` ..", etc.

As soon as we populate all of `req`'s parameter slots, the typechecker infers a more concrete (and understandable) type signature. The following example declares a GET request to a certain address, containing no body or parameters, and requires that the response be returned as a "lazy" [`bytestring`](http://hackage.haskell.org/package/bytestring).


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

The above already requires the user to be familiar with typeclasses, lazy evaluation and a couple standard typeclasses (Monoid and Monad). These are fundamental to Haskell, so it helps seeing them used in context.


# Aside : inspecting types in GHCi

Let's take the last parameter of `req` as a concrete example. It is of type `Option scheme`, where `scheme` is some type parameter. Now, how do I know what are the right types that can be used here? I always have a GHCi session running in one Emacs tile, so that I can explore interactively the libraries imported by the project I'm working on; in this case, I query for information on `Option` (the GHCi prompt is represented by the `>` character):

{% highlight haskell %}
> :i Option
type role Option phantom
data Option (scheme :: Scheme)
  = Network.HTTP.Req.Option (Data.Monoid.Endo
                               (H.QueryText, H.Request))
                            (Maybe (H.Request -> IO H.Request))
  	-- Defined in ‘Network.HTTP.Req’
instance Monoid (Option scheme) -- Defined in ‘Network.HTTP.Req’
instance QueryParam (Option scheme)
  -- Defined in ‘Network.HTTP.Req’
{% endhighlight %}

This is quite a dense bit of information, so let's unpack it: the `data ..` line shows the actual implementation of `Option` (which is normally hidden from the user), and the next two lines list what typeclass instances this type satisfies; there we see `Monoid` and `QueryParam`. The Monoid instance is extremely useful because it provides a type with a "neutral element" (`mempty`) and with a binary operation (`mappend`) with some closure property (if `a` and `b` are values of a Monoid type, `mappend a b` is of Monoid type as well).

Strings of texts are one familiar example of things with the Monoid property: the empty string ("") is the neutral element, and appending two strings (`++`) is a binary and associative operation, corresponding to `mappend`. Other common examples of Monoid are 0 and integer addition, or 1 and integer multiplication.

Back to our function `req`; all of this means that since `Option` is a Monoid and I simply wish to pass "no parameter" as an argument, I can use `mempty` and the concrete type will be inferred automatically.



MonadHttp
---------





{% highlight haskell %}
> :i MonadHttp
class MonadIO m => MonadHttp (m :: * -> *) where
  handleHttpException :: HttpException -> m a
  ...
  {-# MINIMAL handleHttpException #-}
{% endhighlight %}







{% highlight haskell %}

{% endhighlight %}
