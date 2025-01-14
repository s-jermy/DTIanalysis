function savePNGs(map_dicom,trace,contours,saveDir,varargin)
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
tog_cmap = 1;
tog_alpha = 1;
if nargin==5
    error('This function does not accept exactly one argument. Use no variable arguments or more than one.');
end
if nargin>5
    lowb_labels = varargin{1};
    highb_labels = varargin{2};
end
if nargin>6
    tog_cmap = varargin{3};
end
if nargin>7
    tog_alpha = varargin{4};
end

cardiacphases = fieldnames(map_dicom);
if ~tog_cmap
    cmap = "turbo";
    %cmap = other_colormap("inferno");
end

for i=1:length(cardiacphases)
    slicelocation = fieldnames(map_dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        TMPmap = map_dicom.(cardiacphases{i}).(slicelocation{j});
        
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
        under = trace{j}{2}; %b50 trace image used as base image
    
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
                            title([lowb{lb} '-' highb{hb} ' ' sprintf(['MD (' '\x03bc' 'm^2/ms)'])]);
                            ax2 = axes;

                            ForFig = ForFig*1e3;
                            if median(ForFig(M_myo))>2.5
                                imagesc(ax2,ForFig,'alphadata',M_myo,[0 5]); %sj
                            else
                                imagesc(ax2,ForFig,'alphadata',M_myo,[0 2.5]); %sj
                            end
                            if tog_cmap
                                cmap = other_colormap('pf_MD');
                            end
                            colormap(ax2,cmap);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'FA' %fractional anisotropy
                            title([lowb{lb} '-' highb{hb} ' FA']);
                            ax2 = axes;

                            imagesc(ax2,ForFig,'alphadata',M_myo,[0 1]); %sj
                            if tog_cmap
                                cmap = other_colormap('pf_FA');
                            end
                            colormap(ax2,cmap);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        
                        case 'HA' %helix angle
                            title([lowb{lb} '-' highb{hb} ' Helix angle (°)']);
                            ax2 = axes;

                            imagesc(ax2,ForFig,'alphadata',M_myo,[-90 90]); %sj
                            if tog_cmap
                                cmap = other_colormap('helix_angle');
                            end
                            colormap(ax2,cmap);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'HA_filt' %filtered helix angle
                            title([lowb{lb} '-' highb{hb} ' Filtered Helix angle (°)']);
                            ax2 = axes;

                            imagesc(ax2,ForFig,'alphadata',M_myo,[-90 90]); %sj
                            if tog_cmap
                                cmap = other_colormap('helix_angle');
                            end
                            colormap(ax2,cmap);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'E2A' %absolute secondary eigenvector angle
                            title([lowb{lb} '-' highb{hb} ' Absolute E2 angle (°)']);
                            ax2 = axes;

                            ForFig = abs(ForFig);
                            imagesc(ax2,ForFig,'alphadata',M_myo,[0 90]); %sj
                            cmap = other_colormap('pf_abs_E2A');
                            colormap(ax2,cmap);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        
                        case 'AD' %axial diffusivity
                            title([lowb{lb} '-' highb{hb} ' ' sprintf(['AD (' '\x03bc' 'm^2/ms)'])]);
                            ax2 = axes;

                            ForFig = ForFig*1e3;
                            if median(ForFig(M_myo))>3.5
                                imagesc(ax2,ForFig,'alphadata',M_myo,[0 5]); %sj
                            else
                                imagesc(ax2,ForFig,'alphadata',M_myo,[0 3.5]); %sj
                            end
                            if tog_cmap
                                cmap = other_colormap('pf_tensor_mode');
                            end
                            colormap(ax2,cmap);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'RD' %radial diffusivity
                            title([lowb{lb} '-' highb{hb} ' ' sprintf(['RD (' '\x03bc' 'm^2/ms)'])]);
                            ax2 = axes;

                            ForFig = ForFig*1e3;
                            if median(ForFig(M_myo))>2
                                imagesc(ax2,ForFig,'alphadata',M_myo,[0 5]); %sj
                            else
                                imagesc(ax2,ForFig,'alphadata',M_myo,[0 2]); %sj
                            end
                            if tog_cmap
                                cmap = other_colormap('pf_tensor_mode');
                            end
                            colormap(ax2,cmap);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'TRA' %transverse angle
                            title([lowb{lb} '-' highb{hb} ' Transverse angle (°)']);
                            ax2 = axes;
                            
                            imagesc(ax2,ForFig,'alphadata',M_myo,[-90 90]); %sj
                            if tog_cmap
                                cmap = other_colormap('pf_E1_TA');
                            end
                            colormap(ax2,cmap);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'SA' %sheet angle
                            title([lowb{lb} '-' highb{hb} ' Sheet angle (°)']);
                            ax2 = axes;
                            
                            imagesc(ax2,ForFig,'alphadata',M_myo,[-90 90]); %sj
                            if tog_cmap
                                cmap = other_colormap('pf_E2A');
                            end
                            colormap(ax2,cmap);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        otherwise
                            fname = '';
                    end

                    axis equal;colorbar;

                    if ~isempty(fname)
                        export_fig(fname,'-png','-transparent','-r100');
                    end
                    close(hf);
                end
            end
        end
    end
end

end