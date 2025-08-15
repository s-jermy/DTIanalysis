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
numpoints = 100; %sj - number of points in glyph (+1)
figures = struct;
hf = {};
cardiacphases = fieldnames(tensor_dicom);

if ~tog_cmap
    cmap = "turbo";
    %cmap = other_colormap("inferno");
end

%% loop through different cardiac phases and slice locations
for i=1:length(cardiacphases)
    slicelocation = fieldnames(map_dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        skipcopy = 1; %reset each time there is a new slice location/cardiac phase
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

                figure(fignum);
                ax1 = axes; %create separate axis for base trace image
                imagesc(imresize(under,delta));axis equal off;colormap(ax1,'gray'); %scale up trace image to match glyph spacing
                ax2 = axes; %second axis for DTI glyphs
                plotDTI(ax2,D,delta,numpoints);drawnow;
                linkprop([ax1 ax2],{'YDir'}); %base image has reversed Y-direction, copy to glyph axis
                linkprop([ax1 ax2],{'XLim','YLim'}); %link glyph axis limits to base image

                %% cycle through different maps you wish to use to colour the glyphs
                for k=1:length(mapnames)-1
                    map = TMPmap.(mapnames{k}).(lowb{lb}).(highb{hb});
                    switch mapnames{k}
                        % case 'MD' %mean diffusivity
                        %     if tog_cmap
                        %         cmap = "hot";
                        %         %cmap = other_colormap('pf_MD');
                        %     end
                        %     lim = [0 2.5e-3];
                        % case 'FA' %fractional anisotropy
                        %     if tog_cmap
                        %         cmap = brewermap([],"-RdYlGn");
                        %         %cmap = other_colormap('pf_FA');
                        %     end
                        %     lim = [0 1];
                        % case 'AD' %axial diffusivity
                        %     if tog_cmap
                        %         cmap = other_colormap('pf_tensor_mode');
                        %     end
                        %     lim = [0 3.5e-3];
                        % case 'RD' %radial diffusivity
                        %     if tog_cmap
                        %         cmap = other_colormap('pf_tensor_mode');
                        %     end
                        %     lim = [0 2e-3];
                        % case 'HA' %helix angle
                        %     if tog_cmap
                        %         cmap = other_colormap('pf_helix_angle');
                        %     end
                        %     lim = [-60 60];
                        case 'HA_filt' %filtered helix angle
                            lim = [-60 60];
                            cmap = "turbo";
                            if tog_cmap
                                cmap = other_colormap('pf_helix_angle');
                            end
                        case 'E2A' %absolute secondary eigenvector angle
                            map = abs(map);
                            lim = [0 90];
                            cmap = brewermap([],"-RdBu");
                            if tog_cmap
                                cmap = brewermap([],"-RdBu");
                                %cmap = other_colormap('pf_abs_E2A');
                            end
                        % case 'TRA' %transverse angle
                        %     if tog_cmap
                        %         cmap = other_colormap('pf_E1_TA');
                        %     end
                        %     lim = [-90 90];
                        % case 'SA' %sheet angle
                        %     if tog_cmap
                        %         cmap = other_colormap('pf_E1_TA');
                        %     end
                        %     lim = [-90 90];
                        otherwise
                            map = [];
                            cmap = '';
                            lim = [];
                    end

                    if ~isempty(map) %don't do anything if there is no map
                        if ~skipcopy
                            figure(fignum);ax1 = axes;
                            imagesc(imresize(under,delta));axis equal off;colormap(ax1,'gray');
                            axtemp = axes;
                            copyobj(ax2.Children,axtemp);drawnow; %copy existing figure so as to not overwrite with new colormap
                            axis equal off;ax2 = axtemp;
                            linkprop([ax1 ax2],{'YDir'});
                            linkprop([ax2 ax1],{'XLim','YLim'});
                        end
                        colormapDTI(ax2,map,cmap,lim,delta,numpoints);drawnow; %add colour to the glyphs based on map
                        hf{j}{mapnum} = figure(fignum);
                        hf{j}{mapnum}.Name = [mapnames{k} '_' lowb{lb} '_' highb{hb}]; %to save the figure later 
                        hf{j}{mapnum}.Tag = [cardiacphases{i} '_' slicelocation{j}];
                        hf{j}{mapnum}.UserData = delta*(P-1);
                        fignum = fignum+1;
                        mapnum = mapnum+1;
                        skipcopy = 0;
                    end
                end
            end
        end
    end
end

if ~isempty(hf)
    figures.hfig = hf;
end