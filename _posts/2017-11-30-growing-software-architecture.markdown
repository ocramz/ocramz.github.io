---
layout: post
title: Growing a software architecture with types
date: 2017-11-30
categories: haskell 
---


Yesterday evening I made a presentation at a [local functional programming meetup](https://www.meetup.com/got-lambda) regarding my recent experience in building a data ingestion microservice in Haskell. To tell the truth, I was more concerned with communicating the rationale for my design choices rather than the business application per se, and I wanted to show how (my current understanding of) the language helps (or doesn't) in structuring a large and realistic application.

This blog post reproduces roughly the presentation, and incorporates some feedback I received and some further thoughts I have had on the matter in the meanwhile. It is written for people who had some prior exposure to Haskell, but I'll try to keep the exposition as intuitive and beginner-friendly as possible.

My biggest hope is to help beginning Haskellers wrap their heads around a few useful concepts, libraries and good practices, while grounding the examples in a concrete project rather than toy code.

In practical terms, this post will show how to perform HTTP calls, use types, typeclasses and monad transformers to manage application complexity and some aspects of exception handling.

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
      (http "www.datahaskell.org" /: "docs" /: "community" /: "current-environment.html)
      NoReqBody
      lbsResponse
      mempty
   return $ responseBody r   
{% endhighlight %}

The above already requires the user to be at least a bit familiar with typeclasses, lazy evaluation and a couple standard typeclasses (ok, just one really: Monoid. The Monad typeclass is implied by structuring the code in a `do` block). These are fundamental to Haskell, so it helps seeing them used in context. `req` returns in a Monad type because I/O is fundamentally an effect; returning an HTTP response means _doing_ stuff with the network interface, the operating system, and might imply failure of some sort and not return any sensible result, which is distinct from how _pure_ functions behave (i.e. just computing output).


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

Now, we need a way of saying "for each provider `c`, I need a specific set of `Credentials`, and I will receive a specific type of `Token` in return"; the `TypeFamilies` language extension lets us do just that :

{% highlight haskell %}
{-# language TypeFamilies #-}

class HasCredentials c where
  type Credentials c :: *
  type Token c :: *
{% endhighlight %}

In other words, the API provider label will be a distinct type, and we'll need to write a separate instance of `HasCredentials` (and corresponding concrete types for `Credentials` and `Token`) for each.

In addition, let's write a `Handle` record type which will store the actual credentials and (temporary) token for a given provider:

{% highlight haskell %}
data Handle c = Handle {
    credentials :: Credentials c
  , token :: Maybe (Token c)
  }
{% endhighlight %}

The types of the fields of `Handle` are associated (injectively) to the API provider type `c`. All that's left at this point is to actually declare the `Cloud` type, which will use these `Handle`s. We'll see how in the next section.


Managing application complexity with types and monad transformers
------------------------------------------

{% highlight haskell %}
{-# language GeneralizedNewtypeDeriving #-}

newtype Cloud c a = Cloud {
  runCloud :: ReaderT (Handle c) IO a
  } deriving (Functor, Applicative, Monad)
{% endhighlight %}

The body of a `Cloud` computation is something which can _read_ the data in `Handle` (for example the `credentials` or the `token`) and perform some I/O such as connecting to the provider. `ReaderT` is the "reader" [monad transformer](https://wiki.haskell.org/All_About_Monads#Monad_transformers), in this case stacked "on top" of IO. A monad transformer is a very handy way of interleaving effects, and a number of the most common ones are conveniently implemented in the [`mtl`](https://hackage.haskell.org/package/mtl) and [`transformers`](https://hackage.haskell.org/package/transformers) libraries.

The `GeneralizedNewtypeDeriving` language extension is necessary to make the compiler derive the Functor, Applicative and Monad instances for `Cloud`, which are very convenient for composing such computations together.

We may think of `Cloud c a` as an "environment" or "context" within which our networking logic gets executed. In more concrete terms, a `Cloud` computation needs to:

- Read configuration (i.e. a variable of type `Handle c`)
- Create HTTP connections (i.e. I/O)
- Generate random numbers (since the token request is cryptographically hashed)
- Potentially throw and catch exceptions of some sort, for example when an API provider cannot find a certain piece of data.

All the above _effects_ can be "lifted" to corresponding typeclasses, exactly as we saw with `MonadHTTP` and `MonadIO`. The [`exceptions`](https://hackage.haskell.org/package/exceptions) library provides `MonadThrow`/`MonadCatch`, [`cryptonite`](https://hackage.haskell.org/package/cryptonite) provides both all the cryptography primitives and the `MonadRandom` class, and [`mtl`](https://hackage.haskell.org/package/mtl) provides `MonadReader`.

We'll need to provide `Cloud` with instances of all these typeclasses (which most of the time boils down to implementing one or two methods for each), or in other words "augment it" with additional capabilities, in order to unify it with the constraints imposed by our network-related code.

I guess what I wrote above might sound super abstract, so let me provide an example. Suppose we have written a function that requests an authentication token; its type might look something like the following:

{% highlight haskell %}
requestToken :: (MonadHttp m, MonadRandom m, MonadThrow m) =>
     TokenCredentials -> TokenOptions -> m OAuth2Token
{% endhighlight %}

This alone already requires our "execution environment" `m` to have three of the constraints mentioned above. Suppose now we want to read the credentials and/or the options from an immutable record, which might be supplied e.g. by parsing a text file or some command line argument; we can do this if our `m` additionally has a `MonadReader` instance over the relevant configuration variable (e.g. `Handle c` declared above).

If, as we said, our `Cloud c a` type is enriched with these same instances, a complicated set of constraints such as

{% highlight haskell %}
requestToken :: (MonadReader TokenCredentials m, MonadThrow m, MonadHttp m, MonadRandom m) => m OAuth2Token
{% endhighlight %}

might be rewritten as the more informative

{% highlight haskell %}
requestToken :: HasCredentials c => Cloud c OAuth2Token
{% endhighlight %}

# Long overdue aside : why bother ?

This highly polymorphic way of writing functions lets us be as general _or_ precise as we need to. In particular, one of the initial requirements I mentioned was the ability to talk independently about these external data providers, since each has a distinct behaviour and requires different information, but under one same interface.

The `Cloud c a` type is this interface. The parametrization over provider type `c` lets us provide independent implementations of the HTTP exception handling code, for example:

{% highlight haskell %}
{-# language FlexibleInstances #-}

data Provider1

instance MonadHttp (Cloud Provider1) where
  handleHttpException e = ...

... 

data Provider2

instance MonadHttp (Cloud Provider2) where
  handleHttpException e = ...

{% endhighlight %}

while all the behaviour which is _shared_ by all providers can be conveniently written once and for all (for example, random number generation) :

{% highlight haskell %}
instance HasCredentials c => MonadRandom (Cloud c) where
  getRandomBytes = liftIO . getEntropy
{% endhighlight %}

Reducing code duplication while allowing for flexibility where needed, while at the same time having the compiler warn us about every missing or overlapping implementation is a great feature to have for writing software with confidence, I think.

---------


Now we need a function to actually _run_ `Cloud` computations. This is actually trivial: we extract the `ReaderT (Handle c) IO a` stuff that's within the `Cloud` data constructor and apply it to `runReaderT` which passes in the given `Handle` data, thus configuring the computation:

{% highlight haskell %}
runCloudIO :: Handle c -> Cloud c a -> IO a
runCloudIO r (Cloud body) = runReaderT body r
{% endhighlight %}

Since `Cloud` is an instance of Monad we can chain any number of such computations within a `do` block and wrap the overall computation in a `runCloudIO` call, which produces the result:

{% highlight haskell %}
total hdl = runCloudIO hdl $ do 
   c <- cloudAuth
   cloud2 c
   d <- cloud3 c
   ...
{% endhighlight %}







{% highlight haskell %}

{% endhighlight %}
