# Sovobian

Prebuilt Armbian-based images for Sovol H616 printer hosts: **Sovol Zero**, **SV08**, and **SV08 Max**.

Sovol's H616 host boards are near-clones of the BigTreeTech CB1, and stock Armbian (board profile *BigTreeTech CB1*) runs on them — the only real difference is the eMMC clock the vendor validated, plus an enabled toolboard UART on the SV08/SV08 Max. Sovobian takes the upstream Armbian CB1 minimal image and preinstalls a tiny device tree overlay with those per-board differences. Nothing else is changed: kernel upgrades via `apt` keep working because the overlay lives in `overlay-user/`, which kernel packages never touch.

The method and the per-board numbers are documented in [this gist](https://gist.github.com/lexfrei/7f695d61d4f47cbfbc75e6e1369371c0); the full verified walkthrough for the Zero is in [lexfrei/sovol-zero-mainline — OS.md](https://github.com/lexfrei/sovol-zero-mainline/blob/main/OS.md).

## Boards

| Board | eMMC clock | Extra | Status |
| --- | --- | --- | --- |
| Sovol Zero | 40 MHz | — | verified on hardware |
| Sovol SV08 | 45 MHz | uart3 on PI9/PI10 (toolboard) | **untested** — reports welcome |
| Sovol SV08 Max | 40 MHz | uart4 on PI13/PI14 (toolboard) | **untested** — reports welcome |

The SV08 and SV08 Max overlays are derived from the vendor device trees in the official images but have not been verified on real machines yet. If you own one, please [open an issue](../../issues) with your results either way.

## Note for images downloaded before 2026-07-12

Earlier Sovobian images shipped with the kernel apt-pinned to the 6.12 line because of a suspected SDIO wifi regression in sunxi-6.18. The regression did not reproduce on healthy hardware (16/16 clean boots on 6.18.33 on a genuine BTT CB1) and was traced to a failing board; the report was retracted ([armbian/build#10164](https://github.com/armbian/build/issues/10164)). If you run one of those images, delete `/etc/apt/preferences.d/sovobian-kernel-hold` to resume normal kernel upgrades.

## Download and flash

1. Grab the image for your board from [Releases](../../releases) and verify it against `SHA256SUMS`.
2. Write it to a microSD card (Balena Etcher, `dd`, or anything similar).
3. Boot the printer host from the card — the H616 boot ROM prefers SD over eMMC — and go through the standard Armbian first-boot setup.
4. Optionally run `armbian-install` to move the system to the onboard eMMC and free up the card.

## How it works

Each release is the upstream Armbian BigTreeTech CB1 minimal image with two modifications made by [`scripts/repack.sh`](scripts/repack.sh):

- the compiled per-board overlay from [`boards/`](boards/) is placed in `overlay-user/` on the boot filesystem and registered via `user_overlays=` in `armbianEnv.txt`;
- `fdtfile=` is pointed at `sun50i-h616-bigtreetech-cb1-emmc.dtb`, the eMMC-enabled CB1 device tree that Armbian ships.

Versioning mirrors upstream: Sovobian `v26.2.1` is repacked from Armbian `26.2.1`. The upstream version is pinned in [`ARMBIAN_VERSION`](ARMBIAN_VERSION); Renovate watches the Armbian download archive and opens an auto-merged PR when a new version appears, which triggers the build workflow and publishes a new release. Point releases do not always ship every distribution, so the build resolves the distro branch dynamically, preferring Debian releases over Ubuntu ones.

## Building locally

Requires Linux, root (for `losetup`/`mount`), and `dtc`:

```bash
curl --location --remote-name https://dl.armbian.com/bigtreetech-cb1/archive/Armbian_26.2.1_Bigtreetech-cb1_trixie_current_6.12.68_minimal.img.xz
unxz Armbian_26.2.1_Bigtreetech-cb1_trixie_current_6.12.68_minimal.img.xz
sudo scripts/repack.sh Armbian_26.2.1_Bigtreetech-cb1_trixie_current_6.12.68_minimal.img boards/sovol-zero.dts sovobian-zero.img
```

## Trademarks

Sovobian is a community project and is not affiliated with, endorsed by, or supported by Armbian, Sovol, or BigTreeTech. The images are modified Armbian builds distributed under a different name in accordance with the [Armbian trademark policy](https://www.armbian.com/trademark/).

## License

[GPL-3.0](LICENSE)
