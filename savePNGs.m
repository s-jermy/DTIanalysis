function savePNGs(map_dicom,trace,contours,saveDir)
% in:
% map_dicom - struct containing diffusion maps
% trace - struct containing average image for each b-value
% contours - struct containting contours
% saveDir - save directory for current subject
% 
% description:
% save DTI maps

cardiacphases = fieldnames(map_dicom);

for i=1:length(cardiacphases)
    slicelocation = fieldnames(map_dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        TMPmap = map_dicom.(cardiacphases{i}).(slicelocation{j});
        
        if isempty(TMPmap)
            continue
        end
        
        fname1 = fullfile(saveDir,[cardiacphases{i} '_' slicelocation{j}]);
        mkdir(fname1);

        M_myo = contours.myoMask{j};
        under = trace{j}{1};
    
        mapnames = fieldnames(TMPmap);
        for k=1:length(mapnames)
            lowb = fieldnames(TMPmap.(mapnames{k}));
            for lb=1:length(lowb)
                if ~any(strcmp(lowb{lb},{'b0','b15','b50','b350'}))
                    continue
                end
                highb = fieldnames(TMPmap.(mapnames{k}).(lowb{lb}));
                for hb=1:length(highb)
                    if strcmp(highb{hb},'b50')
                        continue
                    end
                    hf = figure;
                    ax1 = axes;
                    imagesc(under);axis off;colormap(ax1,'gray');

                    ForFig = TMPmap.(mapnames{k}).(lowb{lb}).(highb{hb});
                    switch mapnames{k}
                        case 'MD' %mean diffusivity
                            title([lowb{lb} '-' highb{hb} ' ' sprintf(['MD (' '\x03bc' 'm^2/ms)'])]);
                            ax2 = axes;

                            ForFig = ForFig*1e3;
                            imagesc(ax2,ForFig,'alphadata',M_myo,[0 2.5]); %sj
                            colormap(ax2,pf_colormap('MD'));
                            fname = fullfile(fname1,[mapnames{k} '_' lowb{lb} '_' highb{hb} '.png']);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'FA' %fractional anisotropy
                            title([lowb{lb} '-' highb{hb} ' FA']);
                            ax2 = axes;

                            imagesc(ax2,ForFig,'alphadata',M_myo,[0 1]); %sj
                            colormap(ax2,pf_colormap('FA'));
                            fname = fullfile(fname1,[mapnames{k} '_' lowb{lb} '_' highb{hb} '.png']);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'AD' %axial diffusivity
                            title([lowb{lb} '-' highb{hb} ' ' sprintf(['AD (' '\x03bc' 'm^2/ms)'])]);
                            ax2 = axes;

                            ForFig = ForFig*1e3;
                            imagesc(ax2,ForFig,'alphadata',M_myo,[0 3.5]); %sj
                            colormap(ax2,pf_colormap('tensor_mode'));
                            fname = fullfile(fname1,[mapnames{k} '_' lowb{lb} '_' highb{hb} '.png']);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'RD' %radial diffusivity
                            title([lowb{lb} '-' highb{hb} ' ' sprintf(['RD (' '\x03bc' 'm^2/ms)'])]);
                            ax2 = axes;

                            ForFig = ForFig*1e3;
                            imagesc(ax2,ForFig,'alphadata',M_myo,[0 2]); %sj
                            colormap(ax2,pf_colormap('tensor_mode'));
                            fname = fullfile(fname1,[mapnames{k} '_' lowb{lb} '_' highb{hb} '.png']);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'HA' %helix angle
                            title([lowb{lb} '-' highb{hb} ' Helix angle (°)']);
                            ax2 = axes;

                            imagesc(ax2,ForFig,'alphadata',M_myo,[-90 90]); %sj
                            colormap(ax2,pf_colormap('helix_angle'));
                            fname = fullfile(fname1,[mapnames{k} '_' lowb{lb} '_' highb{hb} '.png']);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'HA_filt' %filtered helix angle
                            title([lowb{lb} '-' highb{hb} ' Filtered Helix angle (°)']);
                            ax2 = axes;

                            imagesc(ax2,ForFig,'alphadata',M_myo,[-90 90]); %sj
                            colormap(ax2,pf_colormap('helix_angle'));
                            fname = fullfile(fname1,[mapnames{k} '_' lowb{lb} '_' highb{hb} '.png']);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'E2A' %absolute secondary eigenvector angle
                            title([lowb{lb} '-' highb{hb} ' Absolute E2 angle (°)']);
                            ax2 = axes;

                            ForFig = abs(ForFig);
                            imagesc(ax2,ForFig,'alphadata',M_myo,[0 90]); %sj
                            colormap(ax2,pf_colormap('abs_E2A'));
                            fname = fullfile(fname1,[mapnames{k} '_' lowb{lb} '_' highb{hb} '.png']);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'TRA' %transverse angle
                            title([lowb{lb} '-' highb{hb} ' Transverse angle (°)']);
                            ax2 = axes;
                            
                            imagesc(ax2,ForFig,'alphadata',M_myo,[-90 90]); %sj
                            colormap(ax2,pf_colormap('E1_TA'));
                            fname = fullfile(fname1,[mapnames{k} '_' lowb{lb} '_' highb{hb} '.png']);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'SA' %sheet angle
                            title([lowb{lb} '-' highb{hb} ' Sheet angle (°)']);
                            ax2 = axes;
                            
                            imagesc(ax2,ForFig,'alphadata',M_myo,[-90 90]); %sj
                            colormap(ax2,pf_colormap('E1_TA'));
                            fname = fullfile(fname1,[mapnames{k} '_' lowb{lb} '_' highb{hb} '.png']);
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        otherwise
                            fname = '';
                    end

                    colorbar;

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