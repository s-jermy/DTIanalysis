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

%% Categorise
for i = 1:length(uCp1)
    for j = 1:length(uSl1)
        ind = ind+1;
        
        dicom2{ind} = dicom(uCp3==i & uSl3==j);
        nfo2{ind}.Info = nfo.Info(uCp3==i & uSl3==j);
        nfo2{ind}.contoursDefined = 0;
        nfo2{ind}.registrationComplete = 0;
        nfo2{ind}.PatientID = nfo.PatientID;
        nfo2{ind}.ST = nfo.ST;
        nfo2{ind}.TR = nfo.TR;
        nfo2{ind}.TE = nfo.TE;
        nfo2{ind}.MagneticFieldStrength = nfo.MagneticFieldStrength;
        nfo2{ind}.PixelSpacing = nfo.PixelSpacing;
    
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
            try
                WC = nfo2{ind}.Info(fixedImage).WindowCenter;
                hWW = nfo2{ind}.Info(fixedImage).WindowWidth/2;
                roifig = figure;clf;
                imshow(dicom2{ind}(fixedImage).image,[(WC-hWW) (WC+hWW)]);
            catch
                roifig = figure;clf;
                imshow(dicom2{ind}(fixedImage).image,[]);
            end

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