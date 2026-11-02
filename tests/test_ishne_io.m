%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
if ~ismodule('ishne')
  run([fileparts(nfilename('fullpath')), '/../loader.m']);
end
% The writer is proved by the reader: a record of known integers, including the
% extremes of the signed sixteen bit range, is written and read back unchanged.
% Every file here is written by the test, so nothing reaches the network.
%=============================================================================
folder = strrep(tempname(), char(92), '/');
mkdir(folder);
%=============================================================================
n = 500;
d1 = round(1000 * sin(2 * pi * (0:n - 1)' / 50));
d2 = round(500 * cos(2 * pi * (0:n - 1)' / 30));
d1(1) = -32768;
d1(2) = 32767;
d1(3) = 0;
samples = [d1, d2];
%=============================================================================
% A plain matrix written with lead names and per-lead resolution.
f = [folder, '/h.ecg'];
ishne.write(f, samples, 250, 'Leads', {'II', 'V5'}, 'Resolution', [1000, 2000]);
b = ishne.read(f);
assert_isequal(b.samples, samples);
assert_isequal(b.leadNames, {'II', 'V5'});
assert_isequal(b.leadCodes, [6, 15]);
assert_isequal(b.samplingRate, 250);
assert_isequal(b.resolution, [1000, 2000]);
assert_isequal(b.leadCount, 2);
%=============================================================================
% The checksum the writer stored matches the one computed over the header.
report = ishne.validate(f);
assert_istrue(report.ok);
%=============================================================================
% Physical samples: millivolts out are raw times resolution over a million.
bp = ishne.read(f, 'Physical', true);
assert_isequal(bp.samples(:, 1), samples(:, 1) * 1000 / 1e6);
assert_isequal(bp.samples(:, 2), samples(:, 2) * 2000 / 1e6);
%=============================================================================
% Writing millivolts quantises them back to the raw integers.
mv = samples;
mv = [samples(:, 1) * 1000 / 1e6, samples(:, 2) * 2000 / 1e6];
ishne.write([folder, '/phys.ecg'], mv, 250, 'Resolution', [1000, 2000], ...
  'Physical', true);
bphys = ishne.read([folder, '/phys.ecg']);
assert_isequal(bphys.samples, samples);
%=============================================================================
% isishne, header, select, crop.
assert_istrue(ishne.isishne(f));
assert_isfalse(ishne.isishne([folder, '/none.ecg']));
h = ishne.header(f);
assert_isequal(h.leadCount, 2);
assert_isequal(size(h.samples, 1), 0);
s1 = ishne.select(b, {'V5'});
assert_isequal(s1.leadCount, 1);
assert_isequal(s1.leadNames{1}, 'V5');
assert_isequal(s1.samples, d2);
c1 = ishne.crop(b, [0, 1]);
assert_isequal(size(c1.samples, 1), 250);
assert_isequal(c1.samples(:, 1), d1(1:250));
%=============================================================================
% frombytes and tobytes round-trip in memory, and a struct write is lossless.
raw = ishne.tobytes(b);
b2 = ishne.frombytes(raw);
assert_isequal(b2.samples, samples);
ishne.write([folder, '/h2.ecg'], b);
b3 = ishne.read([folder, '/h2.ecg']);
assert_isequal(b3.samples, samples);
assert_isequal(b3.checksum, b.checksum);
%=============================================================================
% Errors: a missing file, and a file that is not ISHNE. Checked by the error
% identifier, not the message, so the test holds whatever language the runtime
% translates the message into.
failed = false;
try
  ishne.read([folder, '/nope.ecg']);
catch e
  failed = strcmp(e.identifier, 'ishne:noSuchFile');
end
assert_istrue(failed);
% A file long enough to pass the length check but without the magic, so the
% magic check is what refuses it.
notIshne = [folder, '/not.ecg'];
fid = fopen(notIshne, 'wb');
fwrite(fid, uint8(repmat('x', 1, 600)), 'uint8');
fclose(fid);
failed = false;
try
  ishne.read(notIshne);
catch e
  failed = strcmp(e.identifier, 'ishne:badMagic');
end
assert_istrue(failed);
%=============================================================================
rmdir(folder, 's');
%=============================================================================
