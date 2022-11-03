function [dicom] = LoadDicom(dirlisting)
% in:
% dirlisting - list of diffusion images files
%
% out:
% dicom - structure containing diffusion images
% 
% description:
% load all valid dicom files from the chosen directory

dicom = [];
uint8_flag = false;

%%
h = waitbar(0,'Loading...');

notdir = arrayfun(@(x) ~x.isdir,dirlisting);
dirlisting = dirlisting(notdir); %remove folders

ext = arrayfun(@(x) lower(x.name(end-2:end)),dirlisting,'UniformOutput',false);
valid = cellfun(@(x) all(x=='ima'|x=='dcm'),ext);
dirlisting = dirlisting(valid); %remove non-dicom files

for j=1:length(dirlisting)
    try
        dcmInfo = dicominfo(fullfile(dirlisting(j).folder,dirlisting(j).name));
    catch
        fprintf('%s is not a dicom file\n',dirlisting(j).name); %hopefully this shouldn't happen
        continue
    end
    
    if isfield(dcmInfo,'DiffusionDirectionality') || strcmp(dcmInfo.ImageType,'DERIVED\SECONDARY\OTHER')
        uint8_flag = isa(dcmInfo.DiffusionDirectionality,'uint8'); %some dicom data from Zak is formatted as hex
        
        TMPacq = dcmInfo.AcquisitionTime;
        acq = insertAfter(TMPacq,4,':');   acq = insertAfter(acq,2,':'); %change acquisition time to duration format
        dcmInfo.AcqTime = duration(acq,'InputFormat','hh:mm:ss.SSSSSS','Format','hh:mm:ss.SSSS');
        
        TMPsn = dcmInfo.SeriesNumber;
        
        dicom.(sprintf('AT%.0f',str2double(TMPacq)*1e6)).(sprintf('SN%04d',TMPsn)).Name = dirlisting(j).name;
        % done in AnalyseDicoms
%         TMPInfo.NomInt = dcmInfo.NominalInterval;
%         TMPInfo.SliceLoc = dcmInfo.SliceLocation;
%         TMPInfo.TrigTime = dcmInfo.TriggerTime;
%         TMPInfo.WinCenter = dcmInfo.WindowCenter;
%         TMPInfo.halfWinWidth = dcmInfo.WindowWidth/2;
        
%         sinfo = SiemensInfo(dcmInfo);
%         TMPInfo.TrigDelay = sinfo.sPhysioImaging.sPhysioECG.lTriggerDelay;
%         TMPInfo.ScanWindow = sinfo.sPhysioImaging.sPhysioECG.lScanWindow;
        
%         TMPInfo.TR = dcmInfo.RepetitionTime;
%         TMPInfo.TE = dcmInfo.EchoTime;
%         TMPInfo.PS = dcmInfo.PixelSpacing;
%         TMPInfo.ST = dcmInfo.SliceThickness;

        orient = dcmInfo.ImageOrientationPatient;
        or_row = orient(1:3)';
        or_col = orient(4:6)';
        or_thru = cross(or_row,or_col);
        
        if uint8_flag %fix uint8 by casting them to charstr or doubles
            dcmInfo.DiffusionDirectionality = strtrim(char(dcmInfo.DiffusionDirectionality)');
            dcmInfo.B_value = sscanf(char(dcmInfo.B_value),'%d');
            if isfield(dcmInfo,'DiffusionGradientDirection')
                for dd=1:3
                    temp(dd) = typecast(dcmInfo.DiffusionGradientDirection(8*(dd-1)+1:8*dd),'double');
                end
                dcmInfo.DiffusionGradientDirection = temp';
            end
        end
        
        if (strcmp(dcmInfo.DiffusionDirectionality,'NONE') || strcmp(dcmInfo.SequenceName,'ep_b0') || strcmp(dcmInfo.SequenceName,'ep_b15#1'))
            dcmInfo.B_value = 15;
            dcmInfo.DiffDirVec = [0 0 0];
        else %b>0
            if (strcmp(dcmInfo.DiffusionDirectionality,'DIRECTIONAL') && isfield(dcmInfo,'DiffusionGradientDirection'))
                dcmInfo.DiffDirVec = ([or_row;or_col;or_thru] * dcmInfo.DiffusionGradientDirection)';
            else
                dcmInfo.DiffDirVec = [0 0 0];
            end
        end
        
        dicom.(sprintf('AT%.0f',str2double(TMPacq)*1e6)).(sprintf('SN%04d',TMPsn)).Info = dcmInfo;
        
%         if dcmInfo.Rows > dcmInfo.Columns % WARNING: This is commented out for a reason, messes up angle calculations
%             dicom.(sprintf('AT%.0f',str2double(TMPacq)*1e6)).(sprintf('SN%04d',TMPsn)).image = double(rot90(dicomread(dcmInfo),-1));
%         else
            dicom.(sprintf('AT%.0f',str2double(TMPacq)*1e6)).(sprintf('SN%04d',TMPsn)).image = double(dicomread(dcmInfo));
%         end
    end
    waitbar(j/length(dirlisting),h);
end

close(h);
end
