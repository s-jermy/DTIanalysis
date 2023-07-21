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
delta = 1;
m = 50;

% sj
if nargs>0
    map = inargs{1};
end
if nargs>1
    cmap = inargs{2};
end
if nargs>2
    lim = inargs{3};
end
if nargs>3
    delta = inargs{4};
end
if nargs>4
    m = inargs{5};
end

% sz=size(map);
% nx=sz(1);ny=sz(2);

% ha=newplot(ha); %sj
if ~(isempty(cmap)||isempty(lim))
    colormap(pf_colormap(cmap));
    ha.CLim = lim; %sj
end
h = ha.Children; %sj - get the glyph surfaces from the axis

for ii=1:length(h)
    xmin = min(h(ii).XData(:));
    xmax = max(h(ii).XData(:));
    x = round((xmin+xmax)/2); %find x position
    ymin = min(h(ii).YData(:));
    ymax = max(h(ii).YData(:));
    y = round((ymin+ymax)/2); %find y position

    j = x/delta + 1; %transform back to pixel coordinates
    i = y/delta + 1;

    if ~isempty(map)
        cdata = repmat(map(i,j),m+1); %get value from map
        h(ii).CData = cdata;
    end
end

end
