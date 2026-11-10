function V = general_octree_decoding(octree)

byte_levels = separate_octree_levels(octree);
levels = length(byte_levels);
% Cell with bits from each octree level
% bit_levels = octree_to_bitlevels(octree,levels);
bit_levels = cell(1,levels);
for j = 1:levels
	bit_levels{j} = dec2bin(byte_levels{j},8) - '0';
end

% Binary version of the octree
octree_bin = dec2bin(octree,8) - '0';

% The amount of voxels in the octree, N,
% equals the number of ones in the last octree level
N = sum(sum(bit_levels{end}));

% Translation of the octree to the octree mapping
%    For example, if octree = [3 12 7], then: 
%    ==> In the first level, octants 0 and 1 are filled (3: 00000011)
%    ==> In the second level, octants 2 and 3 are filled (12: 00001100)
%        as well as octants 0, 1 and 2 (7: 00000111)
%    So, octree_mapping = [0 2; 0 3; 1 0; 1 1; 1 2]
% octree_mapping leads easily to the determination of the voxel positions
octree_mapping = zeros(N,levels);
octree_mapping(:,end) = bits_to_nodes(bit_levels{end});
sum_bits = cell(1,levels);
sum_bits{end} = sum(bit_levels{end},2);
for j = (levels-1):-1:1
	cur_nodes = bits_to_nodes(bit_levels{j});
	next_sum_bits = sum_bits{j+1};
	octree_mapping(:,j) = repelem(cur_nodes,next_sum_bits);
	% m=1;
	% n=0;
	% for k = 1:size(next_sum_bits,1)
	% 	octree_mapping(n+[1:next_sum_bits(k)],j) = cur_nodes(m);
	% 	n=n+next_sum_bits(k);
	% 	m=m+1;
	% end
	sum_bits{j} = sum(bit_levels{j},2);
	curr_sum_bits = sum_bits{j};
	n=0;
	for m=1:length(curr_sum_bits)
		n1 = curr_sum_bits(m);
		curr_sum_bits(m) = sum(next_sum_bits(n+[1:n1]));
		n=n+n1;
	end
	sum_bits{j} = curr_sum_bits;
end

% Translation of the octree to the voxel positions
% V = reshape(bin2dec(reshape(dec2bin(octree_mapping'),[levels N*3])'),[N 3]);
V = zeros(N,3);
octree_mapping = uint8(octree_mapping);
bin_base = 2.^([(levels-1):-1:0]');
V(:,1) = double(bitget(octree_mapping,3))*bin_base;
V(:,2) = double(bitget(octree_mapping,2))*bin_base;
V(:,3) = double(bitget(octree_mapping,1))*bin_base;
V = sortrows(V);

function nodes = bits_to_nodes(cur_level)

[nodes,~]=find(cur_level(:,end:-1:1)');
nodes = nodes-1;