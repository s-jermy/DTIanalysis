function GlyphDTI(tensor_dicom,map_dicom,contours,lowb_labels,highb_labels)

% in:
% tensor_dicom - struct containting tensors
% map_dicom - struct containing diffusion maps
% contours - struct containting contours
% lowb_labels - restrict output to specific low b-values - {} for no restriction
% highb_labels - restrict output to specific high b-values  - {} for no restriction
% 
% description:


cardiacphases = fieldnames(tensor_dicom);

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
                    
                    tensor = TMPtensor.tensor.(lowb{lb}).(highb{hb});
                    tensor = permute(tensor,[3 4 1 2]); %rearrange array dimension to get 3x3xNxM
                    map = TMPmap.(mapnames{k}).(lowb{lb}).(highb{hb});
                    switch mapnames{k}
%                         case 'MD' %mean diffusivity
%                             cm = 'MD';
%                             lim = [0 2.5e-3];
%                         case 'FA' %fractional anisotropy
%                             cm = 'FA';
%                             lim = [0 1];
%                         case 'AD' %axial diffusivity
%                             cm = 'tensor_mode';
%                             lim = [0 3.5];
%                         case 'RD' %radial diffusivity
%                             cm = 'tensor_mode';
%                             lim = [0 2];
%                         case 'HA' %helix angle
%                             cm = 'helix_angle';
%                             lim = [-90 90];
                        case 'HA_filt' %filtered helix angle
                            cm = 'helix_angle';
                            lim = [-90 90];
                        case 'E2A' %absolute secondary eigenvector angle
                            cm = 'abs_E2A';
                            lim = [0 90];
%                         case 'TRA' %transverse angle
%                             cm = 'E1_TA';
%                             lim = [-90 90];
%                         case 'SA' %sheet angle
%                             cm = 'E1_TA';
%                             lim = [-90 90];
                        otherwise
                            map = [];
                            cm = '';
                            lim = [];
                    end
                    
                    if ~isempty(map)
                        figure;
                        ha = axes;
                        D = tensor.*M_myo;
                        plotDTI(ha,D,2,100,map,cm,lim);
                    end
                end
            end
        end
    end
end