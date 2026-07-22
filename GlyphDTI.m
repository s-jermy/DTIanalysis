function [figures] = GlyphDTI(tensor_dicom,map_dicom,nfo,contours,trace,varargin)

% out:
% figures - struct containing the glyph figures generated
% 
% in:
% tensor_dicom - struct containing tensors
% map_dicom - struct containing diffusion maps
% contours - struct containting contours
% varargin:
% lowb_labels - restrict output to specific low b-values - {} for no restriction
% highb_labels - restrict output to specific high b-values  - {} for no restriction
% 
% description:

lowb_labels = {};
highb_labels = {};
tog_cmap = 0;
lowb_ref = [];
line_axis = 0;

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
        case 'ColourMap'
            tog_cmap = value;
        otherwise
            error('Unknown parameter: %s', key);
    end
end

if isempty(lowb_ref)
    lowb_ref = 50;
end

fignum = 1;
delta = 2; %sj - distance between glyphs
numpoints = 25; %sj - number of points in glyph (+1)
figures = struct;
hf = {};
cardiacphases = fieldnames(tensor_dicom);

cmap = "turbo";

%% loop through different cardiac phases and slice locations
for i=1:length(cardiacphases)
    slicelocation = fieldnames(map_dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        mapnum = 1;
        TMPtensor = tensor_dicom.(cardiacphases{i}).(slicelocation{j});
        TMPmap = map_dicom.(cardiacphases{i}).(slicelocation{j});
        SliceInfo = nfo{j}.SliceInfo;
        
        if isempty(TMPmap)||isempty(TMPtensor)
            continue
        end
        
        M_myo = contours.myoMask{j};
        M_myo_glyph = permute(repmat(M_myo,[1 1 3 3]),[3 4 1 2]); %rearrange array dimension to get 3x3xNxM
        
        B_values = arrayfun(@(x) x.B_value,SliceInfo);
        uBVal = unique(B_values);
        idx = uBVal==lowb_ref;
        if ~any(idx)
            idx = 1;
        end
        refTo = find(idx);
        under = trace{j}{refTo(1)}; %ref trace image used as base image
        
        P = prctile([contours.epi{j};contours.endo{j}],[0 25 50 75 100],1); %calculate percentiles of epi and endo

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
                D = tensor.*M_myo_glyph;

                %% cycle through different maps you wish to use to colour the glyphs
                for k=1:length(mapnames)-1
                    map = TMPmap.(mapnames{k}).(lowb{lb}).(highb{hb});
                    switch mapnames{k}
                        % case 'MD' %mean diffusivity
                        %     lim = [0 2.5e-3];
                        %     if tog_cmap
                        %         cmap = "hot";
                        %         %cmap = other_colormap('pf_MD');
                        %     end
                        % case 'FA' %fractional anisotropy
                        %     lim = [0 1];
                        %     if tog_cmap
                        %         cmap = brewermap([],"-RdYlGn");
                        %         %cmap = other_colormap('pf_FA');
                        %     end
                        % case 'AD' %axial diffusivity
                        %     lim = [0 3.5e-3];
                        %     if tog_cmap
                        %         cmap = other_colormap('pf_tensor_mode');
                        %     end
                        % case 'RD' %radial diffusivity
                        %     lim = [0 2e-3];
                        %     if tog_cmap
                        %         cmap = other_colormap('pf_tensor_mode');
                        %     end
                        % case 'HA' %helix angle
                        %    lim = [-60 60];
                        %    line_axis = 3;
                        %     if tog_cmap
                        %         cmap = other_colormap('pf_helix_angle');
                        %     end
                        case 'HA_filt' %filtered helix angle
                            lim = [-60 60];
                            line_axis = 3;
                            cmap = "turbo";
                            if tog_cmap
                                cmap = other_colormap('pf_helix_angle');
                            end
                        case 'E2A' %absolute secondary eigenvector angle
                            map = abs(map);
                            line_axis = 2;
                            lim = [0 90];
                            cmap = brewermap([],"-RdBu");
                            if tog_cmap
                                cmap = other_colormap('pf_abs_E2A');
                            end
                        % case 'TRA' %transverse angle
                        %     lim = [-90 90];
                        %     line_axis = 3;
                        %     if tog_cmap
                        %         cmap = other_colormap('pf_E1_TA');
                        %     end
                        % case 'SA' %sheet angle
                        %     lim = [-90 90];
                        %     line_axis = 2;
                        %     if tog_cmap
                        %         cmap = other_colormap('pf_E1_TA');
                        %     end
                        otherwise
                            map = [];
                            cmap = '';
                            lim = [];
                    end

                    if ~isempty(map) %don't do anything if there is no map
                        figure(fignum);
                        ax1 = axes; %create separate axis for base trace image
                        imagesc(imresize(under,delta));axis equal off;colormap(ax1,'gray');drawnow; %scale up trace image to match glyph spacing
                        ax2 = axes; %second axis for DTI glyphs
                        plotDTI(D,map,ax2,'Delta',delta,'NumPoints',numpoints,'Axis',line_axis,'ColourMap',cmap,'CLim',lim);drawnow;axis equal off;

                        linkprop([ax1 ax2],{'YDir'}); %base image has reversed Y-direction, copy to glyph axis
                        linkprop([ax1 ax2],{'XLim','YLim'});drawnow; %link glyph axis limits to base image

                        % --- Improve glyph shape perception with lighting ---
                        lighting(ax2,'gouraud');        % smooth shaded lighting (best for curved glyphs)
                        material(ax2,'dull');   % avoids specular glare that distorts colour
                        
                        %axis(ax2,'vis3d');              % preserve 3D aspect during camera moves

                        hf{j}{mapnum} = figure(fignum);
                        hf{j}{mapnum}.Name = [mapnames{k} '_' lowb{lb} '_' highb{hb}]; %to save the figure later 
                        hf{j}{mapnum}.Tag = [cardiacphases{i} '_' slicelocation{j}];
                        hf{j}{mapnum}.UserData = delta*(P-1);
                        fignum = fignum+1;
                        mapnum = mapnum+1;
                    end
                end
            end
        end
    end
end

if ~isempty(hf)
    figures.hfig = hf;
end