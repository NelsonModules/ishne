%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function r = header(file)
  % R = ishne.header(FILE) reads only the header of an ISHNE file: the same
  % neutral struct ishne.read returns, but with no samples, so the leads, their
  % resolutions and the recording's metadata can be inspected cheaply.
  %
  % See also ishne.read, ishne.info.
  narginchk(1, 1);
  nargoutchk(0, 1);
  r = ishne.read(file, 'Data', false);
end
%=============================================================================
