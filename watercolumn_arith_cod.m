function [r_bits,cur_wtcs] = watercolumn_arith_cod(wtc_img)
% WATERCOLUMN_ARITH_COD Lossless coder for multibeam water column data.
%
%   [r_bits, cur_wtcs] = watercolumn_arith_cod(wtc_img)
%
%   Input:
%     wtc_img - water column image in dB (rows = beams, columns = radial
%               samples). Values are expected in [-128,127]; -Inf marks
%               invalid samples.
%
%   Output:
%     r_bits   - total size of the generated bitstream, in bits.
%     cur_wtcs - 1x2 cell with the two image regions that were coded
%                separately (before / after the first seafloor return).
%
%   Overview of the method:
%     1) Split the image in two regions (pure water column vs. seafloor
%        return and beyond).
%     2) Run a least-squares (LS) linear predictor on each region.
%     3) Use the predicted value as a context: the samples of each context
%        are coded with a static arithmetic coder.
%     4) The per-context histograms (side information) are stored as a
%        sparse 3D point cloud (value, prediction, count), coded with an
%        octree geometry coder + arithmetic coding of the occupancy bytes.
%     5) Optionally (decode_seq), decode the stream and check every part.
%
%   Bitstream layout (in order):
%     [ohN | packed octree-occupancy histogram | length of octree code |
%      octree code | ASCII header | LS coefficients (raw doubles) |
%      for each non-empty context: (length | arithmetic code)]

if ~exist('./lib/aren_c.mex')
	cd lib
	build_mex_files
	cd ..
end
addpath('./lib')

%% Configuration
show_intermediate_imgs = 0;  % 1 = plot image, prediction and error
decode_seq = 0;              % 1 = run decoder and verify each stream part
H0 = 4;                      % height of the causal predictor neighborhood
W0 = 4;                      % width of the causal predictor neighborhood
                             % (H0*W0-1 LS coefficients per region)

%% Valid-sample mask
ok = (wtc_img~=-Inf);        % true where the sample is valid
N = sum(sum(ok));            % number of valid samples (unused below)

%% Split the image in two regions
% For each beam (row), find the column of the maximum (seafloor return).
% The smallest of these columns is the first range sample at which any
% beam sees the bottom. Columns before it are "pure" water column;
% columns from it on contain seafloor echo and what lies beyond. The two
% regions have very different statistics, so each gets its own predictor.
[~,max_i] = max(wtc_img');
min_max_i = min(max_i);
cur_wtcs = {wtc_img(:,1:(min_max_i-1)), ...
	wtc_img(:,min_max_i:end)};

cur_oks = {ok(:,1:(min_max_i-1)), ...
	ok(:,min_max_i:end)};    % (unused below)

%% LS prediction on each region
% e = prediction error, t0 = LS coefficients, p0 = predicted image
for k = 1:length(cur_wtcs)
	[e{k},t0{k},p0{k}] = watercolumn_LS_pred( ...
		cur_wtcs{k}, H0, W0);
end

%% Optional debug plots
if show_intermediate_imgs
	for k = 1:2
		figure
		cur_paper_img = rot90(cur_wtcs{k},-1);
		cur_paper_img(cur_paper_img==-Inf) = 0;
		% cur_paper_img += 128;
		% Original region
		subplot(1,3,1);
		imagesc(cur_paper_img);
		xlabel('Angular sample')
		ylabel('Radial sample')
		hcb = colorbar;
		ylabel(hcb, 'Signal intensity (dB)')
		axis square;
		% Predicted region
		% NOTE: p is not a cell array at this point (p0 is); p{k} would
		% fail if this block were enabled. Probably should be p0{k}.
		subplot(1,3,2);
		imagesc(rot90(p{k},-1))%+128);
		xlabel('Angular sample')
		ylabel('Radial sample')
		hcb = colorbar;
		ylabel(hcb, 'Signal intensity (dB)')
		axis square;
		% Prediction error
		subplot(1,3,3);
		imagesc(rot90(e{k},-1))%+128);
		xlabel('Angular sample')
		ylabel('Radial sample')
		hcb = colorbar;
		ylabel(hcb, 'Signal intensity (dB)')
		axis square;
	end
