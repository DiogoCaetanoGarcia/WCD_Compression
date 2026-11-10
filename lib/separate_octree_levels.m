function os = separate_octree_levels(o)

n1s = sum(dec2bin(0:255) - '0', 2)';
os{1} = o(1);
k = [1 1];
l = 1;
while k(end)<length(o)
	n_bytes = sum(n1s(os{l}+1));
	k = k(end)+[1:n_bytes];
	l = l+1;
	os{l} = o(k);
end