function savePNGs(map_dicom,nfo,trace,contours,saveDir,varargin)
% in:
% map_dicom - struct containing diffusion maps
% trace - struct containing average image for each b-value
% contours - struct containting contours
% saveDir - save directory for current subject
% varargin:
% lowb_labels - restrict output to specific low b-values - {} for no restriction
% highb_labels - restrict output to specific high b-values  - {} for no restriction
% tog_cmap - toggle pf colour map
% tog_alpha - toggle alpha map
% 
% description:
% save DTI maps

lowb_labels = {};
highb_labels = {};
tog_cmap = 0;
tog_alpha = 1;
tog_allmaps = 1;
lowb_ref = [];

if mod(numel(varargin), 2) ~= 0
    error('Arguments must be provided in key-value pairs.');
end

for i = 1:2:numel(varargin)
    key = varargin{i};
    value = varargin{i+1};

    switch key
        case 'RefLowB'
            lowb_ref = value;
        case 'LowB'
            lowb_labels = value;
        case 'HighB'
            highb_labels = value;
        case 'CustomColourmap'
            tog_cmap = value;
        case 'MapMask'
            tog_alpha = value;
        case 'PrintAllMaps'
            tog_allmaps = value;
        otherwise
            error('Unknown parameter: %s', key);
    end
end

if isempty(lowb_ref)
    lowb_ref = 50;
end

cardiacphases = fieldnames(map_dicom);

for i=1:length(cardiacphases)
    slicelocation = fieldnames(map_dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        TMPmap = map_dicom.(cardiacphases{i}).(slicelocation{j});
        SliceInfo = nfo{j}.SliceInfo;

        if ~tog_cmap
            cmap = "turbo";
            %cmap = other_colormap("inferno");
        end

        if isempty(TMPmap)
            continue
        end
        
        fname1 = fullfile(saveDir,[cardiacphases{i} '_' slicelocation{j}]);
        warning('off','MATLAB:MKDIR:DirectoryExists');
        mkdir(fname1);
        warning('on','MATLAB:MKDIR:DirectoryExists');

        if tog_alpha
            M_myo = contours.myoMask{j};
        else
            M_myo = ones(size(contours.myoMask{j}));
        end
        
        B_values = arrayfun(@(x) x.B_value,SliceInfo);
        uBVal = unique(B_values);
        idx = uBVal==lowb_ref;
        if ~any(idx)
            idx = 1;
        end
        refTo = find(idx);
        under = trace{j}{refTo(1)}; %ref trace image used as base image
    
        mapnames = fieldnames(TMPmap);
        for k=1:length(mapnames)
            lowb = fieldnames(TMPmap.(mapnames{k}));
            for lb=1:length(lowb)
                if ~isempty(lowb_labels)
                    if ~any(strcmp(lowb{lb},lowb_labels))
                        continue
                    end
                end
                highb = fieldnames(TMPmap.(mapnames{k}).(lowb{lb}));
                for hb=1:length(highb)
                    if ~isempty(highb_labels)
                        if ~any(strcmp(highb{hb},highb_labels))
                            continue
                        end
                    end
                    hf = figure;
                    ax1 = axes;
                    imagesc(under);axis off;axis equal;colormap(ax1,'gray');

                    ForFig = TMPmap.(mapnames{k}).(lowb{lb}).(highb{hb});
                    fname = fullfile(fname1,[mapnames{k} '_' lowb{lb} '_' highb{hb} '.png']);
                    switch mapnames{k}
                        case 'MD' %mean diffusivity
                            label = ['MD (' '\x03bc' 'm^2/ms)'];
                            ForFig = ForFig*1e3;
                            if median(ForFig(M_myo))>2.5
                                clims = [0 3];
                            else
                                clims = [0 2.5];
                            end
                            if tog_cmap
                                cmap = "hot";
                                %cmap = other_colormap('pf_MD');
                            end
                        case 'FA' %fractional anisotropy
                            label = 'FA';
                            clims = [0 1];
                            if tog_cmap
                                cmap = brewermap([],"-RdYlGn");
                                %cmap = other_colormap('pf_FA');
                            end
                        
                        case 'HA' %helix angle
                            label = 'Helix angle (°)';
                            clims = [-60 60];
                            if tog_cmap
                                cmap = other_colormap('pf_helix_angle');
                            end
                        case 'HA_filt' %filtered helix angle
                            label = 'Filtered Helix angle (°)';
                            clims = [-60 60];
                            if tog_cmap
                                cmap = other_colormap('pf_helix_angle');
                            end
                        case 'E2A' %absolute secondary eigenvector angle
                            label = 'Absolute E2 angle (°)';
                            ForFig = abs(ForFig);
                            clims = [0 90];
                            cmap = brewermap([],"-RdBu");
                            if tog_cmap
                                cmap = brewermap([],"-RdBu");
                                %cmap = other_colormap('pf_abs_E2A');
                            end
                        otherwise
                            fname = '';
                    end

                    if tog_allmaps
                        fname = fullfile(fname1,[mapnames{k} '_' lowb{lb} '_' highb{hb} '.png']);
                        switch mapnames{k}
                            case 'AD' %axial diffusivity
                                label = ['AD (' '\x03bc' 'm^2/ms)'];
                                ForFig = ForFig*1e3;
                                if median(ForFig(M_myo))>3.5
                                    clims = [0 5]; %sj
                                else
                                    clims = [0 3.5]; %sj
                                end
                                if tog_cmap
                                    cmap = other_colormap('pf_tensor_mode');
                                end
                            case 'RD' %radial diffusivity
                                label = ['RD (' '\x03bc' 'm^2/ms)'];
                                ForFig = ForFig*1e3;
                                if median(ForFig(M_myo))>2
                                    clims = [0 5]; %sj
                                else
                                    clims = [0 2]; %sj
                                end
                                if tog_cmap
                                    cmap = other_colormap('pf_tensor_mode');
                                end
                            case 'TRA' %transverse angle
                                label = 'Transverse angle (°)';
                                clims = [-90 90]; %sj
                                if tog_cmap
                                    cmap = other_colormap('pf_E1_TA');
                                end
                            case 'SA' %sheet angle
                                label = 'Sheet angle (°)';
                                clims = [-90 90]; %sj
                                if tog_cmap
                                    cmap = other_colormap('pf_E2A');
                                end
                            otherwise
                                fname = '';
                        end
                    end

                    if ~isempty(fname)
                        title([lowb{lb} '-' highb{hb} ' ' sprintf(label)]);
                        ax2 = axes;
                        imagesc(ax2,ForFig,'alphadata',M_myo,clims); %sj
                        colormap(ax2,cmap);
                        ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
    
                        axis equal;colorbar;

                        export_fig(fname,'-png','-transparent','-r100');
                    end
                    close(hf);
                end
            end
        end
    end
end

end