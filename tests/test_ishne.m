%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
% This module is external and test_run gives every test its own process, so
% each test loads the module it is testing rather than inheriting it.
if ~ismodule('ishne')
  run([fileparts(nfilename('fullpath')), '/../loader.m']);
end
%=============================================================================
assert_isequal(ishne_version(), '1.0.0');
%=============================================================================
