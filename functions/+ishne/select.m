%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function r = select(r, which)
  % R = ishne.select(R, WHICH) keeps only some leads of the struct R from
  % ishne.read, by name (a char or cellstr) or by index, in the order asked. The
  % samples columns and every per-lead field (codes, names, resolution, quality)
  % are narrowed together, so the record stays consistent.
  %
  % See also ishne.read, ishne.crop.
  narginchk(2, 2);
  nargoutchk(0, 1);
  if ~isstruct(r) || ~isfield(r, 'samples')
    error('ishne:badStruct', 'The first argument must be a struct from ishne.read.');
  end
  names = r.leadNames;
  if isnumeric(which)
    keep = round(which(:)');
    if any(keep < 1) || any(keep > numel(names))
      error('ishne:badLeadIndex', 'A lead index is outside the range 1 to %d.', numel(names));
    end
  else
    if ischar(which) || isStringScalar(which)
      which = cellstr(which);
    end
    keep = zeros(1, numel(which));
    for index = 1:numel(which)
      match = find(strcmpi(char(which{index}), names), 1);
      if isempty(match)
        error('ishne:noSuchLead', 'No lead is named %s.', char(which{index}));
      end
      keep(index) = match;
    end
  end
  if ~isempty(r.samples)
    r.samples = r.samples(:, keep);
  end
  r.leadCodes = r.leadCodes(keep);
  r.leadNames = r.leadNames(keep);
  r.resolution = r.resolution(keep);
  r.leadQuality = r.leadQuality(keep);
  r.leadCount = numel(keep);
end
%=============================================================================
