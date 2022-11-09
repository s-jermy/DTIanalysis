function CM = pf_colormap(map)

clr_folder = 'tools\cardiac_DTI_colormaps-master\colormaps_data';
clr_name = [map '.txt'];
CM = load(fullfile(clr_folder,clr_name));

end