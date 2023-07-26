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
% SJ - changed to variable input so I can set delta and the nu(m)ber of 
% points. narginchk to keep number of variables between 2 and 4. axescheck 
% allows you to print to a specific set of axes
% SJ - inargs{{0},1,2,3} = {{ha},D,delta,m}
% SJ - changes made to use superquadric glyphs as per 10.1002/mrm.20318
% SJ - moved map, colormap, and colour limits into a separate function
% 
%------------------------------------------------------------------------------------

narginchk(2,4); %sj
[ha,inargs,nargs]=axescheck(varargin{:}); %sj

%sj - default values
D = 1; %sj
delta = 1; %sj - distance between glyphs
gama = 3; % sj - glyph sharpness ( 3 - 6 )
m = 50; %sj - number of points in ellipsoid (+1)
c = [1/3 1/3 1/3]; %sj - linear, planar, spherical anisotropy

% sj
if nargs>0
    D = inargs{1}; %sj
end
if nargs>1
    delta = inargs{2};
end
if nargs>2
    m = inargs{3};
end

sz=size(D);
if length(sz)==2
    ny=1;nx=1;
elseif length(sz)==3
    ny=sz(3);nx=1;
elseif length(sz)==4
    ny=sz(3);nx=sz(4);
end

ha=newplot(ha); %sj
hold on
for i=1:ny
    for j=1:nx
        [v,d]=eig(squeeze(D(:,:,i,j)),'vector');
        d = abs(d);
        
        if sum(d(:))~=0
            d = normalize(d,'norm',Inf); %sj - normalise vectors to maximum eigenvalue
            ds = sort(d,'descend');

            % [dX,dY,dZ]=ellipsoid(0,0,0,d(1),d(2),d(3),m);

            %% see Ennis et al MRM 2005
            c(1) = (ds(1)-ds(2))/sum(ds(:)); %cl linear anisotropy
            c(2) = 2*(ds(2)-ds(3))/sum(ds(:)); %cp planar anisotropy
            c(3) = 1 - c(1) - c(2); %cs spherical anisotropy
            if c(1)>=c(2) %cl>=cp
                e = (1-c(2))^gama; %sj - alpha - horizontal roundness
                n = (1-c(1))^gama; %sj - beta - vertical roundness
            else %cl<cp
                n = (1-c(2))^gama;
                e = (1-c(1))^gama;
            end
            [X,Y,Z]=superquadric(n,e,m); 

            if c(1)>=c(2) %cl>=cp
                tmp = Z;
                Z = X;
                X = tmp;
                Y = -Y;
            end

            %% sj - scale, rotate, and shift glyph
            dX = d(1).*X; %sj - scale the glyph to the eigenvalues
            dY = d(2).*Y;
            dZ = d(3).*Z;
            
            sz=size(dX);
            for x=1:sz(1)
                for y=1:sz(2)
                    A=[dX(x,y); dY(x,y); dZ(x,y)];
                    A = v*A; %sj - orient the glyph to the eigenvectors
                    dX(x,y)=A(1);dY(x,y)=A(2);dZ(x,y)=A(3);
                end
            end
            dX=dX+j*delta; %sj - shift the glyph to the appropriate position
            dY=dY+i*delta;
            h = surf(dX,dY,dZ,'parent',ha);
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
% view([1 -2 20]);
% view(2);
hold off

% fprintf(1,'\nIf you use plotDTI.m please cite the following work:\n');
% fprintf(1,'A. Barmpoutis, B. C. Vemuri, T. M. Shepherd, and J. R. Forder "Tensor splines for\n');
% fprintf(1,'interpolation and approximation of DT-MRI with applications to segmentation of\n');
% fprintf(1,'isolated rat hippocampi", IEEE TMI: Transactions on Medical Imaging, Vol. 26(11),\n');
% fprintf(1,'pp. 1537-1546\n');