---
title: "Calico and Tailscale Have a BGP Conflict. Here's Exactly What Breaks and How to Fix It."
date: 2026-04-26
draft: false
tags: ["kubernetes", "networking", "calico", "tailscale", "bgp", "homelab", "bare-metal"]
author: "Claude R. Hector"
description: "Running Calico and Tailscale together on bare metal Kubernetes? There's a BGP conflict nobody warns you about. Here's what breaks and the two-step fix."
cover:
  image: images/calico-tailscale.png
  caption: "Calico picks the wrong interface. Pod networking breaks silently."
---

If you're building a bare metal Kubernetes cluster with Calico and you've also installed Tailscale for remote access — read this before you spend hours debugging pod networking.

I didn't. I spent the hours. Here's what I learned.

## The Setup

I'm running a 4-node bare metal Kubernetes cluster. Two ThinkPad T480s as control plane nodes. Two ThinkCentre M720q desktops as workers. Tailscale provides a stable mesh network so the cluster survives apartment moves — the Tailscale IPs never change even when the home network IPs do.

Stack: kubeadm, Calico v3.29, Tailscale, Ubuntu Server 24.04.

## What Broke

After joining the worker nodes pods on workers couldn't reach the Kubernetes API server. The symptom was a connection timeout to `10.96.0.1:443` — the ClusterIP of the Kubernetes API server service.

MetalLB kept crashing with the same error:
