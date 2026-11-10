function wtc_img_diff = watercolumn_img_diff(wtc_img)

invalid_wtc_img = (wtc_img==-Inf);
wtc_img_diff = wtc_img;
wtc_img_diff(:,2:end) = diff(wtc_img')';
wtc_img_diff(invalid_wtc_img) = 0;
wtc_img_diff(2:end,:) = diff(wtc_img_diff);