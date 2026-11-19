for k = 1:5
	mat_input  = num2str(k, "%d.mat");
	png_output = num2str(k, "%d.png");
	load(mat_input)
	a=wcd_img+128;
	a(a==-Inf)=0;
	m = (wcd_img~=-Inf)*255;
	imwrite(uint8(a), png_output, 'Alpha', m)
	clear a m
	[a_dec,~,m_dec] = imread(png_output);
	a_dec = double(a_dec)-128;
	a_dec(m_dec==0) = -Inf;
	% figure
	% imagesc([wcd_img; a_dec])
	% axis image
	% colorbar
	mse = mean((a_dec(m_dec>0)-wcd_img(m_dec>0)).^2);
	if mse==0
		printf("%s to %s: loading ok!\n", mat_input, png_output)
	else
		printf("%s to %s: loading not ok...\n", mat_input, png_output)
	end
end