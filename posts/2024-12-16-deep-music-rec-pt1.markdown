---
layout: post
title: Deep music recommendation - pt. 1
date: 2024-12-16
categories: machine-learning
---


# Introduction 


<!-- ![Preference graph](prefs_graph.png "Preference graph") -->

Can we learn a music recommendation model from raw audio samples and a preference graph?

<img src="/images/prefs_graph.png" width=400/>




# Dataset

The music preference graph and audio samples were constructed from public sources.


# Model

The embedding model is a variation of the <a href="https://sander.ai/2014/08/05/spotify-cnns.html">"Spotify CNN" introduced here back in 2014.</a>

The NN architecture can be broken down as follows:

* the audio samples are first transformed into mel-spectrograms (which bins frequencies according to a human perceptual model);
* the STFT representation is fed to 3 convolutional stages, i.e. `Conv1d` interleaved with a max-pooling operation (window size 4). Both the convolutions and the pooling are done over the time axis only.
* After the last 1D convolution there is an average pooling operation over the whole time axis. The result of this is a vector having size `n_mels` for each sample.
* Next, there is a `Linear` layer that projects the frequency bins to our embedding space,
* followed by a $L_2$ normalization step.

The main change from the Spotify CNN is the loss function: here I use a <a href="https://pytorch.org/docs/stable/generated/torch.nn.TripletMarginLoss.html">triplet loss</a> based on the <a href="https://en.wikipedia.org/wiki/Cosine_similarity#Cosine_distance">cosine "distance"</a>, defined as:

$$
d(x_1, x_2) := \sqrt{2 ( 1 - (x_1 \cdot x_2)) }
$$

(NB: the definition above assumes unit-norm vectors $x_1$ and $x_2$).
