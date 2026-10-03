[English](THIRD_PARTY.md) | [日本語](THIRD_PARTY.ja.md)

# Third-party materials and data

## Perfume BVH

**Primary source: [Perfume global site project #001](https://perfume-global.com/web/2012/03/perfume-global-site-project-001/).** Attribution refers to the official primary project.

- Inputs: `aachan.bvh`, `kashiyuka.bvh`, `nocchi.bvh`.
- Verification: `tools/get-bvh.ps1` records each SHA-256.

BVH supplies joint motion. The meshes, MSX program and converters were created here.

The official article describes an open-source project providing motion/sample code for officially recognized fan derivatives. This demo follows that fan-creation purpose. Builds validate BVH placed in `assets/` and put converted motion into ROMs; they do not automatically download from a redistribution repository. The official project provided BVH and MP3; only BVH is used here, and MP3 is neither used nor distributed. Primary-source attribution does not mean existing inputs were downloaded again from the official website.

Raw BVH is excluded from Git. ROMs with converted data are under `dist/`. The official article is the use reference; it is not presented as a specific SPDX license, a blanket permission list, unrestricted commercial asset-library redistribution. The official motion-data use basis is separate from the machine XML notices.

## V9968 / geo3d / openMSX

- [V9968 + geo3d](https://github.com/alexmoncks/V9968_Cartridge/tree/main/geo3d)
- [Original V9968](https://github.com/hra1129/V9968_Cartridge)
- [openMSX](https://github.com/openMSX/openMSX)
- [ASCII-X mapper](https://www.grauw.nl/projects/ascii-x/)
- [z88dk](https://github.com/z88dk/z88dk)
- [C-BIOS](https://cbios.sourceforge.net/)

Machine definitions were copied from the local validation environment. openMSX/definitions retain GPL; C-BIOS retains its distribution license. Local emulator/BIOS copies are excluded from Git, and FS-A1GT BIOS is not distributed here.

`tools/machines/MOTIONGT.xml` and `MOTIONCB.xml` derive from GPL-2.0 openMSX definitions and select V9968. See `licenses/GPL-2.0.txt`. BIOS/emulator binaries are not distributed. The GPL-2.0 notice applies only to these two XML configuration files, not the application code or BVH motion data.