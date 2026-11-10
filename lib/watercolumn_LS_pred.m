function [e,t,pred] = watercolumn_LS_pred(wtc_img, H0, W0)

a = watercolumn_datafilling(wtc_img, 0);
ok = wtc_img~=-Inf;
H3 = size(a,1)-(H0-1);
W2 = size(a,2)-(W0-1);
ctx = zeros(H3*W2,H0*W0);
ctx_ok = ctx;
k=1;
for k1 = 0:(H0-1)
	for k2 = 0:(W0-1)
		cur_a = a([H0:end]-k1,[W0:end]-k2);
		ctx(:,k) = cur_a(:);
		cur_ok = ok([H0:end]-k1,[W0:end]-k2);
		ctx_ok(:,k) = cur_ok(:);
		k = k+1;
	end
end
ctx_ok = sum(ctx_ok==0,2)==0;
t = ctx(ctx_ok,2:end)\ctx(ctx_ok,1);

ad = watercolumn_img_diff(wtc_img);
pred = wtc_img;
% Border treatment
pred(1:H0-1,2:end) = pred(1:H0-1,1:end-1);
pred(H0:end,1:W0-1) = pred([H0:end]-1,1:W0-1);
% LS prediction
pred(H0:end,W0:end) = ...
	reshape(round(ctx(:,2:end)*t), [H3 W2]);
pred = double(int8(pred));
e = [ad(1:(H0-1),:); ...
	ad(H0:end,1:(W0-1)) ...
	a(H0:end,W0:end)-pred(H0:end,W0:end)];