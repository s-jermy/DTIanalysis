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
a1 = [0;0;-2]; %sj - add an axis line
a2 = [0;0;2];

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

% Determine number of vertices & faces per glyph based on resolution 'm'
% A surface grid of (m+1)x(m+1) points gives (m+1)^2 vertices and m^2 faces
verts_per_glyph = (m + 1)^2;
faces_per_glyph = m^2;

% Calculate total counts
num_glyphs = ny * nx;
total_verts = num_glyphs * verts_per_glyph;
total_faces = num_glyphs * faces_per_glyph;

% Pre-allocate the full arrays with zeros. THIS IS THE CRITICAL STEP.
all_vertices = zeros(total_verts, 3);
all_faces = zeros(total_faces, 4); % surf2patch creates 4-sided faces
all_colours = zeros(total_verts, 1);
all_lines = zeros(num_glyphs * 3, 3); 
line_idx = 1; % A counter for the current line's position

% Initialize index counters to keep track of our position
vert_offset = 0;
face_offset = 0;

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
            
            %{
            sz=size(dX);
            for x=1:sz(1)
                for y=1:sz(2)
                    A=[dX(x,y); dY(x,y); dZ(x,y)];
                    A = v*A; %sj - orient the glyph to the eigenvectors
                    dX(x,y)=A(1);dY(x,y)=A(2);dZ(x,y)=A(3);
                end
            end
            %}
            %%{
            % 1. Reshape the X, Y, Z coordinates into a single 3xN matrix of points
            points = [dX(:)'; dY(:)'; dZ(:)'];
            
            % 2. Perform a single matrix multiplication to rotate all points at once
            rotated_points = v * points;
            
            % 3. Reshape the rotated points back to the original matrix dimensions
            dX = reshape(rotated_points(1,:), size(dX));
            dY = reshape(rotated_points(2,:), size(dY));
            dZ = reshape(rotated_points(3,:), size(dZ));
            %}
            dX=dX+j*delta; %sj - shift the glyph to the appropriate position
            dY=dY+i*delta;

            %{
            h = surf(dX,dY,dZ,'parent',ha);
            warning('off');
            h1 = arrow3(da1,da2,'w-2',0);
            warning('on');
            %}

            if sum(d(:))~=0 % Make sure you only do this for non-zero tensors
                % Convert the current glyph surface to patch format
                [faces, vertices, colours] = surf2patch(dX, dY, dZ, dZ);  

                % Define the index range for the current glyph's data
                vert_idx = (1:verts_per_glyph) + vert_offset;
                face_idx = (1:faces_per_glyph) + face_offset;
                
                % Place the new data into the pre-allocated arrays
                all_vertices(vert_idx, :) = vertices;
                all_colours(vert_idx) = colours;
                
                % Place the face data, making sure to offset it by the vertex offset
                all_faces(face_idx, :) = faces + vert_offset;
                
                % Update the offsets for the next iteration
                vert_offset = vert_offset + verts_per_glyph;
                face_offset = face_offset + faces_per_glyph;

                da1 = v*a1;
                da2 = v*a2;
                
                % The start (P1) and end (P2) points of the line, shifted to position
                P1 = [da1(1)+j*delta, da1(2)+i*delta, da1(3)];
                P2 = [da2(1)+j*delta, da2(2)+i*delta, da2(3)];

                % Place the coordinates into the pre-allocated array
                all_lines(line_idx, :)   = P1;
                all_lines(line_idx+1, :) = P2;
                all_lines(line_idx+2, :) = [NaN, NaN, NaN]; % The NaN separator
                
                % Increment the line counter for the next glyph
                line_idx = line_idx + 3;
            end
        end
    end
end

if vert_offset > 0
    % Trim any unused pre-allocated space if some tensors were skipped
    all_vertices = all_vertices(1:vert_offset,:);
    all_faces = all_faces(1:face_offset,:);
    all_colours = all_colours(1:vert_offset);

    % Draw the single, consolidated patch object
    patch('Parent', ha, ...
          'Vertices', all_vertices, ...
          'Faces', all_faces, ...
          'FaceVertexCData', all_colours, ...
          'FaceColor', 'interp', ...
          'EdgeColor', 'none');
end

if line_idx > 1
    % Trim any unused space
    all_lines = all_lines(1:line_idx-1, :); 
    % Plot all lines with a single, fast command
    plot3(ha, all_lines(:,1), all_lines(:,2), all_lines(:,3), 'w-', 'LineWidth', 2);
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