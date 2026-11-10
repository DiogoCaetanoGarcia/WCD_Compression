function x = arde(aren_struct)
% arde() arithmetically decodes a vector.
% Requires compilation of mex-file 'arde_c.c'.
%
% Input:
%	 aren_struct: structure obtained from aren().
%
% Output:
%	 x: Nx1 decoded vector
%

y = zeros(aren_struct.N,1,'uint64');
arde_c(aren_struct.code, uint64([0; cumsum(aren_struct.cts)]), y);
x = aren_struct.alph(y+1);
%y = [y; setdiff([1:length(aren_struct.alph)]'-1, unique(y))];
%[y_sort,i,j] = unique(y);
%x = aren_struct.alph(j);
%x = x(1:aren_struct.N);