function [dicom2,nfo2,FilesToUse] = CleanStruct(dicom,nfo,figures,slice_loc)
% in:
% dicom - structure containing diffusion images
% nfo - structure containing info about dicom images
% figures - reject image figures
% slice_loc - slice locations
% 
% out:
% dicom2 - clean structure containing diffusion images
% nfo2 - clean structure containing info about dicom images
% dicom - original structure containing diffusion images (not used)
% nfo - updated original structure containing info about dicom images
% 
% description:
% separate the images we want to keep from the ones we don't

nfo2 = nfo;
FilesToUse = {};
for i=1:length(dicom)
    tempFTU = [];
    UIDList = arrayfun(@(x) x.SOPInstanceUID,nfo{i}.Info,'UniformOutput',false);
    UIDSelected = cellfun(@(x) [x(isempty(x.UserData)).Tag ''],cat(2,figures.himage{i}{:}),'UniformOutput',false);
    UIDSelected = UIDSelected(cellfun(@(x) ~isempty(x),UIDSelected));
    if ~isempty(UIDSelected)
        for j=1:length(UIDList)
            tempFTU(j) = max(strcmp(UIDList{j},UIDSelected));
        end
        tempFTU = logical(tempFTU);
    end
    dicom2.(nfo2{i}.CardiacPhase).(slice_loc{i}).AllData = dicom{i};
    dicom2.(nfo2{i}.CardiacPhase).(slice_loc{i}).SliceData = dicom{i}(tempFTU);
    nfo2{i}.SliceInfo = nfo{i}.Info(tempFTU);
    % update FilesToUse in CleanInfo
    nfo2{i}.FilesToUse = tempFTU;
    FilesToUse{i} = tempFTU;
end

end