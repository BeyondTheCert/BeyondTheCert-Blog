---
title: "I Didn't Pass the CKA by Studying Harder. I Passed by Debugging Smarter."
date: 2026-02-24
draft: false
tags: ["kubernetes", "cka", "platform-engineering", "career", "devops"]
author: "Claude R. Hector"
description: "My story: 41 → 47 → 65 → 81. Four attempts. Three failures. One certification. Here's what actually happened."
---

You see the announcement: "I passed the CKA!" Here's what you don't see:

My story? 41 → 47 → 65 → 81.

Four attempts. Three failures. One certification.

Here's what actually happened.

## The Beginning: September to December 2025

I'd just passed the RHCSA in September 2025. Working in a heavy Kubernetes shop, I figured the CKA would give me the baseline I needed. I knew what K8s was, but I'd never worked with it in a production environment. My company hired me with light K8s skills — now it was time to formalize them.

From September to early December, I worked through Mumshad's KodeKloud course — solid foundation. I did the practice tests. I felt ready.

I scheduled Exam 1 for December 21st.

## Exam 1: December 21st — Score: 41/66

I was confident going in. But practice tests and the real exam? Two completely different experiences.

The check-in process threw me off. Once I got into the PSI browser environment, I wasted 5–7 minutes just figuring out navigation. Turns out the terminal was hiding behind the browser.

I'd built what I called my "Road to 66%" — my strategic question sequence based on topics I knew would get me to passing: CNI, CRDs, HPA, storage classes, ingress, Helm, sidecars, troubleshooting.

But nerves hit. The environment felt laggy. Before I knew it, an hour had passed.

Two problems killed me:

- **Ingress:** Ran into YAML syntax errors when I tried `k apply`. Wasted too much time.
- **Helm:** Hit an annotation error. More wasted time.

Final result: 11 of 16 questions attempted. Score: 41/66.

I wasn't surprised. I knew where I went wrong. I just needed to get back to the drawing board.

## The Break: December 22nd — January 5th

I didn't touch Kubernetes for two weeks over the holidays. But I thought about it constantly. I replayed scenarios in my head, analyzing what went wrong.

January 6th, I reintroduced myself to K8s. Same practice routine. Same "Road to 66%" sequence.

Exam 2 was scheduled for January 18th.

## Exam 2: January 18th — Score: 47/66 (The Shock)

This time, I felt confident. I'd seen the exam before. I knew the terminal was hiding behind the browser. I knew the check-in quirks.

I went in ready to dominate.

I attempted 13 questions (up from 11).

Progress on some issues:

- **Helm:** Fixed the annotation error from Exam 1.
- **Ingress:** No YAML syntax errors this time. But when I curled to verify, no 200 response. I panicked. Deleted the LoadBalancer service, created a NodePort service. Still didn't work. Wasted 15 minutes.

And then there was sidecar hell.

The sidecar question was my kryptonite. I'd do `k edit deployment`, add the sidecar container perfectly, try to save with `:wq`... and instead of returning to the terminal, I'd stay stuck in the YAML editor. There was a syntax error somewhere, but I could never find it in time.

But I walked out feeling good. I'd attempted 13 questions instead of 11. Even if I barely passed — 67, 70 — a pass is a pass.

The next day: 47/66.

I was shocked. Devastated. Not much improvement from Exam 1. Worse? I'd exhausted my free retake. I'd have to buy a new voucher at full price.

It affected me for days.

## The Analysis: January 19th — 23rd

After two days, I shifted my approach: debug what went wrong instead of dwelling on it.

I asked AI: "Which topics get me to 66%?" I analyzed every mistake. I identified the pattern.

**The breakthrough: I was too declarative.**

Exams 1 and 2, I was writing YAML from scratch using the Kubernetes docs. I'd reference the examples, modify them for the question, then apply. When it didn't work, finding the syntax error in the YAML burned too much time.

**The shift: Go imperative.**
From January 20th to 23rd, I practiced nothing but imperative commands.

I bought a new voucher on January 22nd. Scheduled Exam 3 for Saturday, January 24th.

## Exam 3: January 24th — Score: 65/66 (One Point Away)

This time, I went full imperative where I could.

- **Ingress:** Created it imperatively. Curled. Got a 200 response. Done.
- **Helm:** Fixed my chart name issue.

The result of going imperative? I had way more time. Attempted 14 questions (up from 13).

But sidecar was still my nemesis. `k edit deployment`, add sidecar, try `:wq`... stuck in YAML hell again.

Sunday, January 25th, results came in: 65/66.

One point shy.

But I wasn't disappointed. I was close. I knew what to fix. I just needed to nail sidecar.

An 18-point jump in 6 days. From 47 to 65. The imperative strategy worked. I just needed to execute cleaner.

## The Final Push: January 24th — 28th

Sidecars aren't conceptually difficult — it's the YAML formatting under pressure that kills you. I asked AI to generate messy YAML files. I practiced editing sidecars until I could do it in my sleep.

Scheduled for Wednesday, January 28th.

## Exam 4: January 28th — Score: 81/66 (PASSED)

Fourth time. Same sequence. Same strategy. Attempted 15 questions (up from 14).

- **Ingress:** Imperative. Returned 200. Done.
- **Helm:** Fixed. Done.
- **HPA, storage classes, network policies:** Imperative where possible. Done.

And then… the sidecar question. My final boss.

I saved it for second-to-last. Knocked out everything else first.

Finally, I opened the sidecar question. `k edit deployment`. Made my changes. Held my breath.

`:wq`

The terminal prompt came back.

I knew right then. I passed.

The next day: 81/66.

## What Actually Worked

**Resources:**
- KodeKloud (Mumshad's course, practice exams, lightning labs)
- Tech with Piyush (40 Days of Kubernetes playlist)
- AI for weak spot analysis and sidecar YAML practice

**Strategy:**
- Imperative over declarative (where possible)
- Time management: Skip questions eating too much time, come back later
- Each exam = fix one mistake + attempt one more question
- Not "study harder" but "debug smarter"

**PSI Browser Tips:**
- Terminal is hiding behind the browser (click to bring it forward)
- Environment can be laggy — imperative commands save time

**Aliases:** Just `k` for kubectl. Kept it simple.

## How I Feel Now

When I started this journey in January 2022, I feared containers. We often fear what we don't understand.

Now I'm CKA certified.

But the job's not done. The CKA gave me the baseline I needed, but there's still work to do. I'm actively building depth in the areas where I feel shallow.

You see the 81. You don't see the 41, the 47, the 65. You don't see the sidecar hell, the ingress pain, the Helm mistakes.

But that's the journey. That's what it takes.

If you're stuck where I was — failing exams, close but not passing — stop studying harder. Start debugging smarter.

Each exam is a bug report. Fix one bug. Attempt one more question. That's how you go from 41 to 81.
