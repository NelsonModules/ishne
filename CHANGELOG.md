# Changelog

All notable changes to the `ishne` module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-02

### Added

- Initial release: read and write ISHNE 1.0 Holter ECG files.
- `ishne.read` reads the header and the samples into one domain-free struct, in
  raw signed sixteen-bit integers or in physical millivolts scaled by each
  lead's nanovolt-per-step resolution.
- `ishne.write` writes a struct from `ishne.read` or a plain matrix; a raw read
  followed by a write is lossless to the bit, header CRC included.
- `ishne.header` and `ishne.info` inspect a file without reading the samples;
  `ishne.isishne` probes the `ISHNE1.0` magic without throwing.
- `ishne.validate` checks the magic, the file length, the lead count and the
  CRC-CCITT header checksum.
- `ishne.select` keeps a subset of leads; `ishne.crop` keeps a time or sample
  window.
- `ishne.frombytes` and `ishne.tobytes` read and write a recording in memory,
  with no file on disk.
- ISHNE annotation files are not supported.
