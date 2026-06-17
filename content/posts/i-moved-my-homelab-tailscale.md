---
title: "I Moved My Homelab Across Town and Let Tailscale Handle the Network"
date: 2026-06-17
draft: false
tags: ["kubernetes", "homelab", "tailscale", "etcd", "bare-metal"]
author: "Claude R. Hector"
description: "What happens when you move five Kubernetes nodes and a NAS to a new apartment, and the one thing that breaks isn't what you expect."
---

Last weekend I moved apartments. Five Kubernetes nodes, a NAS, and a switch came with me. By the time I was done unpacking boxes, the cluster was already back online — and I barely had to touch the network configuration to make it happen.

That wasn't luck. Months ago, when I first built this cluster, I already knew a move was on the table at some point — nothing concrete, just the normal background awareness that apartments don't last forever. So I made a deliberate call: route the whole cluster over Tailscale IPs instead of local network addresses. I figured if the day ever came, I didn't want to be reconfiguring DHCP reservations and static routes while also carrying boxes down three flights of stairs.

I just never got to actually test that decision until the day it mattered.

## The setup

Genesis1 is my homelab — five bare metal Kubernetes nodes, three control planes and two workers, plus a Synology NAS handling storage and backups. It runs a self-hosted photo library, a password manager, and an automation pipeline that pulls my Oura Ring and Apple Health data every night and dumps it into a time-series database for tracking with my coach.

Every node talks to every other node over Tailscale. Not as a remote-access VPN bolted on the side — as the actual network the cluster lives on. etcd traffic, API server communication, kubelet checking in with the control plane, all of it rides on 100.x.x.x Tailscale addresses instead of the usual 192.168.x.x you'd get from your router.

Local IPs are tied to whatever network you happen to be plugged into. Tailscale IPs follow the device. Plug the same machine into a different router and the Tailscale address doesn't care. That was the whole bet.

## Shutdown day

Before any of it went into a truck, the cluster had to come down clean. Workers drained first, control planes after, NAS last. A couple of stateful workloads had PodDisruptionBudgets that pushed back on the drain — InfluxDB and n8n both refused to evict because losing their single replica would technically violate the budget. For a one-time full shutdown that's fine to override:

kubectl drain worker1 --ignore-daemonsets --delete-emptydir-data --disable-eviction

That flag bypasses the PDB entirely instead of waiting around for an eviction that's never going to be allowed. Repeated that across both workers, then the three control planes in reverse order of how much I'd miss them if something went wrong — third control plane first, then the second, then the main one last. SSH'd into the NAS and shut it down properly so the RAID array wouldn't get cranky about it.

Then it was just furniture-moving for the rest of the day.

## Power-on at the new place

NAS first, give it a couple minutes to fully boot, then the control planes, then the workers — same order as shutdown, reversed. Within about five minutes of flipping everything on, every node had quietly reconnected to Tailscale on its own. No re-keying, no manual reauth, nothing.

kubectl get nodes

NAME      STATUS                     ROLES           AGE    VERSION
master    Ready,SchedulingDisabled   control-plane   67d    v1.32.13
master2   Ready,SchedulingDisabled   control-plane   67d    v1.32.13
master3   Ready,SchedulingDisabled   control-plane   7d9h   v1.32.13
worker1   Ready,SchedulingDisabled   worker          67d    v1.32.13
worker2   Ready,SchedulingDisabled   worker          67d    v1.32.13

All five Ready, just sitting cordoned from the earlier drain. Uncordoned everything and moved on:

That part went exactly the way I'd hoped. The cluster genuinely did not seem to notice it had changed buildings.

## The one thing that didn't survive the move

Not everything turned out to be network-agnostic. One of my control planes — a small desktop I'd added a few weeks earlier specifically to get a third etcd member — picked up a different local IP from the new apartment's DHCP than it had at the old place. 192.168.1.169 became 192.168.1.168. One digit.

{"level":"error","msg":"creating peer listener failed","error":"listen tcp 192.168.1.169:2380: bind: cannot assign requested address"}

No etcd, no API server on that node. One of my three control planes was effectively dead.

The fix was a few steps, none of them hard, just things I had to work through one at a time. First, point the static pod manifests at the new IP:

sudo sed -i 's/192.168.1.169/192.168.1.168/g' /etc/kubernetes/manifests/etcd.yaml
sudo sed -i 's/192.168.1.169/192.168.1.168/g' /etc/kubernetes/manifests/kube-apiserver.yaml

Then etcd kept getting rejected with `tls: bad certificate` — because even though the manifests now pointed at the right IP, the actual peer certificate's Subject Alternative Name still said 192.168.1.169. Renewing the cert with kubeadm's built-in renew command didn't pick up the new IP either; it just reissued the same cert with the same stale SAN. Had to delete it and regenerate from scratch:

sudo rm /etc/kubernetes/pki/etcd/peer.crt /etc/kubernetes/pki/etcd/peer.key
sudo kubeadm init phase certs etcd-peer

That generated a fresh cert with the correct IP in it. Last step, tell the rest of the etcd cluster about the node's new peer address so the other two members would stop rejecting its handshake:

kubectl exec -n kube-system etcd-master -- etcdctl 
--endpoints=https://127.0.0.1:2379 
--cacert=/etc/kubernetes/pki/etcd/ca.crt 
--cert=/etc/kubernetes/pki/etcd/server.crt 
--key=/etc/kubernetes/pki/etcd/server.key 
member update 23130d76a17b1dd1 --peer-urls=https://192.168.1.168:2380

Deleted the etcd pod on that node to force a clean restart with the new cert and updated peer URL, and within a couple of minutes it rejoined and the cluster had full quorum again.

The whole thing took about half an hour, mostly spent reading logs to figure out which layer was actually broken — first the manifest's IP, then the cert's SAN, then the membership record. Three different things all pointing at the same underlying problem, which is a good way to learn that "TLS handshake failed" rarely tells you exactly which of those three it is on the first try.

## What actually held up

Everything else came back without me touching it:

- All five nodes reconnected to Tailscale on their own, no manual steps
- ArgoCD picked up right where it left off and reconciled every application
- Ingress, internal DNS, service-to-service traffic — all fine, none of it ever depended on local IPs to begin with
- The health data pipeline ran its nightly sync that same night like nothing had happened

The only thing that needed hands-on attention was the one piece whose security model — not its networking — was still tied to a local address.

## The actual lesson

I didn't design this cluster to be portable as some kind of clever flex. I designed it that way because I had a feeling I'd be moving eventually and didn't want network config to be one more thing to deal with on top of everything else moving day brings. Most of the stack honored that decision without me having to think about it again. One layer — a certificate issued weeks earlier when I added that third control plane — quietly didn't, because at the time, certs and local IPs were just a mechanical detail of joining a node, not something I cross-checked against the bigger architectural bet I'd already made.

Lesson noted for next time: when a node joins this cluster, double check what its certs are actually bound to before assuming "it's all on Tailscale anyway" covers it. It mostly does. It's the part that doesn't that finds you on moving day.
