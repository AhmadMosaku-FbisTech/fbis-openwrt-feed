# FBIS OpenWrt Feed

This repository provides:
- `fbis-firmware` OpenWrt package (IMSI gatekeeper, VPN helper, digital twin sync)
- Auto opkg feed GPG key updater on routers
- Key rotation helper and CI that publishes a multi-arch feed to GitHub Pages

## Quick usage

1. Add feed to OpenWrt buildroot:
   ```bash
   echo "src-git fbis https://github.com/<your-org>/<your-repo>.git" >> feeds.conf.default
   ./scripts/feeds update fbis
   ./scripts/feeds install fbis-firmware
   make menuconfig
   make
    ```

2. Or install .ipk from published GitHub Pages feed:
```bash
    echo "src/gz fbis https://<your-org>.github.io/<your-repo>/packages" >> /etc/opkg/customfeeds.conf
    opkg update
    opkg install fbis-firmware
```

## Key rotation (maintainer)

Run scripts/rotate-key.sh <suffix> <owner/repo> <github-token> to generate a new GPG key, push the public key and index, and update FEED_GPG_PRIVATE_KEY secret.

CI will sign the Packages index and deploy feed to GitHub Pages.


---

# Final notes & checklist you should perform

1. Replace placeholders:
   - `<your-org>` and `<your-repo>` in scripts and `update-keys.sh` with your org and repo name/URL.
   - Allowed carrier prefix in `carrier_check.sh`.
2. Make scripts executable: `chmod +x` on `.sh` and `.py` files you placed.
3. Add GitHub secrets:
   - `FEED_GPG_PRIVATE_KEY`: ASCII-armored private GPG key used to sign Packages (rotate-key.sh updates this secret automatically if you use the helper).
   - `FEED_GPG_PASSPHRASE` (if used)
4. Install required packages on the machine you’ll run rotate script:
   - `gpg`, `git`, `jq`, `python3`, `python3-pynacl`, `curl`, `openssl`.
5. Test locally with a development OpenWrt SDK before deploying to production.

---

If you want, I can now:
- produce a ready-to-`git apply` patch that creates this tree in your repo, or
- generate each file as a downloadable archive, or
- convert the `fbis_core.c` into a fully-featured compiled binary with Makefile and test harness.

Which of those next steps would you like?