end

%% Merge the results of the two regions
t = [t0{1}; t0{2}];          % LS coefficients of both regions (column)
p = [p0{1} p0{2}];           % full predicted image (regions side by side)

%% Vectorize valid samples and shift to the 0..255 range
a = wtc_img(ok)+128;         % actual values, column-major order
p = p(ok)+128;               % predicted values (= context index - 1)
p_l = max(p)+1;              % number of contexts (rows of ctx)
ctx = zeros(p_l,256);        % ctx(c,v+1) = #samples with value v given
                             % prediction c-1 (filled in the loop below)
r_bits = zeros(1,p_l);       % (overwritten later; kept from earlier version)

%% Header: ASCII fields + raw LS coefficients
% Fields: rows, cols of region 1, cols of region 2, H0, W0, p(1).
% p(1) is sent because the first sample has no causal neighbors, so the
% decoder cannot compute its prediction by itself.
wtc_code = double(sprintf('%d,%d,%d,%d,%d,%d,', ...
	size(cur_wtcs{1},1), ...
	size(cur_wtcs{1},2), ...
	size(cur_wtcs{2},2), ...
	H0, W0, p(1)));
% Append the LS coefficients as raw bytes of the doubles
wtc_code = [wtc_code double(typecast(t,'uint8')')];

%% Arithmetic coding of the samples, one stream per context
aok = cell(1,p_l);           % samples of each context (kept for checking)
for c = 1:p_l
	pok = find(p==(c-1));    % samples whose prediction equals c-1
	if length(pok)
		aok{c} = a(pok);
		% Histogram of actual values in this context (the static model;
		% it is sent to the decoder as side information)
		ctx(c,:) = hist(aok{c},0:255);
		% Arithmetic encoder (MEX); returned struct has the .code bytes
		aok_ar = aren(aok{c});
		% Code length in bytes, stored using only as many bytes as
		% needed (derived from the number of symbols in the context)
		cur_L = typecast(uint64( ...
			length(aok_ar.code)), 'uint8');
		L_bytes = ceil(log2(length(pok)+1)/8);
		cur_L = double(cur_L(1:L_bytes));
		wtc_code = [wtc_code ...
			cur_L ...
			aok_ar.code'];
		r_bits(c) = length(aok_ar.code)*8;
	end
end

%% Side information: histograms as a sparse 3D point cloud
% Each nonzero entry of ctx becomes a point (value, prediction, count).
% The cloud is clustered near the diagonal (prediction ~ value), so an
% octree geometry coder represents it compactly.
[y x] = find(ctx>0);
V = [x-1 y-1 ctx(sub2ind(size(ctx),y,x))];

if show_intermediate_imgs
	figure;
	imagesc(log10(ctx))
	xlabel('Pixel value')
	ylabel('Pixel prediction')
	hcb = colorbar;
	ylabel(hcb, 'Log_{10}(frequency of occurrence)')
	axis square
end

% Octree coding of V; o = occupancy bytes (values 1..255, since an
% occupied node never has an empty occupancy code)
[~,o] = general_octree_coding(V);
% Histogram of the occupancy symbols (static model for the next coder)
oh = hist(o,1:255);
o_ar = aren(o);              % arithmetic coding of the occupancy bytes

% Pack the 255 counts of oh using ohN bits each
[oh_code, ohN] = Nbits_to_byte(oh);
% Length of the octree code, stored with the minimum number of bytes
cur_L = typecast(uint64( ...
			length(o_ar.code)), 'uint8');
L_bytes = ceil(log2(length(o)+1)/8);
cur_L = double(cur_L(1:L_bytes));

%% Assemble the final bitstream
% Octree side information goes first, then the header + LS coefficients +
% per-context streams built above.
wtc_code = [[ohN; oh_code]' ...
	cur_L ... %double(num2str(length(o_ar.code),'%d,')) ...
	o_ar.code' wtc_code];

% (Earlier theoretical estimate, immediately overwritten below)
r_bits(end+1) = length(o_ar.code)*8 + ...
	255*ceil(log2(max(oh)+1)) + ...
	8 + ...
	8*length(t);

% Actual size of the final bitstream, in bits
r_bits = length(wtc_code)*8;

% Sanity check: every element must be a valid byte
if (min(wtc_code)<0) || (max(wtc_code)>255)
	min(wtc_code)
	max(wtc_code)
end

%% Decoder (verification only)
% Parses the bitstream in reverse order and compares each recovered part
% with the original. Note that it does NOT reconstruct the image; it only
% checks that all coded streams decode correctly. Lines without a
% trailing semicolon print their result to the console.
if decode_seq
	% --- Octree occupancy histogram ---
	ohN_dec = double(wtc_code(1));           % bits per histogram count
	wtc_code = wtc_code(2:end);
	oh_code_dec = wtc_code([1:ceil(255*ohN_dec/8)]);
	wtc_code = wtc_code((length(oh_code_dec)+1):end);
	oh_dec = double(byte_to_Nbits(oh_code_dec, ohN_dec, 255)');
	oh_decode_ok = isequal(oh,oh_dec)

	% --- Octree occupancy bytes ---
	[o_dec, wtc_code] = decode_ar_bytes( ...
		wtc_code, oh_dec, 1:255);
	o_decode_ok = isequal(o,o_dec)

	% --- Point cloud (value, prediction, count) ---
	V_dec = general_octree_decoding(o_dec);

	% --- Rebuild the context histogram matrix from the point cloud ---
	ctx_dec = zeros(max(V_dec(:,2)+1), 256);
	ctx_dec(sub2ind(size(ctx_dec), ...
		V_dec(:,2)+1, V_dec(:,1)+1)) = V_dec(:,3);
	ctx_dec_ok = isequal(ctx, ctx_dec)
	if ~ctx_dec_ok
		% Report size mismatch and up to 10 differing entries
		fprintf('Size ctx: %d x %d\n', size(ctx));
		fprintf('Size ctx_dec: %d x %d\n', size(ctx_dec));

		if isequal(size(ctx), size(ctx_dec))
			[rr, cc] = find(ctx ~= ctx_dec);

			fprintf('Number of mismatches: %d\n', length(rr));

			for k = 1:min(10,length(rr))
				fprintf('(%d,%d): original=%g, decoded=%g\n', ...
					rr(k), cc(k), ctx(rr(k),cc(k)), ...
					ctx_dec(rr(k),cc(k)));
			end
		end
	end

	% --- ASCII header (first 6 commas delimit the 6 integer fields) ---
	header_end = find(wtc_code==double(','));
	header = sscanf(char( ...
		wtc_code(1:header_end(6))), '%d,');
	wtc_code = wtc_code((header_end(6)+1):end);
	H_dec = header(1);       % rows
	W1_dec = header(2);      % columns of region 1
	W2_dec = header(3);      % columns of region 2
	H0_dec = header(4);
	W0_dec = header(5);
	p_dec00 = header(6);     % prediction of the first sample

	% --- LS coefficients: 2 regions x (H0*W0-1) doubles x 8 bytes ---
	t_dec_bytes = 8*2*(H0_dec*W0_dec-1);
	t_dec = typecast(uint8(wtc_code(1:t_dec_bytes)), ...
		'double')';
	wtc_code = wtc_code((t_dec_bytes+1):end);
	header_dec_ok = isequal( ...
		[[size(cur_wtcs{1},1), ...
		size(cur_wtcs{1},2), ...
		size(cur_wtcs{2},2), ...
		H0, W0, p(1)]'; t], [header; t_dec])

	% --- Per-context sample streams, decoded with the recovered
	%     histograms as static models ---
	aok_dec = cell(1,size(ctx_dec,1));
	for k = 1:length(aok_dec)
		if sum(ctx_dec(k,:))
			[aok_dec{k}, wtc_code] = ...
				decode_ar_bytes(wtc_code, ...
					ctx_dec(k,:), 0:255);
			aok_dec{k} = aok_dec{k}';
		end
	end
	aok_dec_ok = isequal(aok,aok_dec),
end
