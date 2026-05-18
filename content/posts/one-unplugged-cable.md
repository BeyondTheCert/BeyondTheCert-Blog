---
title: "One Unplugged Cable. Two Hours of Debugging. Here's What Broke My Bare Metal Kubernetes Cluster."
date: 2026-05-17
draft: false
tags: ["kubernetes", "homelab", "bare-metal", "etcd", "debugging"]
author: "Claude R. Hector"
description: "I unplugged a router to add a power strip. My Kubernetes cluster went down. Here's what broke, how I fixed it, and what I'd do differently."
cover:
  image: images/cluster-down.png
  caption: "One cable. Two hours."
---

I wasn't doing anything dramatic. No major deployment. No risky configuration change.

I was trying to add a NAS to my homelab. New hardware means more devices, more devices means more outlets, more outlets means buying a power strip. What nobody tells you when you start this journey is that cable management becomes its own project the moment hardware starts multiplying. I ran out of space on my existing surge protector so I needed to plug the new one in somewhere close to the router, close to the switch, close to everything.

So I unplugged the router to free up an outlet, plugged the power strip in, then plugged the router back into the strip. Simple enough.

Router went down. Internet went down. Expected. Thirty seconds later everything came back — except my cluster.

---

## The First Sign

FreeLens couldn't connect. The error was a dial TCP timeout trying to reach port 6443 on master. That's the Kubernetes API server port. If you can't reach 6443 you can't talk to the cluster at all.

I SSH'd into master directly since Tailscale was still up. The node was reachable but kubectl wasn't working. The API server wasn't responding.

---

## The Swap Problem

First thing I checked was kubelet. It was crash looping. The logs told me exactly why:
