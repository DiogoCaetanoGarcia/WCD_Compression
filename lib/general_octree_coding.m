function [rate, octree] = general_octree_coding(V)
% general_octree_coding() creates the octree for voxels V
%
% Input:
%	 V: N x 3 pointcloud geometry
%
% Outputs:
%	 r: octree's rate in bits per occupied voxel
%	 o: octree for V, where each 8-bit position o(k)
%	 	indicates if each octant is filled
%

levels = ceil(log2(max(max(V))+1)); %range(V))+1));

if levels<=7
	xb = dec2bin(typecast(int8 (V(:,1)),'uint8' ), 8) - '0';
	yb = dec2bin(typecast(int8 (V(:,2)),'uint8' ), 8) - '0';
	zb = dec2bin(typecast(int8 (V(:,3)),'uint8' ), 8) - '0';
elseif levels<=15
	xb = dec2bin(typecast(int16(V(:,1)),'uint16'),16) - '0';
	yb = dec2bin(typecast(int16(V(:,2)),'uint16'),16) - '0';
	zb = dec2bin(typecast(int16(V(:,3)),'uint16'),16) - '0';
else
	xb = dec2bin(typecast(int32(V(:,1)),'uint32'),32) - '0';
	yb = dec2bin(typecast(int32(V(:,2)),'uint32'),32) - '0';
	zb = dec2bin(typecast(int32(V(:,3)),'uint32'),32) - '0';
end

xb = xb(:, end+[(-levels+1):0]);
yb = yb(:, end+[(-levels+1):0]);
zb = zb(:, end+[(-levels+1):0]);

octree_mapping = sortrows(4*xb + 2*yb + zb);

N = size(V,1);
octree = zeros(1,N);
cur_node = octree_mapping(:,1)*0;
m=0;

%%% Vectorized (fast) code that defines the octree
%%% Source: http://stackoverflow.com/questions/8024639/matlab-conditional-summation/8027389#8027389
%%% Idea: sum values in vector 'a' based on corresponding values of vector 'b'
%%%    a = [1; 2; 3; 4; 5; 6; 7; 8; 9];
%%%    b = [1; 1; 1; 2; 2; 3; 3; 7; 7];
%%%    [unique_b, i, j] = unique(b);
%%%    r = accumarray(j, a)
%%% which results in r = [6; 9; 13; 17]
for j = 1:levels
	cur_node = cur_node*8 + octree_mapping(:,j);
	o2 = unique(cur_node);
	[b,x,y] = unique(floor(o2/8));
	cur_octree = accumarray(y,2.^rem(o2,8));
	octree(m+[1:length(cur_octree)]) = cur_octree;
	m = m + length(cur_octree);
end
octree = octree(1:m);
rate = 8*m/N;