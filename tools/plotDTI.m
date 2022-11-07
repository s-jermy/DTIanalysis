function plotDTI(varargin) %sj
%-fanDTasia ToolBox------------------------------------------------------------------
% This Matlab script is part of the fanDTasia ToolBox: a Matlab library for Diffusion 
% Weighted MRI (DW-MRI) Processing, Diffusion Tensor (DTI) Estimation, High-order 
% Diffusion Tensor Analysis, Tensor ODF estimation, Visualization and more.
%
% A Matlab Tutorial on DW-MRI can be found in:
% http://www.cise.ufl.edu/~abarmpou/lab/fanDTasia/tutorial.php
%
%-CITATION---------------------------------------------------------------------------
% If you use this software please cite the following work:
% A. Barmpoutis, B. C. Vemuri, T. M. Shepherd, and J. R. Forder "Tensor splines for 
% interpolation and approximation of DT-MRI with applications to segmentation of 
% isolated rat hippocampi", IEEE TMI: Transactions on Medical Imaging, Vol. 26(11), 
% pp. 1537-1546 
%
%-DESCRIPTION------------------------------------------------------------------------
% This function plots a 2D field of 3D tensors as ellipsoidal glyphs. The 3D tensors 
% must be in the form of 3x3 symmetric positive definite matrices. The field can 
% contain either a single tensor, or a row of tensors or a 2D field of tensors.
%
% NOTE: This function plots only 2nd-order tensors (i.e. traditional DTI). For higher
% order tensors (such as 4th-order tensor visualization) please use the plotTensors.m
%
%-USE--------------------------------------------------------------------------------
% example 1: plotDTI(D)
% where D is of size 3x3 or 3x3xN or 3x3xNxM
%
% example 2: plotDTI(D,delta)
% where delta is a scalar that controls the size 
% of a voxel in the field. Default: delta=1
%
%-DISCLAIMER-------------------------------------------------------------------------
% You can use this source code for non commercial research and educational purposes 
% only without licensing fees and is provided without guarantee or warrantee expressed
% or implied. You cannot repost this file without prior written permission from the 
% authors. If you use this software please cite the following work:
% A. Barmpoutis, B. C. Vemuri, T. M. Shepherd, and J. R. Forder "Tensor splines for 
% interpolation and approximation of DT-MRI with applications to segmentation of 
% isolated rat hippocampi", IEEE TMI: Transactions on Medical Imaging, Vol. 26(11), 
% pp. 1537-1546 
%
%-AUTHOR-----------------------------------------------------------------------------
% Angelos Barmpoutis, PhD
% Computer and Information Science and Engineering Department
% University of Florida, Gainesville, FL 32611, USA
% abarmpou at cise dot ufl dot edu
%------------------------------------------------------------------------------------
%
% SJ - changed to variable input so I can set delta as the (n)umber of 
% points, which map, (c)olor(m)ap and colour (lim)its. narginchk to keep 
% number of variables between 1 and 7. axescheck allows you to print to a 
% specific set of axes
% SJ - inargs{1,2,3,4,5,6} = {D,delta,n,map,cm,lim}
% SJ - added pf_colormap to colour glyphs using tensor maps (HA for now)
% SJ - 
%------------------------------------------------------------------------------------

narginchk(1,7); %sj
[ha,inargs,nargs]=axescheck(varargin{:}); %sj

%sj - default values
D = inargs{1}; %sj
delta = 1; %sj - distance between glyphs
n = 50; %sj - number of points in ellipsoid
% p = 4; %sj - superellipsoid
map = []; %sj
cm = ''; %sj
lim = []; %sj

% sj
if nargs>1
    delta = inargs{2};
end
if nargs>2
    n = inargs{3};
end
if nargs>3
    map = inargs{4};
end
if nargs>4
    cm = inargs{5};
end
if nargs>5
    lim = inargs{6};
end

% sj - superellipsoid
% if numel(p)==1
% 	p=repmat(p,[1 3]);
% end

sz=size(D);
if length(sz)==2
    nx=1;ny=1;
elseif length(sz)==3
    nx=sz(3);ny=1;
elseif length(sz)==4
    nx=sz(3);ny=sz(4);
end

ha=newplot(ha); %sj
if ~(isempty(cm)||isempty(lim))
    colormap(pf_colormap(cm));
    ha.CLim = lim; %sj
end
hold on
for i=1:nx
    for j=1:ny
        [v,d]=eig(squeeze(D(:,:,i,j)),'vector');
        
        if sum(d(:))~=0
            d = normalize(d,'norm',Inf); %sj - normalise vectors to maximum eigenvalue
            [X,Y,Z]=ellipsoid(0,0,0,d(1),d(2),d(3),n);
%             [X,Y,Z]=superellipsoid([0 0 0],d,p,n);
            sz=size(X);
            for x=1:sz(1)
                for y=1:sz(2)
                    A=[X(x,y) Y(x,y) Z(x,y)];
                    A = v*A';
                    X(x,y)=A(1);Y(x,y)=A(2);Z(x,y)=A(3);
                end
            end
            X=X+(i-1)*delta;
            Y=Y+(j-1)*delta;
            h = surf(X,Y,Z,'parent',ha);
            
            if ~isempty(map)
                cdata = repmat(map(i,j),n+1);
                h.CData = cdata;
            end
        end
    end
end
% set(gca,'GridLineStyle','none')
% set(gca,'ZTick',[])
shading interp
lighting phong
% lighting gouraud
% camlight
% colormap winter
% l = light('Position',[0 0 1],'Style','infinite','Color',[ 1.000 0.584 0.000]);
axis equal
axis off
% view([1 -2 20])
% view([0 90]);
hold off

% fprintf(1,'\nIf you use plotDTI.m please cite the following work:\n');
% fprintf(1,'A. Barmpoutis, B. C. Vemuri, T. M. Shepherd, and J. R. Forder "Tensor splines for\n');
% fprintf(1,'interpolation and approximation of DT-MRI with applications to segmentation of\n');
% fprintf(1,'isolated rat hippocampi", IEEE TMI: Transactions on Medical Imaging, Vol. 26(11),\n');
% fprintf(1,'pp. 1537-1546\n');