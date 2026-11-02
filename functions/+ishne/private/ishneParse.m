%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function r = ishneParse(bytes, wantData)
  % Parse the bytes of an ISHNE 1.0 Holter file into the neutral struct this
  % module returns. The file is a magic of eight bytes, a two byte checksum, a
  % fixed header of five hundred and twelve bytes, a variable-length text block,
  % then the samples as signed sixteen bit integers interleaved by lead, least
  % significant byte first throughout. Every field is cut from the byte vector
  % by its offset, so the file is touched once and nothing is read twice.
  if nargin < 2
    wantData = true;
  end
  bytes = double(reshape(bytes, 1, numel(bytes)));
  if numel(bytes) < 522
    error('ishne:tooShort', 'The file is too short to be an ISHNE recording.');
  end
  if ~strcmp(char(bytes(1:8)), 'ISHNE1.0')
    error('ishne:badMagic', 'The file is not an ISHNE recording; the magic ISHNE1.0 is missing.');
  end
  r = struct();
  r.kind = 'ishne.record';
  r.checksum = ishneInt16(bytes, 8, 1);
  if r.checksum < 0
    r.checksum = r.checksum + 65536;
  end
  r.variableSize = ishneInt32(bytes, 10);
  r.sampleCount = ishneInt32(bytes, 14);
  variableOffset = ishneInt32(bytes, 18);
  ecgOffset = ishneInt32(bytes, 22);
  r.version = ishneInt16(bytes, 26, 1);
  header = struct();
  header.firstName = ishneText(bytes, 28, 40);
  header.lastName = ishneText(bytes, 68, 40);
  header.id = ishneText(bytes, 108, 20);
  header.sex = ishneInt16(bytes, 128, 1);
  header.race = ishneInt16(bytes, 130, 1);
  header.birthDate = ishneInt16(bytes, 132, 3);
  header.recordDate = ishneInt16(bytes, 138, 3);
  header.fileDate = ishneInt16(bytes, 144, 3);
  header.startTime = ishneInt16(bytes, 150, 3);
  header.pacemaker = ishneInt16(bytes, 230, 1);
  header.recorder = ishneText(bytes, 232, 40);
  r.header = header;
  leadCount = ishneInt16(bytes, 156, 1);
  if leadCount < 1 || leadCount > 12
    error('ishne:badLeadCount', 'The header names %d leads; one to twelve are allowed.', leadCount);
  end
  r.leadCount = leadCount;
  spec = ishneInt16(bytes, 158, 12);
  quality = ishneInt16(bytes, 182, 12);
  resolution = ishneInt16(bytes, 206, 12);
  r.leadCodes = spec(1:leadCount);
  r.leadQuality = quality(1:leadCount);
  r.resolution = resolution(1:leadCount);
  r.leadNames = cell(1, leadCount);
  for k = 1:leadCount
    name = ishneLeadTable(r.leadCodes(k));
    if isempty(name)
      name = sprintf('lead%d', k);
    end
    r.leadNames{k} = name;
  end
  rate = ishneInt16(bytes, 272, 1);
  if ~(rate > 0)
    error('ishne:badRate', 'The header does not carry a positive sampling rate.');
  end
  r.samplingRate = rate;
  % The variable text block sits between the header and the samples. Its raw
  % bytes are kept so a round trip is lossless; the printable, trimmed view is
  % the convenience a reader usually wants.
  vStart = variableOffset;
  if vStart < 522
    vStart = 522;
  end
  r.variableBlock = zeros(1, 0);
  if r.variableSize > 0 && vStart + r.variableSize <= numel(bytes)
    r.variableBlock = bytes(vStart + 1:vStart + r.variableSize);
  end
  r.variableText = ishneClean(r.variableBlock);
  if ~wantData
    r.samples = zeros(0, leadCount);
    return;
  end
  start = ecgOffset;
  if start < 522 || start > numel(bytes)
    start = 522 + r.variableSize;
  end
  tail = bytes(start + 1:end);
  whole = floor(numel(tail) / 2);
  low = tail(1:2:2 * whole);
  high = tail(2:2:2 * whole);
  words = low + 256 * high;
  words(words > 32767) = words(words > 32767) - 65536;
  instants = floor(numel(words) / leadCount);
  r.samples = reshape(words(1:instants * leadCount), leadCount, instants).';
end
%=============================================================================
function value = ishneInt32(bytes, off)
  b = bytes(off + 1:off + 4);
  value = b(1) + 256 * b(2) + 65536 * b(3) + 16777216 * b(4);
  if value >= 2147483648
    value = value - 4294967296;
  end
end
%=============================================================================
function values = ishneInt16(bytes, off, count)
  values = zeros(1, count);
  for k = 1:count
    low = bytes(off + 2 * (k - 1) + 1);
    high = bytes(off + 2 * (k - 1) + 2);
    v = low + 256 * high;
    if v > 32767
      v = v - 65536;
    end
    values(k) = v;
  end
end
%=============================================================================
function text = ishneText(bytes, off, width)
  piece = bytes(off + 1:off + width);
  text = ishneClean(piece);
end
%=============================================================================
function text = ishneClean(piece)
  % Keep the printable ASCII bytes and trim the ends; a name field is padded
  % with nulls or spaces and a reader wants the text, not the padding.
  piece = piece(piece >= 32 & piece <= 126);
  text = strtrim(char(reshape(piece, 1, [])));
end
%=============================================================================
