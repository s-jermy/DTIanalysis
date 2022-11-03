function [dicom2,nfo2] = CleanStruct(dicom,nfo,figures,slice_loc)
% in:
% dicom - structure containing diffusion images
% nfo - structure containing info about dicom images
% figures - reject image figures
% slice_loc - slice locations
% 
% out:
% dicom2 - clean structure containing diffusion images
% nfo2 - clean structure containing info about dicom images
% 
% description:
% separate the images we want to keep from the ones we don't

nfo2 = nfo;
for i=1:length(dicom)
    FilesToUse = [];
    UIDList = arrayfun(@(x) x.SOPInstanceUID,nfo{i}.Info,'UniformOutput',false);
    UIDSelected = cellfun(@(x) [x(isempty(x.UserData)).Tag ''],cat(2,figures.himage{i}{:}),'UniformOutput',false);
    UIDSelected = UIDSelected(cellfun(@(x) ~isempty(x),UIDSelected));
    if ~isempty(UIDSelected)
        for j=1:length(UIDList)
            FilesToUse(j) = max(strcmp(UIDList{j},UIDSelected));
        end
        FilesToUse = logical(FilesToUse);
    end
    dicom2.(nfo2{i}.CardiacPhase).(slice_loc{i}).AllData = dicom{i};
    dicom2.(nfo2{i}.CardiacPhase).(slice_loc{i}).SliceData = dicom{i}(FilesToUse);
    nfo2{i}.SliceInfo = nfo{i}.Info(FilesToUse);
    nfo2{i}.FilesToUse = FilesToUse;
end

end