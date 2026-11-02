%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function out = ishneLeadTable(in)
  % The ISHNE lead-specification codes and their names, read both ways. A
  % numeric IN is a code and OUT is its name; a text IN is a name and OUT is its
  % code. One table used for reading and writing keeps a lead's name and code in
  % step, so a file written here reads back with the lead it went in as.
  %
  % Code 0 is unknown, 1 generic bipolar, 2..4 the X Y Z of a Frank lead system,
  % 5..16 the standard twelve, 17..19 the oesophageal and intracardiac leads a
  % Holter recorder may carry. A name the table does not know is written as the
  % unknown code 0 rather than guessed into a limb position.
  names = {'unknown', 'generic', 'X', 'Y', 'Z', 'I', 'II', 'III', 'aVR', ...
  'aVL', 'aVF', 'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'ES', 'AS', 'AI'};
  if isnumeric(in)
    code = round(in);
    if code >= 0 && code <= 19
      out = names{code + 1};
    else
      out = '';
    end
    return;
  end
  name = strtrim(char(in));
  out = 0;
  for k = 1:numel(names)
    if strcmpi(name, names{k})
      out = k - 1;
      return;
    end
  end
end
%=============================================================================
