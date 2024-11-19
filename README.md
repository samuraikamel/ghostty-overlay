# Ghostty Overlay

Gentoo overlay for Ghostty related ebuilds

## Activate overlay (via eselect-repository)

```
    $ eselect repository add ghostty-overlay git https://github.com/samuraikamel/ghostty-overlay.git
    $ emaint sync --repo ghostty-overlay
```

To install ghostty using this ebuild the network-sandbox needs to be temporarly disabled.

`FEATURES="-network-sandbox" emerge gui-apps/ghostty`

