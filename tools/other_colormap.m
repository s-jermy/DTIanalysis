function CM = other_colormap(map,varargin)
narginchk(1,2);
m = 256;
if nargin>1
    m = varargin{1};
end
if strcmp(map(1:3),'pf_')
    map = map(4:end);
    clr_folder = 'tools\cardiac_DTI_colormaps-master\colormaps_data';
    clr_name = [map '.txt'];
    try
        CM = load(fullfile(clr_folder,clr_name));
    catch %in case colormap doesn't exist, return default
        warning('The pf_colormap "%s" does not exist.', map);
        CM = parula(m);
    end
else
    try exist(map, 'file') == 2 || exist(map, 'builtin') == 5
        % Call the function with additional arguments
        CM = feval(map, varargin{:});
    catch
        warning('The colormap function "%s" does not exist.', map);
        CM = parula(m);
    end
end

end