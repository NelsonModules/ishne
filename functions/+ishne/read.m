%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function r = read(varargin)
  % R = ishne.read(FILE) reads an ISHNE 1.0 Holter file into the neutral struct
  % this module returns. The whole file is read in one pass and every field cut
  % from its bytes: a misread of the little-endian samples or the per-lead
  % resolution gives a signal that looks plausible and is wrong, so the format
  % is read in one place, here.
  %
  % R = ishne.read(FILE, 'Physical', true) returns the samples in millivolts,
  % raw * resolution / 1e6, the resolution being the nanovolts per least
  % significant bit each lead stores. By default R.samples holds the raw signed
  % sixteen bit integers the file carries, so a read followed by ishne.write is
  % lossless and the resolution is on R to scale with.
  %
  % R = ishne.read(FILE, 'Leads', WHICH) keeps only some leads, by name (a char
  % or cellstr) or by index, in the order asked.
  %
  % R = ishne.read(FILE, 'Data', false) reads the header only and returns no
  % samples; ishne.header is the shorthand.
  %
  % R has fields: kind, path, samples (N x L), leadCount, leadCodes, leadNames,
  % resolution, leadQuality, samplingRate, version, sampleCount, checksum,
  % header (firstName, lastName, id, sex, race, birthDate, recordDate, fileDate,
  % startTime, pacemaker, recorder), variableBlock and variableText.
  %
  % See also ishne.write, ishne.header, ishne.frombytes.
  narginchk(1, inf);
  nargoutchk(0, 1);
  file = varargin{1};
  if ~ischar(file) && ~isStringScalar(file)
    error('ishne:badName', 'The file name must be text.');
  end
  file = char(file);
  opts = ishneReadOptions(varargin(2:end));
  if ~isfile(file)
    error('ishne:noSuchFile', 'The file %s is not on disk.', file);
  end
  fid = fopen(file, 'rb');
  if fid < 0
    error('ishne:cannotRead', 'The file %s cannot be read.', file);
  end
  bytes = fread(fid, inf, 'uint8');
  fclose(fid);
  r = ishneParse(bytes, opts.data);
  r.path = file;
  if ~isempty(opts.leads)
    r = ishne.select(r, opts.leads);
  end
  if opts.physical
    r.samples = ishneToPhysical(r.samples, r.resolution);
  end
end
%=============================================================================
function opts = ishneReadOptions(args)
  opts = struct('physical', false, 'leads', [], 'data', true);
  if mod(numel(args), 2) ~= 0
    error('ishne:badOptions', 'Options come in name-value pairs.');
  end
  for k = 1:2:numel(args)
    name = args{k};
    if ~ischar(name) && ~isStringScalar(name)
      error('ishne:badOptionName', 'An option name must be text.');
    end
    switch lower(char(name))
      case 'physical'
        opts.physical = logical(args{k + 1});
      case 'leads'
        opts.leads = args{k + 1};
      case 'data'
        opts.data = logical(args{k + 1});
      otherwise
        error('ishne:unknownOption', 'Unknown option %s.', char(name));
    end
  end
end
%=============================================================================
function physical = ishneToPhysical(samples, resolution)
  % Millivolts from the raw integers: each lead's resolution is its nanovolts
  % per step, so the physical value is raw times resolution over a million. A
  % stored resolution of zero is the file forgetting the field; one microvolt
  % per step is the standard default, used rather than scaling by zero.
  physical = zeros(size(samples));
  for k = 1:size(samples, 2)
    res = resolution(k);
    if res == 0
      res = 1000;
    end
    physical(:, k) = samples(:, k) * res / 1e6;
  end
end
%=============================================================================
