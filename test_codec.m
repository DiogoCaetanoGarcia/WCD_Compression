for k = 1:5
	wcd_file = num2str(k, 'data/%d.mat');
	load(wcd_file)
	[r_bits,cur_wtcs] = watercolumn_arith_cod(wcd_img);
	printf("\n%s\n", wcd_file)
	printf('- Size: %d x %d pixels\n', size(wcd_img))
	printf('- Valid pixels: %d (%d%%)\n', ...
		sum(sum(wcd_img~=-Inf)), ...
		round(sum(sum(wcd_img~=-Inf))/numel(wcd_img)*100));
	printf('- Proposed codec compression ratio: %1.2f\n', ...
		numel(wcd_img)*8/r_bits)
end