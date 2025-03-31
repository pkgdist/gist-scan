# @softdist/gist-scanner

**Scan your GitHub Gists for secrets, high-entropy tokens, regex patterns, and terms.**

> [!IMPORTANT]
>
> This project is in early alpha.  It can be reliably cloned and run with the "make run" command, on linux systems or those with Makefile support.  We are currently iterating on improving the pagination features and speed.

---

## Install

```bash
deno install --allow-net --allow-env -n gist-scan https://jsr.io/@softdist/gist-scanner@v0.1.2
```

---

## Usage

```bash
gist-scan [OPTIONS]
```

---

### Options

| Option               | Description                                                                      |
|---------------------|----------------------------------------------------------------------------------|
| `-t, --term`         | Search term(s) to match in gists (filename, description, and content).            |
| `-r, --regex`        | Regex pattern(s) to match in gists.                                              |
| `-s, --secrets`      | Scan for high-entropy secrets (GitHub tokens, JWTs, API keys, hashes, etc.).      |
| `-d, --delete`       | Delete matched gists.                                                            |
| `-y, --yes`          | Auto-confirm deletion without prompting for each gist.                          |
| `-h, --help`         | Display this help message with usage examples.                                   |

---

## Examples

### 1. Search for a specific term in Gists:

```bash
gist-scan --term "password"
```

---

### 2. Search for a regex pattern (e.g., AWS Access Key):

```bash
gist-scan --regex "AKIA[0-9A-Z]{16}"
```

---

### 3. Scan for high-entropy secrets like tokens, JWTs, and hashes:

```bash
gist-scan --secrets
```

---

### 4. Combine search for a specific term and delete matched gists (with confirmation):

```bash
gist-scan --term "password" --delete
```

---

### 5. Automatically delete all matched gists (without confirmation):

```bash
gist-scan --term "password" --delete --yes
```

---

### 6. Combine regex pattern search and secret scanning:

```bash
gist-scan --regex "my-api-key-\d+" --secrets
```

---

## Environment Variables

- `GH_SCAN_TOKEN`: GitHub Personal Access Token (PAT) used for authenticated API access to list and delete Gists.

Example:

```bash
export GH_SCAN_TOKEN=your_github_pat_here
```

---

## How to Publish to [jsr.io](https://jsr.io)

### 1. Check and validate:

```bash
deno check mod.ts
```

---

### 2. Publish to jsr.io (replace version appropriately):

```bash
jsr publish --version v0.1.0
```

---

### 3. Install directly via jsr.io (once published):

```bash
deno install --allow-net --allow-env -n gist-scan https://jsr.io/@softdist/gist-scanner@0.1.0
```

---

## License

MIT License © 2024 SoftDist