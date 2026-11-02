%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function crc = ishneCrc(bytes)
  % The sixteen bit CRC an ISHNE file stores ahead of its header, computed over
  % the 512-byte fixed header: CRC-CCITT, polynomial 0x1021, initial value
  % 0xFFFF, most significant bit first, no final reflection. This is the guard
  % the format carries against a header corrupted on disk; the reader stores
  % whatever value the file holds and the writer recomputes it, so a file
  % written here carries a checksum that matches its own header.
  %
  % The loop is over the 512 header bytes, not over samples, so it is cheap; the
  % inner eight-bit step is unrolled with a table built once.
  persistent table;
  if isempty(table)
    table = zeros(1, 256);
    for value = 0:255
      crc16 = value * 256;
      for bit = 1:8
        if crc16 >= 32768
          crc16 = mod(crc16 * 2, 65536);
          crc16 = bitxor(crc16, 4129);
        else
          crc16 = mod(crc16 * 2, 65536);
        end
      end
      table(value + 1) = crc16;
    end
  end
  crc = 65535;
  bytes = double(bytes(:)');
  for k = 1:numel(bytes)
    index = bitxor(floor(crc / 256), mod(bytes(k), 256));
    crc = bitxor(mod(crc * 256, 65536), table(index + 1));
  end
end
%=============================================================================
