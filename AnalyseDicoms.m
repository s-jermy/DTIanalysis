function [dicom2, nfo] = AnalyseDicoms(dicom)
%     in:
%     dicom - unsorted structure containing diffusion images and info
% 
%     out:
%     dicom2 - sorted structure containing diffusion images
%     nfo - structure containing info about dicom images
% 
%     description:
%     separate images and info into individual structs. only keep important 
%     info about dicoms

dicom2 = [];
nfo.Info = [];

h = waitbar(0,'Analysing...');

warnedonce = false;

%% sort images into mag and phase images; and fix nominal interval

tempAT = fieldnames(dicom);
for i=1:length(tempAT)
    if length(tempAT{i})<14
        ATnum = tempAT{i}(3:end);
        newAT = ['AT0' ATnum];
        dicom.(newAT) = dicom.(tempAT{i});
        dicom = rmfield(dicom,tempAT{i});
    end
end

AcquisitionTimes = sort(fieldnames(dicom));

for i = 1:length(AcquisitionTimes)
    SeriesNos = fieldnames(orderfields(dicom.(AcquisitionTimes{i})));
    % assume magnitude always precedes phase
    
    dicom2(i).image = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).image;
    try
        dicom2(i).phaseimage = pi.*(dicom.(AcquisitionTimes{i}).(SeriesNos{2}).image./2048-1);
        % dicom2(i).compleximage = dicom2(i).image.*exp(1i.*dicom2(i).phaseimage); %do this later
    catch ME
        if warnedonce == false
            warning(ME.message);
            warnedonce=true;
        end
    end

    nfo.Info(i).fname = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Name;
    nfo.Info(i).SOPInstanceUID = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.SOPInstanceUID;
    nfo.Info(i).SeriesDescription = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.SeriesDescription;
    nfo.Info(i).SequenceName = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.SequenceName;
    nfo.Info(i).TriggerTime = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.TriggerTime;
    nfo.Info(i).NominalInterval = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.NominalInterval;
    nfo.Info(i).B_value = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.B_value;
    nfo.Info(i).SeriesNumber = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.SeriesNumber;
    nfo.Info(i).SliceLocation = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.SliceLocation;
    nfo.Info(i).WindowCenter = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.WindowCenter;
    nfo.Info(i).WindowWidth = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.WindowWidth;
    nfo.Info(i).AcqTime = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.AcqTime;
    nfo.Info(i).DiffDirVec = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.DiffDirVec;
    nfo.Info(i).InstanceNumber = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.InstanceNumber;
    if i==1
        nfo.PatientID = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.PatientID;
        nfo.ST = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.SliceThickness;
        nfo.TR = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.RepetitionTime;
        nfo.TE(1) = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.EchoTime(1);
        nfo.MagneticFieldStrength = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.MagneticFieldStrength;
        nfo.PixelSpacing = dicom.(AcquisitionTimes{i}).(SeriesNos{1}).Info.PixelSpacing;
    end
    waitbar(i/length(AcquisitionTimes),h);
end
close(h);

h = waitbar(0,'Fixing nominal intervals...');
if nfo.TE < 30
    AcqDiffToms = 500; % 2RR intervals in s to one RR in ms
else
    AcqDiffToms = 1000;% 1 RR interval in s to one RR in ms
end
% try copying nominal intervals from non-empty neighbours
for i = 1:length(AcquisitionTimes)
    if nfo.Info(i).NominalInterval == 0
        if nfo.Info(i).InstanceNumber == 1
            if nfo.Info(i+1).NominalInterval == 0
                nfo.Info(i).NominalInterval = AcqDiffToms*seconds(nfo.Info(i+1).AcqTime-nfo.Info(i).AcqTime); 
            else
                nfo.Info(i).NominalInterval = nfo.Info(i+1).NominalInterval;
            end
        else
            nfo.Info(i).NominalInterval = AcqDiffToms*seconds(nfo.Info(i).AcqTime-nfo.Info(i-1).AcqTime); 
        end
    end
    waitbar(i/length(AcquisitionTimes),h);
end

close(h);

end

%%
%{
function nfo2 = fixNominalInterval(nfo)
% in:
% nfo - structure containing info about dicom images
% 
% out:
% nfo2 - structure containing info about dicom images with fixed nominal
%           interval
% 
% description:
% fix missing nominal interval info. either replace with the median nominal
% interval or assume hr of 60bpm

nfo2 = nfo;

NomIntervals = arrayfun(@(x) x.NominalInterval,nfo2); %sj - get all nominal intervals from dicoms
nzNomIntervals = NomIntervals(NomIntervals ~= 0); %sj - find non-zero intervals
zNomIntervals = find(NomIntervals == 0); %sj - find zero intervals

if ~isempty(zNomIntervals) && ~isempty(nzNomIntervals)
    replaceNomInterval = median(nzNomIntervals); %sj - median nomint
elseif isempty(nzNomIntervals)
    replaceNomInterval = 1000; % sj - assume 60bpm - maybe not always valid?
    warning('can''t fix nominal interval of 0, assumptions violated, Liz needs to look at this');
end

for i=1:size(zNomIntervals,2)
    nfo2(zNomIntervals(i)).NominalInterval = replaceNomInterval;
end

end
%}