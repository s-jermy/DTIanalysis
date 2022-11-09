function savePNGs(map_dicom,trace,contours,saveDir,patID,lowb_labels,highb_labels)
% in:
% map_dicom - struct containing diffusion maps
% trace - struct containing average image for each b-value
% contours - struct containting contours
% saveDir - save directory for current subject
% lowb_labels - restrict output to specific low b-values - {} for no restriction
% highb_labels - restrict output to specific high b-values  - {} for no restriction
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

        M_myo = trace{1}{1}>10;%1;%contours.myoMask{j};
        under = trace{j}{1};
    
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
                    fname = fullfile(fname1,[mapnames{k} '_' lowb{lb} '_' highb{hb} '_' patID '.png']);
                    switch mapnames{k}
                        case 'MD' %mean diffusivity
                            title([lowb{lb} '-' highb{hb} ' ' sprintf(['MD (' '\x03bc' 'm^2/ms)'])]);
                            ax2 = axes;

                            ForFig = ForFig*1e3;
                            imagesc(ax2,ForFig,'alphadata',M_myo,[0 2.5]); %sj
                            colormap(ax2,pf_colormap('MD'));
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'FA' %fractional anisotropy
                            title([lowb{lb} '-' highb{hb} ' FA']);
                            ax2 = axes;

                            imagesc(ax2,ForFig,'alphadata',M_myo,[0 1]); %sj
                            colormap(ax2,pf_colormap('FA'));
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'AD' %axial diffusivity
                            title([lowb{lb} '-' highb{hb} ' ' sprintf(['AD (' '\x03bc' 'm^2/ms)'])]);
                            ax2 = axes;

                            ForFig = ForFig*1e3;
                            imagesc(ax2,ForFig,'alphadata',M_myo,[0 3.5]); %sj
                            colormap(ax2,pf_colormap('tensor_mode'));
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'RD' %radial diffusivity
                            title([lowb{lb} '-' highb{hb} ' ' sprintf(['RD (' '\x03bc' 'm^2/ms)'])]);
                            ax2 = axes;

                            ForFig = ForFig*1e3;
                            imagesc(ax2,ForFig,'alphadata',M_myo,[0 2]); %sj
                            colormap(ax2,pf_colormap('tensor_mode'));
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'HA' %helix angle
                            title([lowb{lb} '-' highb{hb} ' Helix angle (°)']);
                            ax2 = axes;

                            imagesc(ax2,ForFig,'alphadata',M_myo,[-90 90]); %sj
                            colormap(ax2,pf_colormap('helix_angle'));
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                            hold on; plot(contours.endo{1}(:,1),contours.endo{1}(:,2),'r-');
                            plot(contours.epi{1}(:,1),contours.epi{1}(:,2),'r-');
                            plot(contours.rvi{1}(1),contours.rvi{1}(2),'rx');
                        case 'HA_filt' %filtered helix angle
                            title([lowb{lb} '-' highb{hb} ' Filtered Helix angle (°)']);
                            ax2 = axes;

                            imagesc(ax2,ForFig,'alphadata',M_myo,[-90 90]); %sj
                            colormap(ax2,pf_colormap('helix_angle'));
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'E2A' %absolute secondary eigenvector angle
                            title([lowb{lb} '-' highb{hb} ' Absolute E2 angle (°)']);
                            ax2 = axes;

                            ForFig = abs(ForFig);
                            imagesc(ax2,ForFig,'alphadata',M_myo,[0 90]); %sj
                            colormap(ax2,pf_colormap('abs_E2A'));
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'TRA' %transverse angle
                            title([lowb{lb} '-' highb{hb} ' Transverse angle (°)']);
                            ax2 = axes;
                            
                            imagesc(ax2,ForFig,'alphadata',M_myo,[-90 90]); %sj
                            colormap(ax2,pf_colormap('E1_TA'));
                            ax2.Visible = 'off'; linkprop([ax1 ax2],'Position');
                        case 'SA' %sheet angle
                            title([lowb{lb} '-' highb{hb} ' Sheet angle (°)']);
                            ax2 = axes;
                            
                            imagesc(ax2,ForFig,'alphadata',M_myo,[-90 90]); %sj
                            colormap(ax2,pf_colormap('E1_TA'));
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