%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function info = write(varargin)
  % ishne.write(FILE, R) writes an ISHNE 1.0 Holter file from the neutral struct
  % R that ishne.read returns (or one built by hand). What ishne.read reads back
  % equals what went in; with raw integer samples (the default) it is exact to
  % the bit, checksum included.
  %
  % ishne.write(FILE, SAMPLES, RATE) writes a plain matrix, one column per lead,
  % at RATE hertz. Pass 'Leads' to name the leads, 'Resolution' to set the
  % nanovolts per step, and 'Physical', true when SAMPLES is in millivolts (it
  % is then quantised with the resolution); by default SAMPLES is taken as the
  % raw integers the file stores.
  %
  % INFO returns leads, samples, rate and the file written.
  %
  % See also ishne.read, ishne.tobytes.
  narginchk(2, inf);
  nargoutchk(0, 1);
  file = varargin{1};
  if ~ischar(file) && ~isStringScalar(file)
    error('ishne:badName', 'The file name must be text.');
  end
  file = char(file);
  second = varargin{2};
  if isstruct(second)
    r = second;
  elseif isnumeric(second)
    narginchk(3, inf);
    r = ishneBuild(second, varargin{3}, varargin(4:end));
  else
    error('ishne:badRecord', 'The second argument must be a struct from ishne.read or a numeric matrix.');
  end
  bytes = ishneSerialize(r);
  fid = fopen(file, 'wb');
  if fid < 0
    error('ishne:cannotWrite', 'The file %s cannot be written.', file);
  end
  written = fwrite(fid, bytes, 'uint8');
  fclose(fid);
  if written ~= numel(bytes)
    error('ishne:shortWrite', 'The file %s was not fully written.', file);
  end
  info = struct('leads', size(r.samples, 2), 'samples', size(r.samples, 1), ...
  'rate', ishneRate(r), 'file', file);
end
%=============================================================================
function r = ishneBuild(samples, rate, args)
  opts = struct('leads', [], 'resolution', 1000, 'physical', false);
  if mod(numel(args), 2) ~= 0
    error('ishne:badOptions', 'Options come in name-value pairs.');
  end
  for k = 1:2:numel(args)
    name = args{k};
    if ~ischar(name) && ~isStringScalar(name)
      error('ishne:badOptionName', 'An option name must be text.');
    end
    switch lower(char(name))
      case 'leads'
        opts.leads = args{k + 1};
      case 'resolution'
        opts.resolution = args{k + 1};
      case 'physical'
        opts.physical = logical(args{k + 1});
      otherwise
        error('ishne:unknownOption', 'Unknown option %s.', char(name));
    end
  end
  if ~isscalar(rate) || ~(rate > 0)
    error('ishne:badRateArg', 'The rate must be one positive number of hertz.');
  end
  count = size(samples, 2);
  resolution = opts.resolution;
  if isscalar(resolution)
    resolution = resolution * ones(1, count);
  end
  if numel(resolution) ~= count
    error('ishne:badResolution', 'Resolution must be one value per lead (%d expected).', count);
  end
  if opts.physical
    % Millivolts in: quantise to the raw integer the file holds, raw =
    % round(mV * 1e6 / resolution).
    raw = zeros(size(samples));
    for k = 1:count
      res = resolution(k);
      if res == 0
        res = 1000;
      end
      raw(:, k) = round(samples(:, k) * 1e6 / res);
    end
    samples = raw;
  end
  leadNames = cell(1, count);
  for k = 1:count
    leadNames{k} = sprintf('lead%d', k);
  end
  if ~isempty(opts.leads)
    leads = opts.leads;
    if ischar(leads) || isStringScalar(leads)
      leads = cellstr(leads);
    end
    if numel(leads) ~= count
      error('ishne:badLeads', 'Leads must be one name per lead (%d expected).', count);
    end
    for k = 1:count
      leadNames{k} = char(leads{k});
    end
  end
  codes = zeros(1, count);
  for k = 1:count
    codes(k) = ishneLeadTable(leadNames{k});
  end
  r = struct();
  r.kind = 'ishne.record';
  r.samples = samples;
  r.leadCount = count;
  r.leadCodes = codes;
  r.leadNames = {leadNames{:}};
  r.resolution = resolution;
  r.leadQuality = zeros(1, count);
  r.samplingRate = rate;
  r.version = 10;
  r.header = struct('firstName', '', 'lastName', '', 'id', '', 'sex', 0, ...
  'race', 0, 'birthDate', [0 0 0], 'recordDate', [0 0 0], ...
  'fileDate', [0 0 0], 'startTime', [0 0 0], 'pacemaker', 0, 'recorder', '');
  r.variableBlock = zeros(1, 0);
  r.variableText = '';
end
%=============================================================================
function rate = ishneRate(r)
  rate = 0;
  if isfield(r, 'samplingRate')
    rate = r.samplingRate;
  end
end
%=============================================================================
