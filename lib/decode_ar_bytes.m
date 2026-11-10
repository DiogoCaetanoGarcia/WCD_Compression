function [y,new_x] = decode_ar_bytes(x, x_cts, x_alph)

L_bytes = ceil(log2(sum(x_cts)+1)/8);
L = uint64(0);
for k = 1:L_bytes
    L = bitor(L, bitshift(uint64(x(k)), 8*(k-1)));
end
L = double(L);
if L > numel(x)-L_bytes
    error('Invalid arithmetic code length');
end
x = x((L_bytes+1):end);
x_ar.N = sum(x_cts);
x_ar.cts = x_cts(:);
x_ar.alph = x_alph;
x_ar.code = x(1:L);
y = arde(x_ar);

new_x = x((L+1):end);
% L_bytes = ceil(log2(sum(x_cts)+1)/8);
% L = uint8(x(1:L_bytes));
% switch L_bytes
% 	case 2
% 		L = typecast(L, 'uint16');
% 	case 3
% 		L = typecast([L uint8(0)], 'uint32');
% 	case 4
% 		L = typecast(L, 'uint32');
% 	case 5
% 		L = typecast([L uint8([0 0 0])], 'uint64');
% 	case 6
% 		L = typecast([L uint8([0 0])], 'uint64');
% 	case 7
% 		L = typecast([L uint8([0])], 'uint64');
% 	case 8
% 		L = typecast(L, 'uint64');
% end
% L = double(L);
% x = x((L_bytes+1):end);
% x_ar.N = sum(x_cts);
% x_ar.cts = x_cts(:);
% x_ar.alph = x_alph;
% x_ar.code = x(1:L);
% y = arde(x_ar);
% new_x = x((L+1):end);
