---
title: "I Built Kubernetes From Scratch. Here's What Clicked"
date: 2026-03-18
draft: false
tags: ["kubernetes", "kthw", "platform-engineering", "learning"]
author: "Claude R. Hector"
description: "At work, I click a button and get a Kubernetes cluster. So I built one from scratch to understand what that button actually does."
---

At work, I click a button and get a Kubernetes cluster.

Click another button, add a node.

When you deal with that much automation, you start to forget — or you just don't wonder — how things actually work underneath.

So I built Kubernetes from scratch. No buttons. No managed services. Just me and the components.

## The Abstraction Thing

Look, abstraction is good. It's how we ship fast and scale without losing our minds.

But here's the thing: when everything "just works," you stop asking how.

I've been working with Kubernetes for about 8 months now. Everything was already set up when I started. Clusters were running. I learned to use it — deploy pods, troubleshoot issues, work with the networking.

But I never really questioned what was happening under the hood.

After I passed CKA in January, I wanted to go deeper. Not breadth — I got that from the cert. I wanted depth.

My mentor (platform engineer, teaches Linux at Yellowtail) mentioned Kubernetes the Hard Way back in October, right after I passed RHCSA. I looked at it that night, bookmarked it, and said "I'll do this after CKA."

Four weeks ago, I started.

Last night, I finished.

## It Felt Like Running Commands At First

Honestly — at first, I felt like I was just running commands.

Generate a certificate. Copy a config file. Start a service. Repeat.

I thought I could knock this out in a weekend. Took three weeks (not because it's hard — because I wasn't doing it every night. Monday, Tuesday, Wednesday. Sometimes life came up and I'd skip a session).

But as I compiled notes and kept going, things started clicking.

It was like a puzzle. Each piece you add, you start seeing how the whole thing fits together.

## The Thing That Clicked For Me

Here's what made the whole thing worth it:

**Components don't just talk to each other — they authenticate each other.**

In CKA, you learn that Kubernetes uses TLS certificates. Cool. You accept it and move on.

In KTHW, you actually provision those certificates yourself. For etcd. For the API server. For the controller manager. For the scheduler.

You generate them. You sign them. You configure each component to trust specific certificate authorities.

And that's when it hits you.

The API server doesn't just "trust" etcd. It verifies etcd's certificate before accepting a connection.

Etcd doesn't just "accept" requests from the controller manager. It checks the controller's client certificate first.

The scheduler presents its own certificate when talking to the API server. Mutual authentication.

Every component authenticates every other component — before any data moves.

## Why This Actually Matters

This actually matters.

If someone gets access to your cluster network, they still can't do anything. They can't impersonate the API server — they don't have its private key. They can't read secrets from etcd — the connection requires mutual TLS.

Each component only trusts specific other components, and that trust is cryptographically proven with every connection.

And when you're troubleshooting production at 2am and you see "kubelet can't join the cluster," you need to know: Is it the kubelet's client cert? The API server's cert? The CA chain? Did something expire?

CKA taught me certificates exist.

KTHW taught me why they exist.

## The Other Thing That Clicked

Here's the other realization: etcd doesn't know anything about Kubernetes.

It's just a key-value store. It stores something like `/registry/pods/default/nginx` as a chunk of JSON data. It doesn't care that it's a pod. It doesn't understand "desired state" or "deployments" or "services."

That's the API server's job.

The API server is the translator. You run `kubectl create pod nginx`, and the API server turns that into "write this specific data to etcd at this specific path."

When the controller manager needs to know "what pods exist?", it asks the API server. Not etcd.

When the scheduler needs to assign a pod to a node, it talks to the API server. Not etcd.

When the kubelet needs to know "what should I be running?", it watches the API server. Not etcd.

Only the API server talks to etcd. Everything else goes through the API server.

That's why when you build it manually, the startup order matters:

1. etcd starts first (stores everything)
2. API server starts next (talks to etcd, serves everyone else)
3. Controller, scheduler, kubelet start last (all talk to API server)

The API server isn't just "an API." It's the central nervous system of the cluster. Every component depends on it.

You don't see this dependency chain when everything's already running. You see it when you start services one by one and watch them fail until the API server is up.

## What The Buttons Hide

When you click a button to spin up a Kubernetes cluster, all of this happens in the background:

- Certificate authorities get generated
- Component certificates get signed
- You tell each component exactly who it should trust
- Mutual TLS gets established
- Components start in the right order
- Dependencies get satisfied one by one

You never see it. You never think about it.

Until it breaks.

## Honestly? It Wasn't Hard

I thought this was going to be some brutal grind.

It wasn't.

Everything was pretty straightforward. Yeah, there were moments where something didn't work and I had to troubleshoot it. But nothing was actually difficult.

It was just… satisfying. Like putting together a puzzle where each piece shows you how the system actually works.

## Why I Did This (Real Talk)

I didn't do this thinking "this is going to boost my career" or "this is going to get me promoted."

I did it because I wanted to understand how Kubernetes works under the hood.

After seven months of cert grinding in a new city, I'm taking a more balanced approach now. Health. Building a tribe. Networking with people. But I'm not going to just stop learning.

Will KTHW help my career? Probably. But that's a byproduct. I did it to learn, to get better. The career stuff follows from that.

## Should You Do KTHW?

Hell yes — if you want to understand how Kubernetes actually works.

But it depends on your goal.

If certifications are your focus, CKA covers the operations side well. If you want to understand the architecture — why components exist, how they fit together — KTHW fills that gap.

For me? I wanted to know why things work, not just what they do. I wanted to see the pieces fit together.

If that's you too, do it.

One thing will click for you. Won't be the same thing that clicked for me. But it'll be worth it.

## What's Next

Six months ago, I didn't know Kubernetes the Hard Way existed.

Four weeks ago, I started.

Last night, I finished.

Proud. Accomplished. Ready for what's next.

If you're thinking about doing KTHW — stop thinking, start building.

---

*Have you done Kubernetes the Hard Way? What clicked for you?*
