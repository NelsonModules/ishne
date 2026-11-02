%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function bytes = tobytes(r)
  % BYTES = ishne.tobytes(R) serialises the neutral struct R into the bytes of a
  % valid ISHNE file without writing to disk, for a caller that will send the
  % recording over a stream or keep it in a blob. It is the inverse of
  % ishne.frombytes.
  %
  % See also ishne.write, ishne.frombytes.
  narginchk(1, 1);
  nargoutchk(0, 1);
  bytes = ishneSerialize(r);
end
%=============================================================================
