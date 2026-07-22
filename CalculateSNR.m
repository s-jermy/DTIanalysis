function [snr_dicom] = CalculateSNR(dicom,nfo,contours)
% in:
% dicom - structure containing diffusion images
% nfo - structure containing info about dicom images
% 
% out:
% snr_dicom - structure containing snr estimates
% 
% description:
% 

snr_dicom = [];

cardiacphases = fieldnames(dicom);

for i=1:length(cardiacphases)
    slicelocation = fieldnames(dicom.(cardiacphases{i}));
    for j=1:length(slicelocation)
        SliceData = dicom.(cardiacphases{i}).(slicelocation{j}).SliceData;
        SliceInfo = nfo{j}.SliceInfo;
        mask = contours.myoMask{j};

        bVal = [SliceInfo.B_value];
        [reps,ia,ic] = unique({SliceInfo.SequenceName});
        bv = unique(bVal(ia));
        SNR = struct('SequenceName',reps,'B_Value',num2cell(bVal(ia)));

        for k=1:length(ia)
            DW = cat(3, SliceData(ic == k).regImage);
            count = size(DW,3);
            if count>1
                mu = mean(DW,3);
                sigma = std(DW,0,3);
                sigma(sigma==0) = NaN;
                SNR_map = mu ./ sigma;
                roi_vals = SNR_map(mask > 0);
                SNR_roi = mean(roi_vals, 'omitnan');
                SNR_roi_std = std(roi_vals, 'omitnan');
            else
                SNR_map = NaN(size(DW(:,:,1)));
                SNR_roi = NaN;
                SNR_roi_std = NaN;
            end

            SNR(k).SNR_map = SNR_map;
            SNR(k).SNR_roi = SNR_roi;
            SNR(k).SNR_roi_std = SNR_roi_std;
            SNR(k).repetitions = count;
        end

        B_vals = [SNR.B_Value];
        SNR_vals = [SNR.SNR_roi];

        SNR_mean = arrayfun(@(x) mean(SNR_vals(B_vals==x),'omitnan'), bv);
        SNR_std = arrayfun(@(x) std(SNR_vals(B_vals==x),'omitnan'), bv);
        SNR_std(SNR_std==0) = NaN;

        snr_dicom.(cardiacphases{i}).(slicelocation{j}).SNR = SNR;
        snr_dicom.(cardiacphases{i}).(slicelocation{j}).SNR_mean = SNR_mean;
        snr_dicom.(cardiacphases{i}).(slicelocation{j}).SNR_std = SNR_std;
        snr_dicom.(cardiacphases{i}).(slicelocation{j}).bVal = bv;
    end
end

end