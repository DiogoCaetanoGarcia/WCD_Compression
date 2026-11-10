function [x_code, N] = Nbits_to_byte(x)

N = ceil(log2(max(x)+1));
x_code = dec2bin(x,N);
x_code = x_code';
x_code = x_code(:);
rem8 = rem(length(x_code),8);
if rem8
	x_code = [x_code; char('0'*ones(8-rem8,1))];
end
x_code = reshape(x_code,[8 length(x_code)/8])';
x_code = bin2dec(x_code);