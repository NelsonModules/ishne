%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function r = frombytes(bytes)
  % R = ishne.frombytes(BYTES) parses an ISHNE recording already in memory, the
  % same neutral struct ishne.read returns, for a file fetched over a stream or
  % held in a blob rather than sitting on disk. BYTES is a numeric vector of the
  % file's bytes.
  %
  % See also ishne.read, ishne.tobytes.
  narginchk(1, 1);
  nargoutchk(0, 1);
  if ~isnumeric(bytes)
    error('ishne:badBytes', 'BYTES must be a numeric vector of the file bytes.');
  end
  r = ishneParse(bytes, true);
  r.path = '';
end
%=============================================================================
