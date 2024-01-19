function [dicom2,nfo2,contours] = CategoriseAndConstrain(dicom,nfo)
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
contours = {};

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

ind = 0;

[dur,dur_corr] = calcDuration(nfo);

%% Categorise
for i = 1:length(uCp1)
    for j = 1:length(uSl1)
        ind = ind+1;
        
        dicom2{ind} = dicom(uCp3==i & uSl3==j);
        nfo2{ind}.Info = nfo.Info(uCp3==i & uSl3==j);
        % extract modal series name
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
    
        %new logic for multiple b-values
        [~,uBV1,~] = unique(arrayfun(@(x) x.B_value,nfo2{ind}.Info));
        fixedImage = uBV1(2); % find first b50 image, change to 1 for b0, 3 for b350, etc
%         fixedImage = uBV1(1); % for b0
    
        if (length(dicom2{i})>=7)
            if (nfo2{ind}.Info(fixedImage).TriggerTime >= 500)
                nfo2{ind}.CardiacPhase = 'Diastole';
            else
                nfo2{ind}.CardiacPhase = 'Systole';
            end
            nfo2{ind}.SliceLocation = nfo2{ind}.Info(fixedImage).SliceLocation;

            %% Constrain
            % Draw ROI, or load previously drawn ROI
            ima = single(dicom2{ind}(fixedImage).image);
            try
                WC = nfo2{ind}.Info(fixedImage).WindowCenter;
                WW = nfo2{ind}.Info(fixedImage).WindowWidth;
                low = WC-.5 - (WW-1)/2; high = WC-.5 + (WW-1)/2; % for mag image
                ima(ima<=low) = 0; ima(ima>high) = 255;
                ima = ((ima-(WC-.5))/(WW-1)+.5)*255;
            catch
            end
            roifig = figure;clf;
            imshow(uint8(ima),[]);

            roifig.Name = 'Drag a rectangle around heart to constrain registration';	%sj - I added an extra roi here - just a rectangle to roughly cover whole heart - to constrain registration - don't make too small
            recRoi = drawrectangle('Color',[0 0 1]);customWait(recRoi);
            recRoi.Label = 'Done';
            tempRec = floor(recRoi.Vertices); %sj
    %         recRoi.delete(); %sj

            rec{ind} = tempRec; %sj
            % sj - the rest of the contours will be defined later

            close(roifig);
        end
    end
end

contours.rec = rec; %sj

end