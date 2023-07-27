function [xx,yy,zz] = superquadric(n,e,m)
%SUPERQUAD Barr's "superquadrics" ellipsoid.
%   [x,y,z] = SUPERQUAD(n,e,m) is a generalized ellipsoid with
%   n = vertical roundness, e = horizontal roundness and m facets.
%   If values of n and e are not given, random values are supplied.
%   The default value of m is 24.
%
%   SUPERQUAD(...) , with no output arguments, does a SURF plot.
%
%   Ref: A. H. Barr, IEEE Computer Graphics and Applications, 1981,
%        or, Graphics Gems III, David Kirk, editor, 1992.
%
%   See also XPQUAD.

%   Copyright 1984-2014 The MathWorks, Inc.

if nargin < 3
   m = 24;
end
if nargin < 2
   e = max(0,1+randn);
end
if nargin < 1
   n = max(0,1+randn);
end

u = (0:2:2*m)/m; %azimuth
v = u'/2; %polar

cosv = cospi(v);
sinv = sinpi(v);
cosu = cospi(u);
sinu = sinpi(u);
sinv(1) = 0;
sinv(m+1) = 0;
sinu(1) = 0;
sinu(m+1) = 0;

t = sign(sinv) .* abs(sinv).^n ;
x = t * (sign(cosu) .* abs(cosu).^e );
y = t * (sign(sinu) .* abs(sinu).^e );
z = (sign(cosv) .* abs(cosv).^n ) *  ones(size(u));

if nargout == 0
   surf(x,y,z)
else
   xx = x;
   yy = y;
   zz = z;
end
