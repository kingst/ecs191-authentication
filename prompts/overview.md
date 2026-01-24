# Login example

We are going to be building a system to facilitate SMS-based login for
mobile apps. Overall we'll have three main components: a server that
manages the verification flow, and iOS + Android clients that log in
using the server. The iOS and Android clients will be standard apps vs
an SDK and will be for demonstration purposes, but we will deploy the
server to production so that students can use it this quarter.

We are also including a feature to use on the main view: a food
tracker. The food tracker takes a picture of food, gets it analyzed by
our server, and displays today's information for the user.

## Project organization

From the top level directory of this repo, here are the main
subdirectories:

  - prompts: where we store prompts we use

  - server: The Google App Engine Python service for hosting our APIs

  - ios: The iOS app

  - android: The Android app

## Rules

- Don't edit any of the files in `prompts`. These are files that I
  will update manually as my specification evolves. The rest of the
  directories are where you will implement code and can make
  modifications.

- Don't commit any code using `git`. I'd like to inspect code you
  write before committing it.

- Don't push any code to GitHub. I'll handle pull request creation,
  etc, manually.

- Don't modify iOS project files. These are extremely tricky to get
  right, so I'll add any files you need manually.

- I will be making changes to the code periodically, so from one
  prompt to the next code may have changed. Please re-read any files
  you use to get their current state and don't assume that they are
  unchanged since your last modifications.

- Ask questions if something is unclear! I'm here to help so if my
  instructions are too ambiguous or unclear, let me know and I can
  elaborate.