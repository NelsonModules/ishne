%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function text = info(file)
  % ishne.info(FILE) prints a short human-readable summary of an ISHNE file: its
  % rate, lead names and resolutions, and the recording's metadata. TEXT =
  % ishne.info(FILE) returns that summary as text instead of printing it.
  %
  % See also ishne.header, ishne.read.
  narginchk(1, 1);
  nargoutchk(0, 1);
  r = ishne.header(file);
  lines = {};
  lines{end + 1} = sprintf('ISHNE recording %s', r.header.id);
  lines{end + 1} = sprintf('  rate       : %g Hz', r.samplingRate);
  lines{end + 1} = sprintf('  leads      : %d', r.leadCount);
  for k = 1:r.leadCount
    lines{end + 1} = sprintf('    %2d %-8s %g nV/LSB', k, r.leadNames{k}, ...
    r.resolution(k));
  end
  if any(r.header.startTime ~= 0)
    t = r.header.startTime;
    lines{end + 1} = sprintf('  start time : %02d.%02d.%02d', t(1), t(2), t(3));
  end
  if any(r.header.recordDate ~= 0)
    d = r.header.recordDate;
    lines{end + 1} = sprintf('  record date: %02d/%02d/%04d', d(1), d(2), d(3));
  end
  if ~isempty(r.header.recorder)
    lines{end + 1} = sprintf('  recorder   : %s', r.header.recorder);
  end
  if ~isempty(r.variableText)
    lines{end + 1} = sprintf('  notes      : %s', r.variableText);
  end
  joined = '';
  for k = 1:numel(lines)
    if k == 1
      joined = lines{k};
    else
      joined = [joined, char(10), lines{k}];
    end
  end
  if nargout == 0
    disp(joined);
  else
    text = joined;
  end
end
%=============================================================================
