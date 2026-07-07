# mac-init

A repo that exists because "just Google it again" stopped scaling.

## What is this?

A single shell script that sets up a fresh Mac for development — so you don't have to mass open 14 browser tabs, copy-paste from 6 different Stack Overflow answers, and still forget to install Homebrew first.

You've done this before. Multiple times. You told yourself you'd "document it next time." You didn't. This repo is that documentation.

## Prerequisites

- A Mac. Preferably one that hasn't been "set up" by your past self who thought `sudo chmod -R 777 /` was a reasonable debugging step.
- An internet connection. The script downloads things from the internet. Shocking, I know.
- About 10–15 minutes of your time (or longer if your Wi-Fi is powered by thoughts and prayers).

## How to Run

```bash
# Step 1: Clone this repo (you need git for this, which... you're about to install. 
#         Classic chicken-and-egg. Use the GitHub ZIP download if you must.)
git clone https://github.com/dhileep47/mac-init.git

# Step 2: Navigate into the repo
cd mac-init

# Step 3: Make the script executable, because apparently downloading a file 
#         doesn't mean you're allowed to run it
chmod +x scripts/setup-mac.sh

# Step 4: Run it. Yes, it's that simple. No, there's no catch.
./scripts/setup-mac.sh
```

> [!TIP]
> The script is **idempotent** — a fancy word that means you can run it again without breaking things. Unlike that time you ran `brew upgrade` and your entire Python ecosystem caught fire.

## What Gets Installed

| Tool | Why |
|------|-----|
| **Xcode Command Line Tools** | Because nothing works on macOS without Apple's blessing first |
| **Homebrew** | The package manager that Apple should've shipped but didn't |
| **Git** | So you can `git blame` your coworkers |
| **Python 3.14** | For those `import antigravity` moments |
| **fnm + Node.js LTS** | Because `nvm` was too slow and you know it |
| **Bun** | Because `npm install` taking 45 seconds was unacceptable |
| **Antigravity IDE** | The editor that writes code back at you |

## After Running

Open a **new terminal tab**. Or run:

```bash
source ~/.zprofile && source ~/.zshrc
```

Because your current shell still thinks it's 2019 and has no idea what just happened.

## FAQ

**Q: Can I run this on Linux?**
A: No. It's called `mac-init`, not `linux-init`. Reading is fundamental.

**Q: It failed halfway through. What do I do?**
A: Run it again. That's the whole point of making it idempotent. Pay attention.

**Q: Can I customize what gets installed?**
A: It's a shell script, not a SaaS product. Open it. Edit it. You're a developer (presumably).

---

Made with mass amount of coffee and mass amount of sarcasm.