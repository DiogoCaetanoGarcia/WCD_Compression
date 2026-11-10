function x = byte_to_Nbits(x_code, N, L)

x = dec2bin(x_code, 8);
x = x';
x = x(1:(N*L)); 
x = bin2dec(reshape(x, [N length(x)/N])');
