function wtc_dtf = watercolumn_datafilling(wtc_img, datafilling_mode)

valid_wtc_img = (wtc_img~=-Inf);
wtc_dtf = wtc_img;
if (datafilling_mode~=-1) && ...
	(datafilling_mode~=0) && ...
	(datafilling_mode~=1) && ...
	(datafilling_mode~=2)
	ns = zeros(1,size(wtc_img,1));
	for k = 1:size(wtc_img,1)
		if wtc_img(k,end)==-Inf
			ns(k) = find(wtc_img(k,:)==-Inf,1)-1;
		else
			ns(k) = size(wtc_img,2);
		end
	end
	wtc_dtf(~valid_wtc_img) = round(mean( ...
		wtc_img(sub2ind(size(wtc_img),1:size(wtc_img,1),ns))));
end
switch datafilling_mode
	case -1 % Highest possible value
		wtc_dtf(~valid_wtc_img) = 127;
	case 0 % Null value
		wtc_dtf(~valid_wtc_img) = 0;
	case 1 % Lowest possible value
		wtc_dtf(~valid_wtc_img) = -128;
	case 2 % Mean of valid samples
		wtc_dtf(~valid_wtc_img) = round(mean(wtc_img(valid_wtc_img)));
	case 3 % Low-pass version using large moving average (10% of smaller dimension)
		lpf_N = round(min(size(wtc_img))*.1);
		if rem(lpf_N,2)==0
			lpf_N = lpf_N + 1;
		end
		lpf = ones(lpf_N);
		lpf = lpf/sum(sum(lpf));
		extra_pix = (lpf_N+1)/2;
		wtc_dtf = padarray(wtc_dtf, ...
			[1 1]*extra_pix, 'replicate');
		wtc_dtf = round(conv2(wtc_dtf,lpf,'same'));
		wtc_dtf = wtc_dtf([1:size(wtc_img,1)]+extra_pix, ...
			[1:size(wtc_img,2)]+extra_pix);
	case 4 % Down/upsampled version
		wtc_dtf = round(imresize(imresize(wtc_dtf,.5),2));
	case 5 % DCT strong quantization
		dct_qp = 100;
		wtc_dtf_2 = round(idct2(dct_qp*round(dct2(wtc_dtf)/dct_qp)));
		while mean(mean((wtc_dtf_2-wtc_dtf).^2))>1
			wtc_dtf = wtc_dtf_2;
			wtc_dtf_2 = round(idct2(dct_qp*round(dct2(wtc_dtf)/dct_qp)));
		end
	case 6 % Wavelet strong quantization
		wavelet_qp = 100;
		wavelet_type = 'db8';
		wavelet_levels = 5;
		wtc_dtf_2 = round(ifwt2(wavelet_qp*round( ...
			fwt2(wtc_dtf, wavelet_type, wavelet_levels)/wavelet_qp), ...
			wavelet_type, wavelet_levels));
		while mean(mean((wtc_dtf_2-wtc_dtf).^2))>1
			wtc_dtf = wtc_dtf_2;
			wtc_dtf_2 = round(ifwt2(wavelet_qp*round( ...
				fwt2(wtc_dtf, wavelet_type, wavelet_levels)/wavelet_qp), ...
				wavelet_type, wavelet_levels));
		end
	case 7 % Median filtering
		lpf_N = round(min(size(wtc_img))*.1);
		if rem(lpf_N,2)==0
			lpf_N = lpf_N + 1;
		end
		extra_pix = (lpf_N+1)/2;
		wtc_dtf = padarray(wtc_dtf, ...
			[1 1]*extra_pix, 'replicate');
		wtc_dtf = round(medfilt2(wtc_dtf,lpf_N));
		wtc_dtf = wtc_dtf([1:size(wtc_img,1)]+extra_pix, ...
			[1:size(wtc_img,2)]+extra_pix);
	case 8 % Weighted average (ON DATA FILLING ALGORITHMS FOR MRC LAYERS - http://queiroz.divp.org/papers/icip00prep.pdf)
		M = 15;
		lpf_N = round(min(size(wtc_img))*.1);
		if rem(lpf_N,2)==0
			lpf_N = lpf_N + 1;
		end
		extra_pix = (lpf_N+1)/2;
		ws = ones(size(wtc_img));
		ws(valid_wtc_img) = M;
		ws = padarray(ws, [1 1]*extra_pix, 'replicate');
		ws = conv2(ws,ones(lpf_N),'same');
		wtc_dtf(valid_wtc_img) = M*wtc_dtf(valid_wtc_img);
		wtc_dtf = padarray(wtc_dtf, ...
			[1 1]*extra_pix, 'replicate');
		wtc_dtf = conv2(wtc_dtf,ones(lpf_N),'same');
		wtc_dtf = round(wtc_dtf./ws);
		wtc_dtf = wtc_dtf([1:size(wtc_img,1)]+extra_pix, ...
			[1:size(wtc_img,2)]+extra_pix);
end
wtc_dtf(wtc_dtf<-128) = -128;
if (datafilling_mode~=-1) && ...
	(datafilling_mode~=0) && ...
	(datafilling_mode~=1) && ...
	(datafilling_mode~=2)
	wtc_dtf(valid_wtc_img) = wtc_img(valid_wtc_img);
end