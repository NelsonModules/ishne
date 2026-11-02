%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function tf = isishne(file)
  % TF = ishne.isishne(FILE) is true when FILE begins with the ISHNE1.0 magic
  % and is long enough to hold the fixed header. It reads only the first bytes,
  % so it is cheap to ask before trying to read a file of an unknown kind.
  %
  % See also ishne.read, ishne.header.
  narginchk(1, 1);
  nargoutchk(0, 1);
  tf = false;
  if ~ischar(file) && ~isStringScalar(file)
    return;
  end
  file = char(file);
  if ~isfile(file)
    return;
  end
  fid = fopen(file, 'rb');
  if fid < 0
    return;
  end
  magic = fread(fid, 8, 'uint8');
  fclose(fid);
  tf = numel(magic) == 8 && strcmp(char(reshape(magic, 1, [])), 'ISHNE1.0');
end
%=============================================================================
