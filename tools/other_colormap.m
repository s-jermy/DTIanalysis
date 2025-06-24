function CM = other_colormap(map,varargin)

% need cardiac_DTI_colormaps in tools folder - https://github.com/Pedro-Filipe/cardiac_DTI_colormaps

narginchk(1,2);
m = 256;
if nargin>1
    m = varargin{1};
end
if strcmp(map(1:3),'pf_')
    addpath(genpath('tools/cardiac_DTI_colormaps'));
    map = map(4:end);
    clr_name = [map '.txt'];
    try
        CM = load(clr_name);
    catch %in case colormap doesn't exist, return default
        warning('The pf_colormap "%s" does not exist. Available maps are: "abs_E2A","E1_TA","E2A","FA","helix_angle","MD","tensor_mode"', map);
        CM = parula(m);
    end
else
    if exist(map, 'file') == 2 || exist(map, 'builtin') == 5
        % Call the function with additional arguments
        CM = feval(map, varargin{:});
    else
        warning('The colormap function "%s" does not exist.', map);
        CM = parula(m);
    end
end

end