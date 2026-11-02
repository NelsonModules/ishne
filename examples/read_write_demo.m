%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
% A tour of the ishne toolbox: build a tiny two-lead Holter record, write it,
% read it back and confirm the round trip, then look at the header, validate the
% CRC, cut the record down, and pass it through an in-memory byte vector.
%=============================================================================
if ~ismodule('ishne')
  run([fileparts(nfilename('fullpath')), '/../loader.m']);
end
%=============================================================================
% Five seconds of two leads, in physical millivolts.
rate = 200;
t = (0:5 * rate - 1)' / rate;
samples = [sin(2 * pi * 1.2 * t), 0.5 * cos(2 * pi * 1.2 * t)];

% Write to a scratch file in the temporary folder. The matrix is physical
% millivolts; the resolution is one microvolt (1000 nanovolts) per step.
file = [tempname(), '.ecg'];
info = ishne.write(file, samples, rate, 'Leads', {'I', 'II'}, ...
  'Resolution', 1000, 'Physical', true);
fprintf('Wrote %d lead(s), %d samples at %g Hz.\n', ...
  info.leads, info.samples, info.rate);

% A quick look at the header, without reading the samples.
disp('--- ishne.info ---');
ishne.info(file);

% Read it back in physical units and check it matches what went in.
r = ishne.read(file, 'Physical', true);
err = max(abs(r.samples(:) - samples(:)));
fprintf('\nRead %d lead(s) at %g Hz; max round-trip error %.2e mV.\n', ...
  r.leadCount, r.samplingRate, err);

% The fixed header carries a CRC-CCITT checksum; validate verifies it.
report = ishne.validate(file);
fprintf('Validate ok: %d (%d issue(s)).\n', report.ok, numel(report.issues));

% Keep only the first lead and the first two seconds.
clip = ishne.crop(ishne.select(r, {'I'}), [0, 2]);
fprintf('Cropped to lead %s, %d samples.\n', clip.leadNames{1}, ...
  size(clip.samples, 1));

% The same record goes to and from an in-memory byte vector with no file.
bytes = ishne.tobytes(ishne.read(file));
same = ishne.frombytes(bytes);
fprintf('In-memory round trip: %d lead(s), %d bytes.\n', ...
  same.leadCount, numel(bytes));

% Clean up the scratch file.
rmfile(file);
%=============================================================================
