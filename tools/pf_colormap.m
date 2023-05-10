function CM = pf_colormap(map)

clr_folder = fullfile('tools','cardiac_DTI_colormaps-master','colormaps_data');
clr_name = [map '.txt'];
try
    CM = load(fullfile(clr_folder,clr_name));
catch %in case colormap doesn't exist, return default
    CM = parula(256);
end

end