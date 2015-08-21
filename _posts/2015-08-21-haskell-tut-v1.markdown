---
layout: post
title: Introduction to functional programming with Haskell
date: 2015-08-21
categories: Haskell, tutorials
---

# The interactive Haskell interpreter, GHCi

In the following we show an example interactive session with GHCi, to familiarize the reader with the notation and some fundamental concepts of the language.

The `>}`character at the start of a line indicates the interpreter prompt, whereas `:t` is the GHCi macro for requesting the type of an expression.\\ If the prompt is not present, we assume we are working in a `.hs` text file, to be loaded in GHCi.
The `--` token at the start of a line specifies a comment: the line is not interpreted as Haskell code.\\
If we input an expression that already has a value associated, GHCi computes and prints the expression value on the next line.\\If, on the other hand, we ask for the type of an expression `x` with `:t x`, the interpreter outputs this after a double colon. 

{% highlight haskell %}
main :: IO ()
main = 
  putStrLn "test"
{% endhighlight %}