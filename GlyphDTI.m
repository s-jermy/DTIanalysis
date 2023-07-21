function [figures] = GlyphDTI(tensor_dicom,map_dicom,contours,lowb_labels,highb_labels)

% in:
% tensor_dicom - struct containting tensors
% map_dicom - struct containing diffusion maps
% contours - struct containting contours
% lowb_labels - restrict output to specific low b-values - {} for no restriction
% highb_labels - restrict output to specific high b-values  - {} for no restriction
% 
% description:

fignum = 1;
figures = struct;
cardiacphases = fieldnames(tensor_dicom);

%% loop through different cardiac phases and slice locations
for i=1:length(cardiacphases)
    slicelocation = fieldnames(map_dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        TMPtensor = tensor_dicom.(cardiacphases{i}).(slicelocation{j});
        TMPmap = map_dicom.(cardiacphases{i}).(slicelocation{j});
        
        if isempty(TMPmap)||isempty(TMPtensor)
            continue
        end
        
        M_myo = contours.myoMask{j};
        M_myo = permute(repmat(M_myo,[1 1 3 3]),[3 4 1 2]); %rearrange array dimension to get 3x3xNxM
        
        mapnames = fieldnames(TMPmap);

        %% loop through applicable low and high b-values
        lowb = fieldnames(TMPtensor.tensor);
        for lb=1:length(lowb)
            if ~isempty(lowb_labels)
                if ~any(strcmp(lowb{lb},lowb_labels))
                    continue
                end
            end
            highb = fieldnames(TMPtensor.tensor.(lowb{lb}));
            for hb=1:length(highb)
                if ~isempty(highb_labels)
                    if ~any(strcmp(highb{hb},highb_labels))
                        continue
                    end
                end
                    
                tensor = TMPtensor.tensor.(lowb{lb}).(highb{hb});
                tensor = permute(tensor,[3 4 1 2]); %rearrange array dimension to get 3x3xNxM
                D = tensor.*M_myo;

                figure(fignum);
                ha = axes;
                plotDTI(ha,D,2,100);
                drawnow

                %% cycle through different maps you wish to use to colour the glyphs
                for k=1:length(mapnames)-1
                    map = TMPmap.(mapnames{k}).(lowb{lb}).(highb{hb});
                    switch mapnames{k}
                        % case 'MD' %mean diffusivity
                        %     cmap = 'MD';
                        %     lim = [0 2.5e-3];
                        % case 'FA' %fractional anisotropy
                        %     cmap = 'FA';
                        %     lim = [0 1];
                        % case 'AD' %axial diffusivity
                        %     cmap = 'tensor_mode';
                        %     lim = [0 3.5];
                        % case 'RD' %radial diffusivity
                        %     cmap = 'tensor_mode';
                        %     lim = [0 2];
                        % case 'HA' %helix angle
                        %     cmap = 'helix_angle';
                        %     lim = [-90 90];
                        case 'HA_filt' %filtered helix angle
                            cmap = 'helix_angle';
                            lim = [-90 90];
                        case 'E2A' %absolute secondary eigenvector angle
                            cmap = 'abs_E2A';
                            lim = [0 90];
                        % case 'TRA' %transverse angle
                        %     cmap = 'E1_TA';
                        %     lim = [-90 90];
                        % case 'SA' %sheet angle
                        %     cmap = 'E1_TA';
                        %     lim = [-90 90];
                        otherwise
                            map = [];
                            cmap = '';
                            lim = [];
                    end

                    if ~isempty(map) %don't do anything if there is no map
                        if fignum>1 %copy existing figure so as to not overwrite with new colormap
                            figure(fignum);
                            ax = axes;
                            copyobj(ha.Children,ax);
                            ha = ax;

                            axis equal
                            axis off
                        end
                        colormapDTI(ha,map,cmap,lim,2,100); %add colour to the glyphs based on map
                        drawnow;
                        hf{fignum} = figure(fignum);
                        hf{fignum}.Name = [mapnames{k} '_' lowb{lb} '_' highb{hb}]; %to save the figure later 
                        hf{fignum}.Tag = [cardiacphases{i} '_' slicelocation{j}];
                        fignum = fignum+1;
                    end
                end
            end
        end
    end
end

figures.hfig = hf;