---
layout: post
title: Custom UI components with HTMX
date: 2023-07-05
categories: web
---

## Introduction

I have a confession to make: I caught the [HTMX](https://htmx.org/) bug. It's a neat library for adding interactivity to web pages by sprinkling a few custom attributes to your markup, you should check it out if you already haven't.

Sometimes though, you do hit some limitations even in a well-designed library such as HTMX, and the other day I had one such case when interfacing with another library.


## Problem statement

I needed a ``range slider'', i.e. a slider with two cursors

{% highlight javascript %}

            window.onload = () => {

                var slider = document.getElementById('slider');
                noUiSlider.create(slider, {
                    start: [20, 80],
                    step: 1,
                    connect: true,
                    range: {
                        'min': 0,
                        'max': 100
                    }
                });

                slider.noUiSlider.on('set', (values)=>{
                   document.getElementById('slider_low').value = values[0];
                   document.getElementById('slider_high').value = values[1];
                   ev = new Event('slider-updated')
                   document.getElementById('form0').dispatchEvent(ev)
                });
{% endhighlight %}
