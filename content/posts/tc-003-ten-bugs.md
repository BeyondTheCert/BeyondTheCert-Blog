---
title: "TC-003: Ten Bugs Stood Between My Playbooks and a Public Repo"
date: 2026-06-22
draft: false
tags: ["kubernetes", "homelab", "ansible", "calico", "networking", "automation"]
author: "Claude R. Hector"
description: "Validating my bare-metal Kubernetes automation on a second machine surfaced ten bugs in one night. Here's what each one actually taught me."
---

By the time TC-003 came around I'd already proven my Ansible playbooks could stand up a working Kubernetes cluster. One machine, one run, clean output. Figured that was the hard part done.

TC-003 — my third test case for validating this automation across different hardware — was supposed to be the easy step before going public with the repo. Lenovo M920Q as the control plane, a Dell laptop joined as the worker, same playbooks that already worked once. Run it, confirm it still works, ship it.

Ten bugs later I understood why nobody trusts automation after testing it exactly once.

## Why the second machine wrecked everything the first one didn't

My first successful run worked because everything happened to line up. The hostname in my inventory matched what the playbooks assumed. The interface name matched the hardcoded pattern. My own user already had config files sitting where they needed to be from earlier manual setup.

None of that was the playbooks working. That was the playbooks getting lucky.

A genuinely different machine doesn't get that same luck. The M920Q's ethernet interface was `eno2`, not `eno1` like every other ThinkCentre I'd touched. The Dell laptop connected through a USB ethernet adapter, so its interface name came out as `enx00051bded752` — its MAC address wearing a trench coat. My test inventory called the nodes `m920q` and `testnode`, not `master`. Every one of those small differences turned out to be load-bearing, and I only found out once they all gave way at once.

## The bugs, in the order I found them

**Bug 1 — checking the wrong machine.** One playbook checked whether containerd's config needed a fix by reading a file — except it read that file off the Ansible control node, not the actual target. My control node already had the fix from earlier testing, so the check always came back "already fixed" and skipped the node that actually needed it. Fix was deleting the check entirely. The underlying `sed` command was already idempotent — already fixed, it does nothing; not fixed, it fixes it. The condition wasn't protecting anything, it was just lying to me.

**Bug 2 — a hostname that only worked by accident.** Six playbooks used `hosts: master` — run this only on a host literally named master. My test inventory named the control plane `m920q`. Every one of those plays silently skipped. Swapped them all to `hosts: masters`, the inventory group instead of a literal name, so it matches whatever's in that group no matter what I called it. One spot also needed `hostvars['master']` swapped to dynamically grab whoever's first in the group. First real sign my automation wasn't hardware-agnostic at all — it was name-agnostic in my head and hardcoded everywhere it mattered.

**Bug 3 — root has no idea where the cluster lives.** Several `kubectl` tasks run with elevated privileges, so they execute as root. Root has no kubeconfig sitting around unless you put one there — only my own user did, from setup I'd done by hand. Without it, `kubectl` tries `localhost:8080`, gets refused, dies. Pointed those tasks at `/etc/kubernetes/admin.conf` instead, since that one always exists after `kubeadm init`.

**Bug 4 — right command, wrong namespace.** A Calico fix targeted `calico-system`. On a kubeadm cluster, Calico lives in `kube-system`. Nothing wrong with the command, it was just knocking on the wrong door.

**Bug 5 — a backslash that had no business being there.** `kubeadm init` prints its join command across two lines, joined by a line-continuation backslash. My playbook stitched those two lines together with a space, but the literal backslash and extra whitespace came along uninvited, so `kubeadm join` read it as two broken arguments instead of one. Fixed with a regex that strips the backslash and cleans up the whitespace before the command runs. The kind of bug you only find once you actually parse real output instead of assuming it'll look the way you imagined.

**Bug 6 — assuming a tool exists because it existed last time.** A handful of tasks install things with Helm. Helm itself was never installed by the automation — it was just sitting on my first machine because I'd put it there manually months ago and forgot that wasn't part of the script. Added tasks to download and install it first, with `creates: /usr/local/bin/helm` so it skips itself once it's already there.

**Bug 7 — same root problem, different tool.** Identical story to Bug 3, just for every Helm task instead of every kubectl task. Same fix.

**Bug 8 — a chart update I never asked for.** MetalLB picked up a new subchart dependency (`frr-k8s`) sometime between my last test and this one. It expected Prometheus monitoring values that didn't exist, and without them it died with a nil pointer error buried in its template logic. Disabled the `serviceMonitor` option it wanted. Not really my bug — more a reminder that "worked last time" has an expiration date the second you're pulling from an upstream chart repo that ships changes whether you asked for them or not.

**Bug 9 — the one that took down both nodes at once.** This was the real one. Calico needs to figure out which interface to use, and I'd told it exactly which names to look for — `eno1` and `enp0s31f6`. The M920Q was `eno2`. The Dell laptop was that USB-adapter name. Neither matched. Calico crashed on both machines with the same error — couldn't auto-detect an interface.

First instinct was widening the pattern to catch more `eno`-style names. Didn't help — `enx` is a different naming scheme entirely, no amount of widening an `eno` regex gets you there. Considered just letting Calico grab whatever interface it finds first, then talked myself out of it — any node running Tailscale has a `tailscale0` virtual interface sitting right there, and "first found" gives zero guarantee it picks the real ethernet connection over that.

What actually worked:

IP_AUTODETECTION_METHOD=skip-interface=tailscale.*

Stop guessing what the right interface is called. Exclude the one you already know is wrong. Calico finds whatever real ethernet interface exists — Lenovo's name for it, Dell's name for it, whatever the next machine calls it — because the only thing it's told to avoid is Tailscale's virtual interface.

**Bug 10 — a typo.** The ArgoCD chart reference was `argocd/argocd`. The real chart name is `argocd/argo-cd`. One character off, fails every time, no partial credit.

## Where it landed

m920q   : ok=61  changed=18  unreachable=0  failed=0  skipped=2  rescued=0  ignored=1
testnode: ok=25  changed=3   unreachable=0  failed=0  skipped=2  rescued=0  ignored=0

Both nodes Ready. Calico, MetalLB, Nginx Ingress, cert-manager, Sealed Secrets, ArgoCD, Prometheus, Grafana, Loki, Promtail all came up clean. TC-003 passed.

## What ten bugs in one sitting actually tells you

None of these are exotic. Wrong namespace. A hostname pattern that only matched one specific word. A missing kubeconfig path. A tool that was never actually installed. A typo in a chart name. On their own, every one of these is kind of boring.

What's not boring is the pattern. Every single one was invisible on the first machine because the first machine happened to agree with whatever assumption I'd buried in the code without realizing it. The hostname matched. The interface matched. Helm was already sitting there from manual setup I'd half-forgotten about. None of that was the automation working — it was the automation never being asked a question it couldn't answer, until a second, genuinely different machine asked it ten in a row.

That's the actual point of a test like TC-003. Not proving the happy path works — I already knew it did. Proving the thing survives contact with hardware it's never met. Ten bugs found and killed in one night is ten fewer ways this breaks on whatever shows up next.
