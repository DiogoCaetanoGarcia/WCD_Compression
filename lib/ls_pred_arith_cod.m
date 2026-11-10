function r_bits = ls_pred_arith_cod(wtc_img, ok, H0, W0)

[e,t,p] = watercolumn_LS_pred( ...
	wtc_img, H0, W0);

a = wtc_img(ok)+128;
p = p(ok)+128;
p_l = max(p)+1;
ctx = zeros(p_l,256);
r_bits = zeros(1,p_l);
for c = 1:p_l
	pok = find(p==(c-1));
	if length(pok)
		aok = a(pok);
		ctx(c,:) = hist(aok,0:255);
		aok_ar = aren(aok);
		r_bits(c) = length(aok_ar.code)*8;
	end
end

[y x] = find(ctx>0);
V = [x-1 y-1 ctx(sub2ind(size(ctx),y,x))];
[~,o] = general_octree_coding(V);
oh = hist(o,1:255);
o_ar = aren(o);
r_bits(end+1) = length(o_ar.code)*8 + ...
	255*ceil(log2(max(oh)+1)) + ...
	8 + ...
	8*length(t);
r_bits = sum(r_bits);