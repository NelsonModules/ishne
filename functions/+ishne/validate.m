%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function report = validate(file)
  % REPORT = ishne.validate(FILE) checks an ISHNE file for the faults a reader
  % cannot otherwise see: a missing magic, a file too short for its header, a
  % lead count out of range, and a header whose stored CRC does not match the
  % one computed over it. The CRC is the format's own guard against a header
  % corrupted on disk; this is the one place it is verified.
  %
  % REPORT has fields ok (true when nothing is wrong) and issues (a cellstr of
  % what is). A stored checksum of zero is read as "none computed" and is not
  % held against the file.
  %
  % See also ishne.read, ishne.header.
  narginchk(1, 1);
  nargoutchk(0, 1);
  if ~ischar(file) && ~isStringScalar(file)
    error('ishne:badName', 'The file name must be text.');
  end
  file = char(file);
  issues = {};
  if ~isfile(file)
    report = struct('ok', false, 'issues', {{sprintf('The file %s is not on disk.', file)}});
    return;
  end
  fid = fopen(file, 'rb');
  bytes = double(fread(fid, inf, 'uint8'))';
  fclose(fid);
  if numel(bytes) < 522 || ~strcmp(char(bytes(1:min(8, numel(bytes)))), 'ISHNE1.0')
    report = struct('ok', false, 'issues', {{'The file is not an ISHNE recording or is too short.'}});
    return;
  end
  stored = bytes(9) + 256 * bytes(10);
  if stored ~= 0
    actual = ishneCrc(bytes(11:522));
    if actual ~= stored
      issues{end + 1} = sprintf('The header checksum is %d but the file stores %d.', actual, stored);
    end
  end
  try
    r = ishneParse(bytes, false);
    if r.leadCount < 1 || r.leadCount > 12
      issues{end + 1} = sprintf('The lead count %d is out of range.', r.leadCount);
    end
  catch reason
    issues{end + 1} = reason.message;
  end
  report = struct('ok', isempty(issues), 'issues', {issues});
end
%=============================================================================
