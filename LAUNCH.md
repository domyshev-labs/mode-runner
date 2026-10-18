# Introducing Mode Runner

Author: ilia domyshev. Project: https://github.com/domyshev-labs/mode-runner.
Use these materials only after a signed beta download is published and verified.
Do not publish claims about telemetry, performance, or OS compatibility that have
not been checked for the released build.

## First beta feedback

Invite 5–10 frontend developers who work with more than one local project.
Ask each person to install the DMG, find the menu bar icon, run the starter frontend
and mock API, add one of their own projects, restart a process, run a one-off
command, and combine processes using pins. Observe where they need help.

Collect the app version, macOS version, architecture, time to first successful
project launch, and the main point of confusion. Fix repeated blockers before
sending the app to broader audiences. Track release downloads and concrete issue
reports; no in-app analytics are required for this initial feedback loop.

## A 45-second recording

Use the released app, the starter configuration, and public demo data. Keep
personal projects, hostnames, shell history, and credentials out of the recording.

1. Show the menu bar icon and open Mode Runner.
2. Start a frontend and mock API together, then open the local website from a log.
3. Restart only the frontend and show that the mock process keeps running.
4. Run a command from Seeds and show its completed log.
5. Pin the mock process, switch projects, and start another frontend.
6. End on the running process combination and the project URL.

Capture one screenshot of the workspace with readable logs and pinned tabs, and
one showing the local website beside it. Add real captures to the README and a
future product page. Do not use rendered mockups as screenshots of the app.

## Draft personal announcement

I built Mode Runner after years of working as a frontend developer and running
local apps in terminals, Cursor, WebStorm, and VS Code. Each approach worked,
but I kept wanting a more convenient place to manage several projects at once.

Mode Runner is a native macOS menu bar app. A project can launch a frontend,
mock API, and other processes together, with separate logs and restart controls.
You can also run one-off commands such as seeders and pin process tabs to combine
processes from different projects.

It started as a tool for my own daily work. I’m sharing the first beta because
I’d like to hear whether it makes your development workflow easier too.

Source, installation, and downloads:
https://github.com/domyshev-labs/mode-runner

Created by ilia domyshev. GPLv3.

## Show HN draft

Title: Show HN: Mode Runner – local development processes in your Mac’s menu bar

Use the personal announcement as the opening comment, accompanied by a direct
link to the signed release and a short recording. Mention that configuration is
currently YAML and that the app is a beta. Explain how pins combine processes
from different projects. Make it easy to try without an account or signup.

## Distribution sequence

1. Personal beta invitations and direct feedback.
2. A personal LinkedIn post with the short recording and the story behind the app.
3. Relevant frontend and macOS communities, following each community's promotion rules.
4. Show HN once the signed download and first-run experience work independently.
5. Product Hunt after incorporating initial feedback and preparing real screenshots.

Respond to workflow questions and reproducible problems. Keep a public changelog
and post a follow-up when feedback produces a useful improvement. Do not send or
publish these drafts automatically.
