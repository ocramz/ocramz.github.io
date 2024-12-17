---
layout: post
title: Building a deep learning-based music recommendation system - pt. 1
date: 2024-12-16
categories: machine-learning
---


# Introduction 


<!-- ![Preference graph](prefs_graph.png "Preference graph") -->

Can we learn a music recommendation model from raw audio samples and a preference graph?

<img src="/images/prefs_graph.png" width=400/>

This project started from this question, and the curiosity to combine together a few topics I've been curious about recently: audio processing with deep neural networks, contrastive learning and graph data.

# Technical summary

This post describes an audio embedding model, trained to produce embeddings that are close together if the graph distances of their respective albums are small. In other words, I used the preference graph as supervision labels for the audio embeddings: in a contrastive setting, we consider an "anchor" sample, a positive and a negative one, which are here distinguished by their graph distance to the anchor.

It becomes a (context-free, static, non-personalized) recommendation model by:

* embedding a music collection with the trained model
* storing it into an index (here I used SQLite)
* embedding a query (a new music track) with the same model and looking up the most similar ones from the index.

# Dataset

In order to limit the size of the dataset I only considered music samples having the largest <a href="https://en.wikipedia.org/wiki/Centrality#Degree_centrality">in-degree centrality</a>, i.e. the largest number of inbound edges. In simpler words, these are the most recommended albums in the dataset.

Each graph vertex corresponds to a music /album/ which contains one or more tracks.

There are a number of preprocessing steps, and the intermediate results are stored in SQLite, indexed by album, track and chunk ID. For the sake of brevity let's summarize the preprocessing:

* Compute the graph in-degrees from the edges: `INSERT OR REPLACE INTO nodes_degrees SELECT to_node, count(to_node) FROM edges GROUP BY to_node`
* Download top $k$ albums by in-degree centrality: `SELECT album_url, nodes.album_id FROM nodes INNER JOIN nodes_degrees ON nodes.album_id = nodes_degrees.album_id WHERE degree > {degree_min} ORDER BY degree DESC LIMIT {k}`. So far we used $degree = 10$ and $k = 50$.
* For each track in each album: split the audio in 30-seconds chunks, and assign it to either the training or test or validation partition. It's crucial to fix the chunk length, as training works with data batches, and each batch is a (anchor, positive, negative)-tuple of $B \times T$ tensors (batch size, time steps).
* Compute the preference graph distances for each album, up to distance $d_{max}$, by breadth-first search. So far we used $d_{max} = 4$
* For each dataset partition and audio chunk, sample a few other chunks from the graph distance map (<a href="https://en.wikipedia.org/wiki/Isochrone_map">"isochrone"</a>?), among the closest and farthest from the anchor. The IDs for these will be stored in a triplet metadata table
* The PyTorch `Dataset` looks up a triplet from a row index, then using that it retrieves the respective audio chunks (which are stored in SQLite as `np.ndarray`s).

The music preference graph and audio samples were constructed from public sources.


# Model, take 1

I initially experimented with a <a href="https://pytorch-geometric.readthedocs.io/en/latest/generated/torch_geometric.nn.conv.GCNConv.html#torch_geometric.nn.conv.GCNConv">graph convolutional network</a>. The idea behind this was to:

* Embed the most central audio samples
* Diffuse the embeddings out to all the remaining nodes with the GCN.

I dropped this approach because even with 1 GCN layer it required an awful amount of memory (PyTorch crashed on a 16 GB vRAM T4 GPU instance), and initializing embeddings of all the nodes that don't have audio attached require a whole set of dedicated experiments which I didn't have time for.

# Model, take 2

The embedding model is similar to the <a href="https://sander.ai/2014/08/05/spotify-cnns.html">"Spotify CNN" introduced here back in 2014.</a>

The NN architecture can be broken down as follows:

* the audio samples are first transformed into <b>mel-spectrograms</b> (which bins frequencies according to a human perceptual model). I use `n_mels = 128`, 2048 FFT samples and a FFT stride of 1024 throughout.
* the STFT representation is fed to 3 <b>convolutional stages</b>, i.e. `Conv1d` interleaved with a max-pooling operation (window size 4 and 2 respectively). Both the convolutions and the pooling are done over the time axis only.
* After the last 1D convolution there is an <b>average pooling</b> operation over the whole time axis. The result of this is a vector having size `n_mels` for each sample.
* Next, there are three <b>linear layers</b> interleaved with a `ReLU` nonlinearity. The first linear layer maps from `n_mels` to a larger `dim_hidden`, the middle one is a square matrix and the last one projects the hidden dimension down to our embedding space.
* The fully-connected layers are then followed by a $L_2$ <b>normalization</b> step.

The main changes from the Spotify CNN are: 

* I don't use 3 different time pooling functions but only an average pooling. 
* The loss function: here I use a <a href="https://pytorch.org/docs/stable/generated/torch.nn.TripletMarginLoss.html">triplet loss</a> based on the <a href="https://en.wikipedia.org/wiki/Cosine_similarity#Cosine_distance">cosine "distance"</a>, defined as:

$$
d(x_1, x_2) := \sqrt{2 ( 1 - (x_1 \cdot x_2)) }
$$

(NB: the definition above assumes unit-norm vectors $x_1$ and $x_2$).


# Training

Training the model above converges quite smoothly

<img src="/images/melspec_training_loss.png" width=500/>

With the following parameters:

* Adam optimizer
* base learning rate = 0.005
* batch size = 16


# Saving checkpoints for inference

I use <a href="https://lightning.ai/docs/pytorch/stable/">PyTorch Lightning</a> for all my deep learning models, which takes care of automatically saving models during and at the end of each training run.
