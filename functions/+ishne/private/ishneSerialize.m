%=============================================================================
% Copyright (c) 2026-present Allan CORNET (Nelson)
%=============================================================================
% This file is part of the ishne module for Nelson.
%=============================================================================
% LICENCE_BLOCK_BEGIN
% SPDX-License-Identifier: LGPL-3.0-or-later
% LICENCE_BLOCK_END
%=============================================================================
function bytes = ishneSerialize(r)
  % Turn the neutral struct into the bytes of a valid ISHNE 1.0 file, the exact
  % inverse of ishneParse: the magic, the CRC computed over the header, the
  % 512-byte header, the variable text block (padded to an even length so the
  % samples start on a two-byte boundary), then the samples interleaved by lead
  % as little-endian signed sixteen bit. The whole file is built in memory and
  % the caller writes it in one pass.
  if ~isstruct(r) || ~isfield(r, 'samples')
    error('ishne:badSerializeStruct', 'The record must be a struct with a samples field.');
  end
  samples = r.samples;
  n = size(samples, 1);
  leadCount = size(samples, 2);
  if leadCount < 1 || leadCount > 12
    error('ishne:badLeadCountRecord', 'A record has %d leads; one to twelve are allowed.', leadCount);
  end
  rate = ishneField(r, 'samplingRate', 0);
  if ~(rate > 0)
    error('ishne:badRateRecord', 'The record needs a positive sampling rate.');
  end
  resolution = ishneVector(r, 'resolution', leadCount, 1000);
  codes = ishneCodes(r, leadCount);
  quality = ishneVector(r, 'leadQuality', leadCount, 0);
  header = ishneField(r, 'header', struct());
  variable = ishneVariable(r);
  variableSize = numel(variable);
  paddedV = variableSize;
  if mod(paddedV, 2) == 1
    paddedV = paddedV + 1;
  end
  ecgOffset = 522 + paddedV;
  total = ecgOffset + 2 * n * leadCount;
  buf = zeros(1, total);
  buf(1:8) = double('ISHNE1.0');
  buf = ishnePutInt32(buf, 10, variableSize);
  buf = ishnePutInt32(buf, 14, n);
  buf = ishnePutInt32(buf, 18, 522);
  buf = ishnePutInt32(buf, 22, ecgOffset);
  buf = ishnePutInt16(buf, 26, ishneField(r, 'version', 10));
  buf = ishnePutText(buf, 28, 40, ishneHeaderText(header, 'firstName'));
  buf = ishnePutText(buf, 68, 40, ishneHeaderText(header, 'lastName'));
  buf = ishnePutText(buf, 108, 20, ishneHeaderText(header, 'id'));
  buf = ishnePutInt16(buf, 128, ishneHeaderNum(header, 'sex', 0));
  buf = ishnePutInt16(buf, 130, ishneHeaderNum(header, 'race', 0));
  buf = ishnePutInt16(buf, 132, ishneHeaderTriple(header, 'birthDate'));
  buf = ishnePutInt16(buf, 138, ishneHeaderTriple(header, 'recordDate'));
  buf = ishnePutInt16(buf, 144, ishneHeaderTriple(header, 'fileDate'));
  buf = ishnePutInt16(buf, 150, ishneHeaderTriple(header, 'startTime'));
  buf = ishnePutInt16(buf, 156, leadCount);
  buf = ishnePutInt16(buf, 158, ishnePad(codes, 12));
  buf = ishnePutInt16(buf, 182, ishnePad(quality, 12));
  buf = ishnePutInt16(buf, 206, ishnePad(resolution, 12));
  buf = ishnePutInt16(buf, 230, ishneHeaderNum(header, 'pacemaker', 0));
  buf = ishnePutText(buf, 232, 40, ishneHeaderText(header, 'recorder'));
  buf = ishnePutInt16(buf, 272, rate);
  % The variable block goes right after the header; any pad byte is a zero.
  if variableSize > 0
    buf(523:522 + variableSize) = mod(variable, 256);
  end
  % The samples, interleaved by lead, as little-endian signed sixteen bit.
  if n > 0
    flat = reshape(samples.', 1, []);
    word = mod(flat, 65536);
    ecg = zeros(1, 2 * numel(word));
    ecg(1:2:end) = mod(word, 256);
    ecg(2:2:end) = floor(word / 256);
    buf(ecgOffset + 1:ecgOffset + numel(ecg)) = ecg;
  end
  % The checksum guards the header, so it is computed last, over the 512 header
  % bytes (file offsets 10 to 521), and written into the two bytes before them.
  crc = ishneCrc(buf(11:522));
  buf = ishnePutInt16(buf, 8, crc);
  bytes = buf;
end
%=============================================================================
function value = ishneField(r, name, default)
  if isfield(r, name) && ~isempty(r.(name))
    value = r.(name);
  else
    value = default;
  end
end
%=============================================================================
function value = ishneVector(r, name, count, default)
  value = repmat(default, 1, count);
  if isfield(r, name) && ~isempty(r.(name))
    given = double(r.(name)(:)');
    m = min(count, numel(given));
    value(1:m) = given(1:m);
  end
end
%=============================================================================
function codes = ishneCodes(r, count)
  % The lead codes: the record's own when it has them, otherwise derived from
  % the lead names, otherwise unknown. A name the table does not know becomes
  % the unknown code 0 rather than a guessed limb position.
  codes = zeros(1, count);
  if isfield(r, 'leadCodes') && numel(r.leadCodes) >= count
    codes = double(r.leadCodes(1:count));
    return;
  end
  if isfield(r, 'leadNames') && numel(r.leadNames) >= count
    for k = 1:count
      codes(k) = ishneLeadTable(r.leadNames{k});
    end
  end
end
%=============================================================================
function text = ishneHeaderText(header, name)
  text = '';
  if isstruct(header) && isfield(header, name) && ~isempty(header.(name))
    text = char(header.(name));
  end
end
%=============================================================================
function value = ishneHeaderNum(header, name, default)
  value = default;
  if isstruct(header) && isfield(header, name) && ~isempty(header.(name))
    value = double(header.(name));
    value = value(1);
  end
end
%=============================================================================
function triple = ishneHeaderTriple(header, name)
  triple = [0, 0, 0];
  if isstruct(header) && isfield(header, name) && numel(header.(name)) >= 3
    v = double(header.(name));
    triple = v(1:3);
  end
end
%=============================================================================
function variable = ishneVariable(r)
  % The raw variable block when the record kept one; otherwise the printable
  % text, if any, encoded as its bytes. Lossless when the record came from
  % ishne.read, which keeps the raw bytes.
  variable = zeros(1, 0);
  if isfield(r, 'variableBlock') && ~isempty(r.variableBlock)
    variable = double(r.variableBlock(:)');
    return;
  end
  if isfield(r, 'variableText') && ~isempty(r.variableText)
    variable = double(char(r.variableText));
  end
end
%=============================================================================
function out = ishnePad(values, count)
  out = zeros(1, count);
  m = min(count, numel(values));
  out(1:m) = values(1:m);
end
%=============================================================================
function buf = ishnePutInt32(buf, off, value)
  value = mod(round(value), 4294967296);
  buf(off + 1) = mod(value, 256);
  buf(off + 2) = mod(floor(value / 256), 256);
  buf(off + 3) = mod(floor(value / 65536), 256);
  buf(off + 4) = floor(value / 16777216);
end
%=============================================================================
function buf = ishnePutInt16(buf, off, values)
  values = round(values);
  for k = 1:numel(values)
    word = mod(values(k), 65536);
    buf(off + 2 * (k - 1) + 1) = mod(word, 256);
    buf(off + 2 * (k - 1) + 2) = floor(word / 256);
  end
end
%=============================================================================
function buf = ishnePutText(buf, off, width, text)
  text = char(text);
  m = min(width, numel(text));
  for k = 1:m
    code = double(text(k));
    if code < 0 || code > 255
      code = 0;
    end
    buf(off + k) = code;
  end
end
%=============================================================================
