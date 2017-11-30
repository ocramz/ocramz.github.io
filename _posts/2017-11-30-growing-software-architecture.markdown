---
layout: post
title: Growing a software architecture with types
date: 2017-11-30
categories: haskell 
---


Yesterday evening I made a presentation at a [local functional programming meetup](https://www.meetup.com/got-lambda) regarding my recent experience in building a data ingestion microservice in Haskell. To tell the truth, I was more concerned with communicating the rationale for my design choices rather than the business application per se, and I wanted to show how (my current understanding of) the language helps (or doesn't) in structuring a large and realistic application.

This blog post reproduces roughly the presentation, and incorporates some feedback I received and some further thoughts I have had on the matter in the meanwhile. It is written for people who had some prior exposure to Haskell, but I'll try to keep the exposition as intuitive and beginner-friendly as possible.

My biggest hope is to help beginning Haskellers wrap their heads around a few useful concepts, libraries and good practices, while grounding the examples in a concrete project rather than toy code.

In practical terms, this post will show how to perform HTTP calls, use types and typeclasses to manage application complexity and some aspects of exception handling.

Enjoy!



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


# Aside : inspecting type instances in GHCi

Let's take the last parameter of `req` as a concrete example. It is of type `Option scheme`, where `scheme` is some type parameter. Now, how do I know what are the right types that can be used here? I always have a GHCi session running in one Emacs tile, so that I can explore interactively the libraries imported by the project I'm working on; in this case, I query for information (by using the `:i` GHCi macro) on `Option` (the GHCi prompt is represented by the `>` character):

{% highlight haskell %}
> :i Option
...
instance Monoid (Option scheme) -- Defined in ‘Network.HTTP.Req’
instance QueryParam (Option scheme)
  -- Defined in ‘Network.HTTP.Req’
{% endhighlight %}

I omitted the first few lines because they are not of immediate interest. The rest of the GHCi response shows what typeclass instances the `Option` type satisfies; there we see `Monoid` and `QueryParam`. The Monoid instance is extremely useful because it provides a type with a "neutral element" (`mempty`) and with a binary operation (`mappend`) with some closure property (if `a` and `b` are values of a Monoid type, `mappend a b` is of Monoid type as well).

Strings of texts are one familiar example of things with the Monoid property: the empty string ("") is the neutral element, and appending two strings (`++`) is a binary and associative operation, corresponding to `mappend`. Other common examples of Monoid are 0 and integer addition, or 1 and integer multiplication.

Back to our function `req`; all of this means that since `Option` is a Monoid and I simply wish to pass "no parameter" as an argument, I can use `mempty` and the concrete type will be inferred automatically.



MonadHttp, MonadIO and typeclass "lifting"
----------------------------------------

In the second code snippet above we see that the HTTP response is returned by some computation of type `m`, which is constrained to being an instance of `MonadHttp` :

{% highlight haskell %}
> :i MonadHttp
class MonadIO m => MonadHttp (m :: * -> *) where
  handleHttpException :: HttpException -> m a
  ...
  {-# MINIMAL handleHttpException #-}
{% endhighlight %}

.. What does _that_ mean?

Recall that the HTTP protocol uses status codes to communicate the details of connection failure or success. For example, code 200 stands for success, 404 for "Not Found", etc. The `HttpException` type contains a field where such codes are stored, and any type that's made an instance of `MonadHttp` must provide an implementation of `handleHttpException` that processes this status.

It's important to note that `a`, the return type of `handleHttpException`, is not constrained in any way but may be made to contain whatever information required by the rest of our program logic.

We also see that the parametric type `m` is further required to have a `MonadIO` instance. Fine, web connections are one form of I/O, so this makes some sense. What may be novel to some readers is that rather than being in the usual "concrete" form `.. -> IO a`, the computation is "lifted" to the MonadIO class, thus taking the form `MonadIO m => .. -> m a`. It's as if we went from saying "a computation of type IO" to "something of _any_ type that can perform IO".

The `MonadHttp` typeclass encodes exactly this: since HTTP connections are a form of I/O, the `MonadHttp` constraint _entails_ the `MonadIO` constraint; in other words, every type `m` that has a `MonadHttp` instance _must_ also declare a `MonadIO` instance (the compiler will complain otherwise).

We'll learn about the implications of this way of writing things in the next section.


API authentication and type families
-------------------------------------

Many API providers require some form of authentication; during an initial "handshake" phase the client sends its credentials to the server over some secure channel (e.g. encrypted over TLS), which will in turn send back a "token" which will be necessary to perform the actual API calls and which will expire after a set time. This is for example how the OAuth2 authentication protocol works.

In practice, each provider has its own :

- Set of credentials
- Authentication/token refresh mechanisms
- Handling of invalid input
- Request rate limiting
- Outage modes

and so forth, however the general semantics of token-based authentication are common to all. This screams for some sort of common interface to hide the details of dealing with the individual providers from the rest of the application code.

One possible way of representing this is with a parametrized type; a way of declaring a computation that is "tagged" by the name of the API provider we're talking to under the hood. Let's call this type `Cloud`:

{% highlight haskell %}
newtype Cloud c a = ...
{% endhighlight %}

The first type parameter, `c`, denotes the API provider "label", and the second parameter represents the result type of the computation.

Now, we need a way of saying "for each provider `c`, I need a specific set of `Credentials`, and I will receive a specific type of `Token` in return"; the `TypeFamilies` language extension can help here :

{% highlight haskell %}
{-# language TypeFamilies #-}

class HasCredentials c where
  type Credentials c :: *
  type Token c :: *
{% endhighlight %}

In other words, the API provider label will be a distinct type, and we'll need to write a separate instance of `HasCredentials` for each.

In addition, let's write a `Handle` record type which will store the actual credentials and (temporary) token for a given provider:

{% highlight haskell %}
data Handle c = Handle {
    credentials :: Credentials c
  , token :: Maybe (Token c)
  }
{% endhighlight %}

The types of the fields of `Handle` are associated (injectively) to the API provider type `c`. All that's left at this point is to actually declare the `Cloud` type, which will use these `Handle`s. We'll see how in the next section.


Managing complexity with types
------------------------------

{% highlight haskell %}
{-# language GeneralizedNewtypeDeriving #-}

newtype Cloud c a = Cloud {
  runCloud :: ReaderT (Handle c) IO a
  } deriving (Functor, Applicative, Monad)
{% endhighlight %}

The body of a `Cloud` computation is something which can _read_ the data in `Handle` (for example the `credentials` or the `token`) and perform some I/O such as connecting to the provider. `ReaderT` is the "reader" [monad transformer](https://wiki.haskell.org/All_About_Monads#Monad_transformers), in this case stacked "on top" of IO. A monad transformer is a very handy way of interleaving effects, and a number of the most common ones are conveniently implemented in the [mtl](hackage.haskell.org/package/mtl) and [transformers](hackage.haskell.org/package/transformers)






{% highlight haskell %}

{% endhighlight %}
