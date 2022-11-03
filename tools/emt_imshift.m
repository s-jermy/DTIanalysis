function shifted = emt_imshift(initim, row_shift, col_shift)
% [nr,nc]=size(initim);
% Nr = ifftshift(-fix(nr/2):ceil(nr/2)-1);
% Nc = ifftshift(-fix(nc/2):ceil(nc/2)-1);
% [Nc,Nr] = meshgrid(Nc,Nr);
% shifted = ifft2(fft2(initim).*exp(1i*2*pi*(row_shift*Nr/nr+col_shift*Nc/nc)));

[M N] = size(initim);
[xx yy] = meshgrid(1:N,1:M);
shifted = interp2(xx,yy,double(initim),xx+row_shift,yy+col_shift,'linear',0);

end