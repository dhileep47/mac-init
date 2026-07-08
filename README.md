# mac-init

A repo that exists because "just Google it again" stopped scaling.

## What is this?

A couple of shell scripts that set up a fresh Mac for development — so you don't have to mass open 14 browser tabs, copy-paste from 6 different Stack Overflow answers, and still forget to install Homebrew first.

You've done this before. Multiple times. You told yourself you'd "document it next time." You didn't. This repo is that documentation.

## Prerequisites

- A Mac. Preferably one that hasn't been "set up" by your past self who thought `sudo chmod -R 777 /` was a reasonable debugging step.
- An internet connection. The script downloads things from the internet. Shocking, I know.
- About 10–15 minutes of your time (or longer if your Wi-Fi is powered by thoughts and prayers).

## Scripts

| Script | What it does |
|--------|--------------|
| `setup-mac.sh` | Installs all the dev tools (Homebrew, Git, Python, Node, Bun, etc.) |
| `setup-git-ssh.sh` | Configures git identity + SSH key for GitHub (single account) |
| `setup-git-multi.sh` | Sets up **two** SSH identities — personal + org — for people living double lives on GitHub |

Run `setup-mac.sh` first. Then pick **one** of the git scripts — `setup-git-ssh.sh` if you're a one-account person, `setup-git-multi.sh` if your employer also wants a piece of your GitHub. Running both is not illegal, but it is redundant.

## How to Run

```bash
# Step 1: Clone this repo (you need git for this, which... you're about to install. 
#         Classic chicken-and-egg. Use the GitHub ZIP download if you must.)
git clone https://github.com/dhileep47/mac-init.git

# Step 2: Navigate into the repo
cd mac-init

# Step 3: Make the scripts executable, because apparently downloading a file 
#         doesn't mean you're allowed to run it
chmod +x scripts/*.sh

# Step 4: Install all the things
./scripts/setup-mac.sh

# Step 5: Pick ONE of these depending on your lifestyle:

# Option A — Single GitHub account (normal people)
./scripts/setup-git-ssh.sh

# Option B — Two GitHub accounts: personal + org (corporate spies)
./scripts/setup-git-multi.sh
```

> [!TIP]
> All scripts are **idempotent** — a fancy word that means you can run them again without breaking things. Unlike that time you ran `brew upgrade` and your entire Python ecosystem caught fire.

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

## What Gets Configured

`setup-git-ssh.sh` handles the part where you convince GitHub you are who you say you are:

| Config | What & Why |
|--------|------------|
| **Git identity** | Sets `user.name` and `user.email` so your commits aren't authored by "Unknown" like a horror movie |
| **Default branch → `main`** | Because it's 2026 |
| **Pull strategy → merge** | `pull.rebase false` — no surprise rebase drama |
| **SSH key (ed25519)** | Generates one if you don't have one. Adds it to macOS Keychain so you stop typing passphrases like it's 2005 |
| **SSH over port 443** | Routes `github.com` through `ssh.github.com:443` — so your university/office Wi-Fi that blocks port 22 can't stop you from pushing code |

> [!NOTE]
> After running `setup-git-ssh.sh`, it copies your public key to the clipboard. Go paste it at [github.com/settings/keys](https://github.com/settings/keys). Then re-run the script to verify. Yes, it tests the connection for you. You're welcome.

### `setup-git-multi.sh` — for those with commitment issues (two GitHub accounts)

For when your personal `git blame` history shouldn't show up in your company's repo, and vice versa.

| Config | What & Why |
|--------|------------|
| **Two SSH keys** | Generates `id_ed25519_personal` and `id_ed25519_org` — because one key for two accounts is identity fraud |
| **SSH host aliases** | Creates `github-personal` and `github-org` aliases. You clone with the fake hostname, SSH figures out the rest |
| **Both over port 443** | Same firewall-dodging trick, now for both identities |
| **Directory-based git identity** | Any repo under `~/work/` automatically uses your org name/email. Everything else uses your personal identity. No more "oops wrong email" commits |
| **Conditional `.gitconfig`** | Creates `~/.gitconfig-org` and wires it up with `includeIf` — git's built-in "if you're in this folder, be this person" feature that nobody knows about |

**Usage after setup:**

```bash
# Personal repos — business as usual, but with the alias
git clone git@github-personal:yourname/repo.git

# Org repos — clone into ~/work/ and git identity switches automatically
cd ~/work
git clone git@github-org:yourorg/repo.git
```

> [!NOTE]
> The script prints both public keys at the end. Add each one to the **correct** GitHub account at [github.com/settings/keys](https://github.com/settings/keys). Mix them up and you'll have a very confusing afternoon.

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