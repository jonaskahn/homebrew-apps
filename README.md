# homebrew-relo

Homebrew tap for [Relo](https://github.com/jonaskahn/relo).

```console
brew tap jonaskahn/relo
brew install jonaskahn/relo/relo
```

Start it (console at <http://127.0.0.1:10101>):

```console
relo daemon start
```

Upgrade (the formula stops the running daemon and frees the ports it serves
before the new version is placed):

```console
brew upgrade jonaskahn/relo/relo
```

If `brew uninstall` is used, stop the daemon first so the ports are freed:

```console
relo daemon stop --force
brew uninstall relo
```

Remove (keeps your data in `~/.relo`, same as apt/npm):

```console
relo uninstall --keep-data
brew uninstall relo
```

To delete the data too: `relo uninstall --wipe` before `brew uninstall relo`.
Only one Relo may be installed at a time: if Relo came from the app or npm,
use that method, or remove it completely before `brew install`.
Do not use `brew services` — autostart is `relo autostart enable|disable`.
