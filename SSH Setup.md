# Using SSH to Access Ubuntu Chroot/Sandbox from Termux

## Problem

Opening Ubuntu sandbox/chroot manually every time became annoying.

Typical workflow:

```bash
tsu
ubuntu-sandbox enter
cd ~/Projects/MyProject
...
```

I wanted to treat the Ubuntu environment like a remote machine and access it directly via SSH.

---

## Goal

Access Ubuntu sandbox from normal Termux shell like:

```bash
ssh root@localhost -p 2222
```

or shorter:

```bash
ssh ub
```

---

## Setup

### 1. Install OpenSSH server inside Ubuntu

Inside Ubuntu:

```bash
apt update
apt install openssh-server
```

---

### 2. Configure SSH server

Edit:

```bash
nano /etc/ssh/sshd_config
```

Set:

```conf
Port 2222
PermitRootLogin yes
PasswordAuthentication yes
```

---

### 3. Create required runtime directory

Chroot environments may miss this.

```bash
mkdir -p /run/sshd
```

---

### 4. Start SSH server

```bash
service ssh start
```

Verify:

```bash
ss -tln
```

Expected output:

```text
LISTEN 0 128 0.0.0.0:2222
```

---

## Connection Test

From normal Termux shell:

```bash
ssh root@localhost -p 2222
```

---

## Problem Encountered: Password Login Failed

SSH connected successfully, but login always failed.

Error:

```text
Permission denied, please try again.
```

SSH debug logs showed:

```text
User root not allowed because shell zsh does not exist
Failed password for invalid user root
```

---

## Cause

Root user's shell in `/etc/passwd` was:

```text
root:x:0:0:root:/root:zsh
```

The shell entry was `zsh`, not an absolute path like `/bin/zsh`.

SSH treated this as an invalid shell and rejected the user.

---

## Fix

Change root's shell to a valid absolute path.

Using bash:

```bash
usermod -s /bin/bash root
```

Verify:

```bash
grep '^root:' /etc/passwd
```

Expected:

```text
root:x:0:0:root:/root:/bin/bash
```

Restart SSH:

```bash
service ssh restart
```

---

## Successful Connection

From Termux:

```bash
ssh root@localhost -p 2222
```

Login now works.

---

## Optional: SSH Shortcut

In Termux:

Create config:

```bash
nano ~/.ssh/config
```

Add:

```conf
Host ub
    HostName localhost
    Port 2222
    User root
```

Now connect using:

```bash
ssh ub
```

---

## Useful Debug Commands

### SSH client debug

```bash
ssh -v root@localhost -p 2222
```

### SSH server debug

Inside Ubuntu:

```bash
service ssh stop
/usr/sbin/sshd -D -d
```

This prints detailed authentication errors.

---

## Result

Old workflow:

```text
tsu
→ ubuntu-sandbox enter
→ cd project
→ work
```

New workflow:

```bash
ssh ub
```

Ubuntu sandbox behaves like a local remote development server.
