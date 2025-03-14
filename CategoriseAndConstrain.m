function [dicom2,nfo2,contours2] = CategoriseAndConstrain(dicom,nfo,contours,varargin)
% in:
% dicom - structure containing diffusion images
% nfo - structure containing info about dicom images
% 
% out:
% dicom2 - sorted structure containing diffusion images
% nfo2 - sorted structure containing info about dicom images
% contours - structure containting contours
% 
% description:
% sort structs by cardiac phase and slice location and then define an roi
% around the heart to constrain the registration

dicom2 = {};
nfo2 = {};
contours2 = contours;
refBVal = [];

if mod(numel(varargin), 2) ~= 0
    error('Arguments must be provided in key-value pairs.');
end

for i = 1:2:numel(varargin)
    key = varargin{i};
    value = varargin{i+1};

    switch key
        case 'RefLowB'
            refBVal = value;
        otherwise
            warning('Unknown parameter: %s', key);
    end
end

if isempty(refBVal)
    refBVal = 0;
end

SliceLocations = arrayfun(@(x) x.SliceLocation,nfo.Info);
CardiacPhases = arrayfun(@(x) x.TriggerTime,nfo.Info);

uSl = unique(SliceLocations);
uCp = unique(CardiacPhases);
ST = nfo.ST;

numCP = length(uCp);
if numCP > 1
    for i=1:numCP-1
        for j=i+1:numCP
            if abs(uCp(j)-uCp(i)) < 15
                CardiacPhases(CardiacPhases == uCp(j)) = uCp(i);
                uCp(j) = uCp(i);
            end
        end
    end
end

numSL = length(uSl);
if numSL > 1
    for i=1:numSL-1
        for j=i+1:numSL
            if abs(uSl(j)-uSl(i)) < ST/2
                SliceLocations(SliceLocations == uSl(j)) = uSl(i);
                uSl(j) = uSl(i);
            end
        end
    end
end
% SlCp = SliceLocations.*CardiacPhases; % ensures uniqueness (if all slices are parallel....)
clear uSl uCp
% [uSlCp1,~,uSlCp3] = unique(SlCp);

[uCp1,~,uCp3] = unique(CardiacPhases);
[uSl1,~,uSl3] = unique(SliceLocations);

if length(uCp1)>1
    error('sj - more than one unique cardiac phase');
end

ind = 0;

[dur,dur_corr,gap] = calcDuration(nfo);

%% Categorise
for i = 1:length(uCp1)
    for j = 1:length(uSl1)
        ind = ind+1;
        
        dicom2{ind} = dicom(uCp3==i & uSl3==j);
        nfo2{ind}.Info = nfo.Info(uCp3==i & uSl3==j);
        % extract series name
        SDs = {nfo2{ind}.Info.SeriesDescription};
        SDu = unique(SDs);
        common = find(~all(diff(char(SDu(:)))==0,1),1,'first');
        if isempty(common)
            SeriesDescription = SDu{1};
        else
            SeriesDescription = SDu{1}(1:common-1);
        end
        nfo2{ind}.SeriesDescription = [SeriesDescription num2str(ind)];
        clear SDu common SDs

        nfo2{ind}.contoursDefined = 0;
        nfo2{ind}.registrationComplete = 0;
        nfo2{ind}.PatientID = nfo.PatientID;
        nfo2{ind}.ST = nfo.ST;
        nfo2{ind}.TR = nfo.TR;
        nfo2{ind}.TE = nfo.TE;
        nfo2{ind}.MagneticFieldStrength = nfo.MagneticFieldStrength;
        nfo2{ind}.PixelSpacing = nfo.PixelSpacing;
        nfo2{ind}.TotalDuration = dur; % NOTE:not per slice (whole acquisition)
        nfo2{ind}.TotalDuration_corr = dur_corr; % duration without outlying gaps
        nfo2{ind}.TotalGaps = gap; %duration of gaps without outliers
    
        %new logic for multiple b-values
        [uBVal,~,uBV2] = unique(arrayfun(@(x) x.B_value,nfo2{ind}.Info));
        if refBVal==0||refBVal==15
            idx = uBVal==0;
            if ~any(idx)
                idx = uBVal==15;
            end
        else
            idx = uBVal==refBVal;
        end
        if ~any(idx)
            idx = 1;
        end
        fixedImages = dicom2{ind}(uBV2==find(idx)); % find all lowB fixed images
        fixedInfo = nfo2{ind}.Info(uBV2==find(idx));
    
        if (length(dicom2{i})>=7)
            if mean([fixedInfo.TriggerTime]) >= 500
                nfo2{ind}.CardiacPhase = 'Diastole';
            else
                nfo2{ind}.CardiacPhase = 'Systole';
            end
            nfo2{ind}.SliceLocation = fixedInfo(1).SliceLocation;
            nfo2{ind}.FilesToUse = ones(size(nfo2{ind}.Info)); %at first assume all files will be used, this will be updated after RejectImages

            %% Constrain
            % Draw ROI, or load previously drawn ROI
            ima = single(mean(cat(3,fixedImages.image),3)); %naively average all images together, not keeping this info
            %ima = single(dicom2{ind}(fixedImage(1)).image);
            try
                WC = mean([fixedInfo.WindowCenter]);
                WW = mean([fixedInfo.WindowWidth]);
                low = WC-.5 - (WW-1)/2; high = WC-.5 + (WW-1)/2; % for mag image
                ima(ima<=low) = 0; ima(ima>high) = 255;
                ima = ((ima-(WC-.5))/(WW-1)+.5)*255;
            catch
            end

            roifig = figure;clf;
            imagesc(uint8(ima));colormap("gray");axis off;axis equal;
            roifig.Name = 'Drag a rectangle around heart to constrain registration';	%sj - I added an extra roi here - just a rectangle to roughly cover whole heart - to constrain registration - don't make too small

            try
                vert = contours.rec{ind};
                xs=vert(:,1);
                ys=vert(:,2);
                posn = [min(xs) min(ys) max(xs)-min(xs) max(ys)-min(ys)];
                recRoi = drawrectangle('Color',[0 0 1],'Position',posn);
                recRoi.InteractionsAllowed = 'none';
                recRoi.Label = 'Done';pause(1);
            catch
                recRoi = drawrectangle('Color',[0 0 1]);
                recRoi.InteractionsAllowed = 'all';
                set(roifig, 'KeyPressFcn',@(src,event) customWait(event,recRoi));
                recRoi.Label = 'Enter key to finish'; uiwait;
                recRoi.Label = 'Done';
            end
            tempRec = floor(recRoi.Vertices); %sj
            % recRoi.delete(); %sj

            rec{ind} = tempRec; %sj

            
            % sj - the rest of the contours will be defined later

            close(roifig);
        end
    end
end

contours2.rec = rec; %sj

end