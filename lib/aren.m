function aren_struct = aren(x, alph, cts)
% aren() arithmetically encodes a vector.
% Requires compilation of mex-file 'aren_c.c'.
%
% Inputs:
%	 x: Nx1 vector to be encoded
%	 alph (optional): alphabet of possible values in 'x'
%	 cts (optional): number of occurrences of each
%	 	element in 'alph'
%	 If 'alph' and 'cts' are not provided, they are
%	 	calculated from 'x'
%
% Output:
%	 aren_struct: structure with the following fields:
%	 	aren_struct.code: arithmetically-encoded 'x',
%	 		byte-separated
%	 	aren_struct.N: length of 'x'
%	 	aren_struct.alph: 'alph'
%	 	aren_struct.cts: 'cts'
%	 	aren_struct.code_bits_per_symbol: rate for
%	 		'aren_struct.code', in bits/symbol
%	 	aren_struct.cts_header_per_symbol: rate for
%	 		'aren_struct.cts', in bits/symbol,
%	 		considering L-bit representation, where
%	 		L = ceil(log2(max(cts)+1))
%


x = x(:);
N = length(x);
% if N==1
% 	cts = 1;
% 	aren_struct.code = [];
% 	aren_struct.N = N;
% 	aren_struct.alph = x;
% 	aren_struct.cts = cts;
% 	aren_struct.code_bits_per_symbol = 8*length(aren_struct.code)/N;
% 	aren_struct.cts_header_per_symbol = ceil(log2(max(cts)+1))*length(cts)/N;
% 	return;
% end

if nargin==1
	alph = unique(x);
	% if length(alph)==1
	% 	cts = length(x);
	% 	aren_struct.code = [];
	% 	aren_struct.N = N;
	% 	aren_struct.alph = alph;
	% 	aren_struct.cts = cts;
	% 	aren_struct.code_bits_per_symbol = 8*length(aren_struct.code)/N;
	% 	aren_struct.cts_header_per_symbol = ceil(log2(max(cts)+1))*length(cts)/N;
	% 	return;
	% end
	if length(alph)>1
		cts = hist(x, alph);
	else
		cts = N;
	end
end

alph = alph(:);
cts = cts(:);

if ~issorted(alph)
	[alph als] = sort(alph);
	cts = cts(als);
	clear als;
end

xs = setdiff(alph,unique(x));
x = [x; xs(:)];
[x_sort,i,j] = unique(x);
newcode = [1:length(x_sort)]-1;
y = uint64(newcode(j));
y = y(1:N)';
ccts = uint64([0; cumsum(cts)]);

val_cts = cts>0;
ps = cts(val_cts)/sum(cts);
ux = unique(x);
if length(ux)>1
	hx = hist(x,ux,1)';
else
	hx = 1;
end
[common_cts common_cts_i] = intersect(alph, ux);
entr_est = sum(-hx.*log2(ps(common_cts_i)));
c = zeros(max(ceil(entr_est*N/8)+1,N)*2,1,'uint8');
%c = zeros(4*N,1,'uint8'); 
L = aren_c(y, ccts, c);

aren_struct.code = c(1:L);
aren_struct.N = N;
aren_struct.alph = alph;
aren_struct.cts = cts;
aren_struct.code_bits_per_symbol = 8*length(aren_struct.code)/N;
aren_struct.cts_header_per_symbol = ceil(log2(max(cts)+1))*length(cts)/N;

% function c = aren(x, alph, cts, add_eof)
% x = x(:);

% % For tests:
% % x = kron([1 1 1 1 1 1 1 1 2 2 2 2 3 3 4 4], ones(1,10));

% if nargin==1
% 	alph = unique(x);
% 	cts = hist(x, alph);
% 	cts = cts(:);
% 	alph(end+1) = max(alph)+1;
% 	x(end+1) = alph(end);
% 	cts(end+1) = 1;
% elseif nargin==4
% 	alph = alph(:);
% 	cts = cts(:);
% 	if add_eof
% 		alph(end+1) = max(alph)+1;
% 		x(end+1) = alph(end);
% 		cts(end+1) = 1;
% 	end
% end

% if ~issorted(alph)
% 	[alph als] = sort(alph);
% 	cts = cts(als);
% 	clear als;
% end

% y = uint64(changem(x,[0:(length(alph)-1)],alph));
% y = y(:);
% ccts = uint64([0; cumsum(cts)]);
% c = zeros(max(ceil(calc_entropy(y)*length(y)/8)+1,length(y)),1,'uint8');
% L = aren_c(y, ccts, c);
% c = c(1:L);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% return;

% global c
% global cur_bit
% global cur_pos
% global pending_bits

% high = uint64((2^64)-1);
% low  = uint64(0);
% mddl = uint64(2^63);
% fqrt = uint64(2^62);
% tqrt = fqrt+mddl;
% msk1 = bitcmp(mddl);
% msk2 = mddl+1;

% ccts = uint64(cumsum([0;cts(1:end-1)]));
% den = ccts(end);
% pending_bits = 0;
% N = length(y);
% c = uint8(x*0);
% cur_bit = 1;
% cur_pos = 1;

% for j = 1:N
% 	rng = high-low+1;
% 	ps = ccts(y(j)+[0 1]);
% 	high = low + (rng * ps(2))/den - 1;
% 	low  = low + (rng * ps(1))/den;
% 	while(1)
% 		if high < mddl
% 			%disp('Case 1')
% 			output_bit_plus_pending(0);
% 			low  = low*2;
% 			high = high*2+1;
% 			%low  = low*2;
% 			%high = bitor(high*2,1);
% 		elseif low >= mddl
% 			%disp('Case 2')
% 			output_bit_plus_pending(1);
% 			low  = 2*(low-mddl);
% 			high = 2*(high-mddl)+1;
% 			%low  = low*2;
% 			%high = bitor(high*2,1);
% 		elseif (low >= fqrt) && (high < tqrt)
% 			%disp('Case 3')
% 			pending_bits = pending_bits+1;
% 			low  = 2*(low-fqrt);
% 			high = 2*(high-fqrt)+1;
% 			%low  = bitand(low*2,msk1);
% 			%high = bitor(high*2,msk2);
% 		else
% 			%disp('Case 4')
% 			break;
% 		end
% 	end
% end

% if cur_bit==1
% 	c = c(1:(cur_pos-1));
% else
% 	c = c(1:cur_pos);
% end


% function output_bit_plus_pending(b)
% global pending_bits

% output_bit(b);
% while(pending_bits>0)
% 	pending_bits=pending_bits-1;
% 	output_bit(~b);
% end

% function output_bit(b)
% global c
% global cur_bit
% global cur_pos

% if cur_pos>length(c)
% 	c = [c;(c*0)];
% end

% if b==1
% 	c(cur_pos) = bitor(c(cur_pos),cur_bit);
% end

% if cur_bit<256
% 	cur_bit = cur_bit*2;
% else
% 	cur_bit = 1;
% 	cur_pos = cur_pos+1;
% end