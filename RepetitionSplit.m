function [split_dicom,split_nfo] = RepetitionSplit(dicom,nfo)
% in:
% dicom - structure containing diffusion images
% nfo - structure containing info about dicom images
% 
% out:
% split_dicom - structure containing snr estimates
% 
% description:
% 

split_dicom = [];
split_nfo = nfo;

cardiacphases = fieldnames(dicom);

for i=1:length(cardiacphases)
    slicelocation = fieldnames(dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        SliceData = dicom.(cardiacphases{i}).(slicelocation{j}).SliceData;
        SliceInfo = nfo{j}.SliceInfo;

        bVal = [SliceInfo.B_value];
        [ub,iab,icb] = unique(bVal);

        for k=1:length(iab)
            [reps,iar,icr] = unique({SliceInfo(icb==k).SequenceName});
            for l=1:length(iar)
                c
            end
        end
    end
end

end