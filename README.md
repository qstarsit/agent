# Setup

You will run the coding agent [oh-my-pi](https://github.com/can1357/oh-my-pi) (`omp`) in VS Code, inside a locked-down container. It uses GLM and GPT models on Amazon Bedrock in the EU (Stockholm). The container cannot see your own files, keys or other projects.

Docker Desktop will not work for this. The container needs Podman.
If desired, you can skip the Podman jail and directly use oh-my-pi on your machine.

## 1. Install Podman and VS Code

### macOS

Installation via [Homebrew](https://brew.sh):

```bash
brew install podman
brew install --cask visual-studio-code
```

### Windows

Open PowerShell **as administrator** and install WSL.

```powershell
wsl --install
```

Then, in a normal PowerShell window:

```powershell
winget install RedHat.Podman
winget install Microsoft.VisualStudioCode
```

Close PowerShell and open a new window, so it finds the new commands.

### Linux (Fedora)

```bash
sudo dnf install -y podman
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
printf '%s\n' '[code]' 'name=Visual Studio Code' \
  'baseurl=https://packages.microsoft.com/yumrepos/vscode' 'enabled=1' \
  'gpgcheck=1' 'gpgkey=https://packages.microsoft.com/keys/microsoft.asc' \
  | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
sudo dnf install -y code
```

On Ubuntu or Debian, run `sudo apt install podman` and install VS Code from the `.deb` file on [code.visualstudio.com](https://code.visualstudio.com). Do not use the Snap or Flatpak version of VS Code.

## 2. Start Podman (macOS and Windows only)

On macOS and Windows, Podman runs containers in a small Linux virtual machine. Create it once and start it:

```bash
podman machine init --memory 4096
podman machine start
```

Linux users can skip this step.

## 3. Check Podman

```bash
podman info --format '{{.Host.Security.Rootless}}'
```

This must print `true`. If it prints `false` on macOS or Windows, recreate the machine:

```bash
podman machine rm -f
podman machine init --memory 4096
podman machine start
```

## 4. Get the workshop files

Clone or download this repository and `cd` into it.

## 5. Linux only: install the SELinux wrapper

VS Code switches SELinux off for Podman containers on Linux. This small wrapper switches it back on:

```bash
install -D -m 755 host-setup/podman-selinux ~/.local/bin/podman-selinux
```

## 6. Configure VS Code

Install the Dev Containers extension:

```bash
code --install-extension ms-vscode-remote.remote-containers
```

Open VS Code and press `Ctrl+Shift+P` (`Cmd+Shift+P` on macOS). Run **Preferences: Open User Settings (JSON)** and add these lines inside the outer `{ }`. If the file already has settings, add a comma after the last one first.

```jsonc
"dev.containers.dockerPath": "PODMAN_PATH",
"dev.containers.cacheVolume": false,
"dev.containers.mountWaylandSocket": false,
"dev.containers.copyGitConfig": false,
"dev.containers.gitCredentialHelperConfigLocation": "none",
"dev.containers.dockerCredentialHelper": false,
"chat.disableAIFeatures": true
```

Replace `PODMAN_PATH` with the value for your system:

| System  | `PODMAN_PATH`                                                  |
|---------|----------------------------------------------------------------|
| macOS   | the output of `which podman`, e.g. `/opt/homebrew/bin/podman` |
| Windows | `podman`                                                       |
| Linux   | the output of `echo ~/.local/bin/podman-selinux`               |

These settings stop VS Code from passing your Git login and your desktop session into the container.

## 7. Empty your SSH agent

VS Code also passes your SSH agent into the container. Remove your keys from it before you continue:

```bash
ssh-add -D
```

It is fine if this says there is no agent or there are no keys.

## 8. Open the folder in the container

```bash
code .
```

1. Click **Reopen in Container** in the message at the bottom right. If you miss the message, press `Ctrl+Shift+P` and run **Dev Containers: Reopen in Container**.
2. If VS Code asks whether you trust the authors, click **Trust Folder & Continue**.
3. Wait a few minutes. You are done when the bottom-left corner shows **Dev Container: rootless-agent**.

## 9. Add your API key

Open a terminal in VS Code with `` Ctrl+` `` and run:

```bash
set-key
```

Paste your key and press Enter. Nothing appears on screen while you paste, which is normal. You should see `Key works.` and `Key saved.`

## 10. Start the agent

Clone a project into the container and start oh-my-pi:

```bash
git clone https://github.com/octocat/Hello-World.git /workspace
omp
```

- Switch models with `/model`. GLM-5 is the default. GLM-4.7 and gpt-oss-120b are also available.
- To leave oh-my-pi, type `/quit`.

## Good to know

- **The agent can reach the internet**, because it needs that to reach the models. It cannot see your own files.
- **If you typed the wrong key**, run `set-key` again.
