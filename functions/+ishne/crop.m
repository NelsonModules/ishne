%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function r = crop(r, window, varargin)
  % R = ishne.crop(R, [T0 T1]) keeps only the window from T0 to T1 seconds of
  % the struct R from ishne.read: every lead is cut to that span. All leads of
  % an ISHNE file share one rate, so the cut is the same instant on every lead.
  %
  % R = ishne.crop(R, [I J], 'Samples', true) takes the window as sample indices
  % (one based, inclusive) instead of seconds.
  %
  % See also ishne.read, ishne.select.
  narginchk(2, inf);
  nargoutchk(0, 1);
  if ~isstruct(r) || ~isfield(r, 'samples')
    error('ishne:badStruct', 'The first argument must be a struct from ishne.read.');
  end
  if numel(window) ~= 2 || ~(window(2) > window(1))
    error('ishne:badWindow', 'The window must be two values with the second greater than the first.');
  end
  bySamples = ishneBySamples(varargin);
  if bySamples
    first = max(1, round(window(1)));
    last = round(window(2));
  else
    first = floor(window(1) * r.samplingRate) + 1;
    last = floor(window(2) * r.samplingRate);
  end
  first = max(1, first);
  last = min(last, size(r.samples, 1));
  if last < first
    r.samples = zeros(0, size(r.samples, 2));
  else
    r.samples = r.samples(first:last, :);
  end
end
%=============================================================================
function bySamples = ishneBySamples(args)
  bySamples = false;
  if mod(numel(args), 2) ~= 0
    error('ishne:badOptions', 'Options come in name-value pairs.');
  end
  for k = 1:2:numel(args)
    name = args{k};
    if ~ischar(name) && ~isStringScalar(name)
      error('ishne:badOptionName', 'An option name must be text.');
    end
    if strcmpi(char(name), 'samples')
      bySamples = logical(args{k + 1});
    else
      error('ishne:unknownOption', 'Unknown option %s.', char(name));
    end
  end
end
%=============================================================================
