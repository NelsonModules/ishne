# ishne

An ISHNE Holter ECG toolbox for [Nelson](https://nelson-lang.github.io/nelson-website/).

ISHNE 1.0 is the binary interchange format for long-term (Holter) 

It is designed to be a dependency of higher-level toolboxes (such as `ecglab`) rather than to interpret the signals itself.

## Load

```matlab
run('/path/to/ishne/loader.m')
```

## Functions

All functions live in the `ishne` package (call them as `ishne.read`, `ishne.write`, ...).

| Function | Purpose |
|---|---|
| `ishne.read(file, ...)` | Read a file into the neutral struct. Options: `'Physical'`, `'Leads'`, `'Data'`. |
| `ishne.write(file, r, ...)` / `ishne.write(file, samples, rate, ...)` | Write the neutral struct, or a plain matrix. Options: `'Leads'`, `'Resolution'`, `'Physical'`. |
| `ishne.header(file)` | Read only the header, no samples, fast. |
| `ishne.info(file)` | A compact human-readable summary (header only). |
| `ishne.isishne(file)` | Probe a file for the `ISHNE1.0` magic, never throws. |
| `ishne.validate(file)` | Check the magic, the length, the lead count and the header CRC. |
| `ishne.select(r, which)` | Keep a subset of leads, by name or index, in the order asked. |
| `ishne.crop(r, [t0 t1], ...)` | Keep a time (or `'Samples'`) window of every lead. |
| `ishne.frombytes(bytes)` | Parse a recording already in memory. |
| `ishne.tobytes(r)` | Serialise a recording to a byte vector, the inverse of `frombytes`. |

`ishne.read` options: `'Physical', true` returns the samples in millivolts
(`raw * resolution / 1e6`, the resolution being the nanovolts per step each lead
stores) instead of the raw signed sixteen-bit integers the file holds (raw is
the default, so a read followed by `ishne.write` is lossless, checksum included,
with the resolution on the struct to scale with); `'Leads', which` keeps a
subset by name or index; and `'Data', false` reads the header only.

The samples are raw `int16` with a per-lead resolution in nanovolts per least
significant bit, so physical millivolts are one scaling away. The fixed header
carries a CRC-CCITT checksum that `ishne.validate` verifies. The module both
reads and writes the signal file; ISHNE annotation files are not supported.

## The neutral struct

`ishne.read` returns one struct with no domain assumptions:

```
r.kind          % 'ishne.record'
r.path
r.samples       % N x L, one column per lead (raw int16, or millivolts)
r.leadCount, r.leadCodes, r.leadNames
r.resolution    % nanovolts per least significant bit, one per lead
r.leadQuality
r.samplingRate  % Hz
r.version, r.sampleCount, r.checksum
r.header        % .firstName .lastName .id .sex .race .birthDate
                % .recordDate .fileDate .startTime .pacemaker .recorder
r.variableBlock, r.variableText
```

`ishne.write` accepts the same shape, or a plain matrix (one column per lead)
with a rate; the lead names and resolution are used when present and defaulted
when not.

## Example

A ready-to-run tour is in [`examples/read_write_demo.m`](examples/read_write_demo.m).

```matlab
% Round-trip a two-lead Holter record and read it back in physical units.
rate = 200;
t = (0:5 * rate - 1)' / rate;
file = [tempname(), '.ecg'];
ishne.write(file, [sin(2*pi*1.2*t), 0.5*cos(2*pi*1.2*t)], rate, ...
  'Leads', {'I', 'II'}, 'Resolution', 1000, 'Physical', true);
r = ishne.read(file, 'Physical', true);
```

## Dependencies

This module depends on no other Nelson module.

## License

LGPL-3.0-or-later.
