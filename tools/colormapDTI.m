function colormapDTI(varargin) %sj
%------------------------------------------------------------------------------------
%
% SJ - changed to variable input so I can set map, (c)olor(m)ap and colour 
% (lim)its. narginchk to keep number of variables between 1 and 5. 
% axescheck allows you to print to a specific set of axes
% SJ - inargs{1,2,3,4,5} = {map,cm,lim,delta,m}
% SJ - added pf_colormap to colour glyphs using tensor maps (HA for now)
% SJ - moved map, colormap, and colour limits into a separate function
% 
%------------------------------------------------------------------------------------

narginchk(1,6); %sj
[ha,inargs,nargs]=axescheck(varargin{:}); %sj

%sj - default values
map = []; %sj - DTI map
cmap = ''; %sj - colormap
lim = []; %sj - colour display limits
m = 50; %(+1)
myo = [];

% sj
if nargs>0
    map = inargs{1};
    myo = ones(size(map));
end
if nargs>1
    cmap = inargs{2};
end
if nargs>2
    lim = inargs{3};
end
if nargs>3
    m = inargs{4};
end
if nargs>4
    myo = inargs{5};
end

myo_map = map;
myo_map(~myo) = NaN;

sz=size(myo_map);
nx=sz(1);ny=sz(2);

verts_per_glyph = (m + 1)^2;
num_glyphs = ny * nx;
total_verts = num_glyphs * verts_per_glyph;
new_colours = zeros(total_verts, 1);
vert_offset = 0;

% ha=newplot(ha); %sj
if ~(isempty(cmap)||isempty(lim))
    colormap(ha,cmap);
    ha.CLim = lim; %sj
end
h = ha.Children(2); %sj - get the glyph patch from the axis

for i=1:nx
    for j=1:ny
        if ~isnan(myo_map(i,j))
            glyph_color = map(i,j); % scalar value for this glyph
            colours = repmat(glyph_color, size(verts_per_glyph,1), 1); % same color for all vertices
            vert_idx = (1:verts_per_glyph) + vert_offset;
            new_colours(vert_idx) = colours;
            vert_offset = vert_offset + verts_per_glyph;
        end
    end
end

if vert_offset > 0
    new_colours = new_colours(1:vert_offset);
    set(h,'FaceVertexCData',new_colours,'FaceColor','interp')
end

end
